%% Get information about the model


%% Clear workspace and load model

close all
clear
iris.required(20220720)
%#ok<*SUSENS> 

load mat/readModel.mat m


%% Names of variables, shocks, parameters

disp("List of transition variables")
access(m, "transition-variables")'
% ...or simply m{"transition-variables"}'


disp("List of measurement variables")
access(m, "measurement-variables")'
% ...or simply m{"measurement-variables"}'


disp("List of transition shocks")
access(m, "transition-shocks")'
% ...or simply m{"transition-shocks"}'

disp("List of measurement shocks")
access(m, "measurement-shocks")'
% ...or simply m{"measurement-shocks"}'

disp("List of parameters")
access(m, "parameters")'
% ...or simply m{"parameters"}'


%% Descriptions of variables, shocks, parameters

disp("Struct with descriptions of variables, shocks and parameters")
access(m, "names-descriptions")
% ...or simply m{"names-descriptions"}


%% Equations and their descriptions

disp("All equations")
access(m, "equations")'

[m{"equations-descriptions"}', m{"equation"}']

disp("Transition equations")
access(m, "transition-equations")'

disp("Measurement equations")
access(m, "measurement-equations")'


%% Steady-state values, parameter values, std values

disp("Steady state")
access(m, "steady")
access(m, "steady-level")
access(m, "steady-change")

disp("Parameter values")
access(m, "parameter-values")

disp("Std values")
access(m, "std-values")

