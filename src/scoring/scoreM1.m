function [m1_score] = scoreM1(t_lap)
    % Finds M1 score
    % -----------------------
    % t_lap: time to fly one lap (sec)
    % -----------------------

    t_mission = t_lap * 3;
    m1_score = 0;
    if t_mission < 300
        % Mission successful -- can fly three laps
        m1_score = 1;
    end
end