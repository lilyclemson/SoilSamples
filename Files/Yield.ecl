IMPORT Proagrica;

EXPORT Yield := MODULE

    EXPORT Raw := MODULE

        SHARED SpatialRec := RECORD
            DECIMAL6_2                      adjusted_mass           {XPATH('AdjustedMass')};
            DECIMAL6_2                      area                    {XPATH('Area')};
        END;

        SHARED SectionRec1 := RECORD
            BOOLEAN                         is_active               {XPATH('IsActive')};
            DECIMAL6_2                      width_value             {XPATH('SectionWidth')};
            DECIMAL6_2                      observed_mass           {XPATH('ObservedMass')};
            DATASET(SpatialRec)             spatial                 {XPATH('SpatialRecord')}
        END;

        SHARED YieldSeedRecord1 := RECORD
            DECIMAL6_2                      observed_moisture       {XPATH('YieldSeedData/ObservedMoisture')};
            DECIMAL6_2                      adjusted_moisture       {XPATH('YieldSeedData/AdjMoisture')};
            STRING                          observation_date        {XPATH('YieldData/ObservationDate')};
            DECIMAL9_6                      longitude               {XPATH('YieldData/Longitude')};
            DECIMAL9_6                      latitude                {XPATH('YieldData/Latitude')};
            DECIMAL6_2                      elevation               {XPATH('YieldData/Elevation')};
            DECIMAL6_2                      distance                {XPATH('YieldData/Distance')};
            DECIMAL6_2                      heading_value           {XPATH('YieldData/Heading')};
            DECIMAL6_2                      speed                   {XPATH('YieldData/Speed/Value')};
            DATASET(SectionRec1)            section                 {XPATH('YieldData/Section')};
        END;

        EXPORT Layout1 := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          id                      {XPATH('ID')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(YieldSeedRecord1)       yield_seed_records      {XPATH('YieldSeedRecords')};
        END;

        EXPORT RawFile(STRING path) := DATASET
            (
                path,
                Layout1,
                JSON('', NOROOT),
                OPT
            );
        
        //------------------------------------

        // First normalization
        EXPORT Layout2 := RECORD
            Layout1.created_on_datetime;
            Layout1.id;
            Layout1.field_id;
            UNSIGNED4           sample_id;
            YieldSeedRecord1;
        END;

        EXPORT File1(STRING path) := NORMALIZE
            (
                DISTRIBUTE(RawFile(path), HASH32(field_id)),
                LEFT.yield_seed_records,
                TRANSFORM
                    (
                        Layout2,
                        SELF.sample_id := COUNTER,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );

        // Second normalization
        EXPORT Layout3 := RECORD
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
            SectionRec1;
        END;
        
        EXPORT File2(STRING path) := NORMALIZE
            (
                File1(path),
                LEFT.section,
                TRANSFORM
                    (
                        Layout3,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );
        
        // Third normalization
        EXPORT Layout4 := RECORD
            Layout3.created_on_datetime;
            Layout3.id;
            Layout3.field_id;
            Layout3.sample_id;
            Layout3.observed_moisture;
            Layout3.adjusted_moisture;
            Layout3.observation_date;
            Layout3.longitude;
            Layout3.latitude;
            Layout3.elevation;
            Layout3.distance;
            Layout3.heading_value;
            Layout3.speed;
            Layout3.is_active;
            Layout3.width_value;
            Layout3.observed_mass;
            SpatialRec;
        END;
        
        EXPORT File(STRING path) := PROJECT
            (
                File2(path),
                TRANSFORM
                    (
                        Layout4,
                        SELF.adjusted_mass := SUM(LEFT.spatial, adjusted_mass),
                        SELF.area := SUM(LEFT.spatial, area),
                        SELF := LEFT
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