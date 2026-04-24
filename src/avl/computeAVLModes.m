function modes = computeAVLModes(avl, geom, V, rho)
% computeAVLModes  Build flight dynamics state matrices from AVL derivatives
%                  and compute eigenmodes.
%
%   modes = computeAVLModes(avl, geom, V)
%   modes = computeAVLModes(avl, geom, V, rho)
%
%   Returns a modes struct in the same format as parseXFLR5, so the same
%   plotting code works for both XFLR5 and AVL results:
%
%   modes.Phugoid     .sigma  .omega  .t2
%   modes.ShortPeriod .sigma  .omega  .t2
%   modes.DutchRoll   .sigma  .omega  .t2
%   modes.Roll        .sigma  .omega  .t2
%   modes.Spiral      .sigma  .omega  .t2
%
%   Method: standard linearized rigid-body flight dynamics (Nelson 1998).
%   Longitudinal and lateral equations are decoupled at the symmetric
%   trim condition. Ixz cross-product inertia is included for the lateral.
%
%   Limitation: speed derivatives (Xu, Zu from Mach/velocity changes) are
%   approximated for incompressible flow. Good for our low-speed regime.

if nargin < 4, rho = 1.225; end

g    = 9.81;
m    = geom.mass;
S    = geom.Sref;
c    = geom.Cref;
b    = geom.Bref;
qbar = 0.5 * rho * V^2;

% ── Inertias from mass breakdown ──────────────────────────────────────────
% Parallel axis theorem from same point masses as buildAVLMass.m.
mass_data = [
    0.353, -0.303,  0.000, -0.075;
    0.799, -0.100,  0.000, -0.075;
    0.478,  0.000,  0.000,  0.000;
    0.189,  0.103,  0.000,  0.000;
    0.044,  0.241,  0.000,  0.000;
    0.295,  0.673,  0.000,  0.000;
    0.122, -0.227,  0.000,  0.000;
    0.300,  0.076,  0.000,  0.000;
    0.100, -0.157,  0.000,  0.000;
    0.476,  geom.wing.x_le  + 0.5*geom.wing.chord_root,  0, 0;
    0.150,  geom.htail.x_le + 0.5*geom.htail.chord_root, 0, 0;
    0.150,  geom.vtail.x_le + 0.5*geom.vtail.chord_root, 0, 0;
];
mi = mass_data(:,1);
xi = mass_data(:,2);
yi = mass_data(:,3);
zi = mass_data(:,4);

CG_x = sum(mi.*xi)/m;
CG_z = sum(mi.*zi)/m;
dx = xi - CG_x;
dy = yi;
dz = zi - CG_z;

Ixx = sum(mi .* (dy.^2 + dz.^2));
Iyy = sum(mi .* (dx.^2 + dz.^2));
Izz = sum(mi .* (dx.^2 + dy.^2));
Ixz = sum(mi .* dx .* dz);

% ── Dimensional longitudinal derivatives ─────────────────────────────────
% States: [Δu (m/s), Δa (rad), Δq (rad/s), Δθ (rad)]
% Approximations for incompressible flow: speed derivatives Mu=0, CDu≈2*CDi.

Xu = -2 * avl.CDi   * qbar*S / (m*V);
Xa =      avl.CL    * qbar*S / m;
Zu = -2 * avl.CL    * qbar*S / (m*V);
Za =    -(avl.CLa)  * qbar*S / m;
Zq =    -(avl.CLq)  * qbar*S*c / (2*m);
Ma =      avl.Cma   * qbar*S*c / Iyy;
Mq =      avl.Cmq   * qbar*S*c^2 / (2*V*Iyy);

% Longitudinal A matrix (Nelson eq. 4.50 form)
A_lon = [Xu,     Xa,       0,          -g;
         Zu/V,   Za/V,     1 + Zq/V,   0;
         0,      Ma,       Mq,         0;
         0,      0,        1,          0];

