function T = loadSolarData(fileName)
    arguments
        fileName (1,1) string = "dhaka_hourly_solar.csv"
    end
    raw = readlines(fileName);
    headerEnd = find(contains(raw, "END HEADER"), 1);
    if isempty(headerEnd)
        headerEnd = 0;
    end
    opts = detectImportOptions(fileName, "NumHeaderLines", headerEnd);
    D = readtable(fileName, opts);
    D.T2M(D.T2M == -999) = NaN;
    D.ALLSKY_SFC_SW_DWN(D.ALLSKY_SFC_SW_DWN == -999) = NaN;
    time = datetime(D.YEAR, D.MO, D.DY, D.HR, 0, 0);
    T = table(time, D.T2M, D.ALLSKY_SFC_SW_DWN, ...
        'VariableNames', {'time', 'temp_C', 'irradiance'});
    if nargout == 0
        disp(raw(1:min(headerEnd + 1, 40)));
        fprintf("rows: %d\n", height(T));
        fprintf("missing temperature: %d\n", sum(isnan(T.temp_C)));
        fprintf("missing irradiance: %d\n", sum(isnan(T.irradiance)));
        avgByHour = accumarray(hour(T.time) + 1, T.irradiance, [24 1], ...
            @(x) mean(x, 'omitnan'));
        [~, peak] = max(avgByHour);
        fprintf("hour with the highest average irradiance: %d\n", peak - 1);
        mo = month(T.time);
        tempMonthly = accumarray(mo, T.temp_C, [12 1], @(x) mean(x, 'omitnan'));
        irrMonthly = accumarray(mo, T.irradiance, [12 1], @(x) mean(x, 'omitnan'));
        disp(table((1:12)', tempMonthly, irrMonthly, ...
            'VariableNames', {'month', 'avg_temp_C', 'avg_irradiance'}));
    end
end