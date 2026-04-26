function avlSweep()
% avlSweep  Parameter sweep with trend plots and CSV export.
%
%   avlSweep()
%
%   Runs several single-variable sweeps, produces one figure per sweep
%   with subplots showing how each aerodynamic output responds, and saves
%   all results to a timestamped CSV in the AVL working directory.
%
%   Sweeps:
%     1. Wing AR          (span fixed, chord changes)
%     2. Htail span       (AR fixed)
%     3. Tail arm
%     4. Dihedral angle
%     5. Payload (n_ducks)

cfg = avlConfig();
V   = 27;

% ── Plot style ────────────────────────────────────────────────────────────
col_stable   = [0.07 0.22 0.29];   % navy
col_unstable = [0.70 0.11 0.11];   % red
col_ref      = [0.60 0.60 0.60];   % gray reference line

% ── Baseline ──────────────────────────────────────────────────────────────
base.wing_span       = 1.2;
base.wing_AR         = 4;
base.dihedral        = 3.5;
base.htail_span      = 0.4;
base.htail_AR        = 2.5;
base.htail_incidence = 2;
base.vtail_height    = 0.2;
base.vtail_AR        = 1.5;
base.tail_arm        = 0.85;
base.nose_x          = -0.25;
base.n_ducks         = 3;
base.n_pucks         = 1;

% ── Define sweeps ─────────────────────────────────────────────────────────
% Each sweep: {title, field, values, x-label}
sweeps = {
    'Wing AR',       'wing_AR',    [2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0], 'Wing AR';
    'Htail Span (m)','htail_span', [0.20, 0.25, 0.30, 0.35, 0.40, 0.50, 0.60], 'Htail span (m)';
    'Tail Arm (m)',  'tail_arm',   [0.50, 0.60, 0.70, 0.80, 0.85, 0.95, 1.10], 'Tail arm (m)';
    'Dihedral (deg)','dihedral',   [0, 2, 3.5, 5, 7, 10], 'Dihedral (deg)';
    'Ducks',         'n_ducks',    [0, 1, 2, 3, 4, 5], 'Number of ducks';
};
n_sweeps = size(sweeps, 1);

% ── Output table accumulator ──────────────────────────────────────────────
all_rows = {};   % cell array of result rows for CSV