% ── Dimensional lateral derivatives ──────────────────────────────────────
% States: [b (rad), p (rad/s), r (rad/s), φ (rad)]
% Ixz coupling handled via inertia matrix inversion.

Yb = avl.CYb * qbar*S / m;
Yp = avl.CYp * qbar*S*b / (2*V*m);
Yr = avl.CYr * qbar*S*b / (2*V*m);

Lb_d = avl.Clb * qbar*S*b;
Lp_d = avl.Clp * qbar*S*b^2 / (2*V);
Lr_d = avl.Clr * qbar*S*b^2 / (2*V);

Nb_d = avl.Cnb * qbar*S*b;
Np_d = avl.Cnp * qbar*S*b^2 / (2*V);
Nr_d = avl.Cnr * qbar*S*b^2 / (2*V);

% Inertia coupling (divide by Ixx*Izz - Ixz^2 and cross-multiply)
G  = Ixx*Izz - Ixz^2;
Lb = (Izz*Lb_d + Ixz*Nb_d) / G;
Lp = (Izz*Lp_d + Ixz*Np_d) / G;
Lr = (Izz*Lr_d + Ixz*Nr_d) / G;
Nb = (Ixx*Nb_d + Ixz*Lb_d) / G;
Np = (Ixx*Np_d + Ixz*Lp_d) / G;
Nr = (Ixx*Nr_d + Ixz*Lr_d) / G;

% Lateral A matrix
A_lat = [Yb/V,   Yp/V,   (Yr/V - 1),  g/V;
         Lb,     Lp,     Lr,          0;
         Nb,     Np,     Nr,          0;
         0,      1,      0,           0];

% ── Eigenvalues ───────────────────────────────────────────────────────────
eig_lon = eig(A_lon);
eig_lat = eig(A_lat);

% ── Identify longitudinal modes ───────────────────────────────────────────
% Two conjugate pairs: phugoid (low |λ|) and short period (high |λ|).
% Sort by magnitude to separate them.
[~, idx] = sort(abs(eig_lon));
eig_lon  = eig_lon(idx);

modes.Phugoid     = makeMode(eig_lon(1));  % lowest magnitude = phugoid
modes.ShortPeriod = makeMode(eig_lon(3));  % higher magnitude = short period

% ── Identify lateral modes ────────────────────────────────────────────────
% One complex pair (dutch roll), two real roots (roll and spiral).
is_complex = abs(imag(eig_lat)) > 0.01;
complex_eigs = eig_lat(is_complex);
real_eigs    = sort(real(eig_lat(~is_complex)));  % most negative first

modes.DutchRoll = makeMode(complex_eigs(1));
modes.Roll      = makeMode(real_eigs(1));    % more negative = faster roll mode
modes.Spiral    = makeMode(real_eigs(2));    % less negative (or slightly positive)

% ── Print ─────────────────────────────────────────────────────────────────
fprintf('\n=== Flight Dynamics Modes ===\n')
printMode('Phugoid',      modes.Phugoid)
printMode('Short Period', modes.ShortPeriod)
printMode('Dutch Roll',   modes.DutchRoll)
printMode('Roll',         modes.Roll)
printMode('Spiral',       modes.Spiral)

end


function m = makeMode(lambda)
% Convert an eigenvalue to sigma/omega/t2 format matching parseXFLR5 output.
    m.sigma = real(lambda);
    m.omega = imag(lambda);
    if m.sigma > 0
        m.t2 = log(2) / m.sigma;
    else
        m.t2 = Inf;
    end
end


function printMode(name, m)
    if abs(m.omega) > 0.01
        fprintf('  %-14s  σ = %+.4f   ω = %+.4f rad/s', name, m.sigma, m.omega)
    else
        fprintf('  %-14s  σ = %+.4f   (non-oscillatory)', name, m.sigma)
    end
    if isfinite(m.t2)
        fprintf('   t2 = %.2f s  [UNSTABLE]\n', m.t2)
    else
        fprintf('   [stable]\n')
    end
end