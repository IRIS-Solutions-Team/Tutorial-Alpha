%% Simulating NK model 
%
% * Plain vanilla shock simulation
% * Anticipated vs unanticipated future shocks
% * Exogenized variables
% * Conditional variables
% * Multiple parameter variants
% * Permanent shocks
%


%% Clear workspace and load model

clear
close all
iris.required(20220720)
%#ok<*VUNUS> 

load mat/readModel.mat m


%% Simulate output gap shock

% Set dates for simulation
startDate = qq(2022, 1);
endDate = startDate + 40;

% Crete steady state database
d = databank.forModel(m, startDate:endDate);
d.shock_l_y_gap(startDate) = 1;
s = simulate(m, d, startDate:endDate, "prependInput", true);

% Create chartpack
ch = databank.Chartpack();
ch.Range = startDate-1 : endDate;
ch.Round = 8;
ch + "Output gap // % deviation: l_y_gap "; 
ch + "Inflation rate // % Q/Q PA: dl_cpi ";
ch + "Policy rate // % PA: i ";
ch + "Real interest rate gap // PP PA: r_gap ";
draw(ch, s);

visual.heading("Output gap shock");

%% Simulate output gap shock as deviations from steady state

% Set dates for simulation
startDate = qq(2022, 1);
endDate = startDate + 40;

% Crete steady state database
d = databank.forModel(m, startDate:endDate, "deviation", true);
d.shock_l_y_gap(startDate) = 1;
s = simulate( ...
    m, d, startDate:endDate, ...
    "prependInput", true, ...
    "deviation", true ...
);

ch.YLine = 0;
draw(ch, s);
visual.heading("Output gap shock (deviations from steady state)");
ch.YLine = {};

%% Simulate anticipated vs unanticipated shocks

d = databank.forModel(m, startDate-3:startDate);
d.shock_l_y_gap(startDate+3) = 1;

s1 = simulate( ...
    m, d, startDate:endDate, ...
    "anticipate", true, ... % this is the default setting
    "prependInput", true ...
);

s2 = simulate( ...
    m, d, startDate:endDate, ...
    "anticipate", false, ...
    "prependInput", true ...
);

chartDb = databank.merge("horzcat", s1, s2);
draw(ch, chartDb);

visual.heading("Consumption demand shock: Anticipated vs Unanticipated");
visual.hlegend("bottom", "Anticipated", "Unanticipated");


%% Simulate output gap shock with delayed policy reaction (Simulation plan)
%
% Simulate a consumption shock and, at the same time, delay the policy
% reaction (by exogenising the policy rate to its pre-shock level for 3
% periods). This can be done in an anticipated mode and unanticipated mode.

T = 3;
d = databank.forModel(m, startDate-3:startDate);
d.shock_l_y_gap(startDate) = 1;

% Simulate consumption shocks with immediate policy reaction (no Plan)
s1 = simulate( ...
    m, d, startDate:endDate, ... 
    "prependInput", true ...
);

% Create plan, exogenize policy rate and endogenize corresponding shock
p = Plan.forModel(m, startDate:endDate);
p = exogenize(p, startDate:startDate+T-1, "i");
p = endogenize(p, startDate:startDate+T-1, "shock_i");

% ...or simply:
% p = swap(p, startDate:startDate+T-1, ["i", "shock_i"]);

% Set policy rate to the desired value - this is strictly speaking not
% needed here because we simply want to keep it at its steady state, which
% is exactly what we have in the datbank
d.i(startDate:startDate+T-1) = d.i(startDate-1)

% Simulate the same shock with delayed policy reaction that is announced
% and anticipated from the beginning (default option of shocks in plan 
% is anticipate = true)
s2 = simulate( ...
    m, d, startDate:endDate, ...
    "plan", p, ... 
    "prependInput", true ...
);

