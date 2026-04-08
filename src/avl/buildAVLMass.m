function mass_file = buildAVLMass(geom)
% buildAVLMass  Write the AVL mass file from the geom struct.
%
%   mass_file = buildAVLMass(geom)
%
%   Returns the full path to the written .mass file.
%   AVL needs this for trim calculations and eigenmode analysis.
%   All units are SI (meters, kg, seconds) since our geom struct is in meters.

cfg = avlConfig();
mass_file = fullfile(cfg.work_dir, 'dfo.mass');

fid = fopen(mass_file, 'w');
if fid == -1
    error('Could not open file: %s', mass_file)
end

fprintf(fid, '#  Duck Force One mass file\n');
fprintf(fid, '#  All units: meters, kg, seconds\n\n');
fprintf(fid, 'Lunit = 1.0 m\n');
fprintf(fid, 'Munit = 1.0 kg\n');
fprintf(fid, 'Tunit = 1.0 s\n\n');
fprintf(fid, 'g   = 9.81\n');
fprintf(fid, 'rho = 1.225\n\n');

% Mass breakdown from XFLR5 point masses + surface masses.
% x,y,z are positions from wing leading edge (our coordinate origin).
% Inertias are omitted (set to zero) -- AVL treats absent values as zero.
% If you add inertia data later, the column order is:
%   mass   x     y     z    Ixx   Iyy   Izz
fprintf(fid, '#  mass      x        y       z        description\n');
fprintf(fid, '   0.353   -0.303   0.000  -0.075   ! motor\n');
fprintf(fid, '   0.799   -0.100   0.000  -0.075   ! battery + prop\n');
fprintf(fid, '   0.478    0.000   0.000   0.000   ! fuselage\n');
fprintf(fid, '   0.189    0.103   0.000   0.000   ! main spar\n');
fprintf(fid, '   0.044    0.241   0.000   0.000   ! mini spar\n');
fprintf(fid, '   0.295    0.673   0.000   0.000   ! tail spar + banner release\n');
fprintf(fid, '   0.122   -0.227   0.000   0.000   ! nosecone\n');
fprintf(fid, '   0.300    0.076   0.000   0.000   ! main gear\n');
fprintf(fid, '   0.100   -0.157   0.000   0.000   ! front gear\n');
fprintf(fid, '   %.3f    %.3f   0.000   0.000   ! wing\n', ...
    0.476, geom.wing.x_le + 0.5*geom.wing.chord_root);
fprintf(fid, '   0.150    %.3f   0.000   0.000   ! hstab\n', ...
    geom.htail.x_le + 0.5*geom.htail.chord_root);
fprintf(fid, '   0.150    %.3f   0.000   0.000   ! vstab\n', ...
    geom.vtail.x_le + 0.5*geom.vtail.chord_root);

fclose(fid);
fprintf('Mass file written: %s\n', mass_file)

end