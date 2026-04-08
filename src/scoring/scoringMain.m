function [total_score, score_breakdown] = scoringMain(x, p, t_lap_m1, t_lap_m2, t_lap_m3)
% Calculates total competition score for DBF
%
% Inputs
%   x           : design vector
%   p           : parameter vector (e.g., battery V in p(22))
%   t_lap_m1    : single-lap time for Mission 1 (s)
%   t_lap_m2    : single-lap time for Mission 2 (s)
%   t_lap_m3    : single-lap time for Mission 3 (banner) (s)
%
% Outputs
%   total_score     : scalar total
%   score_breakdown : [GM, M1, M2, M3]

    % -------------------------
    % Pull design / params used by scorers
    % -------------------------
    b_wing    = x(1) * 3.28;      % wingspan [m] * 3.28ft/m
    cap_battery = x(20);
    num_pass    = x(30);
    num_cargo   = x(31);
    l_banner = x(29);     % banner length [in]
    V_nom       = p(22);

    % -------------------------
    % Scoring constants (match your previous values)
    % -------------------------
    % Ground mission
    t_pass         = 2.5;      % s per passenger placement
    t_cargo        = 1.5;      % s per cargo placement
    t_banner       = 7;      % s banner attach/detach
    best_t_mission = 18;     % s reference time

    % Mission 2
    best_profit = 1800;      % reference profit

    % Mission 3 (reference values to compare against)
    best_t_lap_m3  = 55;   % s
    best_l_banner = 300;   % in

    % -------------------------
    % Compute GM, M1, M2 in order, with gating
    % -------------------------
    gm_score = scoreGM(num_pass, t_pass, num_cargo, t_cargo, t_banner, best_t_mission);
    m1_score = scoreM1(t_lap_m1);

    m2_score = 0;
    m3_score = 0;

    if m1_score > 0
        m2_score = scoreM2(num_pass, num_cargo, t_lap_m2, cap_battery, V_nom, best_profit);

        if m2_score > 0
            % --- Mission 3: pass current design + reference values ---
            m3_score = scoreM3(b_wing, t_lap_m3, l_banner, best_t_lap_m3, best_l_banner);
        end
    end

    % -------------------------
    % Aggregate
    % -------------------------
    score_breakdown = [gm_score, m1_score, m2_score, m3_score];
    total_score     = gm_score + m1_score + m2_score + m3_score;
end
