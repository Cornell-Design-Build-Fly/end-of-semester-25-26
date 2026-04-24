function cfg = avlConfig()
% avlConfig  Central configuration for the MATLAB-AVL interface.
%
% All other AVL functions call this to get file paths.
% If you reorganize the project, this is the only file you need to update.

this_dir = fileparts(mfilename('fullpath'));

cfg.avl_exe     = fullfile(this_dir, 'avl352.exe');
cfg.work_dir    = this_dir;
cfg.airfoil_dir = this_dir;

if ~isfile(cfg.avl_exe)
    warning('avlConfig: AVL binary not found at:\n  %s\nCheck your path.', cfg.avl_exe)
end

end