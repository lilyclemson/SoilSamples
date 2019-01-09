IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Create Combined');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

soilSampleData := Proagrica.Files.SoilSampling.Working.File(); // Already distributed on HASH32(field_id)
ecData := Proagrica.Files.EC.Working.File(); // Already distributed on HASH32(field_id)
yieldData := Proagrica.Files.Yield.Working.File(); // Already distributed on HASH32(field_id)
idwLookup := Proagrica.Files.IDW.File();

ecWithIDW := JOIN
    (
        ecData,
        idwLookup,
        LEFT.utm_x = RIGHT.other_utm_x
            AND LEFT.utm_y = RIGHT.other_utm_y,
        TRANSFORM
            (
                {
                    RECORDOF(LEFT),
                    Proagrica.Files.IDW.Layout.soil_sample_utm_x,
                    Proagrica.Files.IDW.Layout.soil_sample_utm_y,
                    Proagrica.Files.IDW.Layout.idw
                },
                SELF := LEFT,
                SELF := RIGHT
            )
    );

yieldWithIDW := JOIN
    (
        yieldData,
        idwLookup,
        LEFT.utm_x = RIGHT.other_utm_x
            AND LEFT.utm_y = RIGHT.other_utm_y,
        TRANSFORM
            (
                {
                    RECORDOF(LEFT),
                    Proagrica.Files.IDW.Layout.soil_sample_utm_x,
                    Proagrica.Files.IDW.Layout.soil_sample_utm_y,
                    Proagrica.Files.IDW.Layout.idw
                },
                SELF := LEFT,
                SELF := RIGHT
            )
    );

//------------------------------------------------------------------------------

MoveMeasure(area, sym) := MACRO
    SELF.area.sym.measure := LEFT.area.sym.measure + (RIGHT.area.sym.measure * RIGHT.area.idw),
    SELF.area.sym.unit_id := RIGHT.area.sym.unit_id
ENDMACRO;

MoveSimple(area, sym) := MACRO
    SELF.area.sym := LEFT.area.sym + (RIGHT.area.sym * RIGHT.area.idw)
ENDMACRO;

NormMeasure(area, sym) := MACRO
    SELF.area.sym.measure := LEFT.area.sym.measure / LEFT.area.idw,
    SELF.area.sym.unit_id := LEFT.area.sym.unit_id
ENDMACRO;

NormSimple(area, sym) := MACRO
    SELF.area.sym := LEFT.area.sym / LEFT.area.idw
ENDMACRO;

//------------------------------------------------------------------------------

ECDataWithIDW := RECORD
    RECORDOF(ecData) - [created_on_datetime, field_id, season_id, sample_id, longitude, latitude, utm_x, utm_y, utm_zone];
    Proagrica.Files.IDW.Layout.idw;
END;

ecWeight1 := JOIN
    (
        soilSampleData,
        ecWithIDW,
        LEFT.utm_x = RIGHT.soil_sample_utm_x
            AND LEFT.utm_y = RIGHT.soil_sample_utm_y,
        TRANSFORM
            (
                {
                    RECORDOF(soilSampleData),
                    RECORDOF(ECDataWithIDW)     ec
                },
                SELF.ec := RIGHT,
                SELF := LEFT
            )
    );

ecWeight2 := ROLLUP
    (
        SORT(ecWeight1, utm_x, utm_y, ec.id),
        TRANSFORM
            (
                RECORDOF(LEFT),
                SELF.ec.id := RIGHT.ec.id,
                MoveMeasure(ec, elevation),
                MoveMeasure(ec, speed),
                MoveSimple(ec, red),
                MoveSimple(ec, ir),
                MoveMeasure(ec, shallow),
                MoveMeasure(ec, deep),
                MoveSimple(ec, slope),
                MoveSimple(ec, curve),
                MoveMeasure(ec, ec02),
                MoveMeasure(ec, dipole),
                MoveMeasure(ec, om),
                MoveMeasure(ec, ced),
                SELF.ec.idw := LEFT.ec.idw + RIGHT.ec.idw,
                SELF := RIGHT
            ),
        utm_x, utm_y, ec.id
    );

