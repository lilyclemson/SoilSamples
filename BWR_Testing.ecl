IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: File Read Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

soilSampleFilePattern := Proagrica.Files.Constants.PATH_PREFIX_SCOPE + '::soil_samples::*';
soilSampleFileList := NOTHOR(Std.File.LogicalFileList(soilSampleFilePattern));
SOIL_FILENAME := '~{' + Std.Str.CombineWords(SET(soilSampleFileList, name), ',') + '}';

enhancedSoilSampleRawData := Proagrica.Files.SoilSampling.Enhanced.File(SOIL_FILENAME);
Dbg(enhancedSoilSampleRawData);
