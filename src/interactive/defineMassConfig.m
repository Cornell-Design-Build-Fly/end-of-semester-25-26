function mass = defineMassConfig(geom)
% defineMassConfig  Build the aircraft mass breakdown, inertia matrix,
%                   and CG from geometric and payload parameters.
%
%   mass = defineMassConfig(geom)
%
%   geom -- minimal geometry struct from defineGeom() (before expandGeom).
%           Required fields: wing_span, wing_AR, htail_span, htail_AR,
%           vtail_height, vtail_AR, tail_arm, nose_x, n_ducks, n_pucks.
%
%   Returns:
%     mass.total  -- total mass [kg]
%     mass.CG     -- [x, y, z] CG location [m]
%     mass.I      -- [Ixx, Iyy, Izz, Ixz] about CG [kg m^2]

wing_span    = geom.wing_span;
wing_AR      = geom.wing_AR;
htail_span   = geom.htail_span;
htail_AR     = geom.htail_AR;
vtail_height = geom.vtail_height;
vtail_AR     = geom.vtail_AR;
tail_arm     = geom.tail_arm;
nose_x       = geom.nose_x;
n_ducks      = geom.n_ducks;
n_pucks      = geom.n_pucks;


%% ── Derived geometry ──────────────────────────────────────────────────────
wing_chord  = wing_span  / wing_AR;
htail_chord = htail_span / htail_AR;
vtail_chord = vtail_height / vtail_AR;

% Tail LE positions: place so AC-to-AC distance equals tail_arm
% tail_x_le = tail_arm + 0.25*wing_chord - 0.25*tail_chord
htail_x_le = tail_arm + 0.25*wing_chord - 0.25*htail_chord;
vtail_x_le = htail_x_le;   % vtail at same station as htail

% Electronics sit ~10 cm aft of the motor
elec_x = nose_x + 0.10;

mass.geom.wing_chord  = wing_chord;
mass.geom.htail_chord = htail_chord;
mass.geom.vtail_chord = vtail_chord;
mass.geom.htail_x_le  = htail_x_le;
mass.geom.vtail_x_le  = vtail_x_le;


%% ── Mass scaling constants ────────────────────────────────────────────────
% Calibrated from Duck Force One measured component masses.
% Wing and tail surfaces scale with planform area (S = span^2 / AR).
% Spar and fuselage scale with length.

k_wing = 2.027;   % [kg/m²]  wing structural mass per planform area
k_tail = 1.344;   % [kg/m²]  tail surface mass per planform area (avg h+v)
k_spar = 0.215;   % [kg/m]   tail spar mass per meter of tail arm
k_fus  = 0.377;   % [kg/m]   fuselage mass per meter of nose-to-tail length


%% ── Scaled component masses ───────────────────────────────────────────────
S_wing  = wing_span^2   / wing_AR;
S_htail = htail_span^2  / htail_AR;
S_vtail = vtail_height^2 / vtail_AR;
fus_len = htail_x_le - nose_x;

m_wing  = k_wing * S_wing;
m_htail = k_tail * S_htail;
m_vtail = k_tail * S_vtail;
m_spar  = k_spar * tail_arm;
m_fus   = k_fus  * fus_len;


%% ── Component x-positions ────────────────────────────────────────────────
% Wing structural CG: ~45% chord (ribs + spar combo)
x_wing  = 0.45 * wing_chord;

% Tail surfaces: ~45% of their own chord from their LE
x_htail = htail_x_le + 0.45 * htail_chord;
x_vtail = vtail_x_le + 0.45 * vtail_chord;

% Tail spar: midpoint between wing LE and htail LE
x_spar  = 0.50 * htail_x_le;

% Fuselage: midpoint between wing TE and nose
x_fus   = 0.50 * (wing_chord + nose_x);

% Gear: main gear near wing spar, front gear partway to nose
x_gear_main  =  0.40 * wing_chord;
x_gear_front =  0.50 * nose_x;

% Banner drop mechanism: at htail station
x_banner_drop = htail_x_le;

% Banner (towed): just aft of htail TE
x_banner = htail_x_le + htail_chord + 0.05;

% Payload: fixed positions regardless of quantity
x_duck = 0.191;   % [m] from wing LE
x_puck = 0.084;   % [m] from wing LE


%% ── Fixed masses ──────────────────────────────────────────────────────────
% Propulsion and electronics are fixed regardless of wing geometry.
% Prop stuff always stays the same (per user).
m_motor_prop  = 0.390;
m_nosecone    = 0.152;
m_battery     = 0.690;
m_receiver    = 0.024;
m_servo_bat   = 0.045;
m_gyro        = 0.021;
m_gear_main   = 0.125;
m_gear_front  = 0.105;
m_banner_drop = 0.136;
m_banner      = 0.233;
m_fasteners   = 0.004;
m_duck_each   = 0.116;
m_puck_each   = 0.190;


%% ── Build component table ─────────────────────────────────────────────────
% Each row: [mass, x, y, z, name]
% y = 0 for everything (symmetric), z from datum (motor/battery sit low)
z0   =  0.000;
z_lo = -0.025;   % motor and battery sit below wing datum

