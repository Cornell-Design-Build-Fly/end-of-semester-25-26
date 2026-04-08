function viewAVLGeom(geom)
% viewAVLGeom  Write the AVL geometry file and open AVL's visual geometry viewer.
%
%   viewAVLGeom(geom)
%
%   Generates dfo.avl from your geom struct, launches AVL in a new cmd window,
%   and automatically navigates to the geometry viewer.
%
%   The graphics window is fully interactive once open:
%     L / R    rotate left / right
%     U / D    rotate up / down
%     I / O    ingress / outgress (perspective)
%     TR       toggle trailing wake vortices
%
%   To close: press Return in the graphics window to exit the geometry-plot
%   menu, then Return again to exit OPER, then type QUIT at the AVL prompt.
%   The cmd window and graphics window will both close.

cfg = avlConfig();

avl_file  = fullfile(cfg.work_dir, 'dfo.avl');
pre_file  = fullfile(cfg.work_dir, 'avl_pre.txt');
bat_file  = fullfile(cfg.work_dir, 'view_avl.bat');

% Write geometry file
buildAVLGeom(geom, avl_file);

% Pre-commands feed AVL into the geometry viewer.
% After these two lines are consumed, stdin switches to the live keyboard
% via 'type CON' in the batch file, so the user has full control.
fid = fopen(pre_file, 'w');
fprintf(fid, 'OPER\n');
fprintf(fid, 'G\n');
fclose(fid);

% Batch file pipes pre-commands then hands stdin to CON (the live keyboard).
% This means:
%   - AVL receives OPER and G automatically on launch
%   - After that, your keystrokes go directly to AVL
%   - The graphics window is fully interactive
%   - Type Return to exit geometry plot menu, Return to exit OPER,
%     then QUIT at the main prompt to close everything cleanly.
fid = fopen(bat_file, 'w');
fprintf(fid, '@echo off\n');
fprintf(fid, 'cd /d "%s"\n', cfg.work_dir);
fprintf(fid, 'echo.\n');
fprintf(fid, 'echo  AVL geometry viewer loading...\n');
fprintf(fid, 'echo  Interact with the graphics window normally.\n');
fprintf(fid, 'echo  To close: Return (in graphics window) then Return then QUIT\n');
fprintf(fid, 'echo.\n');
fprintf(fid, '(type "%s" ^& type CON) | "%s" "%s"\n', ...
    pre_file, cfg.avl_exe, avl_file);
fclose(fid);

fprintf('Opening AVL in a new window...\n')
fprintf('To close AVL: press Return in graphics window, Return again, then type QUIT.\n\n')

system(sprintf('start /WAIT "AVL Viewer" "%s"', bat_file));

delete(pre_file);
delete(bat_file);

fprintf('AVL closed. Back in MATLAB.\n')

end