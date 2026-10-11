function load_kW = buildDemand(P)
    arrivals = round(linspace(P.arrivalStartHour, P.arrivalEndHour, P.nRickshaws));
    gridEnergy = P.energyPerCharge_kWh / P.chargerEfficiency;
    chargePower = gridEnergy / P.chargeHours;
    load_kW = zeros(24, 1);
    for k = 1:P.nRickshaws
        remaining = gridEnergy;
        h = arrivals(k);
        while remaining > 1e-9
            e = min(chargePower, remaining);
            idx = mod(h, 24) + 1;
            load_kW(idx) = load_kW(idx) + e;
            remaining = remaining - e;
            h = h + 1;
        end
    end
    if nargout == 0
        bar(0:23, load_kW);
        xlabel("hour of day");
        ylabel("charging load (kW)");
        title("Garage charging demand");
        fprintf("daily energy: %.1f kWh\n", sum(load_kW));
        peak = max(load_kW);
        fprintf("peak load: %.1f kW at hour %d\n", peak, find(load_kW == peak, 1) - 1);
    end
end