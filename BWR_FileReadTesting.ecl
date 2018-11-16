IMPORT Proagrica;

#WORKUNIT('name', 'Proagrica: File Read Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

soilSampleRawData := Proagrica.Files.SoilSampling.Raw.rawFile;
Dbg(soilSampleRawData);

normalizedSoilSampleRawData := Proagrica.Files.SoilSampling.Raw.file;
Dbg(normalizedSoilSampleRawData);

enhancedSoilSampleRawData := Proagrica.Files.SoilSampling.Enhanced.file;
Dbg(enhancedSoilSampleRawData);

//------------------------------------------------------------------------------

ecSampleRawData := Proagrica.Files.EC.Raw.rawFile;
Dbg(ecSampleRawData);

normalizedECSampleRawData := Proagrica.Files.EC.Raw.file;
Dbg(normalizedECSampleRawData);

//------------------------------------------------------------------------------

yieldSampleRawData := Proagrica.Files.Yield.Raw.rawFile;
Dbg(yieldSampleRawData);

normalizedYieldSampleRawData := Proagrica.Files.Yield.Raw.file;
Dbg(normalizedYieldSampleRawData);
Dbg(COUNT(normalizedYieldSampleRawData), 'normalizedYieldSampleRawData_cnt');
