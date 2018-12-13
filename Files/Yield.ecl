IMPORT Proagrica;

EXPORT Yield := MODULE

    EXPORT Raw := MODULE

        SHARED SpatialRec := RECORD
            DECIMAL6_2                      adjusted_mass           {XPATH('AdjustedMass')};
            DECIMAL6_2                      area                    {XPATH('Area')};
        END;

        SHARED SectionRec := RECORD
            BOOLEAN                         is_active               {XPATH('IsActive')};
            DECIMAL6_2                      width_value             {XPATH('SectionWidth')};
            DECIMAL6_2                      observed_mass           {XPATH('ObservedMass')};
            DATASET(SpatialRec)             spatial                 {XPATH('SpatialRecord')}
        END;

        SHARED Measurement := RECORD
            DECIMAL6_2                      measure                 {XPATH('Measure/Value')};
            UNSIGNED2                       unit_id                 {XPATH('UnitID/Value')};
        END;

        SHARED YieldSeedRecord := RECORD
            DECIMAL6_2                      observed_moisture       {XPATH('YieldSeedData/ObservedMoisture')};
            DECIMAL6_2                      adjusted_moisture       {XPATH('YieldSeedData/AdjMoisture')};
            STRING                          observation_date        {XPATH('YieldData/ObservationDate')};
            DECIMAL9_6                      longitude               {XPATH('YieldData/Longitude')};
            DECIMAL9_6                      latitude                {XPATH('YieldData/Latitude')};
            DECIMAL6_2                      elevation               {XPATH('YieldData/Elevation')};
            DECIMAL6_2                      distance                {XPATH('YieldData/Distance')};
            DECIMAL6_2                      heading_value           {XPATH('YieldData/Heading')};
            DECIMAL6_2                      speed                   {XPATH('YieldData/Speed/Value')};
            DATASET(SectionRec)             section                 {XPATH('YieldData/Section')};
        END;

        EXPORT Layout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(YieldSeedRecord)        yield_seed_records      {XPATH('YieldSeedRecords')};
        END;

        EXPORT RawFile(STRING path) := DATASET
            (
                path,
                Layout,
                JSON('', NOROOT),
                OPT
            );

        EXPORT File(STRING path) := NORMALIZE
            (
                DISTRIBUTE(RawFile(path), HASH32(field_id)),
                LEFT.yield_seed_records,
                TRANSFORM
                    (
                        {
                            Layout.created_on_datetime,
                            Layout.field_id,
                            UNSIGNED4   sample_id,
                            YieldSeedRecord
                        },
                        SELF.sample_id := COUNTER,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );

    END; // Raw Module

    //--------------------------------------------------------------------------

    EXPORT Enhanced := MODULE

        EXPORT Layout := RECORD
            RECORDOF(Raw.File(''));
            DECIMAL14_6     utm_x;
            DECIMAL14_6     utm_y;
            UNSIGNED1       utm_zone;
        END;

        EXPORT File(STRING path) := FUNCTION
            ds := Raw.File(path);

            initialZones := TABLE
                (
                    ds,
                    {
                        field_id,
                        UNSIGNED1   zone := Proagrica.UTM.LongitudeToZone(MIN(GROUP, longitude))
                    },
                    field_id,
                    LOCAL
                );
            
            newDS := JOIN
                (
                    ds,
                    initialZones,
                    LEFT.field_id = RIGHT.field_id,
                    TRANSFORM
                        (
                            Layout,

                            utmInfo := Proagrica.UTM.GPSToUTM(LEFT.latitude, LEFT.longitude, RIGHT.zone);

                            SELF.utm_x := utmInfo.x,
                            SELF.utm_y := utmInfo.y,
                            SELF.utm_zone := utmInfo.zone,
                            SELF := LEFT
                        ),
                    LOOKUP
                );
            
            RETURN newDS;
        END;

    END; // Enhanced Module

    //--------------------------------------------------------------------------

    EXPORT Working := MODULE

        EXPORT Layout := Enhanced.Layout;

        EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::yield';

        EXPORT File(STRING path = DEFAULT_PATH) := DATASET(path, Layout, FLAT);

    END; // Working Module

END;