IMPORT Proagrica;

#WORKUNIT('name', 'Proagrica: Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

res := Proagrica.GPSToUTM(37.762210, -99.86094);
Dbg(res);
