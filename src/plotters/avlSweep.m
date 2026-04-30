function results = avlSweep()
% avlSweep_designSpace  Full-factorial AVL design-space search for teaching scenarios.
%
%   results = avlSweep_designSpace()
%
%   This replaces the old single-variable sweep workflow with a broad
%   candidate generator. It is meant to find six intentionally flawed but
%   fixable aircraft designs for students.
%
%   EXACT NUMBER OF DESIGN CASES: 48,000
%
%   Design variables swept:
%     wing_AR, dihedral, htail_span, htail_incidence, vtail_height,
%     tail_arm, nose_x, and payload combination.
%
%   Output:
%     - One CSV row per attempted aircraft design.
%     - Includes raw geometry, mass/CG, AVL trim, derivatives, mode data,
%       and simple scenario tags such as pitch_unstable, low_static_margin,
%       weak_directional_stability, spiral_unstable, high_trim, high_drag.
%
%   After this runs, send the CSV back to ChatGPT for interpretation.
global pct_done;
cfg = avlConfig();
V   = 27;                 % [m/s] common trim/eigenmode velocity
rho = 1.225;              % [kg/m^3]
g0  = 9.81;               % [m/s^2]

% -------------------------------------------------------------------------
% Baseline values that are not being swept
% -------------------------------------------------------------------------
base.wing_span       = 1.20;   % [m]
base.htail_AR        = 2.50;   % [-]
base.vtail_AR        = 1.50;   % [-]
base.n_pucks         = 1;      % overwritten by payload set

% -------------------------------------------------------------------------
% Full-factorial design space
% -------------------------------------------------------------------------
wing_AR_vec         = [3.0 3.5 4.0 4.5 5.0];          % 5
dihedral_vec        = [4 5 6 7 8];                    % 5
htail_span_vec      = [0.25 0.30 0.35 0.40 0.45];     % 5
htail_incidence_vec = [-4 -2 0 2];                    % 4
vtail_height_vec    = [0.12 0.16 0.20 0.24];          % 4
tail_arm_vec        = [0.55 0.70 0.85];               % 3
nose_x_vec          = [-0.26 -0.20 -0.14 -0.08];      % 4

% Payload rows are [n_ducks, n_pucks]. These represent common contest-load
% situations rather than every possible count.
payload_set = [
    3, 1;
];

n_cases = numel(wing_AR_vec) * numel(dihedral_vec) * ...
          numel(htail_span_vec) * numel(htail_incidence_vec) * ...
          numel(vtail_height_vec) * numel(tail_arm_vec) * ...
          numel(nose_x_vec) * size(payload_set, 1);

case_num = 0;

fprintf('\n============================================================\n')
fprintf('AVL design-space search\n')
fprintf('Exact number of attempted design cases: %d\n', n_cases)
fprintf('Trim/eigenmode speed: %.2f m/s\n', V)
fprintf('============================================================\n\n')

% -------------------------------------------------------------------------
% Preallocate output columns
% -------------------------------------------------------------------------
design_id = (1:n_cases)';
status_ok = false(n_cases, 1);
error_msg = repmat({''}, n_cases, 1);
scenario_tag = repmat({'failed_run'}, n_cases, 1);

% Design variables
wing_span = nan(n_cases,1); wing_AR = nan(n_cases,1); wing_chord = nan(n_cases,1);
dihedral = nan(n_cases,1); htail_span = nan(n_cases,1); htail_AR = nan(n_cases,1);
htail_incidence = nan(n_cases,1); vtail_height = nan(n_cases,1); vtail_AR = nan(n_cases,1);
tail_arm = nan(n_cases,1); nose_x = nan(n_cases,1); n_ducks = nan(n_cases,1); n_pucks = nan(n_cases,1);

% Mass / geometry outputs
mass_kg = nan(n_cases,1); Sref = nan(n_cases,1); Cref = nan(n_cases,1); Bref = nan(n_cases,1);
CG_x_m = nan(n_cases,1); CG_z_m = nan(n_cases,1); CG_pct = nan(n_cases,1);
Ixx = nan(n_cases,1); Iyy = nan(n_cases,1); Izz = nan(n_cases,1); Ixz = nan(n_cases,1);
Vht = nan(n_cases,1); Vvt = nan(n_cases,1);

