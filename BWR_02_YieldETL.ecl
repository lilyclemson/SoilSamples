IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Yield ETL 2');

parsedYieldData := Proagrica.Files.Yield.Parsed.File();

// Remove yield records that contain known-bogus values
isBad := (NOT parsedYieldData.is_active OR parsedYieldData.speed = 0 OR parsedYieldData.adjusted_mass = 0);
goodYieldData1 := parsedYieldData(NOT isBad);

// Compute some stats for speed and adjusted mass for each layer and crop
stats := TABLE
    (
        goodYieldData1,
        {
            field_id,
            id,
            crop_id,
            DECIMAL6_2      speed_mean := AVE(GROUP, speed),
            DECIMAL6_2      speed_std_dev := SQRT(VARIANCE(GROUP, speed)),
            DECIMAL6_2      adj_mass_mean := AVE(GROUP, adjusted_mass),
            DECIMAL6_2      adj_mass_std_dev := SQRT(VARIANCE(GROUP, adjusted_mass))
        },
        field_id, id, crop_id,
        LOCAL
    );

STD_DEV_FACTOR := 2;

minMax := PROJECT
    (
        stats,
        TRANSFORM
            (
                {
                    RECORDOF(LEFT),
                    DECIMAL6_2          speed_min_allowed,
                    DECIMAL6_2          speed_max_allowed,
                    DECIMAL6_2          adj_mass_min_allowed,
                    DECIMAL6_2          adj_mass_max_allowed
                },
                SELF.speed_min_allowed := MAX(LEFT.speed_mean - (STD_DEV_FACTOR * LEFT.speed_std_dev), 0),
                SELF.speed_max_allowed := LEFT.speed_mean + (STD_DEV_FACTOR * LEFT.speed_std_dev),
                SELF.adj_mass_min_allowed := MAX(LEFT.adj_mass_mean - (STD_DEV_FACTOR * LEFT.adj_mass_std_dev), 0),
                SELF.adj_mass_max_allowed := LEFT.adj_mass_mean + (STD_DEV_FACTOR * LEFT.adj_mass_std_dev),
                SELF := LEFT
            )
    );

// Filter yield records
goodYieldData2 := JOIN
    (
        goodYieldData1,
        minMax,
        LEFT.field_id = RIGHT.field_id
            AND LEFT.id = RIGHT.id
            AND LEFT.crop_id = RIGHT.crop_id
            AND LEFT.speed BETWEEN RIGHT.speed_min_allowed AND RIGHT.speed_max_allowed
            AND LEFT.adjusted_mass BETWEEN RIGHT.adj_mass_min_allowed AND RIGHT.adj_mass_max_allowed,
        TRANSFORM(LEFT),
        LOCAL
    );

OUTPUT(goodYieldData2, /*RecStruct*/, Proagrica.Files.Yield.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);
