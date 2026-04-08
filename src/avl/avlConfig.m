function cfg = avlConfig()
% avlConfig  Central configuration for the MATLAB-AVL interface.
%
% All other AVL functions call this to get file paths.
% If you reorganize the project, this is the only file you need to update.

% Directory containing this config file (src\avl\)
this_dir = fileparts(mfilename('C:\Users\kaspe\OneDrive\Cornell\All\Coding\end-of-semester-25-26\src\avl\'));

% AVL binary is two levels up from src\avl\
cfg.avl_exe = fullfile('C:\Users\kaspe\OneDrive\Cornell\All\Coding\end-of-semester-25-26\avl352.exe');

% Working directory for generated AVL files (.avl, .run, output .txt files)
% Keeping them here in src\avl\ next to the MATLAB code.
cfg.work_dir = this_dir;

% Airfoil .dat files directory (place fx60126.dat here)
cfg.airfoil_dir = this_dir;

% Verify AVL binary exists and warn early if not
if ~isfile(cfg.avl_exe)
    warning('avlConfig: AVL binary not found at:\n  %s\nCheck your path.', cfg.avl_exe)
end

end