% AVL trim / derivative outputs
CL_cruise = nan(n_cases,1); alpha_deg = nan(n_cases,1); elevator_deg = nan(n_cases,1);
CL = nan(n_cases,1); CDtot = nan(n_cases,1); CDi = nan(n_cases,1); span_eff_e = nan(n_cases,1);
Xnp_m = nan(n_cases,1); SM_pct = nan(n_cases,1);
CLa = nan(n_cases,1); Cma = nan(n_cases,1); CYb = nan(n_cases,1); Clb = nan(n_cases,1); Cnb = nan(n_cases,1);
CLq = nan(n_cases,1); Cmq = nan(n_cases,1); CYp = nan(n_cases,1); CYr = nan(n_cases,1);
Clp = nan(n_cases,1); Clr = nan(n_cases,1); Cnp = nan(n_cases,1); Cnr = nan(n_cases,1);
spiral_ratio = nan(n_cases,1);

% Mode outputs
ph_sigma = nan(n_cases,1); ph_omega = nan(n_cases,1); ph_t2 = nan(n_cases,1);
sp_sigma = nan(n_cases,1); sp_omega = nan(n_cases,1); sp_t2 = nan(n_cases,1);
dr_sigma = nan(n_cases,1); dr_omega = nan(n_cases,1); dr_t2 = nan(n_cases,1);
roll_sigma = nan(n_cases,1); roll_omega = nan(n_cases,1); roll_t2 = nan(n_cases,1);
spiral_sigma = nan(n_cases,1); spiral_omega = nan(n_cases,1); spiral_t2 = nan(n_cases,1);

% Boolean teaching flags
flag_pitch_unstable = false(n_cases,1);
flag_low_SM = false(n_cases,1);
flag_high_SM = false(n_cases,1);
flag_high_trim = false(n_cases,1);
flag_directional_unstable = false(n_cases,1);
flag_weak_directional = false(n_cases,1);
flag_bad_dihedral_effect = false(n_cases,1);
flag_spiral_unstable = false(n_cases,1);
flag_dutch_unstable = false(n_cases,1);
flag_high_drag = false(n_cases,1);
flag_slow_or_heavy = false(n_cases,1);
fixability_score = nan(n_cases,1);
badness_score = nan(n_cases,1);

