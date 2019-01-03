IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Random testing 2');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

soilSampleData := Proagrica.Files.SoilSampling.Working.File(); // Already distributed on HASH32(field_id)
ecData := Proagrica.Files.EC.Working.File(); // Already distributed on HASH32(field_id)
yieldData := Proagrica.Files.Yield.Working.File(); // Already distributed on HASH32(field_id)
idwLookup := Proagrica.Files.IDW.File();
combinedData := Proagrica.Files.Combined.Working.File();

res := combinedData(ec.ec02.measure != 0);
Dbg(res);
