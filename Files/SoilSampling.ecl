IMPORT Proagrica;

EXPORT SoilSampling := MODULE

    EXPORT Raw := MODULE

        SHARED UnitIDRec := RECORD
            UNSIGNED2                       unit_id                 {XPATH('UnitID/Value')};
            UNSIGNED2                       unit_agx_att_id         {XPATH('UnitID/AgXAttID')};
        END;

        SHARED Measurement := RECORD
            DECIMAL6_2                      measure                 {XPATH('Measure/Value')};
            UnitIDRec;
        END;

        SHARED DepthRec := RECORD
            DECIMAL6_2                      measure                 {XPATH('Depth/Value')};
            UnitIDRec;
        END;

        SHARED PValueRec := RECORD
            DECIMAL6_2                      extraction_method_id    {XPATH('ExtractionMethodID/Value')};
            Measurement                     observed_p              {XPATH('ObservedP')};
        END;

        SHARED SoilSamplingData := RECORD
            STRING                          xy                      {XPATH('XY')};
            DepthRec                        depth                   {XPATH('SoilSamplingData/TopsoilSamplingDepth')};
            DECIMAL6_2                      soil_ph                 {XPATH('SoilSamplingData/Soil_pH/Value')};
            DECIMAL6_2                      buffer_ph               {XPATH('SoilSamplingData/Buffer_pH/Value')};
            DATASET(PValueRec)              p_values                {XPATH('SoilSamplingData/P')};
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

        EXPORT RawFile(STRING path) := DATASET
            (
                path,
                Layout,
                JSON('', NOROOT),
                OPT
            );

        EXPORT File(STRING path) := NORMALIZE
            (
                RawFile(path),
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
            DECIMAL14_6     x_coord;
            DECIMAL14_6     y_coord;
        END;

        EXPORT File(STRING path) := PROJECT
            (
                Raw.File(path),
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

    //--------------------------------------------------------------------------

    EXPORT Working := MODULE

        EXPORT Layout := Enhanced.Layout;

        EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::generated_soil_samples';

        EXPORT File(STRING path = DEFAULT_PATH) := DATASET(path, Layout, FLAT);

    END; // Working Module

END;
