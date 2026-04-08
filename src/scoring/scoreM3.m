function [m3_score] = scoreM3(s_wing, t_lap_m3, l_banner, best_t_lap_m3, best_l_banner)
    % Finds M3 score
    % -----------------------
    % s_wing: wing span (in)
    % t_lap_m3: time for one lap (sec) 
    % l_banner: banner length (in) 
    % best_t_lap_m3: best time for one lap (sec) 
    % best_l_banner: best banner length (in)
    % -----------------------
    
    RAC = 0.05 * s_wing + 0.75;
    best_RAC = 0.90;

    num_laps = floor(300 / t_lap_m3);
    best_num_laps = floor(300 / best_t_lap_m3);

    m3_score = 2 + ((num_laps * l_banner / RAC)/ (best_num_laps * best_l_banner / best_RAC));
    
end