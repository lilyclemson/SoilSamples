IMPORT Proagrica;

#WORKUNIT('name', 'Proagrica: Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

v := Proagrica.Util.PointToLatLon('POINT (-89.079033000384811 43.255562334527198)');

Dbg(v.latitude, 'latitude');
Dbg(v.longitude, 'longitude');