ecWeight3 := PROJECT
    (
        ecWeight2,
        TRANSFORM
            (
                RECORDOF(LEFT),
                NormMeasure(ec, elevation),
                NormMeasure(ec, speed),
                NormSimple(ec, red),
                NormSimple(ec, ir),
                NormMeasure(ec, shallow),
                NormMeasure(ec, deep),
                NormSimple(ec, slope),
                NormSimple(ec, curve),
                NormMeasure(ec, ec02),
                NormMeasure(ec, dipole),
                NormMeasure(ec, om),
                NormMeasure(ec, ced),
                SELF := LEFT
            )
    );

//------------------------------------------------------------------------------

YieldDataWithIDW := RECORD
    RECORDOF(yieldData) - [created_on_datetime, field_id, sample_id, longitude, latitude, utm_x, utm_y, utm_zone, observed_moisture, observed_mass, elevation, distance, heading_value, speed, is_active, width_value];
    Proagrica.Files.IDW.Layout.idw;
END;

yieldWeight1 := JOIN
    (
        soilSampleData,
        yieldWithIDW,
        LEFT.utm_x = RIGHT.soil_sample_utm_x
            AND LEFT.utm_y = RIGHT.soil_sample_utm_y
            AND LEFT.season_id = RIGHT.season_id,
        TRANSFORM
            (
                {
                    RECORDOF(soilSampleData),
                    RECORDOF(YieldDataWithIDW)     yield
                },
                SELF.yield := RIGHT,
                SELF := LEFT
            )
    );

yieldWeight2 := ROLLUP
    (
        SORT(yieldWeight1, utm_x, utm_y, season_id, yield.id),
        TRANSFORM
            (
                RECORDOF(LEFT),
                SELF.yield.id := RIGHT.yield.id,
                MoveSimple(yield, adjusted_moisture),
                SELF.yield.observation_date := RIGHT.yield.observation_date,
                SELF.yield.observation_year := RIGHT.yield.observation_year,
                MoveSimple(yield, yield_value),
                MoveSimple(yield, adjusted_mass),
                MoveSimple(yield, area),
                SELF.yield.idw := LEFT.yield.idw + RIGHT.yield.idw,
                SELF := RIGHT
            ),
        utm_x, utm_y, season_id, yield.id
    );

//------------------------------------------------------------------------------

res1 := JOIN
    (
        ecWeight3,
        yieldWeight2,
        LEFT.id = RIGHT.id
            AND LEFT.field_id = RIGHT.field_id
            AND LEFT.sample_id = RIGHT.sample_id,
        TRANSFORM
            (
                Proagrica.Files.Combined.Temp.Layout,
                SELF.ec := LEFT.ec,
                SELF.yield := RIGHT.yield,
                SELF := LEFT
            )
    );

