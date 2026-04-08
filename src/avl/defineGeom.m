function geom = defineGeom()
% defineGeom  Duck Force One aircraft geometry.
%
% All lengths in meters, angles in degrees, masses in kg.
%
% Coordinate origin: wing leading edge (matches the XFLR5 plane editor
% coordinate system from your stability analysis). X is positive aft,
% Y is positive out the right wing, Z is positive up.
%
% Values sourced from:
%   - Table 5.1.1 (dimensional parameters) for all geometry
%   - XFLR5 plane editor screenshot for surface x/z positions
%   - XFLR5 additional point masses for CG calculation
%
% NOTE: "Mission 1 Iteration 1" in XFLR5 shows a 1.00 m span, which
% differs from the design table (46.51 in = 1.181 m). This file uses
% the design table values. Double-check which is current before running
% AVL if this matters for your analysis.


%% ── Reference Geometry ──────────────────────────────────────────────────

geom.Sref = 0.3628;        % [m^2]   wing reference area  (562.31 in^2)
geom.Cref = 0.3071;        % [m]     mean aerodynamic chord (= chord, rectangular wing)
geom.Bref = 1.1814;        % [m]     full wing span  (46.51 in)

% CG location, computed from XFLR5 mass breakdown + user-provided surface masses.
% Wing centroid assumed at mid-chord (x = 0.153 m), tail surfaces at mid-chord
% of their respective planforms. See comment block at the bottom for the full
% mass breakdown if you want to adjust this.
geom.xref =  0.1031;       % [m]   33.6% chord aft of wing LE — reasonable, check against your CG margin target
geom.yref =  0.000;        % [m]   always zero
geom.zref = -0.0250;       % [m]   ~25 mm below wing LE datum (motor + battery pull it down)


%% ── Main Wing ───────────────────────────────────────────────────────────
% Rectangular planform (single chord value in design table, AR = span/chord = 3.85).
% No taper, no sweep, no dihedral specified.

geom.wing.span        = 1.1814;   % [m]   46.51 in
geom.wing.chord_root  = 0.3071;   % [m]   12.09 in
geom.wing.chord_tip   = 0.3071;   % [m]   12.09 in  (rectangular, no taper)
geom.wing.sweep_LE    = 0;        % [deg] unswept
geom.wing.dihedral    = 0;        % [deg] flat wing (not specified in table)
geom.wing.incidence   = 0;        % [deg] wing incidence (fuselage reference line)
geom.wing.twist_tip   = 0;        % [deg] no washout specified

% LE position from coordinate origin (wing LE, so trivially zero here).
geom.wing.x_le        = 0.000;    % [m]
geom.wing.z_le        = 0.000;    % [m]

% FX 60-126 is a Wortmann airfoil, not a NACA series. AVL cannot use it
% as a string -- you will need a .dat coordinate file for it.
% Download from: https://m-selig.ae.illinois.edu/ads/coord/fx60126.dat
% Then set this to the filename (e.g. 'fx60126.dat') and place the file
% in the same directory as your .avl file.
geom.wing.airfoil     = 'wortmanFX60-126.dat';

% Aileron: 25% control surface ratio means hinge at 75% chord.
geom.wing.aileron_hinge = 0.75;   % [fraction of chord]

geom.wing.Nspan       = 12;
geom.wing.Nchord      = 4;


%% ── Horizontal Stabilizer ───────────────────────────────────────────────
% Rectangular planform, symmetric airfoil, set at -2 deg incidence.

geom.htail.span        = 0.4361;   % [m]   17.17 in
geom.htail.chord_root  = 0.1460;   % [m]   5.75 in
geom.htail.chord_tip   = 0.1460;   % [m]   5.75 in  (rectangular)
geom.htail.sweep_LE    = 0;        % [deg]
geom.htail.dihedral    = 0;        % [deg]
geom.htail.incidence   = -2.0;     % [deg] from Table 5.1.1 and confirmed in XFLR5 (-2.000 deg tilt)

% LE position from XFLR5 plane editor (elevator x = 0.800 m, z = 0.000 m).
geom.htail.x_le        = 0.800;    % [m]   aft of wing LE
geom.htail.z_le        = 0.000;    % [m]

geom.htail.airfoil     = 'NACA 0012';

% Elevator: 30% control surface ratio means hinge at 70% chord.
geom.htail.elevator_hinge = 0.70;  % [fraction of chord]

