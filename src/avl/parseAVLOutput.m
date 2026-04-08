function avl = parseAVLOutput(stability_file)
% parseAVLOutput  Parse the AVL stability output file into a MATLAB struct.
%
%   avl = parseAVLOutput(stability_file)
%
%   stability_file -- path to the ST output file written by runAVL.m
%
%   Returns a struct with fields:
%
%   avl.alpha          trim angle of attack [deg]
%   avl.elevator       trim elevator deflection [deg]
%   avl.CL             total lift coefficient
%   avl.CDi            induced drag (Trefftz plane, most reliable)
%   avl.CDtot          total drag coefficient
%   avl.e              span efficiency factor
%   avl.Xnp            neutral point x-location [m]
%
%   avl.CLa            lift curve slope dCL/dalpha [per rad]
%   avl.Cma            pitch stability dCm/dalpha  [per rad]  (want < 0)
%   avl.CYb            side force    dCY/dbeta     [per rad]
%   avl.Clb            roll moment   dCl/dbeta     [per rad]  (dihedral effect)
%   avl.Cnb            yaw moment    dCn/dbeta     [per rad]  (want > 0)
%   avl.Clp            roll damping  dCl/d(pb/2V)  [per rad]  (want < 0)
%   avl.Cmq            pitch damping dCm/d(qc/2V)  [per rad]  (want < 0)
%   avl.Cnr            yaw damping   dCn/d(rb/2V)  [per rad]  (want < 0)
%   avl.Clr            roll due to yaw              [per rad]
%   avl.Cnp            yaw due to roll              [per rad]
%   avl.CLq            lift due to pitch rate        [per rad]
%   avl.CYr            side force due to yaw rate    [per rad]
%
%   avl.spiral_ratio   Clb*Cnr / (Clr*Cnb)  (> 1 = spirally stable)

txt = fileread(stability_file);

% ── Helper: extract a named scalar ───────────────────────────────────────
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
avl.CDi   = grab('CDff\s*=\s*([\d.E+]+)');     % Trefftz-plane CDi
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
avl.CYr = grab('CYr\s*=\s*([-\d.E+]+)');
avl.Clp = grab('Clp\s*=\s*([-\d.E+]+)');
avl.Clr = grab('Clr\s*=\s*([-\d.E+]+)');
avl.Cnp = grab('Cnp\s*=\s*([-\d.E+]+)');
avl.Cnr = grab('Cnr\s*=\s*([-\d.E+]+)');

% ── Derived ───────────────────────────────────────────────────────────────
avl.spiral_ratio = (avl.Clb * avl.Cnr) / (avl.Clr * avl.Cnb);

% ── Print summary ─────────────────────────────────────────────────────────
fprintf('\n=== AVL Results ===\n')
fprintf('  Trim alpha     = %+.3f deg\n',  avl.alpha)
fprintf('  Trim elevator  = %+.3f deg\n',  avl.elevator)
fprintf('  CL             =  %.4f\n',       avl.CL)
fprintf('  CDi (Trefftz)  =  %.5f\n',       avl.CDi)
fprintf('  Span eff. e    =  %.4f\n',       avl.e)
fprintf('  Neutral pt Xnp =  %.4f m\n',    avl.Xnp)
fprintf('\n  --- Pitch ---\n')
fprintf('  CLa  = %+.4f /rad   (lift curve slope)\n',   avl.CLa)
fprintf('  Cma  = %+.4f /rad   (< 0 = stable)\n',       avl.Cma)
fprintf('  Cmq  = %+.4f /rad   (pitch damping)\n',       avl.Cmq)
fprintf('\n  --- Lateral/Directional ---\n')
fprintf('  Clb  = %+.4f /rad   (dihedral effect)\n',    avl.Clb)
fprintf('  Cnb  = %+.4f /rad   (> 0 = weathercock stable)\n', avl.Cnb)
fprintf('  Clp  = %+.4f /rad   (roll damping, < 0 good)\n',   avl.Clp)
fprintf('  Cnr  = %+.4f /rad   (yaw damping,  < 0 good)\n',   avl.Cnr)
fprintf('  Spiral ratio   =  %.3f  (> 1 = spirally stable)\n', avl.spiral_ratio)

end