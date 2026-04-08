function Rb = batteryResistance(cap_battery)
    % Takes battery capacity in Ah and estimates internal resistance
    % NOTE: only valid for one cell. DBF typically uses 6s batteries

    Rb = 0.013 / cap_battery;
end

% Code used to help with plotting
    % mAh = [150, 300, 450, 850, 1200, 1600, 1800, 2200, 2500, 2700, 3000, 3300, 3700, 4000, 4200, 4500, 5000];
    % Rb = [0.0867, 0.0433, 0.0289, 0.0153, 0.0108, 0.0081, 0.0072, 0.0059, 0.0052, 0.0048, 0.0043, 0.0039, 0.0035, 0.0033, 0.0031, 0.0029, 0.0026];
    % x = linspace(min(mAh), max(mAh));
    % figure;
    % hold on;
    % plot(x, 13.0 ./ x, LineWidth=1.5);
    % scatter(mAh, Rb, 36, "filled");
    % hold off;
    % xlabel("Capacity (mAh)");
    % ylabel("Resistance (Ohms)");
    % title("Resistance of 80/120C Batteries");
    % grid on;
    % legend(["Curve Fit (13/x)", "Collected eCalc Data"]);


% Values found by hand for eCalc for 80/120C LiPo
% mAh    Rb        g
% 150    0.0867    5
% 300    0.0433    9
% 450    0.0289    13
% 850    0.0153    25
% 1200   0.0108    35
% 1600   0.0081    46
% 1800   0.0072    52
% 2200   0.0059    63
% 2500   0.0052    72
% 2700   0.0048    77
% 3000   0.0043    86
% 3300   0.0039    94
% 3700   0.0035    106
% 4000   0.0033    114
% 4200   0.0031    120
% 4500   0.0029    128
% 5000   0.0026    143