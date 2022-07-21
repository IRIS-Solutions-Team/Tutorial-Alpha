%% Create HTML data report


%% Clear workspace

close all
clear
iris.required(20220720)


%% Read input data

dm = databank.fromCSV('data/dataMonthly.csv');
dq = databank.fromCSV('data/hpFilter.csv');


%% Define auxiliary functions

% Print last observation of a time series as a string
printEnd = @(x) toDefaultString(getEnd(x));


%% Create report object

report = rephrase.Report( ...
    "Country Name" ...
    , "Subtitle", "Data Screening Report" ...
    , "Footer", "Disclaimer" ...
);

% Add section 
report + rephrase.Section('General Overview'); 

 % Add page break (only matters for PDF printout of the report)
report + rephrase.Pagebreak( );

% Create line charts
grid1 = rephrase.Grid("", 2, 2, "pass", {"showLegend", false, "dateFormat", "YY-QQ"});

    chart1 = ...
        rephrase.Chart("Policy Rate % PA, last obs: " + printEnd(dm.ir_ib), mm(2012,01):getEnd(dm.ir_ib)) ...
        + rephrase.Series("", dm.ir_ib);

    chart2 = ...
        rephrase.Chart("Nominal Exchange Rate EGP per USD, last obs: " + printEnd(dm.egp_usd), mm(2017,01):getEnd(dm.egp_usd)) ...
       + rephrase.Series("", dm.egp_usd);

    chart3 = ...
        rephrase.Chart("CPI Inflation (percent YoY), last obs: " + printEnd(dm.cpi_18_u), mm(2019,01):getEnd(dm.cpi_18_u)) ...
        + rephrase.Series("", pct(dm.cpi_18_u, -12));

    chart4 = ...
        rephrase.Chart("GDP growth (percent YoY), last obs: " + printEnd(dq.y), qq(2010,1):getEnd(dq.y)) ...
        + rephrase.Series("", pct(dq.y, -4));

% Add charts to grid
grid1 + chart1 + chart2 + chart3 + chart4;

% Add grid of charts to report
report + grid1;

% Add page break (only matters for PDF printout of the report)
report + rephrase.Pagebreak();

% Create table
tableRange = qq(2021,1):qq(2022,1);
table1 = rephrase.Table("Output growth decomposition", tableRange, "dateFormat", "YYYY-\QQ", "numDecimals", 2);

table1 ...
    + rephrase.Heading("Growth rate Q/Q PA") ...
    + rephrase.Series("Output gap", 4*diff(dq.l_y_gap)) ...
    + rephrase.Series("Output trend", 4*diff(dq.l_y_tnd)) ...
    + rephrase.Series("Output level", 4*diff(dq.l_y));

% Add table to report
report + table1;

% Show structure of the report
show(report)


% Buld report as an HTML file
build( ...
    report, "reports/screeningReport", [] ...
    , "source", ["web", "bundle"] ...
);

