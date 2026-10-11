function P = defaultParams(scenario)
    arguments
        scenario (1,1) string {mustBeMember(scenario, ["low", "base", "high"])} = "base"
    end
    energy = struct("low", 4.8, "base", 8, "high", 12);
    P.scenario = scenario;
    P.nRickshaws = 30;
    P.energyPerCharge_kWh = energy.(scenario);
    P.chargeHours = 9;
    P.arrivalStartHour = 18;
    P.arrivalEndHour = 22;
    P.chargerEfficiency = 0.9;
end