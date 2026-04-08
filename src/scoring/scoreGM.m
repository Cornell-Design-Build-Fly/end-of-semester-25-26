function [gm_score] = scoreGM(num_pass, t_pass, num_cargo, t_cargo, t_banner, best_t_mission)
    % Finds GM score
    % -----------------------
    % num_pass: number of passenger duckies installed on plane
    % t_pass: estimated time to install each passenger (sec)
    % num_cargo: number of cargo pucks installed
    % t_cargo: estimated time to install each cargo (sec)
    % t_banner: estimated time to install banner (sec)
    % -----------------------
    
    t_mission = 2* (num_pass * t_pass + num_cargo * t_cargo) + t_banner;
    gm_score = best_t_mission / t_mission;
end