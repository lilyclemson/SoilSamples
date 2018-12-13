IMPORT Proagrica;

EXPORT EC := MODULE

    EXPORT Raw := MODULE

        SHARED Measurement := RECORD
            DECIMAL6_2                      measure                 {XPATH('Measure/Value')};
            UNSIGNED2                       unit_id                 {XPATH('UnitID/Value')};
        END;

        SHARED ECData := RECORD
            DECIMAL9_6                      longitude               {XPATH('Longitude')};
            DECIMAL9_6                      latitude                {XPATH('Latitude')};
            Measurement                     elevation               {XPATH('Elevation')};
            Measurement                     speed                   {XPATH('Speed')};
            DECIMAL6_2                      red                     {XPATH('Red/Value')};
            DECIMAL6_2                      ir                      {XPATH('IR/Value')};
            Measurement                     shallow                 {XPATH('ECShallow')};
            Measurement                     deep                    {XPATH('ECDeep')};
            DECIMAL6_2                      slope                   {XPATH('Slope/Value')};
            DECIMAL6_2                      curve                   {XPATH('Curve/Value')};
            Measurement                     ec02                    {XPATH('EC0_2')};
            Measurement                     dipole                  {XPATH('Dipole')};
            Measurement                     om                      {XPATH('OM')};
            Measurement                     ced                     {XPATH('CEC')};
        END;

        EXPORT Layout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          id                      {XPATH('ID')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(ECData)                 ec_data                 {XPATH('ECData')};
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
                LEFT.ec_data,
                TRANSFORM
                    (
                        {
                            Layout.created_on_datetime,
                            Layout.id,
                            Layout.field_id,
                            UNSIGNED4   sample_id,
                            ECData
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

        EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::ec';

        EXPORT File(STRING path = DEFAULT_PATH) := DATASET(path, Layout, FLAT);

    END; // Working Module

END;
