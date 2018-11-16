IMPORT $;
IMPORT Proagrica;

EXPORT SoilSampling := MODULE

    EXPORT Raw := MODULE

        SHARED Measurement := RECORD
            DECIMAL6_2                      measure                 {XPATH('Measure/Value')};
            UNSIGNED2                       unit_id                 {XPATH('UnitID/Value')};
        END;

        SHARED SoilSamplingData := RECORD
            STRING                          wkt_type                {XPATH('WKTTypeID')};
            STRING                          wkt                     {XPATH('WKT')};
            UDECIMAL4_2                     depth                   {XPATH('SoilSamplingData/TopsoilSamplingDepth/Depth/Value')};
            DECIMAL6_2                      soil_ph                 {XPATH('SoilSamplingData/Soil_pH/Value')};
            DECIMAL6_2                      buffer_ph               {XPATH('SoilSamplingData/Buffer_pH/Value')};
            DATASET(Measurement)            p_values                {XPATH('SoilSamplingData/P/ObservedP')};
            Measurement                     k                       {XPATH('SoilSamplingData/K')};
            Measurement                     no3                     {XPATH('SoilSamplingData/NO3_N')};
            Measurement                     ca                      {XPATH('SoilSamplingData/Ca')};
            Measurement                     mg                      {XPATH('SoilSamplingData/Mg')};
            Measurement                     ce                      {XPATH('SoilSamplingData/CationExchangeCapacity/CEC')};
            Measurement                     s                       {XPATH('SoilSamplingData/S')};
            Measurement                     zn                      {XPATH('SoilSamplingData/Zn')};
            Measurement                     om                      {XPATH('SoilSamplingData/OrganicMatter')};
        END;

        EXPORT Layout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          field_id                {XPATH('FieldID')};
            DATASET(SoilSamplingData)       soil_samples            {XPATH('SoilSamplingRecords')};
        END;

        EXPORT PATH := $.Constants.PATH_PREFIX + '::soil_sampling_format.json';

        EXPORT File := DATASET(PATH, Layout, JSON('', NOROOT));

        EXPORT Normalized := NORMALIZE
            (
                File,
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
            RECORDOF(Raw.Normalized);
            BOOLEAN         hasLonLat;
            DECIMAL9_6      longitude;
            DECIMAL9_6      latitude;
        END;

        EXPORT File := PROJECT
            (
                Raw.Normalized,
                TRANSFORM
                    (
                        Layout,

                        coordinates := Proagrica.Util.PointToLatLon(LEFT.wkt);

                        SELF.hasLonLat := coordinates.isValid,
                        SELF.longitude := coordinates.longitude,
                        SELF.latitude := coordinates.latitude,
                        SELF := LEFT
                    )
            );

    END; // Enhanced Module

END;
