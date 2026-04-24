function plotMassLayout(mass)
% plotMassLayout  Side-view and top-down mass layout diagrams.
%
%   plotMassLayout(mass)
%
%   Two figures:
%     Figure 1 -- side view (XZ plane): component positions, CG, surfaces
%     Figure 2 -- top view  (XY plane): planform layout with mass projections

col_struct = [0.07 0.22 0.29];   % navy  -- structure
col_prop   = [0.70 0.11 0.11];   % red   -- propulsion / electronics
col_pay    = [0.20 0.55 0.20];   % green -- payload
col_fus    = [0.75 0.75 0.75];   % light gray -- fuselage tube

% Convenience
wc   = mass.wing_chord;
ws   = mass.wing_span;
hxl  = mass.htail_x_le;
hxr  = hxl + mass.htail_chord;
hhs  = mass.htail_span / 2;
nx   = mass.nose_x;
vxl  = mass.vtail_x_le;
vxr  = vxl + mass.vtail_chord;
vh   = mass.vtail_height;
fus_w = 0.05;   % visual fuselage half-width [m]

% ═════════════════════════════════════════════════════════════════════════
%% Figure 1 — Side view (XZ)
% ═════════════════════════════════════════════════════════════════════════
figure('Color', 'w');
hold on;

% Fuselage tube
patch([nx, hxr, hxr, nx], [-fus_w, -fus_w, fus_w, fus_w]*0.4, ...
    col_fus, 'FaceAlpha', 0.25, 'EdgeColor', col_fus*0.7, 'LineWidth', 1.0, ...
    'HandleVisibility', 'off')

% Wing (thin chordwise slab)
wh = 0.018;
patch([0, wc, wc, 0], [-wh, -wh, wh, wh], ...
    col_struct, 'FaceAlpha', 0.20, 'EdgeColor', col_struct, 'LineWidth', 1.4, ...
    'HandleVisibility', 'off')

% Htail
th = 0.010;
patch([hxl, hxr, hxr, hxl], [-th, -th, th, th], ...
    col_struct, 'FaceAlpha', 0.20, 'EdgeColor', col_struct, 'LineWidth', 1.2, ...
    'HandleVisibility', 'off')

% Vtail (true chord width, spans upward from z=0)
patch([vxl, vxr, vxr, vxl], [th, th, th+vh, th+vh], ...
    col_struct, 'FaceAlpha', 0.15, 'EdgeColor', col_struct, 'LineWidth', 1.0, ...
    'HandleVisibility', 'off')

% Wing LE / TE reference lines
xline(0,  ':', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8, 'HandleVisibility', 'off')
xline(wc, ':', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8, 'HandleVisibility', 'off')

% Mass bubbles
r_scale = 0.018;
for k = 1:numel(mass.m_vec)
    xi   = mass.x_vec(k);
    zi   = mass.z_vec(k);
    r    = r_scale * sqrt(mass.m_vec(k));
    name = mass.names{k};
    col  = classifyColor(name, col_struct, col_prop, col_pay);

    theta = linspace(0, 2*pi, 40);
    fill(xi + r*cos(theta), zi + r*sin(theta), col, ...
         'FaceAlpha', 0.80, 'EdgeColor', col*0.55, 'LineWidth', 0.7, ...
         'HandleVisibility', 'off')

    % Label above bubble, avoid overlap with a small offset
    text(xi, zi + r + 0.008, name, ...
         'FontSize', 7.5, 'HorizontalAlignment', 'center', ...
         'Color', col*0.65, 'Interpreter', 'none', 'FontWeight', 'normal')
end

% CG
plot(mass.CG(1), mass.CG(3), 'x', 'Color', [0.85 0.1 0.1], ...
     'MarkerSize', 16, 'LineWidth', 2.8, 'HandleVisibility', 'off')
text(mass.CG(1), mass.CG(3) - 0.030, ...
     sprintf('CG  %.3f m  (%.1f%% MAC)', mass.CG(1), mass.CG(1)/wc*100), ...
     'HorizontalAlignment', 'center', 'FontSize', 9, ...
     'Color', [0.75 0.05 0.05], 'FontWeight', 'bold')

xlabel('x  (m from wing LE,  + aft)',   'FontSize', 10)
ylabel('z  (m,  + up)',                 'FontSize', 10)
title(sprintf('Side View  —  %.3f kg   CG at %.1f%% MAC', ...
    mass.total, mass.CG(1)/wc*100), 'FontSize', 11, 'FontWeight', 'normal')

