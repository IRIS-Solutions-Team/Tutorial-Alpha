%% Loading and solving NK model


%% Clear workspace

close all
clear
iris.required(20220720)


%% Create a model object from a model file
%
% Mark the model as linear; in linear models, the first-order approximation is
% independent of the steady state, and can be calculated without or before
% the steady state is known.
%

m = Model.fromFile("model-source/linearNK.model", "linear", true);


%% Set parameters

% Steady state parameters
m.ss_target = 2;
m.ss_r_tnd = 0.5;
m.ss_dl_y_tnd = 2;

% Dynamic parameters
m.c1_dl_cpi = 0.65;
m.c2_dl_cpi = 0.10;
m.c1_l_y_gap = 0.6;
m.c2_l_y_gap = 0.1;
m.c1_i = 0.75;
m.c2_i = 3.5;
m.c3_i = 0.1;
m.c1_dl_y_tnd = 0.9;
m.c1_r_tnd = 0.9;
m.c1_target = 0.9;

% Standard deviations of the shocks
m.std_shock_l_y_gap = 0.7;
m.std_shock_dl_cpi = 1.5;
m.std_shock_i = 1;
m.std_shock_dl_y_tnd = 0.2;
m.std_shock_r_tnd = 0.2;
m.std_shock_target = 0.2;


%% Alernative way of setting parameters

% From a struct: the struct may also contain names that are not recognized
% by the model; these names will be simply ignored
p = struct();
p.ss_target = 2.5;
p.ss_r_tnd = 0.5;
p.ss_dl_y_tnd = 2;
p.invalid_name = 1000;

m = assign(m, p);


%% Solve the model and calculate steady state 

m = solve(m);
m = steady(m);


%% Show steady state table

t = table(m, ["steadyLevel", "steadyChange", "description"], "round", 8)


%% Save model to a mat file for further use

save mat/readModel.mat m


