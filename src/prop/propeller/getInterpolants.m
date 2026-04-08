function [F_thrust, F_torque] = getInterpolants(prop_id, prop_data_library)
    % Creates interpolation functions using a direct integer index.
    %
    % --- Inputs ---
    % prop_id: The integer index of the propeller (from 1 to N).
    % prop_data_cell: The pre-sorted cell array of propeller data.

    % 2. Access the data directly using the index
    prop_data = prop_data_library.Data(prop_id);

    % Check if there is any data to interpolate
    if isempty(prop_data.V_all)
        warning('No valid data points found for prop_id: %d.', prop_id);
        F_thrust = @(V, RPM) 0;
        F_torque = @(V, RPM) inf;
        return;
    end
    
    % Create interpolants directly from the clean, numeric arrays
    F_thrust = scatteredInterpolant(prop_data.V_all, prop_data.RPM_all, prop_data.Thrust_all, 'linear', 'linear');
    F_torque = scatteredInterpolant(prop_data.V_all, prop_data.RPM_all, prop_data.Torque_all, 'linear', 'linear');
end