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
            STRING                          wkt                     {XPATH('WKT')};
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

        SHARED RawLayout := RECORD
            STRING                          created_on_datetime     {XPATH('CreatedOn')};
            STRING                          id                      {XPATH('ID')};
            STRING                          field_id                {XPATH('FieldID')};
            UNSIGNED2                       season_id               {XPATH('SeasonID/Value')};
            DATASET(SoilSamplingData)       soil_samples            {XPATH('SoilSamplingRecords')};
        END;

        EXPORT RawFile(STRING path) := DATASET
            (
                path,
                RawLayout,
                JSON, // JSON('', NOROOT),
                OPT
            );
        
        //------------------------------------

        // First normalization
        SHARED Layout1 := RECORD
            RawLayout.created_on_datetime;
            RawLayout.id;
            RawLayout.field_id;
            RawLayout.season_id;
            UNSIGNED4   sample_id;
            SoilSamplingData;
        END;

        SHARED File1(STRING path) := FUNCTION
            cachePath := Proagrica.Files.Constants.PATH_PREFIX + '::cache::soil_samples_spray';
            baseData := DISTRIBUTE(RawFile(path), HASH32(field_id)) : PERSIST(cachePath, SINGLE);
            ds := NORMALIZE
                (
                    baseData,
                    LEFT.soil_samples,
                    TRANSFORM
                        (
                            Layout1,
                            SELF.sample_id := COUNTER,
                            SELF := LEFT,
                            SELF := RIGHT
                        )
                );
            
            RETURN ds;
        END;
        
        //---------------

        // Second normalization
        SHARED Layout2 := RECORD
            {Layout1 - [p_values]};
            PValueRec       p_value;
        END;

        SHARED File2(STRING path) := NORMALIZE
            (
                File1(path),
                LEFT.p_values,
                TRANSFORM
                    (
                        Layout2,
                        SELF.p_value := RIGHT,
                        SELF := LEFT
                    )
            );
        
        //--------------------
        
        EXPORT Layout := Layout2;

        EXPORT File(STRING path) := File2(path);

    END; // Raw Module

    //--------------------------------------------------------------------------

    EXPORT Enhanced := MODULE

        EXPORT Layout := RECORD
            RECORDOF(Raw.File(''));
            BOOLEAN         has_lat_lon;
            DECIMAL9_6      latitude;
            DECIMAL9_6      longitude;
            DECIMAL14_6     utm_x;
            DECIMAL14_6     utm_y;
            UNSIGNED1       utm_zone;
        END;

        EXPORT File(STRING path) := FUNCTION
            ds := Raw.File(path);

            LatLonLayout := RECORD
                RECORDOF(Raw.File(''));
                BOOLEAN         has_lat_lon;
                DECIMAL9_6      latitude;
                DECIMAL9_6      longitude;
            END;

            withLatLon := PROJECT
                (
                    ds,
                    TRANSFORM
                        (
                            LatLonLayout,

                            coordinates := Proagrica.Util.PointToLatLon(LEFT.wkt);

                            SELF.has_lat_lon := coordinates.isValid,
                            SELF.latitude := coordinates.latitude,
                            SELF.longitude := coordinates.longitude,
                            SELF := LEFT
                        )
                );

            initialZones := TABLE
                (
                    withLatLon,
                    {
                        field_id,
                        UNSIGNED1   zone := Proagrica.UTM.LongitudeToZone(MIN(GROUP, longitude))
                    },
                    field_id,
                    LOCAL
                );
            
            newDS := JOIN
                (
                    withLatLon,
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

        EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::soil_samples';

        EXPORT File(STRING path = DEFAULT_PATH) := DATASET(path, Layout, FLAT);

    END; // Working Module

END;
