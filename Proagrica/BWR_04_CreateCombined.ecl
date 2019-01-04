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
    SELF.area.sym.measure := LEFT.area.sym.measure * LEFT.area.idw,
    SELF.area.sym.unit_id := LEFT.area.sym.unit_id
ENDMACRO;

NormSimple(area, sym) := MACRO
    SELF.area.sym := LEFT.area.sym * LEFT.area.idw
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
                Proagrica.Files.Combined.Working.Layout,
                SELF.ec := LEFT.ec,
                SELF.yield := RIGHT.yield,
                SELF := LEFT
            )
    );

res2 := DISTRIBUTE(res1, HASH32(field_id));

OUTPUT(res2, /* ResultRec */, Proagrica.Files.Combined.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);
