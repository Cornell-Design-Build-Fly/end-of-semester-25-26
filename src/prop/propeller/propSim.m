function [max_thrust, max_t_flight, max_P, max_I] = propSim(V_mph, cap_battery, V_nom, Rb, Kv, I0, Rm, cruise_throttle, F_thrust, F_torque)
    % Finds the RPM at which max thrust and corresponding flight time created 
    % without crossing motor limits nor throttle values.
    % Input:
    %   V_mph: velocity in mph
    %   Motor parameters
    %   F_thrust and F_torque: thrust and torque interpolation functions
    % Outputs:
    %   max_thrust: max thrust (N)
    %   max_t_flight: best battery life flight time (s)
    

    % --- Parameter Setup ---
    max_RPM = 16000;
    min_RPM = 3000;
    RPM_step = 100;

    max_thrust = intmin;
    max_t_flight = intmax;
    max_P = intmin;
    max_I = intmin;

    RPM_low = min_RPM;
    RPM_high = max_RPM;

    % fprintf('[cruiseValues] Starting RPM search for %s at V = %.2f m/s\n', prop_key, V);

    while (RPM_high - RPM_low) >= RPM_step
        RPM_mid = round((RPM_low + RPM_high) / 2);
        thrust = F_thrust(V_mph, RPM_mid);
        torque = F_torque(V_mph, RPM_mid);

        if isnan(thrust) || isnan(torque)
            % fprintf('[RPM %d] NaN output from simProp. Skipping...\n', RPM_mid);
            RPM_low = RPM_mid + 1;
            continue;
        end

        [pass, throttle, t_flight, P, I] = motorCheck(torque, V_nom, cap_battery, Rb, RPM_mid, Kv, I0, Rm);

        % fprintf('  [RPM %d %.0f mph] Thrust: %.2f N | Torque: %.3f Nm | Throttle: %.3f | Power: %.1f W | Pass: %d\n', RPM_mid, V_mph, thrust, torque, throttle, P, pass);

        if pass
            if throttle <= cruise_throttle
                % fprintf('    ✓ Throttle within cruise limit (%.3f). Saving point.\n', cruise_throttle);
                if thrust > max_thrust
                    max_thrust = thrust;
                    max_t_flight = t_flight;
                    max_P = P;
                    max_I = I;
                end
                RPM_low = RPM_mid + 1;  % Try for higher-thrust solution
            else
                % fprintf('    ✗ Throttle too high (%.3f > %.3f). Trying lower RPM.\n', throttle, cruise_throttle);
                RPM_high = RPM_mid - 1;
            end
        else
            % fprintf('    ✗ Motor check failed (P > P_max or other constraint). Trying lower RPMs.\n');
            RPM_high = RPM_mid - 1;
        end
    end

    if max_thrust == intmin
        % fprintf('[Failure] No valid cruise point found at V = %.2f for %dx%d\n', V, prop_D, prop_pitch);
        max_thrust = 0;
        max_t_flight = 0;
        max_P = 0;
        max_I = 0;
    else
        % fprintf('[Success] Final cruise thrust: %.2f N | Flight Time: %.1f s | RPM: %.1f | Vel: %.1f m/s\n', maxThrust, max_t_flight, RPM_);
    end
end


