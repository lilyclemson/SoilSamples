IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Create IDW');

//------------------------------------------------------------------------------

soilSampleData := Proagrica.Files.SoilSampling.Working.File(); // Already distributed on HASH32(field_id)
ecData := Proagrica.Files.EC.Working.File(); // Already distributed on HASH32(field_id)
yieldData := Proagrica.Files.Yield.Working.File(); // Already distributed on HASH32(field_id)

soilSampleUTM := TABLE
    (
        soilSampleData,
        {
            utm_zone,
            utm_x,
            utm_y
        },
        utm_zone, utm_x, utm_y,
        MERGE
    );

ecUTM := TABLE
    (
        ecData,
        {
            utm_zone,
            utm_x,
            utm_y
        },
        utm_zone, utm_x, utm_y,
        MERGE
    );

yieldUTM := TABLE
    (
        yieldData,
        {
            utm_zone,
            utm_x,
            utm_y
        },
        utm_zone, utm_x, utm_y,
        MERGE
    );

UTMRec := RECORD
    UNSIGNED1       utm_zone;
    DECIMAL14_6     utm_x;
    DECIMAL14_6     utm_y;
END;

basicSoilSampleUTM := PROJECT(soilSampleUTM, TRANSFORM(UTMRec, SELF := LEFT));

combinedUTM := PROJECT(ecUTM, TRANSFORM(UTMRec, SELF := LEFT))
                + PROJECT(yieldUTM, TRANSFORM(UTMRec, SELF := LEFT));

reducedUTM := TABLE
    (
        combinedUTM,
        {
            utm_zone,
            utm_x,
            utm_y
        },
        utm_zone, utm_x, utm_y,
        MERGE
    );

WIDTH_RANGE := 24; // meters
IDW_EXP := 2;

nearbyPoints := JOIN
    (
        reducedUTM,
        basicSoilSampleUTM,
        LEFT.utm_zone = RIGHT.utm_zone
            AND LEFT.utm_x BETWEEN (RIGHT.utm_x - WIDTH_RANGE) AND (RIGHT.utm_x + WIDTH_RANGE)
            AND LEFT.utm_y BETWEEN (RIGHT.utm_y - WIDTH_RANGE) AND (RIGHT.utm_y + WIDTH_RANGE),
        TRANSFORM
            (
                Proagrica.Files.IDW.Layout,

                dist := Proagrica.Util.UTMDistance(LEFT.utm_x, LEFT.utm_y, RIGHT.utm_x, RIGHT.utm_y);

                SELF.soil_sample_utm_x := RIGHT.utm_x,
                SELF.soil_sample_utm_y := RIGHT.utm_y,
                SELF.other_utm_x := LEFT.utm_x,
                SELF.other_utm_y := LEFT.utm_y,
                SELF.distance := IF(dist <= WIDTH_RANGE, dist, SKIP),
                SELF.idw := POWER(1.0 / (REAL4)SELF.distance, IDW_EXP),
                SELF := RIGHT
            ),
        MANY LOOKUP
    );

OUTPUT(nearbyPoints, /* RecStruct */, Proagrica.Files.IDW.DEFAULT_PATH, OVERWRITE, COMPRESSED);