% Tidy axes -- do NOT use axis equal here, z range is tiny vs x range
xl = [min(nx, -0.08) - 0.05,  hxr + 0.10];
yl = [-0.12, vh + 0.08];
xlim(xl); ylim(yl);
grid on; box on; axis equal;
hold off;

% ═════════════════════════════════════════════════════════════════════════
%% Figure 2 — Top view (XY)
% ═════════════════════════════════════════════════════════════════════════
figure('Color', 'w');
hold on;

% Fuselage tube (top view: narrow rectangle along x)
patch([nx, hxr, hxr, nx], [-fus_w, -fus_w, fus_w, fus_w], ...
    col_fus, 'FaceAlpha', 0.30, 'EdgeColor', col_fus*0.7, 'LineWidth', 1.0, ...
    'HandleVisibility', 'off')

% Wing planform (full span, both halves)
patch([0, wc, wc, 0], [-ws/2, -ws/2, ws/2, ws/2], ...
    col_struct, 'FaceAlpha', 0.15, 'EdgeColor', col_struct, 'LineWidth', 1.5, ...
    'HandleVisibility', 'off')

% Htail planform
patch([hxl, hxr, hxr, hxl], [-hhs, -hhs, hhs, hhs], ...
    col_struct, 'FaceAlpha', 0.15, 'EdgeColor', col_struct, 'LineWidth', 1.2, ...
    'HandleVisibility', 'off')

% Vtail (centerline projection -- top view shows it as a chordwise line)
plot([vxl, vxr], [0, 0], '-', 'Color', col_struct, 'LineWidth', 2.5, ...
     'HandleVisibility', 'off')

% Centerline
yline(0, ':', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8, 'HandleVisibility', 'off')
xline(0,  ':', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8, 'HandleVisibility', 'off')
xline(wc, ':', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8, 'HandleVisibility', 'off')

% Mass dots (all at y=0 since symmetric; size by mass)
r_scale_top = 0.014;
labeled = {};   % track names already labeled to avoid duplicate text
for k = 1:numel(mass.m_vec)
    xi   = mass.x_vec(k);
    r    = r_scale_top * sqrt(mass.m_vec(k));
    name = mass.names{k};
    col  = classifyColor(name, col_struct, col_prop, col_pay);

    theta = linspace(0, 2*pi, 40);
    fill(xi + r*cos(theta), r*sin(theta), col, ...
         'FaceAlpha', 0.80, 'EdgeColor', col*0.55, 'LineWidth', 0.7, ...
         'HandleVisibility', 'off')

    if ~ismember(name, labeled)
        text(xi, r + 0.012, name, ...
             'FontSize', 7.5, 'HorizontalAlignment', 'center', ...
             'Color', col*0.65, 'Interpreter', 'none')
        labeled{end+1} = name;
    end
end

% CG
plot(mass.CG(1), 0, 'x', 'Color', [0.85 0.1 0.1], ...
     'MarkerSize', 16, 'LineWidth', 2.8, 'HandleVisibility', 'off')
text(mass.CG(1), -fus_w - 0.025, ...
     sprintf('CG  %.3f m', mass.CG(1)), ...
     'HorizontalAlignment', 'center', 'FontSize', 9, ...
     'Color', [0.75 0.05 0.05], 'FontWeight', 'bold')

xlabel('x  (m from wing LE,  + aft)',   'FontSize', 10)
ylabel('y  (m,  + right wing)',         'FontSize', 10)
title(sprintf('Top View  —  %.3f kg   CG at %.1f%% MAC', ...
    mass.total, mass.CG(1)/wc*100), 'FontSize', 11, 'FontWeight', 'normal')

xlim([min(nx,-0.08) - 0.05,  hxr + 0.10])
ylim([-ws/2 - 0.06,  ws/2 + 0.06])
grid on; box on; axis equal;
hold off;

end


function col = classifyColor(name, col_struct, col_prop, col_pay)
    if contains(name, {'Motor','Battery','Nosecone','Receiver','Servo','Gyro','Gear','Fastener'})
        col = col_prop;
    elseif contains(name, {'Duck','Puck'})
        col = col_pay;
    else
        col = col_struct;
    end
end