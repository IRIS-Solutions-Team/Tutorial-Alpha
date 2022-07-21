%% Hodrick-Prescott filter


%% Clear workspace

close all
clear
iris.required(20220720)


%% Load historical data

db = databank.fromCSV("data/preprocessedData.csv");
filterRange = getRange(db.l_y);


%% HP filter with different types of assumptions

% Plain vanilla, default lambda for quarterly == 1,600

[db.l_y_tnd, db.l_y_gap] = hpf(db.l_y, filterRange);


% Smaller lambda (more variability in trend)

[db.l_y_tnd0, db.l_y_gap0] = hpf(db.l_y, filterRange, "lambda", 100);


% HP with trend such that output gap is -2 in 2015Q3

level = Series();
level(qq(2015,3)) = db.l_y(qq(2015,3)) + 2;
[db.l_y_tnd1, db.l_y_gap1] = hpf(db.l_y, filterRange, "level", level);


% HP with growth -1% in 2021Q4
change = Series();
change(qq(2018,4)) = -1/400;
[db.l_y_tnd2, db.l_y_gap2] = hpf(db.l_y, filterRange, "change", change);


%% Plot the results

f1 = figure();

h = plot( ...
    [db.l_y_tnd, db.l_y_tnd0, db.l_y_tnd1, db.l_y_tnd2, db.l_y], ...
    "range", qq(2008,1):filterRange(end), ...
    "marker", "s" ...
);
h(end).LineWidth = 3;
h(end).Color = 0.75*[1, 1, 1];
grid on

title("Log GDP and HP Trend");
legend("HP", "HP with lambda=100", "HP with Trend=Data in 2015-Q3", "HP with trend growth -1% in 2022-Q4", "Data","Location","NorthWest");


figure();

h = plot( ...
    4*diff([db.l_y_tnd, db.l_y_tnd0, db.l_y_tnd1, db.l_y_tnd2]), ...
    "range", qq(2008,1):filterRange(end), ...
    "marker", "s" ...
);
grid on

title("4*Diff log GDP and HP Trend");
legend("HP", "HP with lambda=100", "HP with Trend=Data in 2015-Q3", "HP with trend growth -1% in 2022-Q4", "Location","NorthWest");

figure(f1);


%% Save data to CSV file

databank.toCSV(db, "data/hpFilter.csv", "format", "%.16g");


