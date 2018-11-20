IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: File Read Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

// SOIL_FILENAME := 'soil_sampling_format.json';
// SOIL_FILENAME := 'soil_sampling_generated_02.json';
// SOIL_FILENAME := 'soil_sampling_generated_03.json';

soilSampleFilePattern := Proagrica.Files.Constants.PATH_PREFIX_SCOPE + '::soil_samples_01::*';
soilSampleFileList := NOTHOR(Std.File.LogicalFileList(soilSampleFilePattern));
SOIL_FILENAME := '~{' + Std.Str.CombineWords(SET(soilSampleFileList, name), ',') + '}';

// soilSampleRawData := Proagrica.Files.SoilSampling.Raw.RawFile(SOIL_FILENAME);
// Dbg(soilSampleRawData);

normalizedSoilSampleRawData := Proagrica.Files.SoilSampling.Raw.File(SOIL_FILENAME);
Dbg(normalizedSoilSampleRawData);
Dbg(COUNT(normalizedSoilSampleRawData), 'normalizedSoilSampleRawData_cnt');

enhancedSoilSampleRawData := Proagrica.Files.SoilSampling.Enhanced.File(SOIL_FILENAME);
Dbg(enhancedSoilSampleRawData);
Dbg(COUNT(enhancedSoilSampleRawData), 'enhancedSoilSampleRawData_cnt');

//------------------------------------------------------------------------------

GENERATED_SOIL_FILENAME := Proagrica.Files.SoilSampling.Working.DEFAULT_PATH;

etlSoilSampleData := Proagrica.Files.SoilSampling.Working.File(GENERATED_SOIL_FILENAME);
Dbg(etlSoilSampleData);
Dbg(COUNT(etlSoilSampleData), 'etlSoilSampleData_cnt');

//------------------------------------------------------------------------------

EC_FILENAME := Proagrica.Util.MakePath('ec_format.json');

// ecSampleRawData := Proagrica.Files.EC.Raw.RawFile(EC_FILENAME);
// Dbg(ecSampleRawData);

normalizedECSampleRawData := Proagrica.Files.EC.Raw.File(EC_FILENAME);
Dbg(normalizedECSampleRawData);

//------------------------------------------------------------------------------

YIELD_FILENAME := Proagrica.Util.MakePath('yield_format.json');

// yieldSampleRawData := Proagrica.Files.Yield.Raw.RawFile(YIELD_FILENAME);
// Dbg(yieldSampleRawData);

normalizedYieldSampleRawData := Proagrica.Files.Yield.Raw.File(YIELD_FILENAME);
Dbg(normalizedYieldSampleRawData);
Dbg(COUNT(normalizedYieldSampleRawData), 'normalizedYieldSampleRawData_cnt');
