IMPORT Proagrica;
IMPORT Std;

EXPORT Combined := MODULE

    EXPORT Temp := MODULE

        SHARED DepthRec := RECORD
            DECIMAL6_2          measure                 {XPATH('Depth/Value')};
            UNSIGNED2           unit_id                 {XPATH('UnitID/Value')};
            UNSIGNED2           unit_agx_att_id         {XPATH('UnitID/AgXAttID')};
        END;

        SHARED Measurement := RECORD
            DECIMAL6_2          measure                 {XPATH('Measure/Value')};
            UNSIGNED2           unit_id                 {XPATH('UnitID/Value')};
            UNSIGNED2           unit_agx_att_id         {XPATH('UnitID/AgXAttID')};
        END;

        SHARED PValueRec := RECORD
            DECIMAL6_2          extraction_method_id    {XPATH('ExtractionMethodID/Value')};
            Measurement         observed_p              {XPATH('ObservedP')};
        END;

        SHARED Measurement___1 := RECORD
            DECIMAL6_2          measure                 {XPATH('Measure/Value')};
            UNSIGNED2           unit_id                 {XPATH('UnitID/Value')};
        END;

        SHARED ECDataWithIDW := RECORD
            STRING              id                      {XPATH('ID')};
            Measurement___1     elevation               {XPATH('Elevation')};
            Measurement___1     speed                   {XPATH('Speed')};
            DECIMAL6_2          red                     {XPATH('Red/Value')};
            DECIMAL6_2          ir                      {XPATH('IR/Value')};
            Measurement___1     shallow                 {XPATH('ECShallow')};
            Measurement___1     deep                    {XPATH('ECDeep')};
            DECIMAL6_2          slope                   {XPATH('Slope/Value')};
            DECIMAL6_2          curve                   {XPATH('Curve/Value')};
            Measurement___1     ec02                    {XPATH('EC0_2')};
            Measurement___1     dipole                  {XPATH('Dipole')};
            Measurement___1     om                      {XPATH('OM')};
            Measurement___1     ced                     {XPATH('CEC')};
            DECIMAL7_6          idw;
        END;

        SHARED YieldDataWithIDW := RECORD
            STRING              id                      {XPATH('ID')};
            UNSIGNED2           crop_id                 {XPATH('CropID/Value')};
            UNSIGNED2           season_id               {XPATH('SeasonID/Value')};
            DECIMAL6_2          adjusted_moisture       {XPATH('YieldSeedData/AdjMoisture')};
            STRING              observation_date        {XPATH('YieldData/ObservationDate')};
            INTEGER2            observation_year;
            DECIMAL6_2          yield_value;
            DECIMAL6_2          adjusted_mass           {XPATH('AdjustedMass')};
            DECIMAL6_2          area                    {XPATH('Area')};
            DECIMAL7_6          idw;
        END;

        EXPORT Layout := RECORD
            STRING              created_on_datetime     {XPATH('CreatedOn')};
            STRING              id                      {XPATH('ID')};
            STRING              field_id                {XPATH('FieldID')};
            UNSIGNED2           season_id               {XPATH('SeasonID/Value')};
            UNSIGNED4           sample_id;
            DepthRec            depth                   {XPATH('SoilSamplingData/TopsoilSamplingDepth')};
            DECIMAL6_2          soil_ph                 {XPATH('SoilSamplingData/Soil_pH/Value')};
            DECIMAL6_2          buffer_ph               {XPATH('SoilSamplingData/Buffer_pH/Value')};
            Measurement         k                       {XPATH('SoilSamplingData/K')};
            Measurement         no3                     {XPATH('SoilSamplingData/NO3_N')};
            Measurement         ca                      {XPATH('SoilSamplingData/Ca')};
            Measurement         mg                      {XPATH('SoilSamplingData/Mg')};
            Measurement         cec                     {XPATH('SoilSamplingData/CationExchangeCapacity/CEC')};
            UDECIMAL6_2         percent_k               {XPATH('SoilSamplingData/CationExchangeCapacity/PercentK/Value')};
            UDECIMAL6_2         percent_ca              {XPATH('SoilSamplingData/CationExchangeCapacity/PercentCa/Value')};
            UDECIMAL6_2         percent_mg              {XPATH('SoilSamplingData/CationExchangeCapacity/PercentMg/Value')};
            UDECIMAL6_2         percent_na              {XPATH('SoilSamplingData/CationExchangeCapacity/PercentNa/Value')};
            Measurement         s                       {XPATH('SoilSamplingData/S')};
            Measurement         zn                      {XPATH('SoilSamplingData/Zn')};
            Measurement         om                      {XPATH('SoilSamplingData/OrganicMatter')};
            Measurement         sand                    {XPATH('SoilSamplingData/SoilTexture/Sand')};
            Measurement         silt                    {XPATH('SoilSamplingData/SoilTexture/Silt')};
            Measurement         clay                    {XPATH('SoilSamplingData/SoilTexture/Clay')};
            Measurement         stone                   {XPATH('SoilSamplingData/SoilTexture/Stone')};
            PValueRec           p_value;
            DECIMAL14_6         utm_x;
            DECIMAL14_6         utm_y;
            UNSIGNED1           utm_zone;
            ECDataWithIDW       ec;
            YieldDataWithIDW    yield;
        END;

        EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::combined_temp';

        EXPORT File(STRING path = DEFAULT_PATH) := DISTRIBUTED(DATASET(path, Layout, FLAT), HASH32(field_id));

    END; // Temp Module

    //--------------------------------------------------------------------------

    EXPORT Working := MODULE

        EXPORT Layout := RECORD
            STRING              created_on_datetime;
            STRING              id;
            STRING              field_id;
            UNSIGNED2           season_id;
            UNSIGNED4           sample_id;
            DECIMAL6_2          depth_measure;
            UNSIGNED2           depth_unit_id;
            UNSIGNED2           depth_unit_agx_att_id;
            DECIMAL6_2          soil_ph;
            DECIMAL6_2          buffer_ph;
            DECIMAL6_2          k_measure;
            UNSIGNED2           k_unit_id;
            DECIMAL6_2          no3_measure;
            UNSIGNED2           no3_unit_id;
            DECIMAL6_2          ca_measure;
            UNSIGNED2           ca_unit_id;
            DECIMAL6_2          mg_measure;
            UNSIGNED2           mg_unit_id;
            DECIMAL6_2          cec_measure;
            UNSIGNED2           cec_unit_id;
            UDECIMAL6_2         percent_k;
            UDECIMAL6_2         percent_ca;
            UDECIMAL6_2         percent_mg;
            UDECIMAL6_2         percent_na;
            DECIMAL6_2          s_measure;
            UNSIGNED2           s_unit_id;
            DECIMAL6_2          zn_measure;
            UNSIGNED2           zn_unit_id;
            DECIMAL6_2          om_measure;
            UNSIGNED2           om_unit_id;
            DECIMAL6_2          sand_measure;
            UNSIGNED2           sand_unit_id;
            DECIMAL6_2          silt_measure;
            UNSIGNED2           silt_unit_id;
            DECIMAL6_2          clay_measure;
            UNSIGNED2           clay_unit_id;
            DECIMAL6_2          stone_measure;
            UNSIGNED2           stone_unit_id;
            DECIMAL6_2          p_value_extraction_method_id;
            DECIMAL6_2          p_value_observed_p_measure;
            UNSIGNED2           p_value_observed_p_unit_id;
            DECIMAL14_6         utm_x;
            DECIMAL14_6         utm_y;
            UNSIGNED1           utm_zone;
            STRING              ec_id;
            DECIMAL6_2          ec_elevation_measure;
            UNSIGNED2           ec_elevation_unit_id;
            DECIMAL6_2          ec_speed_measure;
            UNSIGNED2           ec_speed_unit_id;
            DECIMAL6_2          ec_red;
            DECIMAL6_2          ec_ir;
            DECIMAL6_2          ec_shallow_measure;
            UNSIGNED2           ec_shallow_unit_id;
            DECIMAL6_2          ec_deep_measure;
            UNSIGNED2           ec_deep_unit_id;
            DECIMAL6_2          ec_slope;
            DECIMAL6_2          ec_curve;
            DECIMAL6_2          ec_ec02_measure;
            UNSIGNED2           ec_ec02_unit_id;
            DECIMAL6_2          ec_dipole_measure;
            UNSIGNED2           ec_dipole_unit_id;
            DECIMAL6_2          ec_om_measure;
            UNSIGNED2           ec_om_unit_id;
            DECIMAL6_2          ec_ced_measure;
            UNSIGNED2           ec_ced_unit_id;
            STRING              yield_id;
            UNSIGNED2           yield_crop_id;
            UNSIGNED2           yield_season_id;
            DECIMAL6_2          yield_adjusted_moisture;
            STRING              yield_observation_date;
            INTEGER2            yield_observation_year;
            DECIMAL6_2          yield_yield_value;
            DECIMAL6_2          yield_adjusted_mass;
            DECIMAL6_2          yield_area;
        END;

        EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::combined';

        EXPORT File(STRING path = DEFAULT_PATH) := DISTRIBUTED(DATASET(path, Layout, FLAT), HASH32(field_id));

    END; // Working Module

END;
