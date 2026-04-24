function avlValidation()
% avlValidation  Sanity-check plots for the AVL pipeline.
%
%   avlValidation()
%
%   Runs a series of parameter sweeps and plots the results against
%   analytical predictions or physical intuition. If the curves look
%   wrong, something in the pipeline is broken.
%
%   Tests:
%     1. CLa vs AR              -- compared against Prandtl lifting line
%     2. CDi vs CL^2            -- must be a straight line through origin
%     3. Static margin vs CG    -- slope must equal -1 (pure geometry)
%     4. Cma vs htail volume    -- must become more negative with more tail
%     5. Trim elevator vs CG    -- must be monotonic: aft CG = more elevator

fprintf('=== AVL Validation Suite ===\n\n')

geom0 = defineGeom();   % baseline geometry
V     = 27;             % cruise velocity for all runs

% ── Shared style ──────────────────────────────────────────────────────────
col_avl  = [0.07 0.22 0.29];   % navy  -- AVL results
col_pred = [0.70 0.11 0.11];   % red   -- analytical prediction
lw = 2.0;

% =========================================================================
%% Test 1: CLa vs AR  (Prandtl Lifting Line comparison)
% =========================================================================
% Prandtl: CLa = 2*pi*AR / (AR + 2)  [per radian, thin airfoil]
% AVL uses the actual FX 63-137 camber so we expect a small positive offset,
% but the trend should track well. If the slope is way off, something in the
% geometry or panel count is wrong.

fprintf('Test 1: CLa vs AR...\n')
AR_vec = [2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0];
CLa_avl  = zeros(size(AR_vec));
CLa_pred = zeros(size(AR_vec));

for i = 1:numel(AR_vec)
    g = modifyGeom(geom0, 'wing_AR', AR_vec(i));
    avl = quickRun(g, V);
    if ~isempty(avl)
        CLa_avl(i)  = avl.CLa;
    end
    CLa_pred(i) = 2*pi*AR_vec(i) / (AR_vec(i) + 2);
end

figure; hold on;
plot(AR_vec, CLa_avl,  'o-',  'Color', col_avl,  'LineWidth', lw, ...
     'MarkerFaceColor', col_avl,  'MarkerSize', 7, 'DisplayName', 'AVL')
plot(AR_vec, CLa_pred, '--',  'Color', col_pred, 'LineWidth', lw, ...
     'DisplayName', 'Prandtl lifting line')
xlabel('Aspect Ratio',           'FontSize', 11)
ylabel('CL_\alpha  (per rad)',   'FontSize', 11)
title('Test 1 — CLα vs AR', 'FontSize', 12, 'FontWeight', 'normal')
legend('Location', 'northwest', 'FontSize', 10)
grid on; box on;
annotation_box(gca, ...
    'AVL includes tail surfaces so whole-aircraft CLa < isolated wing.', ...
    'Trend must match slope of lifting line. Parallel curves = pass.')

% =========================================================================
%% Test 2: CDi vs CL^2  (must be a straight line through origin)
% =========================================================================
% Induced drag: CDi = CL^2 / (pi * e * AR)
% So CDi vs CL^2 must be linear through origin with slope 1/(pi*e*AR).
% We sweep velocity to get different CL values at the same geometry.

fprintf('Test 2: CDi vs CL^2...\n')
V_vec = [14, 16, 18, 20, 22, 24, 27, 30, 34];
CL_vec  = zeros(size(V_vec));
CDi_vec = zeros(size(V_vec));

for i = 1:numel(V_vec)
    avl = quickRun(geom0, V_vec(i));
    if ~isempty(avl)
        CL_vec(i)  = avl.CL;
        CDi_vec(i) = avl.CDi;
    end
end

CL2 = CL_vec.^2;

% Fit a line through origin to get effective e
slope_fit = CL2(:) \ CDi_vec(:);   % least squares through origin
e_fit     = 1 / (pi * geom0.AR * slope_fit);
CL2_line  = linspace(0, max(CL2)*1.1, 50);

figure; hold on;
plot(CL2, CDi_vec, 'o', 'Color', col_avl, 'MarkerFaceColor', col_avl, ...
     'MarkerSize', 8, 'DisplayName', 'AVL points')
plot(CL2_line, slope_fit*CL2_line, '--', 'Color', col_pred, 'LineWidth', lw, ...
     'DisplayName', sprintf('Linear fit  (e = %.3f)', e_fit))
xlabel('C_L^2',          'FontSize', 11)
ylabel('C_{Di}',         'FontSize', 11)
title('Test 2 — CDi vs CL²', 'FontSize', 12, 'FontWeight', 'normal')
legend('Location', 'northwest', 'FontSize', 10)
grid on; box on;
annotation_box(gca, ...
    'Points must fall on a straight line through the origin.', ...
    sprintf('Fitted Oswald e = %.3f  (expect 0.85–0.92 for rectangular wing)', e_fit))