res2 := PROJECT
    (
        res1,
        TRANSFORM
            (
                Proagrica.Files.Combined.Working.Layout,
                SELF.depth_measure := LEFT.depth.measure,
                SELF.depth_unit_id := LEFT.depth.unit_id,
                SELF.depth_unit_agx_att_id := LEFT.depth.unit_agx_att_id,
                SELF.k_measure := LEFT.k.measure,
                SELF.k_unit_id := LEFT.k.unit_id,
                SELF.no3_measure := LEFT.no3.measure,
                SELF.no3_unit_id := LEFT.no3.unit_id,
                SELF.ca_measure := LEFT.ca.measure,
                SELF.ca_unit_id := LEFT.ca.unit_id,
                SELF.mg_measure := LEFT.mg.measure,
                SELF.mg_unit_id := LEFT.mg.unit_id,
                SELF.cec_measure := LEFT.cec.measure,
                SELF.cec_unit_id := LEFT.cec.unit_id,
                SELF.s_measure := LEFT.s.measure,
                SELF.s_unit_id := LEFT.s.unit_id,
                SELF.zn_measure := LEFT.zn.measure,
                SELF.zn_unit_id := LEFT.zn.unit_id,
                SELF.om_measure := LEFT.om.measure,
                SELF.om_unit_id := LEFT.om.unit_id,
                SELF.sand_measure := LEFT.sand.measure,
                SELF.sand_unit_id := LEFT.sand.unit_id,
                SELF.silt_measure := LEFT.silt.measure,
                SELF.silt_unit_id := LEFT.silt.unit_id,
                SELF.clay_measure := LEFT.clay.measure,
                SELF.clay_unit_id := LEFT.clay.unit_id,
                SELF.stone_measure := LEFT.stone.measure,
                SELF.stone_unit_id := LEFT.stone.unit_id,
                SELF.p_value_extraction_method_id := LEFT.p_value.extraction_method_id,
                SELF.p_value_observed_p_measure := LEFT.p_value.observed_p.measure,
                SELF.p_value_observed_p_unit_id := LEFT.p_value.observed_p.unit_id,
                SELF.ec_id := LEFT.ec.id,
                SELF.ec_elevation_measure := LEFT.ec.elevation.measure,
                SELF.ec_elevation_unit_id := LEFT.ec.elevation.unit_id,
                SELF.ec_speed_measure := LEFT.ec.speed.measure,
                SELF.ec_speed_unit_id := LEFT.ec.speed.unit_id,
                SELF.ec_red := LEFT.ec.red,
                SELF.ec_ir := LEFT.ec.ir,
                SELF.ec_shallow_measure := LEFT.ec.shallow.measure,
                SELF.ec_shallow_unit_id := LEFT.ec.shallow.unit_id,
                SELF.ec_deep_measure := LEFT.ec.deep.measure,
                SELF.ec_deep_unit_id := LEFT.ec.deep.unit_id,
                SELF.ec_slope := LEFT.ec.slope,
                SELF.ec_curve := LEFT.ec.curve,
                SELF.ec_ec02_measure := LEFT.ec.ec02.measure,
                SELF.ec_ec02_unit_id := LEFT.ec.ec02.unit_id,
                SELF.ec_dipole_measure := LEFT.ec.dipole.measure,
                SELF.ec_dipole_unit_id := LEFT.ec.dipole.unit_id,
                SELF.ec_om_measure := LEFT.ec.om.measure,
                SELF.ec_om_unit_id := LEFT.ec.om.unit_id,
                SELF.ec_ced_measure := LEFT.ec.ced.measure,
                SELF.ec_ced_unit_id := LEFT.ec.ced.unit_id,
                SELF.yield_id := LEFT.yield.id,
                SELF.yield_crop_id := LEFT.yield.crop_id,
                SELF.yield_season_id := LEFT.yield.season_id,
                SELF.yield_adjusted_moisture := LEFT.yield.adjusted_moisture,
                SELF.yield_observation_date := LEFT.yield.observation_date,
                SELF.yield_observation_year := LEFT.yield.observation_year,
                SELF.yield_yield_value := LEFT.yield.yield_value,
                SELF.yield_adjusted_mass := LEFT.yield.adjusted_mass,
                SELF.yield_area := LEFT.yield.area,
                SELF := LEFT
            )
    );

res3 := DISTRIBUTE(res2, HASH32(field_id));

OUTPUT(res3, /* ResultRec */, Proagrica.Files.Combined.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);

// Also write as a .csv file
headerText := 'created_on_datetime,id,field_id,season_id,sample_id,depth_measure,depth_unit_id,depth_unit_agx_att_id,soil_ph,buffer_ph,k_measure,k_unit_id,no3_measure,no3_unit_id,ca_measure,ca_unit_id,mg_measure,mg_unit_id,cec_measure,cec_unit_id,percent_k,percent_ca,percent_mg,percent_na,s_measure,s_unit_id,zn_measure,zn_unit_id,om_measure,om_unit_id,sand_measure,sand_unit_id,silt_measure,silt_unit_id,clay_measure,clay_unit_id,stone_measure,stone_unit_id,p_value_extraction_method_id,p_value_observed_p_measure,p_value_observed_p_unit_id,utm_x,utm_y,utm_zone,ec_id,ec_elevation_measure,ec_elevation_unit_id,ec_speed_measure,ec_speed_unit_id,ec_red,ec_ir,ec_shallow_measure,ec_shallow_unit_id,ec_deep_measure,ec_deep_unit_id,ec_slope,ec_curve,ec_ec02_measure,ec_ec02_unit_id,ec_dipole_measure,ec_dipole_unit_id,ec_om_measure,ec_om_unit_id,ec_ced_measure,ec_ced_unit_id,yield_id,yield_crop_id,yield_season_id,yield_adjusted_moisture,yield_observation_date,yield_observation_year,yield_yield_value,yield_adjusted_mass,yield_area\n';
OUTPUT(res3, /* ResultRec */, Proagrica.Files.Combined.Working.DEFAULT_PATH + '.csv', CSV(HEADING(headerText, SINGLE)), OVERWRITE, COMPRESSED);
