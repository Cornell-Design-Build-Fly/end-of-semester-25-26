function [aero, geom] = parseXFLR5(stabFile)
% parseXFLR5  Parse an XFLR5 Type-7 stability analysis export (.txt).
%
% USAGE
%   [aero, geom] = parseXFLR5('output.txt')
%   aero         = parseXFLR5('output.txt')   % geom silently ignored
%
% OUTPUT STRUCT  aero  (operating point + derivatives + modes — unchanged)
%   ── Operating point ──────────────────────────────────────────────────
%   .V          Cruise speed              [m/s]
%   .alpha      Trim angle of attack      [deg]
%   .mass       Aircraft mass             [kg]
%   .CL         Lift coefficient          [-]       -> cruise Cz
%   .CD         Total drag coefficient    [-]       -> cruise Cx
%   .CD_induced Induced drag (ICD)        [-]       -> span efficiency
%   .CD_profile Viscous/profile drag(VCD) [-]       -> Cx0 proxy
%   .LD         Lift-to-drag ratio        [-]       -> lap time
%   .XNP        Neutral point             [m]       -> static margin input
%   .XCP        Centre of pressure        [m]       -> trim reference
%
%   ── Stability derivatives ────────────────────────────────────────────
%   .CLa  .Cma  .Cmq  .Cyb  .Clb  .Cnb  .Clp  .Cnr
%
%   ── Flight modes ─────────────────────────────────────────────────────
%   .modes.ShortPeriod / .Phugoid / .Roll / .DutchRoll / .Spiral
%     each with: .sigma .omega .wn .wd .zeta .stable .t2
%
% OUTPUT STRUCT  geom  (reference geometry + inertia)
%   .S      Reference wing area        [m²]
%   .b      Reference span             [m]
%   .c      Reference chord (MAC)      [m]
%   .AR     Aspect ratio               [-]     = b²/S
%   .Xg     CG x-position              [m]     -> static margin
%   .Zg     CG z-position              [m]
%   .Ixx    Roll inertia               [kg.m²]
%   .Iyy    Pitch inertia              [kg.m²] -> lon_stability Byy input
%   .Izz    Yaw inertia                [kg.m²]
%   .Ixz    Cross inertia              [kg.m²]
%   .rho    Air density                [kg/m³]
%   .nu     Kinematic viscosity        [m²/s]
%   .SM     Static margin              [-]     = (XNP - Xg) / c
%
% -------------------------------------------------------------------------

    txt  = fileread(stabFile);
    aero = struct();

    %% ── Operating point ──────────────────────────────────────────────────
    aero.V      = sc(txt, 'VInf\s*=\s*([\d.]+)');
    aero.alpha  = sc(txt, 'Alpha\s*=\s*([-\d.]+)');
    aero.mass   = sc(txt, 'Mass\s*=\s*([\d.]+)');
    aero.CL     = sc(txt, 'CL\s*=\s*([\d.]+)');
    aero.CD     = sc(txt, '(?<![A-Z])CD\s*=\s*([\d.]+)');
    aero.CD_induced = sc(txt, 'ICD\s*=\s*([\d.]+)');
    aero.CD_profile = sc(txt, 'VCD\s*=\s*([\d.]+)');
    aero.XNP    = sc(txt, 'XNP\s*=\s*([\d.]+)');
    aero.XCP    = sc(txt, 'XCP\s*=\s*([\d.]+)');

    if ~isnan(aero.CL) && ~isnan(aero.CD) && aero.CD > 0
        aero.LD = aero.CL / aero.CD;
    else
        aero.LD = NaN;
    end

    %% ── Stability derivatives ────────────────────────────────────────────
    aero.CLa = sc(txt, 'CLa\s*=\s*([-\d.]+)');
    aero.Cma = sc(txt, 'Cma\s*=\s*([-\d.]+)');
    aero.Cmq = sc(txt, 'Cmq\s*=\s*([-\d.]+)');
    aero.Cyb = sc(txt, 'CYb\s*=\s*([-\d.]+)');
    aero.Clb = sc(txt, 'Clb\s*=\s*([-\d.]+)');
    aero.Cnb = sc(txt, 'Cnb\s*=\s*([-\d.]+)');
    aero.Clp = sc(txt, 'Clp\s*=\s*([-\d.]+)');
    aero.Cnr = sc(txt, 'Cnr\s*=\s*([-\d.]+)');

    %% ── Flight modes ─────────────────────────────────────────────────────
    % Parse all mode blocks in file order:
    % Longitudinal: ShortPeriod(+), ShortPeriod(-), Phugoid(+), Phugoid(-)
    % Lateral:      Roll, DutchRoll(+), DutchRoll(-), Spiral
    blocks = splitModeBlocks(txt);

    modeNames = {'ShortPeriod','ShortPeriod2','Phugoid','Phugoid2', ...
                 'Roll','DutchRoll','DutchRoll2','Spiral'};

    % Build a blank template so field access is always safe
    blank = struct('eig',NaN,'sigma',NaN,'omega',NaN, ...
                   'wn',NaN,'wd',NaN,'zeta',NaN,'stable',false,'t2',Inf);
    for k = 1:numel(modeNames)
        rawModes.(modeNames{k}) = blank;
    end

    for k = 1:min(numel(blocks), numel(modeNames))
        rawModes.(modeNames{k}) = parseModeBlock(blocks{k});
    end

    % Keep one representative per physical mode (positive-imaginary conjugate)
    aero.modes.ShortPeriod = rawModes.ShortPeriod;
    aero.modes.Phugoid     = rawModes.Phugoid;
    aero.modes.Roll        = rawModes.Roll;
    aero.modes.DutchRoll   = rawModes.DutchRoll;
    aero.modes.Spiral      = rawModes.Spiral;

    %% ── Geometry + inertia ───────────────────────────────────────────────
    geom      = struct();
    geom.S    = sc(txt, 'Ref\.\s*area\s*=\s*([\d.]+)');
    geom.b    = sc(txt, 'Ref\.\s*span\s*=\s*([\d.]+)');
    geom.c    = sc(txt, 'Ref\.\s*chord\s*=\s*([\d.]+)');
    geom.Xg   = sc(txt, 'CoG\.x\s*=\s*([-\d.]+)');
    geom.Zg   = sc(txt, 'CoG\.z\s*=\s*([-\d.]+)');
    geom.Ixx  = sc(txt, 'Ixx\s*=\s*([\d.]+)');
    geom.Iyy  = sc(txt, 'Iyy\s*=\s*([\d.]+)');
    geom.Izz  = sc(txt, 'Izz\s*=\s*([\d.]+)');
    geom.Ixz  = sc(txt, 'Ixz\s*=\s*([\d.]+)');
    geom.rho  = sc(txt, 'Density\s*=([\d.]+)');
    geom.nu   = sc(txt, 'Viscosity\s*=([\d.eE+-]+)');

    % Derived
    if ~isnan(geom.b) && ~isnan(geom.S) && geom.S > 0
        geom.AR = geom.b^2 / geom.S;
    else
        geom.AR = NaN;
    end

    if ~isnan(aero.XNP) && ~isnan(geom.Xg) && ~isnan(geom.c) && geom.c > 0
        geom.SM = (aero.XNP - geom.Xg) / geom.c;
    else
        geom.SM = NaN;
    end
