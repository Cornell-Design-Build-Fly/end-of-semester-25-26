%% DBF Stability & Mission Performance — Live Script
% Run parseXFLR5 first, then work through each section.
% Each section (Ctrl+Enter) is self-contained.

%% 0  ── Load data ─────────────────────────────────────────────────────────
aero = parseXFLR5('output.txt');   % <-- change filename as needed

% Quick text summary
fprintf('=== Operating Point ===\n')
fprintf('  V     = %.3f m/s\n',  aero.V)
fprintf('  alpha = %.3f deg\n',  aero.alpha)
fprintf('  CL    = %.5f\n',      aero.CL)

% CD: use total if parsed, otherwise sum components
CD_use = aero.CD;
if isnan(CD_use) && ~isnan(aero.CD_induced) && ~isnan(aero.CD_profile)
    CD_use = aero.CD_induced + aero.CD_profile;
end
LD_use = aero.CL / CD_use;

fprintf('  CD    = %.5f\n',      CD_use)
fprintf('  L/D   = %.2f\n',      LD_use)
fprintf('  XNP   = %.4f m\n',    aero.XNP)
fprintf('\n=== Key Derivatives ===\n')
fprintf('  CLa = %7.4f  (lift curve slope)\n',   aero.CLa)
fprintf('  Cma = %7.4f  (pitch stab, need < 0)\n', aero.Cma)
fprintf('  Cmq = %7.4f  (pitch damp, need < 0)\n', aero.Cmq)
fprintf('  Cnb = %7.4f  (yaw stab,   need > 0)\n', aero.Cnb)
fprintf('  Clp = %7.4f  (roll damp,  need < 0)\n', aero.Clp)
fprintf('  Cnr = %7.4f  (yaw damp,   need < 0)\n', aero.Cnr)


%% 1  ── Root Locus — all 5 flight modes ──────────────────────────────────
% Shows where each mode sits on the complex plane.
% Left-half plane = stable. Shaded red zone = unstable.
% Iso-damping lines help judge "how stable" — you want zeta > 0.05 minimum.

figure('Name','Root Locus','Color','w','Position',[60 80 820 520])

modes = { ...
    'Short period',  aero.modes.ShortPeriod, [0.18 0.45 0.75], 'o', 12; ...
    'Phugoid',       aero.modes.Phugoid,     [0.20 0.63 0.55], 's', 11; ...
    'Roll',          aero.modes.Roll,         [0.88 0.55 0.20], '^', 12; ...
    'Dutch roll',    aero.modes.DutchRoll,    [0.55 0.22 0.70], 'd', 11; ...
    'Spiral',        aero.modes.Spiral,       [0.80 0.20 0.22], 'p', 14; ...
};

hold on

% ── Unstable region shading
yl = [-15 15];
xl = [-12 5];
patch([0 xl(2) xl(2) 0], [yl(1) yl(1) yl(2) yl(2)], ...
      [1 0.88 0.88], 'FaceAlpha',0.25, 'EdgeColor','none', 'HandleVisibility','off')
text(3.0, 13.5, 'UNSTABLE', 'Color',[0.75 0.10 0.10], ...
     'FontSize',9, 'FontWeight','bold', 'HorizontalAlignment','right')

% ── Iso-damping lines (zeta = 0.05, 0.1, 0.3, 0.5)
zetas = [0.05 0.10 0.30 0.50];
theta = linspace(pi/2, pi, 200);
r     = 15;
for z = zetas
    ang  = pi - acos(z);
    xlin = r * cos(linspace(pi/2, ang, 200));
    ylin = r * sin(linspace(pi/2, ang, 200));
    plot(xlin,  ylin, '--', 'Color',[0.75 0.75 0.75], 'LineWidth',0.7, 'HandleVisibility','off')
    plot(xlin, -ylin, '--', 'Color',[0.75 0.75 0.75], 'LineWidth',0.7, 'HandleVisibility','off')
    text(xlin(end)*1.04, ylin(end)*1.04, sprintf('\\zeta=%.2f',z), ...
         'FontSize',7.5, 'Color',[0.60 0.60 0.60])
end

% ── Axes
xline(0, 'k-', 'LineWidth',1.2, 'HandleVisibility','off')
yline(0, 'k-', 'LineWidth',0.6, 'HandleVisibility','off')

