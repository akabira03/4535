function R = simulateDispatch(T, P)
    n = height(T);
    pv = pvOutput(T, P);
    dayDemand = buildDemand(P);
    dayDemand = dayDemand(:);
    demand = dayDemand(hour(T.time) + 1);
    etaC = sqrt(P.battRoundTrip);
    etaD = sqrt(P.battRoundTrip);
    eMin = P.battKwh * P.socMin;
    eMax = P.battKwh * P.socMax;
    E = zeros(n + 1, 1);
    E(1) = P.battKwh * P.socInit;
    pvDirect = zeros(n, 1);
    charge = zeros(n, 1);
    discharge = zeros(n, 1);
    grid = zeros(n, 1);
    spill = zeros(n, 1);
    for t = 1:n
        pvDirect(t) = min(pv(t), demand(t));
        surplus = pv(t) - pvDirect(t);
        deficit = demand(t) - pvDirect(t);
        room = max((eMax - E(t)) / etaC, 0);
        charge(t) = min([surplus, P.battPowerKw, room]);
        spill(t) = surplus - charge(t);
        available = max((E(t) - eMin) * etaD, 0);
        discharge(t) = min([deficit, P.battPowerKw, available]);
        grid(t) = deficit - discharge(t);
        E(t + 1) = E(t) + etaC * charge(t) - discharge(t) / etaD;
    end
    R.time = T.time;
    R.pv = pv;
    R.demand = demand;
    R.pvDirect = pvDirect;
    R.charge = charge;
    R.discharge = discharge;
    R.grid = grid;
    R.spill = spill;
    R.soc = 100 * E(1:n) / P.battKwh;
    if nargout == 0
        totalDemand = sum(demand);
        fprintf("annual demand: %.0f kWh\n", totalDemand);
        fprintf("grid import: %.0f kWh\n", sum(grid));
        fprintf("solar share of demand: %.1f %%\n", 100 * (1 - sum(grid) / totalDemand));
        fprintf("PV spilled: %.0f kWh (%.1f %% of PV)\n", sum(spill), 100 * sum(spill) / sum(pv));
        fprintf("battery full cycles per year: %.0f\n", sum(discharge) / etaD / (P.battKwh * (P.socMax - P.socMin)));        fprintf("energy balance error: %.6f kWh\n", sum(pv) + sum(discharge) + sum(grid) - sum(demand) - sum(charge) - sum(spill));
        fprintf("battery energy error: %.6f kWh\n", E(end) - E(1) - (etaC * sum(charge) - sum(discharge) / etaD));
        week = T.time >= datetime(2023, 4, 3) & T.time < datetime(2023, 4, 10);
        tiledlayout(2, 1);
        nexttile;
        plot(T.time(week), demand(week), T.time(week), pv(week), T.time(week), grid(week));
        legend("charging demand", "PV output", "grid import");
        ylabel("power (kW)");
        title("Dispatch, 3 to 9 April 2023");
        nexttile;
        plot(T.time(week), R.soc(week));
        ylabel("battery state of charge (%)");
        xlabel("time");
    end
end