% =========================================================================
%% Test 3: Static Margin vs CG position  (slope must be exactly -1)
% =========================================================================
% Static margin = (Xnp - Xcg) / MAC
% Xnp is fixed for a given geometry. Moving Xcg aft by ΔMAC reduces SM by Δ%.
% Slope of SM vs Xcg must be exactly -1/MAC * 100 = -100 %/m ... 
% or equivalently, slope of SM(%) vs CG(% MAC) must be exactly -1.

fprintf('Test 3: Static margin vs CG...\n')
cg_pct_vec = [15, 20, 25, 30, 35, 40, 45];
SM_vec = zeros(size(cg_pct_vec));

for i = 1:numel(cg_pct_vec)
    g = modifyGeom(geom0, 'cg_pct', cg_pct_vec(i));
    avl = quickRun(g, V);
    if ~isempty(avl)
        Xcg = g.xref;
        SM_vec(i) = (avl.Xnp - Xcg) / g.Cref * 100;
    end
end

% Analytical prediction: slope = -1 through (cg_pct, SM) space
% Fit to find Xnp in %MAC terms
cg_mid  = mean(cg_pct_vec);
SM_mid  = mean(SM_vec);
SM_pred = SM_mid + (-1) * (cg_pct_vec - cg_mid);   % slope exactly -1

figure; hold on;
plot(cg_pct_vec, SM_vec,  'o-',  'Color', col_avl,  'LineWidth', lw, ...
     'MarkerFaceColor', col_avl, 'MarkerSize', 7, 'DisplayName', 'AVL')
plot(cg_pct_vec, SM_pred, '--',  'Color', col_pred, 'LineWidth', lw, ...
     'DisplayName', 'Expected slope = -1')
yline(0, 'k:', 'LineWidth', 1, 'HandleVisibility', 'off')
yline(5, '--', 'Color', [0.8 0.4 0.0], 'LineWidth', 1, 'HandleVisibility', 'off')
text(cg_pct_vec(end)*0.98, 2, 'min SM', 'FontSize', 9, ...
     'Color', [0.8 0.4 0.0], 'HorizontalAlignment', 'right')
xlabel('CG position (% MAC)',     'FontSize', 11)
ylabel('Static Margin (%MAC)',    'FontSize', 11)
title('Test 3 — Static Margin vs CG', 'FontSize', 12, 'FontWeight', 'normal')
legend('Location', 'northeast', 'FontSize', 10)
grid on; box on;
annotation_box(gca, ...
    'AVL points must lie exactly on the slope = -1 line.', ...
    'Any deviation means Xnp is shifting (it should not with geometry fixed).')

% =========================================================================
%% Test 4: Cma vs horizontal tail volume coefficient
% =========================================================================
% More tail volume = more pitch restoring moment = more negative Cma.
% We scale htail span while keeping everything else fixed.
% Direction must be consistently negative with increasing Vht.

fprintf('Test 4: Cma vs htail volume...\n')
htail_span_vec = [0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60];
Cma_vec = zeros(size(htail_span_vec));
Vht_vec = zeros(size(htail_span_vec));

for i = 1:numel(htail_span_vec)
    g = modifyGeom(geom0, 'htail_span', htail_span_vec(i));
    avl = quickRun(g, V);
    if ~isempty(avl)
        Cma_vec(i) = avl.Cma;
        Vht_vec(i) = g.Vht;
    end
end

figure; hold on;
plot(Vht_vec, Cma_vec, 'o-', 'Color', col_avl, 'LineWidth', lw, ...
     'MarkerFaceColor', col_avl, 'MarkerSize', 7, 'DisplayName', 'AVL')
yline(0, 'k--', 'LineWidth', 1, 'HandleVisibility', 'off')
text(mean(Vht_vec), 0.005, 'unstable', 'FontSize', 9, ...
     'Color', col_pred, 'HorizontalAlignment', 'center')
text(mean(Vht_vec), -0.005, 'stable', 'FontSize', 9, ...
     'Color', [0.0 0.45 0.15], 'HorizontalAlignment', 'center')
xlabel('Horizontal Tail Volume Coefficient V_{ht}', 'FontSize', 11)
ylabel('Cm_\alpha  (per rad)',                       'FontSize', 11)
title('Test 4 — Cmα vs Htail Volume', 'FontSize', 12, 'FontWeight', 'normal')
legend('Location', 'northeast', 'FontSize', 10)
grid on; box on;
annotation_box(gca, ...
    'Cmα must become more negative as tail volume increases.', ...
    'A non-monotonic trend would indicate a geometry or parsing error.')

