function EVMicrogridApp
    P = defaultParams;
    T = [];
    dataFile = "dhaka_hourly_solar_2023.csv";
    energyMap = struct("low", 4.8, "base", 8, "high", 12);

    fig = uifigure("Name", "E-Rickshaw Charging Microgrid Designer", "Position", [60 60 1180 740]);
    root = uigridlayout(fig, [1 1]);
    tabs = uitabgroup(root);

    tab1 = uitab(tabs, "Title", "Garage and demand");
    g1 = uigridlayout(tab1, [1 2]);
    g1.ColumnWidth = {320, "1x"};
    c1 = uigridlayout(g1, [9 2]);
    c1.RowHeight = {30, 30, 30, 30, 30, 30, 30, 70, "1x"};
    c1.ColumnWidth = {170, "1x"};
    uilabel(c1, "Text", "Energy scenario");
    ddScenario = uidropdown(c1, "Items", ["low", "base", "high"], "Value", "base", ...        "ValueChangedFcn", @(~, ~) onScenario());
    fN = numField(c1, "Rickshaws", P.nRickshaws, [1 500], @(~, ~) refresh());
    fE = numField(c1, "Energy per charge (kWh)", P.energyPerCharge_kWh, [0.5 30], @(~, ~) refresh());
    fH = numField(c1, "Charge duration (h)", P.chargeHours, [1 24], @(~, ~) refresh());
    fS = numField(c1, "Arrival start hour", P.arrivalStartHour, [0 23], @(~, ~) refresh());
    fEnd = numField(c1, "Arrival end hour", P.arrivalEndHour, [0 23], @(~, ~) refresh());
    fEff = numField(c1, "Charger efficiency", P.chargerEfficiency, [0.5 1], @(~, ~) refresh());
    lblDemand = uilabel(c1, "Text", "", "WordWrap", "on");
    lblDemand.Layout.Row = 8;
    lblDemand.Layout.Column = [1 2];
    axDemand = uiaxes(g1);

    tab2 = uitab(tabs, "Title", "Solar resource");
    g2 = uigridlayout(tab2, [3 2]);
    g2.RowHeight = {34, 34, "1x"};
    uibutton(g2, "Text", "Load Dhaka 2023 data", "ButtonPushedFcn", @(~, ~) loadData(dataFile));
    uibutton(g2, "Text", "Choose another CSV file", "ButtonPushedFcn", @(~, ~) chooseFile());
    lblSolar = uilabel(g2, "Text", "No solar data loaded");
    lblSolar.Layout.Row = 2;
    lblSolar.Layout.Column = [1 2];
    axIrr = uiaxes(g2);
    axIrr.Layout.Row = 3;
    axIrr.Layout.Column = 1;
    axTemp = uiaxes(g2);
    axTemp.Layout.Row = 3;
    axTemp.Layout.Column = 2;

    tab3 = uitab(tabs, "Title", "System design");
    g3 = uigridlayout(tab3, [1 2]);
    g3.ColumnWidth = {420, "1x"};
    c3 = uigridlayout(g3, [7 3]);
    c3.ColumnWidth = {150, "1x", 80};
    c3.RowHeight = {45, 45, 45, 45, 45, 90, "1x"};
    [sPV, ~] = sliderRow(c3, "PV size", [0 200], P.pvKw, "%.0f kW", @() refresh());
    [sBatt, ~] = sliderRow(c3, "Battery capacity", [0 400], P.battKwh, "%.0f kWh", @() refresh());
    [sPow, ~] = sliderRow(c3, "Battery power limit", [0 200], P.battPowerKw, "%.0f kW", @() refresh());
    [sRTE, ~] = sliderRow(c3, "Round-trip efficiency", [0.7 1], P.battRoundTrip, "%.2f", @() refresh());
    [sSoc, ~] = sliderRow(c3, "Minimum charge", [0 0.5], P.socMin, "%.2f", @() refresh());
    lblSystem = uilabel(c3, "Text", "", "WordWrap", "on");
    lblSystem.Layout.Row = 6;
    lblSystem.Layout.Column = [1 3];
    axPVWeek = uiaxes(g3);

    tab4 = uitab(tabs, "Title", "Dispatch simulation");
    g4 = uigridlayout(tab4, [1 2]);
    g4.ColumnWidth = {330, "1x"};
    c4 = uigridlayout(g4, [3 1]);
    c4.RowHeight = {22, 32, "1x"};
    uilabel(c4, "Text", "Week starting");
    dp = uidatepicker(c4, "Value", datetime(2023, 4, 3), ...
        "Limits", [datetime(2023, 1, 1) datetime(2023, 12, 25)], ...
        "ValueChangedFcn", @(~, ~) refresh());
    tblResults = uitable(c4, "ColumnName", {"Metric", "Value"}, "Data", cell(0, 2), ...
        "ColumnWidth", {190, "auto"});
    p4 = uigridlayout(g4, [2 1]);
    axPower = uiaxes(p4);
    axSoc = uiaxes(p4);

    tab5 = uitab(tabs, "Title", "Assumptions");
    g5 = uigridlayout(tab5, [1 1]);
    tblAssump = uitable(g5, "ColumnName", {"Parameter", "Value", "Basis"}, ...
        "ColumnWidth", {230, 150, "auto"});

    if isfile(dataFile)
        loadData(dataFile);
    else
        refresh();
    end

    function readInputs()
        P.nRickshaws = round(fN.Value);
        P.energyPerCharge_kWh = fE.Value;
        P.chargeHours = round(fH.Value);
        P.arrivalStartHour = round(fS.Value);
        P.arrivalEndHour = round(fEnd.Value);
        P.chargerEfficiency = fEff.Value;
        P.pvKw = round(sPV.Value);
        P.battKwh = round(sBatt.Value);
        P.battPowerKw = round(sPow.Value);
        P.battRoundTrip = sRTE.Value;
        P.socMin = sSoc.Value;
    end

    function onScenario()
        P.scenario = string(ddScenario.Value);
        fE.Value = energyMap.(ddScenario.Value);
        refresh();
    end

    function refresh()
        readInputs();
        updateAssumptions();
        try
            d = buildDemand(P);
            d = d(:);
            cla(axDemand);
            bar(axDemand, 0:23, d);
            xlabel(axDemand, "hour of day");
            ylabel(axDemand, "charging load (kW)");
            title(axDemand, "Charging demand profile");
            lblDemand.Text = sprintf("Daily energy %.1f kWh | Peak load %.1f kW", sum(d), max(d));
        catch ME
            uialert(fig, ME.message, "Demand error");
            return;
        end
        if isempty(T)
            lblSystem.Text = "Load solar data in the Solar resource tab.";
            return;
        end
        runModel();
    end

    function runModel()
        R = simulateDispatch(T, P);
        t0 = dp.Value;
        wk = T.time >= t0 & T.time < t0 + days(7);
        cla(axPower);
        plot(axPower, T.time(wk), R.demand(wk), T.time(wk), R.pv(wk), T.time(wk), R.grid(wk));
        legend(axPower, {"charging demand", "PV output", "grid import"}, "Location", "northwest");
        ylabel(axPower, "power (kW)");
        title(axPower, "Power flows");
        cla(axSoc);
        plot(axSoc, T.time(wk), R.soc(wk));
        ylim(axSoc, [0 100]);
        ylabel(axSoc, "battery state of charge (%)");
        xlabel(axSoc, "time");
        cla(axPVWeek);
        plot(axPVWeek, T.time(wk), R.pv(wk), T.time(wk), R.demand(wk));
        legend(axPVWeek, {"PV output", "charging demand"}, "Location", "northwest");
        ylabel(axPVWeek, "power (kW)");
        title(axPVWeek, "PV output against charging demand");
        demandTot = sum(R.demand);
        pvTot = sum(R.pv);
        gridTot = sum(R.grid);
        spillTot = sum(R.spill);
        etaD = sqrt(P.battRoundTrip);
        cap = P.battKwh * (P.socMax - P.socMin);
        cycles = 0;
        if cap > 0
            cycles = sum(R.discharge) / etaD / cap;
        end
        spillPct = 0;
        if pvTot > 0
            spillPct = 100 * spillTot / pvTot;
        end
        yield = 0;
        if P.pvKw > 0
            yield = pvTot / P.pvKw;
        end
        tblResults.Data = {
            "Annual demand (kWh)", sprintf("%.0f", demandTot);
            "Annual PV energy (kWh)", sprintf("%.0f", pvTot);
            "Grid import (kWh)", sprintf("%.0f", gridTot);
            "Solar share of demand (%)", sprintf("%.1f", 100 * (1 - gridTot / demandTot));
            "PV spilled (kWh)", sprintf("%.0f", spillTot);
            "PV spilled (% of PV)", sprintf("%.1f", spillPct);
            "Battery full cycles per year", sprintf("%.0f", cycles);
            "Peak grid import (kW)", sprintf("%.1f", max(R.grid))};
        lblSystem.Text = sprintf("Annual PV energy %.0f kWh | specific yield %.0f kWh per kW | peak PV output %.1f kW", ...
            pvTot, yield, max(R.pv));
    end

    function loadData(fileName)
        try
            T = loadSolarData(fileName);
        catch ME
            uialert(fig, ME.message, "Data error");
            return;
        end
        updateSolarTab();
        refresh();
    end

    function chooseFile()
        [f, p] = uigetfile("*.csv", "Select a NASA POWER hourly CSV file");
        if isequal(f, 0)
            return;
        end
        loadData(fullfile(p, f));
    end

    function updateSolarTab()
        mo = month(T.time);
        irr = T.irradiance;
        irr(isnan(irr)) = 0;
        nDays = accumarray(mo, 1, [12 1]) / 24;
        ins = accumarray(mo, irr, [12 1]) ./ nDays / 1000;
        tmp = accumarray(mo, T.temp_C, [12 1], @(x) mean(x, "omitnan"));
        cla(axIrr);
        bar(axIrr, 1:12, ins);
        axIrr.XTick = 1:12;
        xlabel(axIrr, "month");
        ylabel(axIrr, "daily irradiation (kWh/m^2 per day)");
        title(axIrr, "Monthly solar resource, horizontal plane");
        cla(axTemp);
        plot(axTemp, 1:12, tmp, "-o");
        axTemp.XTick = 1:12;
        xlabel(axTemp, "month");
        ylabel(axTemp, "mean air temperature (C)");
        title(axTemp, "Monthly mean temperature");
        lblSolar.Text = sprintf("%d hourly rows, %s to %s | annual irradiation %.0f kWh/m^2", ...
            height(T), string(min(T.time), "dd-MMM-yyyy"), string(max(T.time), "dd-MMM-yyyy"), sum(irr) / 1000);
    end

    function updateAssumptions()
        rows = [
            "Rickshaws in garage", string(P.nRickshaws), "A Dhaka design study sized a station for 30 easy bikes (third-party source)";
            "Energy per charge (kWh)", string(P.energyPerCharge_kWh), "Published ranges 4.8 to 12 kWh; the sources conflict";
            "Charge duration (h)", string(P.chargeHours), "One 20 kW station study";
            "Arrival window", string(sprintf("%d to %d h", P.arrivalStartHour, P.arrivalEndHour)), "Assumption: evening arrival, overnight charging";
            "Charger efficiency", string(P.chargerEfficiency), "Assumption";
            "PV size (kW)", string(P.pvKw), "Design choice";
            "Temperature coefficient (per C)", string(P.tempCoeff), "Assumption; replace with a datasheet value";
            "NOCT (C)", string(P.noct), "Assumption; replace with a datasheet value";
            "System efficiency", string(P.systemEfficiency), "Assumption for wiring, inverter and dirt losses";
            "Battery capacity (kWh)", string(P.battKwh), "Design choice";
            "Battery power limit (kW)", string(P.battPowerKw), "Design choice";
            "Round-trip efficiency", string(P.battRoundTrip), "Assumption; replace with a datasheet value";
            "Minimum state of charge", string(P.socMin), "Assumption; replace with the datasheet depth of discharge";
            "Solar data", "NASA POWER, 2023", "Hourly point data for 23.71 N, 90.41 E, local solar time"];
        tblAssump.Data = cellstr(rows);
    end
end

function f = numField(parent, label, value, lim, cb)
    uilabel(parent, "Text", label);
    f = uieditfield(parent, "numeric", "Value", value, "Limits", lim, "ValueChangedFcn", cb);
end

function [s, l] = sliderRow(parent, name, lim, value, fmt, cb)
    uilabel(parent, "Text", name);
    s = uislider(parent, "Limits", lim, "Value", value);
    l = uilabel(parent, "Text", sprintf(fmt, value));
    s.ValueChangingFcn = @(~, evt) set(l, "Text", sprintf(fmt, evt.Value));
    s.ValueChangedFcn = @(~, evt) sliderDone(l, fmt, evt.Value, cb);
end

function sliderDone(l, fmt, v, cb)
    l.Text = sprintf(fmt, v);
    cb();
end