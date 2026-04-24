function avl = parseAVLOutput(stability_file)
% parseAVLOutput  Parse the AVL stability output file into a MATLAB struct.
%
%   avl = parseAVLOutput(stability_file)
%
%   NOTE ON CD0: AVL is inviscid. CDvis is always 0. CDi (Trefftz-plane
%   induced drag) is reliable. True CD0 (fuselage, gear, interference) must
%   come from your sizing script. Use avl.CDi for induced drag only.

txt = fileread(stability_file);

    function val = grab(pattern)
        tok = regexp(txt, pattern, 'tokens', 'once');
        if isempty(tok)
            warning('parseAVLOutput: pattern not found: %s', pattern)
            val = NaN;
        else
            val = str2double(tok{1});
        end
    end

% ── Trim state ────────────────────────────────────────────────────────────
avl.alpha    = grab('Alpha\s*=\s*([-\d.E+]+)');
avl.elevator = grab('elevator\s*=\s*([-\d.E+]+)');

% ── Forces ────────────────────────────────────────────────────────────────
avl.CL    = grab('CLtot\s*=\s*([-\d.E+]+)');
avl.CDtot = grab('CDtot\s*=\s*([-\d.E+]+)');
avl.CDi   = grab('CDff\s*=\s*([\d.E+]+)');
avl.e     = grab('\be\s*=\s*([\d.E+]+)');

% ── Neutral point ─────────────────────────────────────────────────────────
avl.Xnp = grab('Neutral point\s+Xnp\s*=\s*([\d.E+]+)');

% ── Alpha / beta derivatives ──────────────────────────────────────────────
avl.CLa = grab('CLa\s*=\s*([-\d.E+]+)');
avl.Cma = grab('Cma\s*=\s*([-\d.E+]+)');
avl.CYb = grab('CYb\s*=\s*([-\d.E+]+)');
avl.Clb = grab('Clb\s*=\s*([-\d.E+]+)');
avl.Cnb = grab('Cnb\s*=\s*([-\d.E+]+)');

% ── Rate derivatives ──────────────────────────────────────────────────────
avl.CLq = grab('CLq\s*=\s*([-\d.E+]+)');
avl.Cmq = grab('Cmq\s*=\s*([-\d.E+]+)');
avl.CYp = grab('CYp\s*=\s*([-\d.E+]+)');
avl.CYr = grab('CYr\s*=\s*([-\d.E+]+)');
avl.Clp = grab('Clp\s*=\s*([-\d.E+]+)');
avl.Clr = grab('Clr\s*=\s*([-\d.E+]+)');
avl.Cnp = grab('Cnp\s*=\s*([-\d.E+]+)');
avl.Cnr = grab('Cnr\s*=\s*([-\d.E+]+)');

% ── Spiral stability ──────────────────────────────────────────────────────
avl.spiral_ratio = (avl.Clb * avl.Cnr) / (avl.Clr * avl.Cnb);

% ── Print summary ─────────────────────────────────────────────────────────
fprintf('\n=== AVL Results ===\n')
fprintf('  Trim alpha     = %+.3f deg\n',  avl.alpha)
fprintf('  Trim elevator  = %+.3f deg\n',  avl.elevator)
fprintf('  CL             =  %.4f\n',       avl.CL)
fprintf('  CDi (Trefftz)  =  %.5f  [induced only -- CD0 from sizing script]\n', avl.CDi)
fprintf('  Span eff. e    =  %.4f\n',       avl.e)
fprintf('  Neutral pt Xnp =  %.4f m\n',    avl.Xnp)
fprintf('\n  --- Pitch ---\n')
fprintf('  CLa  = %+.4f /rad\n',   avl.CLa)
fprintf('  Cma  = %+.4f /rad   (< 0 = stable)\n', avl.Cma)
fprintf('  Cmq  = %+.4f /rad\n',   avl.Cmq)
fprintf('\n  --- Lateral/Directional ---\n')
fprintf('  Clb  = %+.4f /rad\n',   avl.Clb)
fprintf('  Cnb  = %+.4f /rad   (> 0 = weathercock stable)\n', avl.Cnb)
fprintf('  Clp  = %+.4f /rad   (roll damping)\n',  avl.Clp)
fprintf('  Cnr  = %+.4f /rad   (yaw  damping)\n',  avl.Cnr)
fprintf('  Spiral ratio   =  %.3f  (> 1 = spirally stable)\n', avl.spiral_ratio)

end