% ── Mode markers (plot conjugate pairs together)
for k = 1:size(modes,1)
    nm  = modes{k,1};
    md  = modes{k,2};
    col = modes{k,3};
    mk  = modes{k,4};
    sz  = modes{k,5};

    sigma = md.sigma;
    omega = md.omega;

    if abs(omega) > 0.01     % oscillatory — plot both conjugates
        plot([sigma sigma], [omega -omega], mk, ...
             'MarkerSize',sz, 'Color',col, 'MarkerFaceColor',col, ...
             'LineStyle','none', 'DisplayName', nm)
    else                     % non-oscillatory — single point
        plot(sigma, 0, mk, ...
             'MarkerSize',sz, 'Color',col, 'MarkerFaceColor',col, ...
             'LineStyle','none', 'DisplayName', nm)
    end

    % Label
    if omega >= 0
        text(sigma + 0.18, omega + 0.4, nm, 'FontSize',9, 'Color',col)
    end
end

xlabel('Real  \sigma  (1/s)', 'FontSize',12)
ylabel('Imaginary  \omega  (rad/s)', 'FontSize',12)
title('Flight Mode Root Locus', 'FontSize',13, 'FontWeight','normal')
legend('Location','east', 'FontSize',10)
grid on; box on
xlim(xl); ylim(yl)


%% 2  ── Mode Health — "how close to bad" ─────────────────────────────────
% Three different ways to see the same thing. Pick whichever resonates.

figure('Name','Mode Health','Color','w','Position',[80 60 1000 420])

modeList = {'Short\nperiod','Phugoid','Roll','Dutch\nroll','Spiral'};
modeData = [aero.modes.ShortPeriod, aero.modes.Phugoid, aero.modes.Roll, ...
            aero.modes.DutchRoll,   aero.modes.Spiral];

sigmas = arrayfun(@(m) m.sigma, modeData);
zetas  = arrayfun(@(m) m.zeta,  modeData);
stab   = arrayfun(@(m) m.stable, modeData);

% ── Panel A: sigma bar chart (real part distance from zero)
subplot(1,3,1)
barColors = zeros(5,3);
for k = 1:5
    if stab(k), barColors(k,:) = [0.20 0.60 0.35];
    else,        barColors(k,:) = [0.80 0.22 0.22]; end
end
b = bar(sigmas, 'FaceColor','flat');
b.CData = barColors;
b.EdgeColor = 'none';
yline(0,'k-','LineWidth',1.2)
labels = strrep(modeList,'\n',' ');
set(gca,'XTickLabel', labels, 'FontSize',10)
ylabel('\sigma  (real part, 1/s)', 'FontSize',11)
title('Real part of eigenvalue', 'FontSize',11, 'FontWeight','normal')
subtitle('More negative = more stable', 'FontSize',9)
grid on; box on
hold on
% annotate values
for k=1:5
    yOff = 0.3;
    if sigmas(k) < 0, yOff = -0.6; end
    text(k, sigmas(k)+yOff, sprintf('%.3f',sigmas(k)), ...
         'HorizontalAlignment','center','FontSize',8,'Color',barColors(k,:))
end

% ── Panel B: damping ratio (zeta) — only meaningful for oscillatory modes
subplot(1,3,2)
zetaPlot = zetas;
zetaPlot(isnan(zetaPlot) | zetaPlot == 0) = NaN;   % skip pure-real modes
b2 = bar(zetaPlot, 'FaceColor','flat');
zetaColors = [0.20 0.60 0.35; 0.20 0.60 0.35; ...
              0.75 0.75 0.75; 0.20 0.60 0.35; 0.75 0.75 0.75];
b2.CData = zetaColors;
b2.EdgeColor = 'none';
yline(0.05, 'r--', 'LineWidth',1.4, 'DisplayName','\zeta_{min} = 0.05')
yline(0.10, '--',  'Color',[0.9 0.6 0.0], 'LineWidth',1.1, 'DisplayName','\zeta = 0.10')
set(gca,'XTickLabel', labels, 'FontSize',10)
ylabel('Damping ratio  \zeta', 'FontSize',11)
title('Damping ratio', 'FontSize',11, 'FontWeight','normal')
subtitle('\zeta < 0.05 is uncomfortable to fly', 'FontSize',9)
legend('Location','north','FontSize',9)
grid on; box on

