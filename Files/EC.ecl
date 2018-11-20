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
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(ECData)                 ec_data                 {XPATH('ECData')};
        END;

        EXPORT RawFile(STRING pathLeafName) := DATASET
            (
                Proagrica.Util.MakePath(pathLeafName),
                Layout,
                JSON('', NOROOT),
                OPT
            );

        EXPORT File(STRING pathLeafName) := NORMALIZE
            (
                RawFile(pathLeafName),
                LEFT.ec_data,
                TRANSFORM
                    (
                        {
                            Layout.created_on_datetime,
                            Layout.field_id,
                            UNSIGNED4   sample_id;
                            ECData
                        },
                        SELF.sample_id := COUNTER,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );

    END; // Raw Module

END;
