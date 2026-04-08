function buildAVLGeom(geom, filename)
% buildAVLGeom  Write an AVL geometry file from the geom struct.
%
%   buildAVLGeom(geom, filename)
%
%   geom     -- geometry struct from defineGeom.m
%   filename -- output filename, e.g. 'dfo.avl'
%
% Open the resulting file in AVL (type 'load dfo.avl' then 'oper' then 'g')
% to visually confirm the geometry before running any analysis.
%
% Build order for verification:
%   Step 1 (now):   Main wing only, no tails, no controls
%   Step 2:         Add horizontal and vertical tail
%   Step 3:         Add control surfaces (aileron, elevator, rudder)
%   Step 4:         Add mass file (.mass) for eigenmode / trim analysis

fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file: %s', filename)
end

% ── Header ───────────────────────────────────────────────────────────────
fprintf(fid, 'Duck Force One\n');
fprintf(fid, '0.0                        !Mach\n');
fprintf(fid, '0    0    0.0              !iYsym  iZsym  Zsym\n');
fprintf(fid, '%-8.4f %-8.4f %-8.4f   !Sref  Cref  Bref\n', ...
        geom.Sref, geom.Cref, geom.Bref);
fprintf(fid, '%-8.4f %-8.4f %-8.4f   !Xref  Yref  Zref (CG location)\n\n', ...
        geom.xref, geom.yref, geom.zref);

% ── Main Wing ────────────────────────────────────────────────────────────
% YDUPLICATE mirrors the surface across the XZ plane, giving us both wings
% from one half-span definition. This is how AVL handles symmetric aircraft.

half_span = geom.wing.span / 2;

% Tip LE position accounting for sweep and dihedral.
% dx_tip = half_span * tan(sweep_LE),  dz_tip = half_span * tan(dihedral)
dx_tip = half_span * tand(geom.wing.sweep_LE);
dz_tip = half_span * tand(geom.wing.dihedral);

fprintf(fid, '#=============================================================\n');
fprintf(fid, 'SURFACE\n');
fprintf(fid, 'Main Wing\n');
fprintf(fid, '%d  1.0  %d  1.0          !Nspan Sspace Nchord Cspace\n', ...
        geom.wing.Nspan, geom.wing.Nchord);
fprintf(fid, '\n');
fprintf(fid, 'YDUPLICATE\n');
fprintf(fid, '0.0\n\n');
fprintf(fid, 'ANGLE\n');
fprintf(fid, '%.1f\n\n', geom.wing.incidence);

% Root section
fprintf(fid, 'SECTION\n');
fprintf(fid, '#Xle      Yle    Zle    chord   angle\n');
fprintf(fid, '%-8.4f  0.0000  %-6.4f  %-8.4f  %.2f\n', ...
        geom.wing.x_le, geom.wing.z_le, geom.wing.chord_root, geom.wing.twist_tip*0);
writeAirfoil(fid, geom.wing.airfoil);

% Tip section
fprintf(fid, '\nSECTION\n');
fprintf(fid, '#Xle      Yle       Zle       chord     angle\n');
fprintf(fid, '%-8.4f  %-8.4f  %-8.4f  %-8.4f  %.2f\n', ...
        geom.wing.x_le + dx_tip, half_span, geom.wing.z_le + dz_tip, ...
        geom.wing.chord_tip, geom.wing.twist_tip);
writeAirfoil(fid, geom.wing.airfoil);

% Aileron control surface on tip section
fprintf(fid, '\nCONTROL\n');
fprintf(fid, 'aileron    1.0   %.2f    0.0 0.0 0.0    -1.0\n', geom.wing.aileron_hinge);
fprintf(fid, '\n\n');

% ── Horizontal Stabilizer ────────────────────────────────────────────────
htail_half = geom.htail.span / 2;
htail_dx   = htail_half * tand(geom.htail.sweep_LE);
htail_dz   = htail_half * tand(geom.htail.dihedral);

fprintf(fid, '#=============================================================\n');
fprintf(fid, 'SURFACE\n');
fprintf(fid, 'Horizontal Stabilizer\n');
fprintf(fid, '%d  1.0  %d  1.0          !Nspan Sspace Nchord Cspace\n', ...
        geom.htail.Nspan, geom.htail.Nchord);
fprintf(fid, '\n');
fprintf(fid, 'YDUPLICATE\n');
fprintf(fid, '0.0\n\n');
fprintf(fid, 'ANGLE\n');
fprintf(fid, '%.1f\n\n', geom.htail.incidence);

