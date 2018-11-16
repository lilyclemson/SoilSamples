IMPORT Proagrica;

#WORKUNIT('name', 'Proagrica: Testing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

x := Proagrica.Util.StringToTimestamp('2016-05-03T14:36:43.905044Z');

Dbg(x, 'StringToTimestamp');

//------------------------------------------------------------------------------

v := Proagrica.Util.PointToLatLon('POINT (-89.079033000384811 43.255562334527198)');

Dbg(v.isValid, 'PointToLatLon_isValid');
Dbg(v.latitude, 'PointToLatLon_latitude');
Dbg(v.longitude, 'PointToLatLon_longitude');
