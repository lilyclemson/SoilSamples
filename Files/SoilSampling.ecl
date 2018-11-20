IMPORT Proagrica;

EXPORT SoilSampling := MODULE

    EXPORT Raw := MODULE

        SHARED Measurement := RECORD
            DECIMAL6_2                      measure                 {XPATH('Measure/Value')};
            UNSIGNED2                       unit_id                 {XPATH('UnitID/Value')};
            UNSIGNED2                       unit_agx_att_id         {XPATH('UnitID/AgXAttID')};
        END;

        SHARED SoilSamplingData := RECORD
            STRING                          xy                      {XPATH('XY')};
            UDECIMAL4_2                     depth                   {XPATH('SoilSamplingData/TopsoilSamplingDepth/Depth/Value')};
            DECIMAL6_2                      soil_ph                 {XPATH('SoilSamplingData/Soil_pH/Value')};
            DECIMAL6_2                      buffer_ph               {XPATH('SoilSamplingData/Buffer_pH/Value')};
            DATASET(Measurement)            p_values                {XPATH('SoilSamplingData/P/ObservedP')};
            Measurement                     k                       {XPATH('SoilSamplingData/K')};
            Measurement                     no3                     {XPATH('SoilSamplingData/NO3_N')};
            Measurement                     ca                      {XPATH('SoilSamplingData/Ca')};
            Measurement                     mg                      {XPATH('SoilSamplingData/Mg')};
            Measurement                     cec                     {XPATH('SoilSamplingData/CationExchangeCapacity/CEC')};
            UDECIMAL6_2                     percent_k               {XPATH('SoilSamplingData/CationExchangeCapacity/PercentK/Value')};
            UDECIMAL6_2                     percent_ca              {XPATH('SoilSamplingData/CationExchangeCapacity/PercentCa/Value')};
            UDECIMAL6_2                     percent_mg              {XPATH('SoilSamplingData/CationExchangeCapacity/PercentMg/Value')};
            UDECIMAL6_2                     percent_na              {XPATH('SoilSamplingData/CationExchangeCapacity/PercentNa/Value')};
            Measurement                     s                       {XPATH('SoilSamplingData/S')};
            Measurement                     zn                      {XPATH('SoilSamplingData/Zn')};
            Measurement                     om                      {XPATH('SoilSamplingData/OrganicMatter')};
            Measurement                     sand                    {XPATH('SoilSamplingData/SoilTexture/Sand')};
            Measurement                     silt                    {XPATH('SoilSamplingData/SoilTexture/Silt')};
            Measurement                     clay                    {XPATH('SoilSamplingData/SoilTexture/Clay')};
            Measurement                     stone                   {XPATH('SoilSamplingData/SoilTexture/Stone')};
        END;

        EXPORT Layout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(SoilSamplingData)       soil_samples            {XPATH('SoilSamplingRecords')};
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
                LEFT.soil_samples,
                TRANSFORM
                    (
                        {
                            Layout.created_on_datetime,
                            Layout.field_id,
                            UNSIGNED4   sample_id;
                            SoilSamplingData
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
            BOOLEAN         has_x_y;
            DECIMAL12_6     x_coord;
            DECIMAL12_6     y_coord;
        END;

        EXPORT File(STRING pathLeafName) := PROJECT
            (
                Raw.File(pathLeafName),
                TRANSFORM
                    (
                        Layout,

                        coordinates := Proagrica.Util.PointToUTM(LEFT.xy);

                        SELF.has_x_y := coordinates.isValid,
                        SELF.x_coord := coordinates.x,
                        SELF.y_coord := coordinates.y,
                        SELF := LEFT
                    )
            );

    END; // Enhanced Module

END;
