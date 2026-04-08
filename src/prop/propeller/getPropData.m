function [prop_data_library] = getPropData(mat_file)
    % Retrives APC electric propeller performance data from mat file in
    % prop/indexed_prop_data.mat
    % Outputs
    %   prop_data_library: one file which contains prop .manifest and
    %   .data, which contain the 
    
    if ~exist(mat_file, 'file')
        error("Indexed MAT file not found: %s.", mat_file);
    end
    
    loaded_data = load(mat_file);

    % Two datasets are loaded -- the performance data and the manifest
    prop_data_library = loaded_data.prop_data_library;
end