geom.htail.Nspan       = 8;
geom.htail.Nchord      = 4;


%% ── Vertical Stabilizer ─────────────────────────────────────────────────
% Single vertical tail (conventional config, not twin boom).
% In AVL, a vertical surface uses dihedral = 90 deg internally so the
% "span" direction runs in Z. buildAVLGeom.m handles this automatically.

geom.vtail.height      = 0.2601;   % [m]   10.24 in
geom.vtail.chord_root  = 0.1460;   % [m]   5.75 in
geom.vtail.chord_tip   = 0.1460;   % [m]   5.75 in  (rectangular)
geom.vtail.sweep_LE    = 0;        % [deg]
geom.vtail.incidence   = 0;        % [deg] always 0

% LE position from XFLR5 plane editor (fin x = 0.800 m, z = 0.000 m).
geom.vtail.x_le        = 0.800;    % [m]   aft of wing LE
geom.vtail.z_le        = 0.000;    % [m]   root at fuselage datum

geom.vtail.airfoil     = 'NACA 0012';

% Rudder: 30% control surface ratio means hinge at 70% chord.
geom.vtail.rudder_hinge = 0.70;    % [fraction of chord]

geom.vtail.Nspan       = 6;
geom.vtail.Nchord      = 4;


%% ── Mass ────────────────────────────────────────────────────────────────

geom.mass = 3.456;    % [kg]  total aircraft mass (see breakdown at bottom of file)


%% ── Derived Values ──────────────────────────────────────────────────────

geom.AR    = geom.Bref^2 / geom.Sref;
geom.taper = geom.wing.chord_tip / geom.wing.chord_root;
geom.MAC   = geom.Cref;

% Tail moment arms (lifting surface AC to lifting surface AC).
% Computed as: x_tail_LE + 0.25*c_tail - (x_wing_LE + 0.25*c_wing)
% Result: 0.760 m, consistent with XFLR5 reported Elev. Lever Arm = 0.75 m.
geom.htail.moment_arm = (geom.htail.x_le + 0.25*geom.htail.chord_root) ...
                      - (geom.wing.x_le  + 0.25*geom.wing.chord_root);

geom.vtail.moment_arm = (geom.vtail.x_le + 0.25*geom.vtail.chord_root) ...
                      - (geom.wing.x_le  + 0.25*geom.wing.chord_root);

geom.Vht = (geom.htail.span   * geom.htail.chord_root * geom.htail.moment_arm) ...
           / (geom.Sref * geom.Cref);

geom.Vvt = (geom.vtail.height * geom.vtail.chord_root * geom.vtail.moment_arm) ...
           / (geom.Sref * geom.Bref);

fprintf('Geometry defined.\n')
fprintf('  AR           = %.2f\n',  geom.AR)
fprintf('  Taper        = %.2f\n',  geom.taper)
fprintf('  Vht          = %.3f\n',  geom.Vht)
fprintf('  Vvt          = %.3f\n',  geom.Vvt)
fprintf('  Htail arm    = %.4f m\n', geom.htail.moment_arm)
fprintf('  MAC          = %.4f m\n', geom.MAC)
fprintf('  CG           = %.4f m (%.1f%% chord)\n', geom.xref, geom.xref/geom.Cref*100)
fprintf('  Mass         = %.3f kg\n', geom.mass)

end


%{
Mass breakdown used for CG calculation (XFLR5 coord system, x from wing LE):

  Item                  mass (kg)    x (m)     z (m)
  Motor                 0.353       -0.303    -0.075
  Battery + prop        0.799       -0.100    -0.075
  Fuselage              0.478        0.000     0.000
  Main spar             0.189        0.103     0.000
  Mini spar             0.044        0.241     0.000
  Tail spar + release   0.295        0.673     0.000
  Nosecone              0.122       -0.227     0.000
  Main gear             0.300        0.076     0.000
  Front gear            0.100       -0.157     0.000
  Wing (skin/ribs)      0.476        0.153*    0.000
  Hstab                 0.150        0.873*    0.000
  Vstab                 0.150        0.873*    0.000
  TOTAL                 3.456       CG=0.103  CG=-0.025

  * Approximated at geometric centroid of each surface (mid-chord).
    If you have more precise estimates, update geom.xref accordingly.
%}