components = {
%  mass                x                y   z      name
   m_wing,             x_wing,          0,  z0,    'Wing';
   m_htail,            x_htail,         0,  z0,    'Htail';
   m_vtail,            x_vtail,         0,  z0,    'Vtail';
   m_spar,             x_spar,          0,  z0,    'Tail spar';
   m_fus,              x_fus,           0,  z0,    'Fuselage';
   m_motor_prop,       nose_x,          0,  z_lo,  'Motor+Prop';
   m_nosecone,         nose_x + 0.04,   0,  z0,    'Nosecone';
   m_battery,          elec_x,          0,  z_lo,  'Battery';
   m_receiver,         elec_x + 0.05,   0,  z0,    'Receiver';
   m_servo_bat,        elec_x + 0.03,   0,  z0,    'Servo bat.';
   m_gyro,             elec_x + 0.02,   0,  z0,    'Gyro';
   m_gear_main,        x_gear_main,     0,  z_lo,  'Main gear';
   m_gear_front,       x_gear_front,    0,  z_lo,  'Front gear';
   % m_banner_drop,    x_banner_drop,   0,  z0,    'Banner drop';  % commented out
   % m_banner,         x_banner,        0,  z0,    'Banner';        % commented out
   % m_fasteners,      0.0,             0,  z0,    'Fasteners';     % commented out
   n_ducks*m_duck_each, x_duck,         0,  z0,    sprintf('%d Duck(s)', n_ducks);
   n_pucks*m_puck_each, x_puck,         0,  z0,    sprintf('%d Puck(s)', n_pucks);
};

% Strip zero-mass rows (e.g. 0 ducks)
keep = cellfun(@(m) m > 0, components(:,1));
components = components(keep, :);

% Unpack
m_vec = cell2mat(components(:,1));
x_vec = cell2mat(components(:,2));
y_vec = cell2mat(components(:,3));
z_vec = cell2mat(components(:,4));
names = components(:,5);


%% ── CG and total mass ─────────────────────────────────────────────────────
m_total = sum(m_vec);
CG_x    = sum(m_vec .* x_vec) / m_total;
CG_y    = 0;
CG_z    = sum(m_vec .* z_vec) / m_total;


%% ── Inertia matrix ────────────────────────────────────────────────────────
% Point mass approximation with parallel axis theorem.
% Wing gets a span correction for roll inertia (distributed mass in y).
dx = x_vec - CG_x;
dy = y_vec - CG_y;
dz = z_vec - CG_z;

Ixx = sum(m_vec .* (dy.^2 + dz.^2));
Iyy = sum(m_vec .* (dx.^2 + dz.^2));
Izz = sum(m_vec .* (dx.^2 + dy.^2));
Ixz = sum(m_vec .* dx .* dz);

% Wing roll inertia correction: uniform span distribution adds m*b^2/12
% (rod of length b about its midpoint, then parallel axis already applied above)
% This replaces the point mass Ixx contribution from the wing
idx_wing = find(strcmp(names, 'Wing'));
if ~isempty(idx_wing)
    % Remove point-mass y-contribution for wing, add distributed correction
    Ixx = Ixx - m_wing * dy(idx_wing)^2 + m_wing * (wing_span/2)^2 / 3;
    Izz = Izz - m_wing * dy(idx_wing)^2 + m_wing * (wing_span/2)^2 / 3;
end
% Same correction for htail
idx_h = find(strcmp(names, 'Htail'));
if ~isempty(idx_h)
    Ixx = Ixx - m_htail * dy(idx_h)^2 + m_htail * (htail_span/2)^2 / 3;
    Izz = Izz - m_htail * dy(idx_h)^2 + m_htail * (htail_span/2)^2 / 3;
end
% Vtail correction for yaw and pitch (distributed in z)
idx_v = find(strcmp(names, 'Vtail'));
if ~isempty(idx_v)
    Iyy = Iyy + m_vtail * vtail_height^2 / 12;
end


%% ── Store results ────────────────────────────────────────────────────────
mass.total  = m_total;
mass.CG     = [CG_x, CG_y, CG_z];
mass.I      = [Ixx, Iyy, Izz, Ixz];
mass.m_vec  = m_vec;
mass.x_vec  = x_vec;
mass.z_vec  = z_vec;
mass.names  = names;
mass.wing_chord = wing_chord;
mass.nose_x     = nose_x;
mass.htail_x_le = htail_x_le;
mass.vtail_x_le = vtail_x_le;
mass.htail_chord = htail_chord;
mass.vtail_height = vtail_height;
mass.wing_span    = wing_span;
mass.htail_span   = htail_span;
mass.vtail_chord  = vtail_chord;
mass.vtail_AR     = vtail_AR;


%% ── Print summary ─────────────────────────────────────────────────────────
fprintf('\n=== Mass Breakdown ===\n')
fprintf('  %-20s  %6s  %7s  %7s\n', 'Component', 'm (kg)', 'x (m)', 'z (m)')
fprintf('  %s\n', repmat('-', 1, 48))
for k = 1:numel(m_vec)
    fprintf('  %-20s  %6.3f  %+7.3f  %+7.4f\n', names{k}, m_vec(k), x_vec(k), z_vec(k))
end
fprintf('  %s\n', repmat('-', 1, 48))
fprintf('  %-20s  %6.3f  %+7.4f  %+7.4f\n', 'TOTAL / CG', m_total, CG_x, CG_z)
fprintf('\n  CG: %.4f m = %.1f%% MAC\n', CG_x, CG_x/wing_chord*100)
fprintf('  Ixx = %.4f  Iyy = %.4f  Izz = %.4f  Ixz = %.4f  [kg m^2]\n', ...
    Ixx, Iyy, Izz, Ixz)


%% ── Plot ──────────────────────────────────────────────────────────────────
% plotMassLayout(mass);

end