% Root section
fprintf(fid, 'SECTION\n');
fprintf(fid, '#Xle      Yle    Zle    chord   angle\n');
fprintf(fid, '%-8.4f  0.0000  %-6.4f  %-8.4f  0.00\n', ...
        geom.htail.x_le, geom.htail.z_le, geom.htail.chord_root);
writeAirfoil(fid, geom.htail.airfoil);
fprintf(fid, '\nCONTROL\n');
fprintf(fid, 'elevator   1.0   %.2f    0.0 0.0 0.0     1.0\n', geom.htail.elevator_hinge);

% Tip section
fprintf(fid, '\nSECTION\n');
fprintf(fid, '#Xle      Yle       Zle       chord     angle\n');
fprintf(fid, '%-8.4f  %-8.4f  %-8.4f  %-8.4f  0.00\n', ...
        geom.htail.x_le + htail_dx, htail_half, ...
        geom.htail.z_le + htail_dz, geom.htail.chord_tip);
writeAirfoil(fid, geom.htail.airfoil);
fprintf(fid, '\nCONTROL\n');
fprintf(fid, 'elevator   1.0   %.2f    0.0 0.0 0.0     1.0\n', geom.htail.elevator_hinge);
fprintf(fid, '\n\n');

% ── Vertical Stabilizer ──────────────────────────────────────────────────
% The vertical tail's "span" runs in Z. We achieve this by setting
% dihedral = 90 deg. In AVL's section coordinates, Yle becomes the
% spanwise coordinate running upward, so we use it for the height here.
% No YDUPLICATE for the vertical tail.

vtail_dx = geom.vtail.height * tand(geom.vtail.sweep_LE);

fprintf(fid, '#=============================================================\n');
fprintf(fid, 'SURFACE\n');
fprintf(fid, 'Vertical Stabilizer\n');
fprintf(fid, '%d  1.0  %d  1.0          !Nspan Sspace Nchord Cspace\n', ...
        geom.vtail.Nspan, geom.vtail.Nchord);
fprintf(fid, '\n');

% Root section (at fuselage, y=0, z=z_le)
fprintf(fid, 'SECTION\n');
fprintf(fid, '#Xle      Yle    Zle       chord   angle\n');
fprintf(fid, '%-8.4f  0.0000  %-6.4f  %-8.4f  0.00\n', ...
        geom.vtail.x_le, geom.vtail.z_le, geom.vtail.chord_root);
writeAirfoil(fid, geom.vtail.airfoil);
fprintf(fid, '\nCONTROL\n');
fprintf(fid, 'rudder   1.0   %.2f    0.0 0.0 0.0     1.0\n', geom.vtail.rudder_hinge);

% Tip section (displaced upward by height, and aft by sweep)
fprintf(fid, '\nSECTION\n');
fprintf(fid, '#Xle                  Yle    Zle (tip height)   chord   angle\n');
fprintf(fid, '%-8.4f  0.0000  %-6.4f  %-8.4f  0.00\n', ...
        geom.vtail.x_le + vtail_dx, geom.vtail.z_le + geom.vtail.height, ...
        geom.vtail.chord_tip);
writeAirfoil(fid, geom.vtail.airfoil);
fprintf(fid, '\nCONTROL\n');
fprintf(fid, 'rudder   1.0   %.2f    0.0 0.0 0.0     1.0\n', geom.vtail.rudder_hinge);

fclose(fid);
fprintf('AVL geometry file written: %s\n', filename)
fprintf('Open in AVL with:  load %s\n', filename)
fprintf('Then view with:    oper -> g\n')

end


% ── Helper: write airfoil line ────────────────────────────────────────────
function writeAirfoil(fid, airfoil_str)
% Handles both NACA strings and .dat filenames.
    if startsWith(airfoil_str, 'NACA') || startsWith(airfoil_str, 'naca')
        % AVL expects the keyword on one line and the 4-digit identifier
        % on the next line. 'NACA 0012' on one line gets misread.
        digits = strtrim(strrep(strrep(airfoil_str, 'NACA', ''), 'naca', ''));
        fprintf(fid, 'NACA\n%s\n', digits);
    else
        % External .dat file reference
        fprintf(fid, 'AFILE\n');
        fprintf(fid, '%s\n', airfoil_str);
    end
end