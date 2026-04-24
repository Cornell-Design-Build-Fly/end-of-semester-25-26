function aircraft = massToAVL(mass)
    % massToAVL  Build the AVL-compatible aircraft struct from a mass breakdown.
    %
    %   aircraft = massToAVL(mass)
    %
    %   mass     -- output of defineMassConfig()
    %
    %   aircraft -- fully populated struct ready for runAVL(), buildAVLGeom(),
    %               computeAVLModes(), etc. Same field layout as the old defineGeom()
    %               so all downstream functions work without changes.
    
    %% ── Reference geometry ───────────────────────────────────────────────────
    aircraft.Sref = mass.wing_span * mass.wing_chord;
    aircraft.Cref = mass.wing_chord;
    aircraft.Bref = mass.wing_span;
    aircraft.AR   = mass.wing_span / mass.wing_chord;
    aircraft.MAC  = mass.wing_chord;
    aircraft.taper = 1.0;
    
    %% ── CG ───────────────────────────────────────────────────────────────────
    aircraft.xref = mass.CG(1);
    aircraft.yref = 0;
    aircraft.zref = mass.CG(3);
    aircraft.mass = mass.total;
    
    %% ── Tail arm (recovered from htail_x_le and chord geometry) ─────────────
    aircraft.tail_arm = (mass.htail_x_le + 0.25*mass.htail_chord) ...
                      - (0               + 0.25*mass.wing_chord);
    
    %% ── Tail volume coefficients ─────────────────────────────────────────────
    aircraft.Vht = (mass.htail_span  * mass.htail_chord  * aircraft.tail_arm) ...
                   / (aircraft.Sref  * aircraft.Cref);
    aircraft.Vvt = (mass.vtail_height * mass.vtail_chord * aircraft.tail_arm) ...
                   / (aircraft.Sref  * aircraft.Bref);
    
    %% ── Wing ─────────────────────────────────────────────────────────────────
    aircraft.wing.span          = mass.wing_span;
    aircraft.wing.chord_root    = mass.wing_chord;
    aircraft.wing.chord_tip     = mass.wing_chord;
    aircraft.wing.sweep_LE      = 0;
    aircraft.wing.dihedral      = 0;
    aircraft.wing.incidence     = 0;
    aircraft.wing.twist_tip     = 0;
    aircraft.wing.x_le          = 0;
    aircraft.wing.z_le          = 0;
    aircraft.wing.airfoil       = 'wortmanFX60-126.dat';
    aircraft.wing.aileron_hinge = 0.75;
    aircraft.wing.Nspan         = 12;
    aircraft.wing.Nchord        = 4;
    
    %% ── Horizontal tail ──────────────────────────────────────────────────────
    aircraft.htail.span             = mass.htail_span;
    aircraft.htail.chord_root       = mass.htail_chord;
    aircraft.htail.chord_tip        = mass.htail_chord;
    aircraft.htail.sweep_LE         = 0;
    aircraft.htail.dihedral         = 0;
    aircraft.htail.incidence        = -2.0;
    aircraft.htail.x_le             = mass.htail_x_le;
    aircraft.htail.z_le             = 0;
    aircraft.htail.airfoil          = 'NACA 0012';
    aircraft.htail.elevator_hinge   = 0.70;
    aircraft.htail.moment_arm       = aircraft.tail_arm;
    aircraft.htail.Nspan            = 8;
    aircraft.htail.Nchord           = 4;
    
    %% ── Vertical tail ────────────────────────────────────────────────────────
    aircraft.vtail.height           = mass.vtail_height;
    aircraft.vtail.chord_root       = mass.vtail_chord;
    aircraft.vtail.chord_tip        = mass.vtail_chord;
    aircraft.vtail.sweep_LE         = 0;
    aircraft.vtail.incidence        = 0;
    aircraft.vtail.x_le             = mass.vtail_x_le;
    aircraft.vtail.z_le             = 0;
    aircraft.vtail.airfoil          = 'NACA 0012';
    aircraft.vtail.rudder_hinge     = 0.70;
    aircraft.vtail.moment_arm       = aircraft.tail_arm;
    aircraft.vtail.Nspan            = 6;
    aircraft.vtail.Nchord           = 4;
    
    %% ── Inertia (for computeAVLModes) ────────────────────────────────────────
    aircraft.Ixx = mass.I(1);
    aircraft.Iyy = mass.I(2);
    aircraft.Izz = mass.I(3);
    aircraft.Ixz = mass.I(4);
    
    %% ── Print summary ────────────────────────────────────────────────────────
    fprintf('\n=== Aircraft Config ===\n')
    fprintf('  Wing:    span = %.3f m   chord = %.4f m   AR = %.2f   S = %.4f m²\n', ...
        aircraft.Bref, aircraft.Cref, aircraft.AR, aircraft.Sref)
    fprintf('  Htail:   span = %.3f m   chord = %.4f m   x_le = %.4f m\n', ...
        aircraft.htail.span, aircraft.htail.chord_root, aircraft.htail.x_le)
    fprintf('  Vtail:   h    = %.3f m   chord = %.4f m   x_le = %.4f m\n', ...
        aircraft.vtail.height, aircraft.vtail.chord_root, aircraft.vtail.x_le)
    fprintf('  Tail arm = %.4f m   Vht = %.3f   Vvt = %.3f\n', ...
        aircraft.tail_arm, aircraft.Vht, aircraft.Vvt)
    fprintf('  Mass     = %.3f kg\n', aircraft.mass)
    fprintf('  CG       = %.4f m (%.1f%% MAC)\n', aircraft.xref, aircraft.xref/aircraft.Cref*100)
end