% Simulate the same shock with delayed policy reaction that takes
% everyone by surprise every quarter (set shocks in plan as unanticipated)
p = Plan.forModel(m, startDate:endDate, "anticipate", false);
p = exogenize(p, startDate:startDate+T-1, "i");
p = endogenize(p, startDate:startDate+T-1, "shock_i");

s3 = simulate( ...
    m, d, startDate:endDate, ...
    "plan", p, ... 
    "prependInput", true ...
);

% Compare results
chartDb = databank.merge("horzcat", s1, s2, s3);
draw(ch, chartDb);
visual.heading("Consumption demand shock with different policy responses and anticipation");
visual.hlegend("bottom", "No delay", "Anticipated", "Unanticipated");


%% Simulate output gap shock with fixed impact
%
% Find the size of a output gap shock such that it results in an 2pp
% increase in inflation in the second period

d = databank.forModel(m, startDate-3:startDate);
d.dl_cpi(startDate+1) = d.dl_cpi(startDate+1) + 2;

p = Plan.forModel(m, startDate:endDate);
p = exogenize(p, startDate+1, "dl_cpi");
p = endogenize(p, startDate, "shock_l_y_gap");

s4 = simulate(...
    m, d, startDate:endDate, ...
    "plan", p, ...
    "prependInput", true ...
);

disp(s4.dl_cpi{startDate-1:startDate+5})

draw(ch, s4);
visual.heading("Output gap shock with fixed impact on inflation");


%% Conditioning with multiple shocks 
% 
% Hard tune on inflation 2.5% in the first period explained by three shocks

d = databank.forModel(m, startDate-3:startDate);
d.dl_cpi(startDate+1) = d.dl_cpi(startDate+1) + 2;

p = Plan.forModel(m, startDate:endDate, "anticipate", true, "method", "condition");
p = exogenize(p, startDate+1, "dl_cpi");
p = endogenize(p, startDate, ["shock_l_y_gap", "shock_dl_cpi", "shock_i"]);

s5 = simulate( ...
    m, d, startDate:endDate ...
    , "plan", p ...
    , "prependInput", true ...
);

disp(s4.dl_cpi{startDate-1:startDate+5})

% Compare shocks from previous and current simulation
disp('Explained by output gap shock');
disp([s4.shock_l_y_gap{startDate} s4.shock_dl_cpi{startDate} s4.shock_i{startDate}]);

disp('Conditioned by multiple shocks');
disp([s5.shock_l_y_gap{startDate} s5.shock_dl_cpi{startDate} s5.shock_i{startDate}]);

draw(ch, s5);
visual.heading("Combination of shocks with fixed impact on inflation");


%% Simulate output gap shock with multiple parameterisations
%
% Within the same model object, expand the number of parameter variants, 
% and assign different sets of values to some (or all) of the parameters
%
% Solve and simulate all parameter variants at once.
% Almost all IrisT model functions support multiple parametert variants.

% Create four alternative model parametrizations
% More hawkish central bank
mm = alter(m, 4);
mm.c2_i = m.c2_i + [1, 2, 3, 4];
mm = solve(mm);
disp(mm);

d = databank.forModel(mm, startDate-3:startDate);
d.shock_l_y_gap(startDate, :) = 1;

s6 = simulate( ...
    mm, d, startDate:endDate, ...
    "prependInput", true ...
);

draw(ch, s6);
visual.heading("Output gap shock with mutliple parameter variants");


%% Simulate disinflation

% Create model with lower inflation target; create initial steady state
% databank for high-inflation model, and then simulate transition to
% low-inflation model

m1 = m;
m1.ss_target = m.ss_target - 1;
m1 = solve(m1);
m1 = steady(m1);
table([m, m1], ["steadyLevel", "description"])

d = steadydb(m, startDate-3:endDate+50);
s = simulate(m1, d, startDate:endDate, "prependInput", true);

% Add sacrifice ratio to chartpack
ch + "Sacrifice ratio: cumsum(l_y_gap)/4";
draw(ch, s);
visual.heading("Disinflation");
ch.Charts(end) = [];