% -------------------------------------------------------------------------
% Main sweep
% -------------------------------------------------------------------------
i = 0;
tic
for ia = 1:numel(wing_AR_vec)
for idh = 1:numel(dihedral_vec)
for ihs = 1:numel(htail_span_vec)
for ihi = 1:numel(htail_incidence_vec)
for iv = 1:numel(vtail_height_vec)
for ita = 1:numel(tail_arm_vec)
for inx = 1:numel(nose_x_vec)
for ip = 1:size(payload_set, 1)
    i = i + 1;

    g = base;
    g.wing_AR         = wing_AR_vec(ia);
    g.dihedral        = dihedral_vec(idh);
    g.htail_span      = htail_span_vec(ihs);
    g.htail_incidence = htail_incidence_vec(ihi);
    g.vtail_height    = vtail_height_vec(iv);
    g.tail_arm        = tail_arm_vec(ita);
    g.nose_x          = nose_x_vec(inx);
    g.n_ducks         = payload_set(ip, 1);
    g.n_pucks         = payload_set(ip, 2);

    % Store design variables before attempting AVL, so failed rows are useful.
    wing_span(i)       = g.wing_span;
    wing_AR(i)         = g.wing_AR;
    wing_chord(i)      = g.wing_span / g.wing_AR;
    dihedral(i)        = g.dihedral;
    htail_span(i)      = g.htail_span;
    htail_AR(i)        = g.htail_AR;
    htail_incidence(i) = g.htail_incidence;
    vtail_height(i)    = g.vtail_height;
    vtail_AR(i)        = g.vtail_AR;
    tail_arm(i)        = g.tail_arm;
    nose_x(i)          = g.nose_x;
    n_ducks(i)         = g.n_ducks;
    n_pucks(i)         = g.n_pucks;

    if mod(i, 250) == 0 || i == 1
        fprintf('  Case %5d / %5d\n', i, n_cases)
    end

    try
        case_num = case_num + 1;
        pct_done = 100 * case_num / n_cases;
        

        mass     = defineMassConfig(g);
        fprintf('Progress: case %d / %d  (%.2f%% done)\n', case_num, n_cases, pct_done);
        aircraft = massToAVL(mass);
        % fprintf('Progress: case %d / %d  (%.2f%% done)\n', case_num, n_cases, pct_done);
        out      = runAVL(aircraft, V);
        % fprintf('Progress: case %d / %d  (%.2f%% done)\n', case_num, n_cases, pct_done);
        avl      = parseAVLOutput(out.stability_file);
        % fprintf('Progress: case %d / %d  (%.2f%% done)\n', case_num, n_cases, pct_done);
        modes    = computeAVLModes(avl, aircraft, V, rho);
        % fprintf('Progress: case %d / %d  (%.2f%% done)\n', case_num, n_cases, pct_done);

        status_ok(i) = true;

        % Geometry and mass outputs
        mass_kg(i) = aircraft.mass;
        Sref(i)    = aircraft.Sref;
        Cref(i)    = aircraft.Cref;
        Bref(i)    = aircraft.Bref;
        CG_x_m(i)  = aircraft.xref;
        CG_z_m(i)  = aircraft.zref;
        CG_pct(i)  = aircraft.xref / aircraft.Cref * 100;
        Ixx(i)     = aircraft.Ixx;
        Iyy(i)     = aircraft.Iyy;
        Izz(i)     = aircraft.Izz;
        Ixz(i)     = aircraft.Ixz;
        Vht(i)     = aircraft.Vht;
        Vvt(i)     = aircraft.Vvt;

        % AVL outputs
        CL_cruise(i)  = out.CL_cruise;
        alpha_deg(i)  = avl.alpha;
        elevator_deg(i) = avl.elevator;
        CL(i)         = avl.CL;
        CDtot(i)      = avl.CDtot;
        CDi(i)        = avl.CDi;
        span_eff_e(i) = avl.e;
        Xnp_m(i)      = avl.Xnp;
        SM_pct(i)     = (avl.Xnp - aircraft.xref) / aircraft.Cref * 100;

        CLa(i) = avl.CLa; Cma(i) = avl.Cma; CYb(i) = avl.CYb; Clb(i) = avl.Clb; Cnb(i) = avl.Cnb;
        CLq(i) = avl.CLq; Cmq(i) = avl.Cmq; CYp(i) = avl.CYp; CYr(i) = avl.CYr;
        Clp(i) = avl.Clp; Clr(i) = avl.Clr; Cnp(i) = avl.Cnp; Cnr(i) = avl.Cnr;
        spiral_ratio(i) = avl.spiral_ratio;

        ph_sigma(i) = modes.Phugoid.sigma; ph_omega(i) = modes.Phugoid.omega; ph_t2(i) = capInf(modes.Phugoid.t2);
        sp_sigma(i) = modes.ShortPeriod.sigma; sp_omega(i) = modes.ShortPeriod.omega; sp_t2(i) = capInf(modes.ShortPeriod.t2);
        dr_sigma(i) = modes.DutchRoll.sigma; dr_omega(i) = modes.DutchRoll.omega; dr_t2(i) = capInf(modes.DutchRoll.t2);
        roll_sigma(i) = modes.Roll.sigma; roll_omega(i) = modes.Roll.omega; roll_t2(i) = capInf(modes.Roll.t2);
        spiral_sigma(i) = modes.Spiral.sigma; spiral_omega(i) = modes.Spiral.omega; spiral_t2(i) = capInf(modes.Spiral.t2);

        % Teaching flags. These thresholds are intentionally broad: the goal
        % is to identify teachable designs, not final certification limits.
        flag_pitch_unstable(i)       = Cma(i) > 0;
        flag_low_SM(i)               = SM_pct(i) < 5;
        flag_high_SM(i)              = SM_pct(i) > 25;
        flag_high_trim(i)            = abs(elevator_deg(i)) > 15;
        flag_directional_unstable(i) = Cnb(i) < 0;
        flag_weak_directional(i)     = Cnb(i) >= 0 && Cnb(i) < 0.02;
        flag_bad_dihedral_effect(i)  = Clb(i) > 0;
        flag_spiral_unstable(i)      = spiral_sigma(i) > 0 || spiral_ratio(i) < 1;
        flag_dutch_unstable(i)       = dr_sigma(i) > 0;
        flag_high_drag(i)            = CDi(i) > 0.080;
        flag_slow_or_heavy(i)        = CL_cruise(i) > 0.90;

        % A soft ranking to help pick examples later.
        badness_score(i) = 0;
        badness_score(i) = badness_score(i) + 3.0 * flag_pitch_unstable(i);
        badness_score(i) = badness_score(i) + 2.0 * flag_low_SM(i);
        badness_score(i) = badness_score(i) + 1.0 * flag_high_SM(i);
        badness_score(i) = badness_score(i) + 1.5 * flag_high_trim(i);
        badness_score(i) = badness_score(i) + 2.5 * flag_directional_unstable(i);
        badness_score(i) = badness_score(i) + 1.0 * flag_weak_directional(i);
        badness_score(i) = badness_score(i) + 1.5 * flag_bad_dihedral_effect(i);
        badness_score(i) = badness_score(i) + 2.0 * flag_spiral_unstable(i);
        badness_score(i) = badness_score(i) + 2.0 * flag_dutch_unstable(i);
        badness_score(i) = badness_score(i) + 1.0 * flag_high_drag(i);
        badness_score(i) = badness_score(i) + 1.0 * flag_slow_or_heavy(i);

        % Fixability prefers cases with one or two clear problems, not total disasters.
        n_flags = flag_pitch_unstable(i) + flag_low_SM(i) + flag_high_SM(i) + ...
                  flag_high_trim(i) + flag_directional_unstable(i) + flag_weak_directional(i) + ...
                  flag_bad_dihedral_effect(i) + flag_spiral_unstable(i) + ...
                  flag_dutch_unstable(i) + flag_high_drag(i) + flag_slow_or_heavy(i);
        fixability_score(i) = badness_score(i) - 0.75 * max(0, n_flags - 2);

        scenario_tag{i} = chooseScenarioTag(flag_pitch_unstable(i), flag_low_SM(i), ...
            flag_high_SM(i), flag_high_trim(i), flag_directional_unstable(i), ...
            flag_weak_directional(i), flag_bad_dihedral_effect(i), ...
            flag_spiral_unstable(i), flag_dutch_unstable(i), ...
            flag_high_drag(i), flag_slow_or_heavy(i));

    catch err
        status_ok(i) = false;
        error_msg{i} = err.message;
        scenario_tag{i} = 'failed_run';
    end
