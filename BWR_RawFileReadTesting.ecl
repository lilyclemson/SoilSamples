IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Raw File Read Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

SOIL_FILENAME := Std.File.ExternalLogicalFileName('10.0.0.13', '/var/lib/HPCCSystems/mydropzone/uploads/soil_samples_combined.json');

enhancedSoilSampleRawData := Proagrica.Files.SoilSampling.Enhanced.File(SOIL_FILENAME);
Dbg(enhancedSoilSampleRawData);
// Dbg(COUNT(enhancedSoilSampleRawData), 'enhancedSoilSampleRawData_cnt');

//------------------------------------------------------------------------------

EC_FILENAME := Std.File.ExternalLogicalFileName('10.0.0.13', '/var/lib/HPCCSystems/mydropzone/uploads/ec_combined.json');

enhancedECSampleRawData := Proagrica.Files.EC.Enhanced.File(EC_FILENAME);
Dbg(enhancedECSampleRawData);

//------------------------------------------------------------------------------

YIELD_FILENAME := Std.File.ExternalLogicalFileName('10.0.0.13', '/var/lib/HPCCSystems/mydropzone/uploads/yield_combined.json');

enhancedYieldSampleRawData := Proagrica.Files.Yield.Enhanced.File(YIELD_FILENAME);
Dbg(enhancedYieldSampleRawData);
