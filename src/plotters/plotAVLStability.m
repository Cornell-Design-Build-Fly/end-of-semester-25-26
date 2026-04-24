function plotAVLStability(modes)
% plotAVLStability  Eigenvalue and doubling time plots from AVL modes struct.
%
%   plotAVLStability(modes)
%
%   Produces two figures:
%     1. Root map: longitudinal (left) and lateral (right) side by side,
%        with damping ratio guide lines and direct mode labels.
%     2. Doubling time bar chart for any unstable modes.

col_stable   = [0.07 0.22 0.29];   % navy  -- stable modes
col_unstable = [0.70 0.11 0.11];   % red   -- unstable modes
col_guide    = [0.65 0.65 0.65];   % gray  -- zeta lines

lon_modes = {'Phugoid', 'Short Period'};
lon_data  = {modes.Phugoid, modes.ShortPeriod};
lat_modes = {'Dutch Roll', 'Roll', 'Spiral'};
lat_data  = {modes.DutchRoll, modes.Roll, modes.Spiral};

% ── Figure 1: Root map ────────────────────────────────────────────────────
figure('Color', 'w');

titles    = {'Longitudinal Modes', 'Lateral Modes'};
mode_sets = {lon_data, lat_data};
name_sets = {lon_modes, lat_modes};

for panel = 1:2
    ax = subplot(1, 2, panel);
    hold on;

    mdata = mode_sets{panel};
    mnames = name_sets{panel};

    % Collect all sigma/omega to size the axes
    all_sigma = [];
    all_omega = [];
    for k = 1:numel(mdata)
        all_sigma(end+1) = mdata{k}.sigma;
        all_omega(end+1) = abs(mdata{k}.omega);
    end

    % Axis limits with some breathing room
    sig_min = min(all_sigma);
    sig_max = max(all_sigma);
    om_max  = max(all_omega);

    pad_x = max(abs([sig_min sig_max])) * 0.5 + 0.05;
    pad_y = om_max * 0.4 + 0.05;

    x_lo = sig_min - pad_x;
    x_hi = max(sig_max + pad_x, pad_x);   % always show some right-half plane
    y_hi = om_max + pad_y;

    % Unstable half-plane shading
    patch([0, x_hi, x_hi, 0], [-y_hi, -y_hi, y_hi, y_hi], ...
          [1.0 0.93 0.93], 'EdgeColor', 'none', 'FaceAlpha', 0.5)

    % Damping ratio guide lines (from origin, angle arccos(zeta))
    for zeta = [0.3, 0.7]
        slope = sqrt(1 - zeta^2) / zeta;  % omega / |sigma| at this zeta
        r = max(abs(x_lo), y_hi) * 1.5;
        plot([-r, 0], [slope*r, 0], '--', 'Color', col_guide, 'LineWidth', 0.8, 'HandleVisibility','off')
        plot([-r, 0], [-slope*r, 0], '--', 'Color', col_guide, 'LineWidth', 0.8, 'HandleVisibility','off')
        text(-r*0.88, slope*r*0.88, sprintf('\\zeta=%.1f', zeta), ...
             'Color', col_guide, 'FontSize', 8, 'HorizontalAlignment', 'center')
    end

    % Axes
    xline(0, 'k', 'LineWidth', 1.2, 'HandleVisibility', 'off')
    yline(0, 'k', 'LineWidth', 0.8, 'HandleVisibility', 'off')

    % Plot each mode
    for k = 1:numel(mdata)
        m = mdata{k};
        is_unstable = m.sigma > 0;
        col = col_stable;
        if is_unstable, col = col_unstable; end

        if abs(m.omega) > 0.01
            % Complex pair -- plot both conjugates
            plot([m.sigma m.sigma], [m.omega -m.omega], 'x', ...
                 'Color', col, 'MarkerSize', 11, 'LineWidth', 2.2, ...
                 'HandleVisibility', 'off')
            % Label above the upper conjugate
            text(m.sigma, m.omega + pad_y*0.25, mnames{k}, ...
                 'Color', col, 'FontSize', 9, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center')
        else
            % Real root
            plot(m.sigma, 0, 'x', ...
                 'Color', col, 'MarkerSize', 11, 'LineWidth', 2.2, ...
                 'HandleVisibility', 'off')
            text(m.sigma, pad_y*0.18, mnames{k}, ...
                 'Color', col, 'FontSize', 9, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center')
        end
    end

    xlim([x_lo, x_hi])
    ylim([-y_hi, y_hi])
    xlabel('Real  (growth rate, s^{-1})',  'FontSize', 10)
    ylabel('Imaginary  (frequency, rad/s)', 'FontSize', 10)
    title(titles{panel}, 'FontSize', 11, 'FontWeight', 'normal')
    grid on; box on;
    set(ax, 'Layer', 'top')
    hold off;
end

sgtitle('Stability Root Map', 'FontSize', 13, 'FontWeight', 'bold')

% ── Figure 2: Doubling times ──────────────────────────────────────────────
all_mode_keys   = {'Phugoid', 'ShortPeriod', 'DutchRoll', 'Roll', 'Spiral'};
all_mode_labels = {'Phugoid', 'Short Period', 'Dutch Roll', 'Roll', 'Spiral'};

unstable_labels = {};
unstable_t2     = [];

for k = 1:numel(all_mode_keys)
    m = modes.(all_mode_keys{k});
    if isfinite(m.t2)
        fprintf('Mode: %-14s  t2 = %.3f s\n', all_mode_labels{k}, m.t2)
        unstable_labels{end+1} = all_mode_labels{k};
        unstable_t2(end+1)     = m.t2;
    end
end

if isempty(unstable_labels)
    fprintf('All modes are stable -- no doubling times to report.\n')
    return
end

figure('Color', 'w');
hold on;
title('Mode Doubling Times', 'FontSize', 12, 'FontWeight', 'normal')
xlabel('Time to double amplitude (s)', 'FontSize', 10)

x_max = max(max(unstable_t2) * 1.3, 12);
bar_h = 0.35;

for k = 1:numel(unstable_labels)
    t2 = unstable_t2(k);
    y  = [k-bar_h/2, k-bar_h/2, k+bar_h/2, k+bar_h/2];

    patch([0, min(3,x_max), min(3,x_max), 0], y, ...
          [0.90 0.20 0.20], 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    if x_max > 3
        patch([3, min(8,x_max), min(8,x_max), 3], y, ...
              [0.95 0.60 0.10], 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    end
    if x_max > 8
        patch([8, x_max, x_max, 8], y, ...
              [0.20 0.70 0.30], 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    end

    plot([t2 t2], [k-bar_h/2-0.05, k+bar_h/2+0.05], ...
         'k-', 'LineWidth', 2.5, 'HandleVisibility', 'off')
    text(t2 + x_max*0.02, k, sprintf('%.1f s', t2), ...
         'VerticalAlignment', 'middle', 'FontSize', 10)
end

xline(3, 'r--', 'LineWidth', 1.2, 'HandleVisibility', 'off')
xline(8, '--', 'Color', [0.85 0.50 0.0], 'LineWidth', 1.2, 'HandleVisibility', 'off')

set(gca, 'YTick', 1:numel(unstable_labels), ...
         'YTickLabel', unstable_labels, 'FontSize', 11)
xlim([0 x_max])
ylim([0.5, numel(unstable_labels) + 0.5])
grid on; box on;
hold off;

end