end
end
end
end
end
end
end
end

elapsed_s = toc;
fprintf('\nCompleted %d attempted cases in %.1f seconds.\n', n_cases, elapsed_s)
fprintf('Successful rows: %d\n', nnz(status_ok))
fprintf('Failed rows:     %d\n', nnz(~status_ok))

% -------------------------------------------------------------------------
% Save CSV
% -------------------------------------------------------------------------
results = table(design_id, status_ok, scenario_tag, error_msg, ...
    wing_span, wing_AR, wing_chord, dihedral, htail_span, htail_AR, ...
    htail_incidence, vtail_height, vtail_AR, tail_arm, nose_x, n_ducks, n_pucks, ...
    mass_kg, Sref, Cref, Bref, CG_x_m, CG_z_m, CG_pct, Ixx, Iyy, Izz, Ixz, Vht, Vvt, ...
    CL_cruise, alpha_deg, elevator_deg, CL, CDtot, CDi, span_eff_e, Xnp_m, SM_pct, ...
    CLa, Cma, CYb, Clb, Cnb, CLq, Cmq, CYp, CYr, Clp, Clr, Cnp, Cnr, spiral_ratio, ...
    ph_sigma, ph_omega, ph_t2, sp_sigma, sp_omega, sp_t2, dr_sigma, dr_omega, dr_t2, ...
    roll_sigma, roll_omega, roll_t2, spiral_sigma, spiral_omega, spiral_t2, ...
    flag_pitch_unstable, flag_low_SM, flag_high_SM, flag_high_trim, ...
    flag_directional_unstable, flag_weak_directional, flag_bad_dihedral_effect, ...
    flag_spiral_unstable, flag_dutch_unstable, flag_high_drag, flag_slow_or_heavy, ...
    badness_score, fixability_score);

csv_file = fullfile(cfg.work_dir, sprintf('avlDesignSpace_%s_%d_cases.csv', ...
    datestr(now, 'yyyymmdd_HHMMSS'), n_cases));
writetable(results, csv_file);

fprintf('\nAll results saved to:\n  %s\n', csv_file)
fprintf('Send that CSV back for candidate selection and interpretation.\n')

end

function x = capInf(x)
% Keep CSV numeric and sortable. Stable modes get 9999 instead of Inf.
    if isinf(x)
        x = 9999;
    end
end

function tag = chooseScenarioTag(pitch_unstable, low_SM, high_SM, high_trim, ...
    directional_unstable, weak_directional, bad_dihedral, spiral_unstable, ...
    dutch_unstable, high_drag, slow_or_heavy)

    if pitch_unstable
        tag = 'pitch_unstable_aft_or_weak_tail';
    elseif low_SM
        tag = 'low_static_margin';
    elseif high_trim
        tag = 'excessive_trim_required';
    elseif directional_unstable || weak_directional
        tag = 'weak_directional_stability';
    elseif bad_dihedral
        tag = 'wrong_dihedral_effect';
    elseif dutch_unstable
        tag = 'dutch_roll_unstable';
    elseif spiral_unstable
        tag = 'spiral_unstable';
    elseif high_SM
        tag = 'overstable_forward_cg';
    elseif high_drag
        tag = 'high_induced_drag';
    elseif slow_or_heavy
        tag = 'high_required_lift';
    else
        tag = 'mostly_ok_baseline_candidate';
    end
end
