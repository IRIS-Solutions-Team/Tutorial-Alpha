%% Using Kalman filter 
%
% * Taking model to data 
% * Resimulation history
% * Contribution of shocks
%


%% Clear workspace and load model

close all
clear
iris.required(20220720)

load mat/readModel.mat m


%% Create databank with measurement variables

h = databank.fromCSV("data/preprocessedData.csv");

% Rename xxx -> obs_xxx
names = ["l_y", "dl_cpi", "i"];
d = databank.copy(h, "sourceNames", names, "targetNames", "obs_"+names);
databank.list(d)


%% Run Kalman filter
%
% The output data struct returned from the Kalman filter, `f`, consist by
% default of three sub-databases returned by the smoother (i.e. two-sided
% filtering):
%
% * `.Mean` with point estimates of all model variables
% * `.Std` with std dev of those estimates
% * `.MSE` with the MSE matrix for backward-looking transition variables.
%
% Use the options `Output`, `MeanOnly`, `ReturnStd` and
% `ReturnMse` to control what is returned in the output data struct.
%

% Set the filtering range
startHist = qq(2008,1);
endHist = qq(2022,1);

% Run the Kalman filter and get the two-sided results returned (smoother)
f = kalmanFilter(m, d, startHist:endHist);
disp(f)

% Extract the databank with point estimates (means)
d = f.Mean;

ch = databank.Chartpack(); 
ch + ["l_y_gap", "dl_cpi", "i", "r_gap"];
ch < ["[l_y l_y_tnd]", "[dl_cpi ss_target]", "[r r_tnd]"];
draw(ch, d); 


%% Plot estimated shocks
%
% The measurement shocks are kept turned off in our exercises (i.e. their
% standard errors are zero), and hence their estimates are zero throughout
% the historical sample.

% shocks (lines)
ch = databank.Chartpack();
ch.Range = startHist:endHist;
ch + access(m, "transition-shocks");
draw(ch, d);
visual.heading("Estimates of transition shocks");

% histogram
ch = databank.Chartpack();
ch.PlotFunc = @histogram;
ch.Range = cell.empty(1, 0);
ch + access(m, "transition-shocks");
draw(ch, d);
visual.heading("Histograms of estimated transition shocks");


%% Simulate from historical initial condition

% Set dates for simulation
startFcast = endHist + 1;
endFcast = endHist + 40;

% Simulate from historical initial condition
s = simulate(m, d, startFcast:endFcast, 'prependInput', true);


% Add steady state lines
ss = databank.forModel(m, startFcast-20:endFcast);
s = databank.merge("horzcat", s, ss);

% Create chart
ch = databank.Chartpack();
ch.Range = startFcast-20 : endFcast;
ch.Highlight = startFcast : endFcast;
ch.PlotSettings = {"marker", "s"};
ch < "Output gap // % deviation: l_y_gap ";
ch < "Inflation rate // % Q/Q PA: dl_cpi ";
ch < "Policy rate // % PA: i ";
ch < "Real interest rate gap // PP PA: r_gap ";
draw(ch, s);
visual.heading("Simulation from initial condition");



%% Simulate contributions of shocks
%
% Re-simulate the filtered data with the `Contributions=` option set to
% true. This returns each variable as a multivariate time series with $n+1$
% columns, where $n$ is the number of model shocks. The first $n$ columns
% are contributions of individual shocks (in order of their appearance in
% the `!transition_shocks` declaration block in the model file), the last,
% $n+1$-th column is the contribution of the initial condition and/or the
% deterministic drift.

c = simulate( ...
    m, d, startHist:endHist ...
    , "anticipate", false ...
    , "contributions", true ...
    , "prependInput", true ...
);

c 
c.dl_cpi

% To plot the shock contributions, use the function `barcon( )`. Plot first
% the actual data and the effect of the initial condition and deterministic
% constant (i.e. the last, $n+1$-th column in the database `c`) in the
% upper panel, and then the contributions of individual shocks, i.e. the
% first $n$ columns.
%

figure();
subplot(2, 1, 1);
plot(startHist:endHist, [d.dl_cpi, c.dl_cpi{:, end-1}]);
grid on
title("Inflation, % Q/Q PA");
legend("Actual data", "Steady state + Init Cond", "location", "northWest");

subplot(2, 1, 2);
bar(startHist:endHist, c.dl_cpi{:, 1:end-2}, "stacked"); 
grid on
title("Contributions of shocks");

descriptions = access(m, "shocks-descriptions");
legend(descriptions, "location", "northWest");


%% Plot grouped contributions
%
% Use a `grouping` object to define groups of shocks whose contributions
% will be added together and plotted as one category. Run `eval( )` to
% create a new database with the contributions grouped accordingly.
% Otherwise, the information content of this figure window is the same as
% the previous one.

g = grouping(m, "shock", "includeExtras", true);
g = addgroup(g, "Demand and supply", ["shock_l_y_gap", "shock_dl_cpi"]); 
g = addgroup(g, "Monetary policy", ["shock_i"]);
g = addgroup(g, "Trend", ["shock_dl_y_tnd", "shock_r_tnd", "shock_target"]);

detail(g);

[cg, lg] = eval(g, c); 

figure( );

subplot(2, 1, 1);
plot(startHist:endHist, [d.dl_cpi, c.dl_cpi{:, end-1}]);
grid on
title("Inflation, % Q/Q PA");
legend("Actual data", "Steady state + Init Cond", "location", "northWest");

subplot(2, 1, 2);
bar(cg.dl_cpi{:, 1:end-1}, "stacked");
grid on
title("Contributions of shocks");
legend(lg(:, 1:end-1), "location", "northWest");



%% Saving Kalman filter results

databank.toCSV(d, "data/kalmanFilter.csv", "format", "%.16g");