% ── Run sweeps ────────────────────────────────────────────────────────────
for si = 1:n_sweeps
    sweep_title = sweeps{si,1};
    sweep_field = sweeps{si,2};
    sweep_vals  = sweeps{si,3};
    sweep_xlabel = sweeps{si,4};
    n_pts = numel(sweep_vals);

    fprintf('\n=== Sweep: %s ===\n', sweep_title)

    % Pre-allocate result vectors
    r_CG   = nan(1, n_pts);   r_Cma  = nan(1, n_pts);
    r_SM   = nan(1, n_pts);   r_CLa  = nan(1, n_pts);
    r_CDi  = nan(1, n_pts);   r_Cnb  = nan(1, n_pts);
    r_Clb  = nan(1, n_pts);   r_pho  = nan(1, n_pts);
    r_spo  = nan(1, n_pts);   r_dro  = nan(1, n_pts);
    r_spt2 = nan(1, n_pts);   r_elev = nan(1, n_pts);

    for pi = 1:n_pts
        g = base;
        g.(sweep_field) = sweep_vals(pi);

        fprintf('  [%d/%d]  %s = %.3g  ', pi, n_pts, sweep_field, sweep_vals(pi))
        try
            mass     = defineMassConfig(g);
            aircraft = massToAVL(mass);
            out      = runAVL(aircraft, V);
            avl      = parseAVLOutput(out.stability_file);
            modes    = computeAVLModes(avl, aircraft, V);

            SM = (avl.Xnp - aircraft.xref) / aircraft.Cref * 100;

            r_CG(pi)  = aircraft.xref / aircraft.Cref * 100;
            r_Cma(pi) = avl.Cma;
            r_SM(pi)  = SM;
            r_CLa(pi) = avl.CLa;
            r_CDi(pi) = avl.CDi;
            r_Cnb(pi) = avl.Cnb;
            r_Clb(pi) = avl.Clb;
            r_pho(pi) = modes.Phugoid.sigma;
            r_spo(pi) = modes.ShortPeriod.sigma;
            r_dro(pi) = modes.DutchRoll.sigma;
            r_spt2(pi)= modes.Spiral.t2;
            r_elev(pi)= avl.elevator;

            fprintf('OK   CG=%.1f%%  Cmα=%+.3f  SM=%+.1f%%\n', r_CG(pi), r_Cma(pi), r_SM(pi))

            % Accumulate for CSV
            all_rows{end+1} = {sweep_title, sweep_vals(pi), ...
                r_CG(pi), r_Cma(pi), r_SM(pi), r_CLa(pi), r_CDi(pi), ...
                r_Cnb(pi), r_Clb(pi), r_pho(pi), r_spo(pi), r_dro(pi), ...
                min(r_spt2(pi), 999), r_elev(pi)};
        catch err
            fprintf('FAILED: %s\n', err.message)
        end
    end

    % ── Plot this sweep ───────────────────────────────────────────────────
    fh = figure('Color', 'w');
    sgtitle(sprintf('Sweep: %s', sweep_title), ...
        'FontSize', 13, 'FontWeight', 'bold')

    subplots = {
        r_Cma,  'Cm_\alpha  (per rad)',    'Pitch stability',       true,  0;
        r_SM,   'Static margin (%MAC)',    'Static margin',         false, 5;
        r_CLa,  'CL_\alpha  (per rad)',    'Lift curve slope',      false, 0;
        r_CDi,  'CDi  (Trefftz)',          'Induced drag',          false, 0;
        r_CG,   'CG  (%MAC)',              'CG position',           false, 0;
        r_Clb,  'Cl_\beta  (per rad)',     'Dihedral effect',       true,  0;
        r_Cnb,  'Cn_\beta  (per rad)',     'Weathercock stability', false, 0;
        r_pho,  'Phugoid \sigma',          'Phugoid',               true,  0;
        r_spo,  'Short period \sigma',     'Short period',          true,  0;
        r_dro,  'Dutch roll \sigma',       'Dutch roll',            true,  0;
        r_elev, 'Elevator trim (deg)',     'Trim elevator',         false, 0;
        r_spt2, 'Spiral t_2 (s, cap 999)','Spiral doubling time',  false, 0;
    };
    n_sub = size(subplots, 1);
    n_cols = 4;
    n_rows = ceil(n_sub / n_cols);

    % Baseline value of sweep variable for reference line
    if isfield(base, sweep_field)
        base_val = base.(sweep_field);
    else
        base_val = NaN;
    end

    for k = 1:n_sub
        y_data      = subplots{k,1};
        y_label     = subplots{k,2};
        sub_title   = subplots{k,3};
        zero_ref    = subplots{k,4};   % draw y=0 line
        thresh      = subplots{k,5};   % draw threshold line

        ax = subplot(n_rows, n_cols, k);
        hold(ax, 'on');

        % Color points by stability if this is a sigma plot
        if zero_ref
            for pi = 1:n_pts
                if isnan(y_data(pi)), continue; end
                c = col_stable;
                if y_data(pi) > 0, c = col_unstable; end
                plot(ax, sweep_vals(pi), y_data(pi), 'o', ...
                    'MarkerFaceColor', c, 'MarkerEdgeColor', c*0.7, ...
                    'MarkerSize', 6, 'HandleVisibility', 'off')
            end
            % Connect with line
            plot(ax, sweep_vals, y_data, '-', 'Color', [0.6 0.6 0.6], ...
                'LineWidth', 1, 'HandleVisibility', 'off')
            yline(ax, 0, '--', 'Color', col_unstable, 'LineWidth', 0.8, ...
                'HandleVisibility', 'off')
        else
            plot(ax, sweep_vals, y_data, 'o-', ...
                'Color', col_stable, 'MarkerFaceColor', col_stable, ...
                'MarkerEdgeColor', col_stable*0.7, 'MarkerSize', 6, ...
                'LineWidth', 1.5, 'HandleVisibility', 'off')
        end

        % Threshold line if specified
        if thresh ~= 0
            yline(ax, thresh, '--', 'Color', [0.85 0.5 0.0], ...
                'LineWidth', 0.9, 'HandleVisibility', 'off')
        end

        % Baseline reference line
        if ~isnan(base_val)
            xline(ax, base_val, ':', 'Color', [0.6 0.6 0.6], ...
                'LineWidth', 0.8, 'HandleVisibility', 'off')
        end

        xlabel(ax, sweep_xlabel, 'FontSize', 8)
        ylabel(ax, y_label, 'FontSize', 8)
        title(ax, sub_title, 'FontSize', 9, 'FontWeight', 'normal')
        grid(ax, 'on'); box(ax, 'on');
        hold(ax, 'off');
    end

    % % Save figure as PNG
    % timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    % fname = fullfile(cfg.work_dir, ...
    %     sprintf('sweep_%s_%s.png', strrep(sweep_title,' ','_'), timestamp));
    % exportgraphics(fh, fname, 'Resolution', 150)
    % fprintf('  Figure saved: %s\n', fname)
end

% ── Save CSV ──────────────────────────────────────────────────────────────
csv_file = fullfile(cfg.work_dir, ...
    sprintf('avlSweep_%s.csv', datestr(now, 'yyyymmdd_HHMMSS')));

fid = fopen(csv_file, 'w');
fprintf(fid, 'sweep,value,CG_pct,Cma,SM_pct,CLa,CDi,Cnb,Clb,ph_sigma,sp_sigma,dr_sigma,spiral_t2,elevator_deg\n');
for k = 1:numel(all_rows)
    r = all_rows{k};
    fprintf(fid, '%s,%.4g,%.3f,%.4f,%.3f,%.4f,%.6f,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.3f\n', ...
        r{1}, r{2}, r{3}, r{4}, r{5}, r{6}, r{7}, r{8}, r{9}, r{10}, r{11}, r{12}, r{13}, r{14});
end
fclose(fid);

fprintf('\nAll results saved to:\n  %s\n', csv_file)
fprintf('Open in Excel or paste into the chat to review.\n')

end