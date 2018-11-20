IMPORT Proagrica;

EXPORT Yield := MODULE

    EXPORT Raw := MODULE

        SHARED SectionRec := RECORD
            BOOLEAN                         is_active               {XPATH('IsActive')};
            DECIMAL6_2                      width_value             {XPATH('SectionWidth')};
            DECIMAL6_2                      observed_mass           {XPATH('ObservedMass')};
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
            SectionRec                      section                 {XPATH('YieldData/Section')};
        END;

        EXPORT Layout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(YieldSeedRecord)        yield_seed_records      {XPATH('YieldSeedRecords')};
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
                LEFT.yield_seed_records,
                TRANSFORM
                    (
                        {
                            Layout.created_on_datetime,
                            Layout.field_id,
                            UNSIGNED4   sample_id;
                            YieldSeedRecord
                        },
                        SELF.sample_id := COUNTER,
                        SELF := LEFT,
                        SELF := RIGHT
                    )
            );

    END; // Raw Module

END;