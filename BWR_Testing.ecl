IMPORT Proagrica;

#WORKUNIT('name', 'Proagrica: Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

utmInfo := Proagrica.UTM.GPSToUTM(37.762210, -99.86094);

Dbg(utmInfo.x, 'x');
Dbg(utmInfo.y, 'y');
Dbg(utmInfo.zone, 'zone');
