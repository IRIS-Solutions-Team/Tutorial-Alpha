%% Prepare data for Kalman filtering

%% Clear workspace

close all
clear
iris.required(20220720)


%% Load CSV data files as databank

dm = databank.fromCSV('data/dataMonthly.csv');
dq = databank.fromCSV('data/dataQuarterly.csv');


%% Eyeball the datbank, basic operations with time series

% Get basic info about variables in the database (size and class of variables, ranges)
disp("Monthly databank")
databank.list(dm)

disp("Quarterly databank")
databank.list(dq)

% Get list of seasonally unadjusted series (with suffix _u)
databank.filterFields(dm, "name", @(n) endsWith(n, "_u"))

% Seasonally adjust CPI
dm.cpi_10 = x13.season(dm.cpi_10_u);

% Seasonally adjust all *_u series
func = @x13.season;
[dm, listAdjusted] = databank.apply(dm, func, "endsWith", "_u", "removeEnd", true);

% Convert a series to quarterly frequency
dq.oil = convert(dm.oil, Frequency.QUARTERLY, "method", @mean);

% Convert all monthly series to quartely frequency, and add them to the
% quarterly databank
func = @(x) convert(x, Frequency.QUARTERLY, "method", @mean);
dq = databank.apply(func, dm, "targetDb", dq);

% Quick exploration of full databank in a chart
ch1 = databank.Chartpack();
ch1.Range = qq(2005,1):qq(2022,1);
ch1 + databank.fieldNames(dq);
draw(ch1, dq);

% Plot of selected variables
ch2 = databank.Chartpack();
ch2.Range = mm(2010,1):mm(2022,1);
ch2.Autocaption = true;
ch2 + ["oil", "ir_ib", "egp_usd"];
draw(ch2, dm);


%% Dates and ranges

% get the time range of the variable (first and last date)
range = getRange(dq.oil);
startDate = getStart(dq.oil);
endDate = getEnd(dq.oil);


% clip the quartely database from (to) some date
dqClip1   = databank.clip(dq, qq(2010,1), Inf);
dqClip2  = databank.clip(dq,-Inf, qq(2020,4));

% merge original and clipped database
dqMerged = databank.merge("horzcat", dq, dqClip1);
dqMerged.gdp_us


%% Prepare model consistent databank

h = struct();
h.y = dq.gdp_us;
h.cpi = dq.cpi_us;
h.i = dq.i_us;
h.l_y = 100*log(h.y);
h.l_cpi = 100*log(h.cpi);
h.dl_cpi = 4*diff(h.l_cpi);

databank.list(h)


%% Save model consistent databank to CSV file

databank.toCSV(h, "data/preprocessedData.csv", "format", "%.16g");

