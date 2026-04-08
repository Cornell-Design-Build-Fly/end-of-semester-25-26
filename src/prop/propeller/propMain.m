function [thrusts_fit, t_flights_fit, powers_fit, currents_fit, velocities] = propMain(V_nom, cap_battery, use, Kv, I0, Rm, throttle, prop_id, prop_data_library)
    % propMain - Evaluates thrust and flight time vs velocity for a prop config
    %
    % Inputs:
    %   x: design vector
    %   prop_data: .mat organized array containing all data for APC props
    %
    % Outputs:
    %   thrusts, 
    %   t_flights, 
    %   powers, 
    %   currents
    %   velocities
    
    Rb = batteryResistance(cap_battery);        % Battery resistance
    ms_to_mph = 2.2369;
    cap_battery = cap_battery * use;

    % --- Load propeller data functions once ---
    [F_thrust, F_torque] = getInterpolants(prop_id, prop_data_library);

    % --- Run sweep over velocity ---
    velocities = linspace(0.001, 25, 8);
    thrusts = zeros(1, length(velocities));
    t_flights = zeros(1, length(velocities));
    powers = zeros(1, length(velocities));
    currents = zeros(1, length(velocities));

    for i = 1:length(velocities)
        % thrust and torque functions are in MPH for velocities
        vel_mph = velocities(i) * ms_to_mph;
        
        % Calculating values
        [thrust, t_flight, power, current] = propSim(vel_mph, cap_battery, V_nom, Rb, Kv, I0, Rm, throttle, F_thrust, F_torque);
    
        % Saving
        thrusts(i) = thrust;
        t_flights(i) = t_flight;
        powers(i) = power;
        currents(i) = current;
    end

    thrusts_fit = polyfit(velocities, thrusts, 2);
    t_flights_fit = polyfit(velocities, t_flights, 2);
    powers_fit = polyfit(velocities, powers, 2);
    currents_fit = polyfit(velocities, currents, 2);
end