end


%% =========================================================================
%  MODE BLOCK SPLITTER — line-by-line, no lookahead
%  Collects lines from each "Eigenvalue =" until the next one or end of
%  the main mode section (stops before Phillips analytical lines).
%% =========================================================================
function blocks = splitModeBlocks(txt)
    lines  = strsplit(txt, '\n');
    blocks = {};
    current = {};
    inPhillips = false;

    for i = 1:numel(lines)
        ln = lines{i};

        % Stop collecting once we hit Phillips approximations
        if contains(ln, 'Phillips')
            inPhillips = true;
        end
        if inPhillips
            continue
        end

        % New eigenvalue line starts a fresh block
        if ~isempty(regexp(ln, 'Eigenvalue\s*=', 'once'))
            if ~isempty(current)
                blocks{end+1} = strjoin(current, '\n'); %#ok<AGROW>
            end
            current = {ln};
        elseif ~isempty(current)
            current{end+1} = ln; %#ok<AGROW>
        end
    end

    % Flush last block
    if ~isempty(current)
        blocks{end+1} = strjoin(current, '\n');
    end
end


%% =========================================================================
%  SINGLE MODE BLOCK PARSER
%% =========================================================================
function m = parseModeBlock(blk)
    m = struct('eig', NaN, 'sigma', NaN, 'omega', NaN, ...
               'wn', NaN, 'wd', NaN, 'zeta', NaN, ...
               'stable', false, 't2', Inf);

    % Eigenvalue line: "  Eigenvalue    =   -8.23210-  12.13015i"
    % Real and imaginary parts may be separated by sign with optional spaces
    tok = regexp(blk, 'Eigenvalue\s*=\s*([-\d.]+)\s*([-+]\s*[\d.]+)i', 'tokens', 'once');
    if ~isempty(tok)
        re = str2double(strtrim(tok{1}));
        im = str2double(strrep(strtrim(tok{2}), ' ', ''));
        m.eig   = complex(re, im);
        m.sigma = re;
        m.omega = im;
    end

    % Explicitly stated metrics (more reliable than recomputing)
    m.wn   = sc(blk, 'Undamped Natural Frequency\s*=\s*([\d.]+)');
    m.wd   = sc(blk, 'Damped Natural Frequency\s*=\s*([\d.]+)');
    m.zeta = sc(blk, 'Damping Ratio\s*=\s*([\d.]+)');

    m.stable = (m.sigma < 0);

    if ~m.stable && m.sigma > 0
        m.t2 = log(2) / m.sigma;   % time to double amplitude
    end
end


%% =========================================================================
%  HELPER: scalar extract
%% =========================================================================
function val = sc(txt, pattern)
    tok = regexp(txt, pattern, 'tokens', 'once');
    if ~isempty(tok), val = str2double(tok{1});
    else,             val = NaN;
    end
end