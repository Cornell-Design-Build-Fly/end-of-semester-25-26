function [thrusts, t_flights, powers, currents, throttles] = eCalcMain(V_nom, cap_battery, use, Kv, I0, Rm, prop_id, prop_data_library)

    % propMain - Evaluates thrust and flight time vs throttle for a prop config

    Rb = batteryResistance(cap_battery);
    ms_to_mph = 2.2369;
    cap_battery = cap_battery * use;

    % Load propeller aero interpolants
    [F_thrust, F_torque] = getInterpolants(prop_id, prop_data_library);

    % --- Sweep over throttle instead of velocity ---
    throttles = linspace(0, 1, 21);     % 0%, 5%, 10%, ..., 100%
    thrusts   = zeros(size(throttles));
    t_flights = zeros(size(throttles));
    powers    = zeros(size(throttles));
    currents  = zeros(size(throttles));

    % Choose a velocity at which to evaluate thrust
    vel_mph = 0.0001 * ms_to_mph;   % static thrust (change if needed)

    for i = 1:length(throttles)
        thr = throttles(i);

        % Compute performance at this throttle setting
        [T, t_flight, P, I] = propSim(vel_mph, cap_battery, V_nom, Rb, Kv, I0, Rm, thr, F_thrust, F_torque);

        thrusts(i)   = T;
        t_flights(i) = t_flight;
        powers(i)    = P;
        currents(i)  = I;
    end
end