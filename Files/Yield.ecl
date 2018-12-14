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

        EXPORT RawLayout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          id                      {XPATH('ID')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(YieldSeedRecord)        yield_seed_records      {XPATH('YieldSeedRecords')};
        END;

        EXPORT RawFile(STRING path) := DATASET
            (
                path,
                RawLayout,
                JSON('', NOROOT),
                OPT
            );
        
        //------------------------------------

        // First normalization
        SHARED Layout1 := RECORD
            RawLayout.created_on_datetime;
            RawLayout.id;
            RawLayout.field_id;
            UNSIGNED4           sample_id;
            YieldSeedRecord;
        END;

        SHARED File1(STRING path) := NORMALIZE
            (
                DISTRIBUTE(RawFile(path), HASH32(field_id)),
                LEFT.yield_seed_records,
                TRANSFORM
                    (
                        Layout1,
                        SELF.sample_id := COUNTER,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );

        // Second normalization
        SHARED Layout2 := RECORD
            Layout1.created_on_datetime;
            Layout1.id;
            Layout1.field_id;
            Layout1.sample_id;
            Layout1.observed_moisture;
            Layout1.adjusted_moisture;
            Layout1.observation_date;
            Layout1.longitude;
            Layout1.latitude;
            Layout1.elevation;
            Layout1.distance;
            Layout1.heading_value;
            Layout1.speed;
            SectionRec;
        END;
        
        SHARED File2(STRING path) := NORMALIZE
            (
                File1(path),
                LEFT.section,
                TRANSFORM
                    (
                        Layout2,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );
        
        // Third normalization
        SHARED Layout3 := RECORD
            Layout2.created_on_datetime;
            Layout2.id;
            Layout2.field_id;
            Layout2.sample_id;
            Layout2.observed_moisture;
            Layout2.adjusted_moisture;
            Layout2.observation_date;
            Layout2.longitude;
            Layout2.latitude;
            Layout2.elevation;
            Layout2.distance;
            Layout2.heading_value;
            Layout2.speed;
            Layout2.is_active;
            Layout2.width_value;
            Layout2.observed_mass;
            SpatialRec;
        END;
        
        SHARED File3(STRING path) := PROJECT
            (
                File2(path),
                TRANSFORM
                    (
                        Layout,
                        SELF.adjusted_mass := SUM(LEFT.spatial, adjusted_mass),
                        SELF.area := SUM(LEFT.spatial, area),
                        SELF := LEFT
                    )
            );

        EXPORT Layout := Layout3;

        EXPORT File(STRING path) := File3(path);

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