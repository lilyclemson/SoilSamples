IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Parsed File Read Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

soilSampleData := Proagrica.Files.SoilSampling.Working.File();
Dbg(soilSampleData);
// Dbg(COUNT(soilSampleData), 'soilSampleData_cnt');

//------------------------------------------------------------------------------

ecData := Proagrica.Files.EC.Working.File();
Dbg(ecData);
// Dbg(COUNT(ecData), 'ecData_cnt');

//------------------------------------------------------------------------------

yieldData := Proagrica.Files.Yield.Working.File();
Dbg(yieldData);
// Dbg(COUNT(yieldData), 'yieldData_cnt');