% ── Panel C: stability margin (normalised distance, 0=neutral, 1=very stable)
% For oscillatory modes: use zeta. For aperiodic: use -sigma normalised.
subplot(1,3,3)
health = zeros(1,5);
for k = 1:5
    if ~isnan(zetas(k)) && zetas(k) > 0
        health(k) = min(zetas(k) / 0.5, 1.0);  % saturate at zeta=0.5
    elseif stab(k)
        health(k) = min(-sigmas(k) / 20, 1.0); % saturate at sigma=-20
    else
        health(k) = -min(sigmas(k) / 0.5, 1.0); % negative = unstable
    end
end
healthColors = zeros(5,3);
for k=1:5
    if health(k) >= 0
        t = health(k);
        healthColors(k,:) = (1-t)*[1 0.65 0] + t*[0.20 0.60 0.35];  % amber -> green
    else
        healthColors(k,:) = [0.80 0.22 0.22];  % red = unstable
    end
end
b3 = bar(health, 'FaceColor','flat');
b3.CData = healthColors;
b3.EdgeColor = 'none';
yline(0,'k-','LineWidth',1.2)
yline(0.1,'r--','LineWidth',1.0,'HandleVisibility','off')
set(gca,'XTickLabel', labels, 'FontSize',10)
ylabel('Stability health  [0=marginal, 1=excellent]', 'FontSize',10)
title('Mode health score', 'FontSize',11, 'FontWeight','normal')
subtitle('Composite: zeta (oscillatory) | sigma (aperiodic)', 'FontSize',9)
grid on; box on
ylim([-1.1 1.1])

sgtitle('Mode Stability Analysis', 'FontSize',13, 'FontWeight','bold')


%% 3  ── Reconstructed Drag Polar ─────────────────────────────────────────
% We have one operating point (CL, CD) and CLa.
% Back-calculate aspect ratio from Prandtl: CLa ≈ 2*pi*AR/(AR+2) => AR = 2*CLa/(2*pi - CLa)
% Then fit CD0 and e from the one known point.

figure('Name','Drag Polar','Color','w','Position',[100 80 820 480])

% Reconstruct CD from components if the total parsed as NaN
CD_use = aero.CD;
if isnan(CD_use) && ~isnan(aero.CD_induced) && ~isnan(aero.CD_profile)
    CD_use = aero.CD_induced + aero.CD_profile;
    fprintf('Note: CD reconstructed from ICD+VCD = %.5f\n', CD_use)
end
LD_use = aero.CL / CD_use;

CLa_rad  = aero.CLa;                          % [1/rad], whole aircraft
AR_est   = 2*CLa_rad / (2*pi - CLa_rad);      % Prandtl lifting line inverse
e_est    = 0.85;                               % assumed Oswald efficiency
CD0_est  = CD_use - aero.CL^2 / (pi * AR_est * e_est);  % from operating point

CL_range = linspace(-0.1, 1.4, 300);
CD_polar  = CD0_est + CL_range.^2 / (pi * AR_est * e_est);

% Max L/D tangent line from origin
LD_max   = sqrt(pi * AR_est * e_est / (4 * CD0_est));
CL_opt   = sqrt(pi * AR_est * e_est * CD0_est);   % CL at max L/D
CD_opt   = 2 * CD0_est;

subplot(1,2,1)
hold on

% Polar curve
plot(CD_polar, CL_range, 'b-', 'LineWidth', 2.0, 'DisplayName', ...
     sprintf('Parabolic polar  (AR=%.1f, e=%.2f)', AR_est, e_est))

% Operating point
plot(CD_use, aero.CL, 'ro', 'MarkerSize',10, 'MarkerFaceColor','r', ...
     'DisplayName', sprintf('XFLR5 op. point  (L/D=%.1f)', LD_use))

% Max L/D tangent
plot([0 CD_opt*2.5], [0 CL_opt*2.5], 'k--', 'LineWidth', 1.2, ...
     'DisplayName', sprintf('Max L/D tangent  (L/D_{max}=%.1f)', LD_max))
