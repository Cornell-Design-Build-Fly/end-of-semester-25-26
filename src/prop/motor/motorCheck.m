function [pass, throttle, t_flight, P, I] = motorCheck(torque, V_nom, cap_battery, Rb, RPM, Kv, I0, Rm)
    % Checks if electronics can sustain propeller at RPM and throttle level
    % --- Inputs ---
    % Torque: the torque caused by drag acting on the propeller (Nm)
    % Motor and battery parameters derived earlier
    % RPM: revolutions per minute
    %
    % --- Outputs ---
    % pass: whether or not the current torque & rpm are sustainable (boolean)
    % throttle: throttle level achieved at this RPM and torque (0-->1)
    % t_flight: lifetime of battery under current load (s)
    % P: power of motor required at given load (W)
    
    % Instanting variables
    pass = true;
    Kt = 60.0 / (Kv * 2 * pi); % Motor torque constant Nm/A
    % E_battery = cap_battery * V_nom; % Battery energy in Watt-hours (assuming cap_battery in Amp-hours)

    % Current needed to sustain torque
    I = (torque / Kt) + I0;

    % Voltage drop in battery under load
    V_sag = V_nom - I * (Rb * V_nom / 3.7);

    % Voltage required due to EMF
    V_req = RPM / Kv + I * Rm;

    % Electrical power drawn from the battery
    P = I * V_sag;

    % Battery flight time calculation
    if I <= 1e-6 % Avoid division by zero or very small power; use a small threshold
        t_flight = inf; % Effectively infinite time if no significant power drawn
    else
        % E_battery is in Wh. P is in W. (Wh / W) = hours.
        % Convert hours to seconds by multiplying by 3600.
        t_flight = cap_battery / I * 3600.0; 
    end

    % Throttle Required
    if V_sag <= 1e-6 % Avoid division by zero or negative V_sag
        throttle = inf; % Effectively infinite throttle required if V_sag is non-positive
    else
        throttle = V_req / V_sag;
    end
    
    % --- Start of Failure conditions ---

    % Motor Power Limit Check
    % Motor Power will later set all values to zero if overshot
    % if P > P_max
    %     % fprintf('MOTOR CHECK FAIL: Power overload. RPM: %.0f, P_electrical: %.2f W > P_max_motor: %.2f W\n', RPM, P, P_max);
    %     pass = false;
    % end

    % Voltage Required vs Nominal Voltage
    if V_req > V_nom
        % fprintf('MOTOR CHECK FAIL: Insufficient nominal voltage. RPM: %.0f, V_req: %.2f V > V_nom: %.2f V\n', RPM, V_req, V_nom);
        pass = false;
        return;
    end

    % Throttle Limit Check (This is often the key RPM limiting factor)
    if throttle > 1.0
        % fprintf('MOTOR CHECK FAIL: Throttle overload. RPM: %.0f, Throttle: %.3f > 1. (V_req: %.2f V, V_sag: %.2f V, I: %.2f A)\n', RPM, throttle, V_req, V_sag, I);
        pass = false;
        return;
    end
    
    % Check for V_sag becoming non-positive (battery completely depleted or calculation issue)
    if V_sag <= 0
        % fprintf('MOTOR CHECK FAIL: Battery voltage sagged too low. RPM: %.0f, V_sag: %.2f V, I: %.2f A\n', RPM, V_sag, I);
        pass = false;
        return;
    end
end