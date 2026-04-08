function out = runAVL(geom, flight)
% runAVL  Run a trimmed AVL analysis and return paths to output files.
%
%   out = runAVL(geom, flight)
%
%   Inputs:
%     geom    -- geometry struct from defineGeom.m
%     flight  -- flight condition struct with fields:
%                  flight.V      [m/s]   cruise velocity
%                  flight.rho    [kg/m3] air density (default 1.225)
%                  flight.mass   [kg]    total aircraft mass (default geom.mass)
%
%   Output:
%     out.forces_file      -- path to FT forces output text file
%     out.stability_file   -- path to ST stability derivatives output text file
%     out.status           -- AVL exit status (0 = clean)
%
%   What this runs (equivalent manual session):
%     OPER
%       A C [cruise_CL]      -- constrain alpha to give level-flight CL
%       D1 PM 0              -- elevator to zero pitching moment (trimmed)
%       X                    -- execute
%       FT                   -- forces output
%       fs forces.txt        -- write to file
%       ST                   -- stability derivatives
%       ss stability.txt     -- write to file
%       (return)             -- exit OPER
%     QUIT

cfg = avlConfig();

% ── Defaults ─────────────────────────────────────────────────────────────
if ~isfield(flight, 'rho'),  flight.rho  = 1.225;     end
if ~isfield(flight, 'mass'), flight.mass = geom.mass;  end

% ── File paths ────────────────────────────────────────────────────────────
avl_file      = fullfile(cfg.work_dir, 'dfo.avl');
mass_file     = fullfile(cfg.work_dir, 'dfo.mass');
cmd_file      = fullfile(cfg.work_dir, 'avl_run_cmd.txt');
forces_file   = fullfile(cfg.work_dir, 'dfo_forces.txt');
stability_file = fullfile(cfg.work_dir, 'dfo_stability.txt');

% ── Write geometry and mass files ─────────────────────────────────────────
buildAVLGeom(geom, avl_file);
buildAVLMass(geom);

% ── Compute cruise CL ─────────────────────────────────────────────────────
% Level flight: L = W  ->  CL = 2mg / (rho V^2 S)
g  = 9.81;
CL_cruise = (2 * flight.mass * g) / (flight.rho * flight.V^2 * geom.Sref);

fprintf('Flight condition:\n')
fprintf('  V      = %.2f m/s\n',  flight.V)
fprintf('  rho    = %.4f kg/m3\n', flight.rho)
fprintf('  mass   = %.3f kg\n',   flight.mass)
fprintf('  CL_cruise = %.4f\n',   CL_cruise)

% ── Write AVL command file ────────────────────────────────────────────────
% AVL reads mass file with the MASS command, then MSET applies it to the
% run case so the trim knows the actual aircraft weight.
% A C [CL] constrains alpha to achieve that CL.
% D1 PM 0  constrains elevator (control 1) to zero pitching moment.
% X executes the trimmed solution.
% Forces are already printed to avl_log.txt after X executes.
% ST prompts "Enter filename or <return> for screen" -- provide filename
% directly on the next line. One blank exits OPER, then QUIT.

fid = fopen(cmd_file, 'w');
fprintf(fid, 'MASS %s\n', mass_file);
fprintf(fid, 'MSET 0\n');
fprintf(fid, 'OPER\n');
fprintf(fid, 'A C %.6f\n', CL_cruise);
fprintf(fid, 'D2 PM 0\n');
fprintf(fid, 'X\n');
fprintf(fid, 'ST\n');
fprintf(fid, '%s\n', stability_file);
fprintf(fid, '\n');
fprintf(fid, 'QUIT\n');
fclose(fid);

% ── Run AVL ───────────────────────────────────────────────────────────────
cmd = sprintf('"%s" "%s" < "%s" > "%s"', ...
    cfg.avl_exe, avl_file, cmd_file, fullfile(cfg.work_dir, 'avl_log.txt'));

fprintf('Running AVL...\n')
status = system(cmd);

% ── Check outputs ─────────────────────────────────────────────────────────
if status ~= 0
    warning('runAVL: AVL exited with status %d. Check avl_log.txt for details.', status)
end

if ~isfile(forces_file)
    warning('runAVL: Forces output file not found. AVL may have failed during execution.')
end

if ~isfile(stability_file)
    warning('runAVL: Stability output file not found. AVL may have failed during execution.')
end

% ── Clean up and return ───────────────────────────────────────────────────
delete(cmd_file);

out.forces_file    = fullfile(cfg.work_dir, 'avl_log.txt');  % forces parsed from log
out.stability_file = stability_file;
out.status         = status;
out.CL_cruise      = CL_cruise;
out.flight         = flight;

fprintf('Done. Output files:\n')
fprintf('  Forces:      %s\n', forces_file)
fprintf('  Stability:   %s\n', stability_file)
fprintf('  AVL log:     %s\n', fullfile(cfg.work_dir, 'avl_log.txt'))

end