plot(CD_opt, CL_opt, 'k^', 'MarkerSize', 9, 'MarkerFaceColor','k', ...
     'HandleVisibility','off')

xlabel('C_D', 'FontSize',12)
ylabel('C_L', 'FontSize',12)
title('Drag Polar', 'FontSize',12, 'FontWeight','normal')
legend('Location','northwest', 'FontSize',9)
grid on; box on
xlim([0 max(CD_polar)*1.1])
ylim([-0.15 1.5])
text(CD_opt+0.0008, CL_opt-0.06, sprintf('L/D_{max}=%.1f', LD_max), ...
     'FontSize',9, 'Color',[0.2 0.2 0.2])

% ── CL/CD vs CL (efficiency curve)
subplot(1,2,2)
LD_curve = CL_range ./ max(CD_polar, 1e-6);
hold on
plot(CL_range, LD_curve, 'b-', 'LineWidth',2.0, 'DisplayName','L/D vs C_L')
plot(aero.CL, LD_use, 'ro', 'MarkerSize',10, 'MarkerFaceColor','r', ...
     'DisplayName', sprintf('Operating point  (C_L=%.3f)', aero.CL))
xline(CL_opt, 'k--', 'LineWidth',1.2, 'DisplayName', ...
      sprintf('Optimal C_L = %.3f', CL_opt))
xlabel('C_L', 'FontSize',12)
ylabel('L/D', 'FontSize',12)
title('Aerodynamic Efficiency', 'FontSize',12, 'FontWeight','normal')
legend('Location','north', 'FontSize',9)
grid on; box on
xlim([-0.05 1.3])

annotation('textbox',[0.52 0.12 0.20 0.16], ...
    'String', sprintf('AR_{est}  = %.2f\ne_{est}   = %.2f\nCD_0      = %.5f\nL/D_{max} = %.1f', ...
                      AR_est, e_est, CD0_est, LD_max), ...
    'FitBoxToText','on','BackgroundColor',[0.97 0.97 0.97], ...
    'EdgeColor',[0.8 0.8 0.8],'FontSize',9,'FontName','Monospaced')

sgtitle('Reconstructed Drag Polar', 'FontSize',13, 'FontWeight','bold')


%% 4  ── Static Margin Diagram ────────────────────────────────────────────
% Shows XNP, estimated XCG, and the static margin on a simplified fuselage line.
% Static margin SM = (XNP - XCG) / MAC.
% We estimate XCG from XCP (trimmed flight) and a typical CG-CP offset.

figure('Name','Static Margin','Color','w','Position',[120 80 760 300])

MAC      = aero.V^0 * 0.307;     % chord from design vector (x(2) = 0.3071 m)
XCG_est  = aero.XCP * 1.15;      % rough estimate: CG typically aft of CP
SM       = (aero.XNP - XCG_est) / MAC;

fuselage_len = 1.0;    % nominal, for display only
hold on

% Fuselage line
plot([0 fuselage_len], [0 0], 'k-', 'LineWidth', 4)

% Reference markers
xvals = [XCG_est, aero.XNP, aero.XCP];
labels_pts = {'X_{CG} (est)', 'X_{NP}', 'X_{CP}'};
colors_pts = {[0.20 0.50 0.80], [0.80 0.22 0.22], [0.20 0.62 0.35]};
yoff = [0.06, 0.06, -0.10];

for k = 1:3
    plot(xvals(k), 0, 'v', 'MarkerSize',14, 'Color',colors_pts{k}, ...
         'MarkerFaceColor',colors_pts{k})
    text(xvals(k), yoff(k), labels_pts{k}, 'HorizontalAlignment','center', ...
         'FontSize',10, 'Color',colors_pts{k})
    text(xvals(k), yoff(k)-0.06, sprintf('%.4f m', xvals(k)), ...
         'HorizontalAlignment','center','FontSize',8,'Color',colors_pts{k})
end

% Static margin arrow
arrow_y = -0.18;
annotation_x1 = XCG_est / fuselage_len;
annotation_x2 = aero.XNP / fuselage_len;

% SM fill bar
patch([XCG_est, aero.XNP, aero.XNP, XCG_est], ...
      [arrow_y-0.025, arrow_y-0.025, arrow_y+0.025, arrow_y+0.025], ...
      [0.75 0.90 0.75], 'EdgeColor','none', 'FaceAlpha',0.6)
