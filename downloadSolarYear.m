function downloadSolarYear(year)
    arguments
        year (1,1) double = 2023
    end
    url = "https://power.larc.nasa.gov/api/temporal/hourly/point" + ...
        "?parameters=T2M,ALLSKY_SFC_SW_DWN&community=RE" + ...
        "&longitude=90.41&latitude=23.71" + ...
        "&start=" + year + "0101&end=" + year + "1231&format=CSV";
    outFile = "dhaka_hourly_solar_" + year + ".csv";
    websave(outFile, url, weboptions("Timeout", 120));
    fprintf("saved %s\n", outFile);
end