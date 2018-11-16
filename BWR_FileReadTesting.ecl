IMPORT Proagrica;

#WORKUNIT('name', 'Proagrica: File Read Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

soilSampleRawData := Proagrica.Files.SoilSampling.Raw.File;
Dbg(soilSampleRawData);

normalizedSoilSampleRawData := Proagrica.Files.SoilSampling.Raw.Normalized;
Dbg(normalizedSoilSampleRawData);

enhancedSoilSampleRawData := Proagrica.Files.SoilSampling.Enhanced.File;
Dbg(enhancedSoilSampleRawData);

//------------------------------------------------------------------------------

ecSampleRawData := Proagrica.Files.EC.Raw.File;
Dbg(ecSampleRawData);

normalizedECSampleRawData := Proagrica.Files.EC.Raw.Normalized;
Dbg(normalizedECSampleRawData);

//------------------------------------------------------------------------------

yieldSampleRawData := Proagrica.Files.Yield.Raw.File;
Dbg(yieldSampleRawData);

normalizedYieldSampleRawData := Proagrica.Files.Yield.Raw.Normalized;
Dbg(normalizedYieldSampleRawData);
Dbg(COUNT(normalizedYieldSampleRawData), 'normalizedYieldSampleRawData_cnt');