plot([XCG_est aero.XNP], [arrow_y arrow_y], 'g-', 'LineWidth',2)
text((XCG_est+aero.XNP)/2, arrow_y+0.05, ...
     sprintf('SM = %.1f%% MAC', SM*100), ...
     'HorizontalAlignment','center','FontSize',11,'FontWeight','bold', ...
     'Color',[0.10 0.45 0.15])

xlim([-0.05 fuselage_len+0.05])
ylim([-0.32 0.22])
xlabel('Fuselage station (m)', 'FontSize',11)
title(sprintf('Static Margin Diagram  |  SM = %.1f%% MAC  (Cma = %.4f)', ...
      SM*100, aero.Cma), 'FontSize',12, 'FontWeight','normal')
axis off
box off
set(gca,'YTick',[])


%% 5  ── Spider / Radar Chart — Derivative Sign & Magnitude Health ─────────
% Each spoke = one derivative. Distance from centre = how "healthy" the value is.
% Colour = pass (green) / fail (red).

figure('Name','Derivative Radar','Color','w','Position',[140 60 600 560])

derivNames  = {'Cm\alpha', 'Cm_q', 'Cl_p', 'Cn\beta', 'Cn_r', 'Cl\beta', 'CY\beta'};
derivVals   = [aero.Cma,  aero.Cmq, aero.Clp, aero.Cnb, aero.Cnr, aero.Clb, aero.Cyb];
reqSign     = [-1, -1, -1, +1, -1, -1, -1];
refMag      = [0.60, 7.0, 0.30, 0.08, 0.14, 0.01, 0.12];  % typical "good" magnitude

N    = numel(derivVals);
angs = linspace(0, 2*pi, N+1); angs(end) = [];
angs = angs + pi/2;   % start from top

% Normalise: 1 = at reference magnitude, scale linearly
score = abs(derivVals) ./ refMag;
score = min(score, 2.0);   % cap at 2x reference

hold on

% Background rings
for r = [0.25 0.5 0.75 1.0 1.5]
    theta_ring = linspace(0, 2*pi, 200);
    plot(r*cos(theta_ring), r*sin(theta_ring), '-', ...
         'Color',[0.85 0.85 0.85], 'LineWidth',0.6, 'HandleVisibility','off')
end
text(0, 1.03, 'ref', 'HorizontalAlignment','center','FontSize',7,'Color',[0.7 0.7 0.7])
text(0, 0.53, '0.5×','HorizontalAlignment','center','FontSize',7,'Color',[0.7 0.7 0.7])

% Spokes
for k = 1:N
    plot([0 2.1*cos(angs(k))], [0 2.1*sin(angs(k))], '-', ...
         'Color',[0.88 0.88 0.88],'LineWidth',0.5,'HandleVisibility','off')
    lx = 2.25*cos(angs(k));
    ly = 2.25*sin(angs(k));
    text(lx, ly, derivNames{k}, 'HorizontalAlignment','center', ...
         'FontSize',10.5, 'Interpreter','tex')
end

% Filled polygon
px = score .* cos(angs);
py = score .* sin(angs);
patch([px px(1)], [py py(1)], [0.20 0.50 0.80], ...
      'FaceAlpha',0.18, 'EdgeColor',[0.20 0.50 0.80], 'LineWidth',1.5)

% Individual dot, colour-coded by sign correctness
for k = 1:N
    ok  = (sign(derivVals(k)) == reqSign(k));
    col = [0.20 0.60 0.35];
    if ~ok, col = [0.80 0.22 0.22]; end
    plot(px(k), py(k), 'o', 'MarkerSize',9, ...
         'MarkerFaceColor',col, 'Color',col)
    text(px(k)+0.06*cos(angs(k)), py(k)+0.06*sin(angs(k)), ...
         sprintf('%.3f', derivVals(k)), 'FontSize',7.5, 'Color',col, ...
         'HorizontalAlignment','center')
end

axis equal; axis off
title('Stability Derivative Radar', 'FontSize',12, 'FontWeight','normal')
subtitle('Radius = magnitude relative to typical DBF values  |  Green = correct sign', ...
         'FontSize',9)