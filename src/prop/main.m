function main()
    disp_res = false;
    prop_data = getPropData("prop_data_library.mat");
    V_nom = 22.2;
    cap_battery = 4.2;
    use = 0.85;
    Kv = 520;
    I0 = 1.4;
    Rm = 0.016;
    % throttle = 1.0;
    prop_id = 62;

    [thrusts, ~, ~, ~, throttles] = eCalcMain(V_nom, cap_battery, use, Kv, I0, Rm, prop_id, prop_data);
    thrusts = thrusts .* 101.97162; % N to g conversion
    throttles = throttles .* 100; % Converting to 100% scale

    T = table(throttles(:), thrusts(:), 'VariableNames', {'Throttle (%)', 'Thrust (g)'});
    disp(T)

    if disp_res
        figure;
        title("Thrust vs Throttle");
        scatter(throttles, thrusts);
        xlabel("Throttle (%)");
        ylabel("Thrust (g)");
        grid on;
    end


    % [thrusts_fit, t_flights_fit, powers_fit, currents_fit, ~] = propMain(V_nom, cap_battery, use, Kv, I0, Rm, throttle, prop_id, prop_data);

    % x = linspace(0, 30, 300).';       % column vector
    % 
    % % Ensure coeffs are in a shape polyval accepts (row or column both fine)
    % % thrusts, t_flights, powers, currents are each [a b c]
    % y_thrust   = polyval(thrusts_fit,   x);
    % y_t_flight  = polyval(t_flights_fit, x);
    % y_power    = polyval(powers_fit,    x);
    % y_current  = polyval(currents_fit,  x);
    % 
    % figure;
    % 
    % subplot(2, 2, 1);
    % plot(x, y_thrust);
    % title("Thrust");
    % 
    % subplot(2, 2, 2);
    % plot(x, y_t_flight);
    % title("Flight");
    % 
    % subplot(2, 2, 3);
    % plot(x, y_power);
    % title("Power");
    % 
    % subplot(2, 2, 4);
    % plot(x, y_current);
    % title("Current");    
end