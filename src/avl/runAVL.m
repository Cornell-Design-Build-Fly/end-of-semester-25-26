function out = runAVL(geom, V)
% runAVL  Run a trimmed AVL analysis and return paths to output files.
%
%   out = runAVL(geom, V)
%
%   Inputs:
%     geom  -- geometry struct from defineGeom.m
%     V     -- cruise velocity [m/s]

cfg = avlConfig();

% ── Flight condition ──────────────────────────────────────────────────────
flight.V    = V;
flight.rho  = 1.225;
flight.mass = geom.mass;

g         = 9.81;
CL_cruise = (2 * flight.mass * g) / (flight.rho * V^2 * geom.Sref);

fprintf('Flight condition:\n')
fprintf('  V         = %.2f m/s\n',   V)
fprintf('  rho       = %.4f kg/m3\n', flight.rho)
fprintf('  mass      = %.3f kg\n',    flight.mass)
fprintf('  CL_cruise = %.4f\n',       CL_cruise)

% ── File paths ────────────────────────────────────────────────────────────
avl_file       = fullfile(cfg.work_dir, 'dfo.avl');
mass_file      = fullfile(cfg.work_dir, 'dfo.mass');
cmd_file       = fullfile(cfg.work_dir, 'avl_run_cmd.txt');
bat_file       = fullfile(cfg.work_dir, 'run_avl.bat');
stability_file = fullfile(cfg.work_dir, 'dfo_stability.txt');
log_file       = fullfile(cfg.work_dir, 'avl_log.txt');

% ── Write geometry and mass files ─────────────────────────────────────────
buildAVLGeom(geom, avl_file);
buildAVLMass(geom);

% ── Write AVL command file ────────────────────────────────────────────────
% All filenames in the command file are bare (no path) because the batch
% file cds into work_dir first, so AVL resolves them locally.
fid = fopen(cmd_file, 'w');
fprintf(fid, 'MASS dfo.mass\n');
fprintf(fid, 'MSET 0\n');
fprintf(fid, 'OPER\n');
fprintf(fid, 'A C %.6f\n', CL_cruise);
fprintf(fid, 'D2 PM 0\n');
fprintf(fid, 'X\n');
fprintf(fid, 'ST\n');
fprintf(fid, 'dfo_stability.txt\n');
fprintf(fid, 'O\n');   % if file exists: overwrite; if not: harmless Options cmd
fprintf(fid, '\n');    % exit Options submenu if O was interpreted as Options
fprintf(fid, '\n');    % exit OPER menu
fprintf(fid, 'QUIT\n');
fclose(fid);

% ── Delete any existing stability file ────────────────────────────────────
% Overwrite handled in command file with 'O' response (see below)

% ── Write batch file ──────────────────────────────────────────────────────
% The batch file cds into work_dir so all filenames can be bare (no spaces).
% The avl exe path is quoted since it may contain spaces.
fid = fopen(bat_file, 'w');
fprintf(fid, '@echo off\n');
fprintf(fid, 'cd /d "%s"\n', cfg.work_dir);
fprintf(fid, '"%s" dfo.avl < avl_run_cmd.txt > avl_log.txt\n', cfg.avl_exe);
fclose(fid);

% ── Run ───────────────────────────────────────────────────────────────────
% cmd /c "path" is the correct Windows invocation for a batch file whose
% path contains spaces.
fprintf('Running AVL...\n')
global pct_done;
fprintf('Progress: case %.2f%% done\n', pct_done);
status = system(sprintf('cmd /c "%s"', bat_file));
delete(bat_file);
delete(cmd_file);

% ── Check outputs ─────────────────────────────────────────────────────────
if status ~= 0
    warning('runAVL: AVL exited with status %d. Check avl_log.txt.', status)
end
if ~isfile(stability_file)
    warning('runAVL: Stability file not found. AVL may have failed.')
end

% ── Return ────────────────────────────────────────────────────────────────
out.forces_file    = log_file;
out.stability_file = stability_file;
out.status         = status;
out.CL_cruise      = CL_cruise;
out.flight         = flight;

fprintf('Done. Output files:\n')
fprintf('  Stability: %s\n', stability_file)
fprintf('  AVL log:   %s\n', log_file)

end