% =========================================================================
%% Test 5: Trim elevator vs CG position
% =========================================================================
% Aft CG = more nose-up tendency = more trailing-edge-up elevator to trim.
% Should be monotonically increasing (more positive elevator) as CG moves aft.

fprintf('Test 5: Trim elevator vs CG...\n')
% NOTE: buildAVLMass writes fixed point masses whose CG AVL computes and
% applies via MSET, overriding geom.xref. For this test we need to actually
% move the CG, so we write a single lumped mass at the desired location.
elev_vec = zeros(size(cg_pct_vec));

for i = 1:numel(cg_pct_vec)
    g = modifyGeom(geom0, 'cg_pct', cg_pct_vec(i));
    writeLumpedMassFile(g);          % single mass at g.xref
    avl = quickRun(g, V);
    if ~isempty(avl)
        elev_vec(i) = avl.elevator;
    end
end
% Restore real mass file for any subsequent runs
buildAVLMass(geom0);

figure; hold on;
plot(cg_pct_vec, elev_vec, 'o-', 'Color', col_avl, 'LineWidth', lw, ...
     'MarkerFaceColor', col_avl, 'MarkerSize', 7)
yline(0, 'k:', 'LineWidth', 1)
xlabel('CG position (% MAC)',        'FontSize', 11)
ylabel('Trim elevator deflection (deg)', 'FontSize', 11)
title('Test 5 — Trim Elevator vs CG', 'FontSize', 12, 'FontWeight', 'normal')
grid on; box on;
annotation_box(gca, ...
    'Elevator deflection must increase monotonically as CG moves aft.', ...
    'Non-monotonic or wrong sign indicates a trim or geometry issue.')

fprintf('\nAll tests complete.\n')
fprintf('Check each plot against the annotation for pass/fail.\n')

end


% ── Run AVL and return parsed output, or empty on failure ─────────────────
function avl = quickRun(geom, V)
    try
        out = runAVL(geom, V);
        avl = parseAVLOutput(out.stability_file);
    catch
        avl = [];
        warning('quickRun: AVL failed for this parameter point, skipping.')
    end
end


% ── Modify a single geometric parameter on the baseline geom ─────────────
function g = modifyGeom(g0, param, val)
    g = g0;
    switch param
        case 'wing_AR'
            % Keep span fixed, change chord to hit new AR
            new_chord   = g.Bref / val;
            g.Cref      = new_chord;
            g.Sref      = g.Bref * new_chord;
            g.AR        = val;
            g.MAC       = new_chord;
            g.wing.chord_root = new_chord;
            g.wing.chord_tip  = new_chord;
            % Recompute tail volume coefficients
            g.Vht = (g.htail.span * g.htail.chord_root * g.htail.moment_arm) ...
                    / (g.Sref * g.Cref);
            g.Vvt = (g.vtail.height * g.vtail.chord_root * g.vtail.moment_arm) ...
                    / (g.Sref * g.Bref);

        case 'cg_pct'
            g.xref = (val / 100) * g.Cref;

        case 'htail_span'
            g.htail.span = val;
            g.Vht = (val * g.htail.chord_root * g.htail.moment_arm) ...
                    / (g.Sref * g.Cref);
    end
end


% ── Write a single lumped mass at geom.xref for CG sweep tests ───────────
function writeLumpedMassFile(geom)
% Replaces the real mass breakdown with a single point mass at the desired
% CG location. This lets us sweep CG position without the real mass file
% overriding it via MSET.
    cfg      = avlConfig();
    mass_file = fullfile(cfg.work_dir, 'dfo.mass');
    fid = fopen(mass_file, 'w');
    fprintf(fid, 'Lunit = 1.0 m\n');
    fprintf(fid, 'Munit = 1.0 kg\n');
    fprintf(fid, 'Tunit = 1.0 s\n\n');
    fprintf(fid, 'g   = 9.81\n');
    fprintf(fid, 'rho = 1.225\n\n');
    fprintf(fid, '%.4f  %.4f  0.0000  %.4f\n', ...
        geom.mass, geom.xref, geom.zref);
    fclose(fid);
end


% ── Add a small annotation box to a plot ─────────────────────────────────
function annotation_box(ax, line1, line2)
    xl = xlim(ax);
    yl = ylim(ax);
    x  = xl(1) + 0.02*(xl(2)-xl(1));
    y  = yl(1) + 0.05*(yl(2)-yl(1));
    text(ax, x, y, sprintf('%s\n%s', line1, line2), ...
         'FontSize', 8, 'Color', [0.4 0.4 0.4], ...
         'VerticalAlignment', 'bottom', ...
         'BackgroundColor', [0.97 0.97 0.97], ...
         'EdgeColor', [0.8 0.8 0.8])
end