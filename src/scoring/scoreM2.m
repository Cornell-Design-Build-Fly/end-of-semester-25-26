function [m2_score] = scoreM2(num_pass, num_cargo, t_lap_m2, cap_battery, V_nom, best_profit)
    % Finds M2 score
    % -----------------------
    % num_pass: number of passenger duckies installed on plane
    % num_cargo: number of cargo pucks installed
    % t_lap_m2: time to complete one lap (sec)
    % cap_battery: battery capacity (Ah)
    % V_nom: nominal battery voltage (V)
    % best_profit: estimated best profit
    % -----------------------

    num_laps = floor(300 / t_lap_m2);
    
    income_pass = num_pass * (6 + (2 * num_laps));
    income_cargo = num_cargo * (10 + (8 * num_laps));

    efficiency_factor = (cap_battery * V_nom) / 100;
    cost = num_laps * (10 + (num_pass * 0.5) + (num_cargo * 2)) * efficiency_factor;

    profit = (income_pass + income_cargo) - cost;

    m2_score = 1 + (profit / best_profit);
end