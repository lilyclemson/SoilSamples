IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Test Yield Processing');

Dbg(sym, name = '') := MACRO
    OUTPUT(sym, NAMED(#IF(#TEXT(name) != '') name #ELSE #TEXT(sym) #END), NOXPATH);
ENDMACRO;

//------------------------------------------------------------------------------

yieldData := Proagrica.Files.Yield.Working.File();

scanCounts := TABLE
    (
        yieldData,
        {
            field_id,
            UNSIGNED4   cnt := COUNT(GROUP)
        },
        field_id,
        MERGE
    );

Dbg(SORT(scanCounts, field_id), 'scan_counts_by_field');
DBG(COUNT(scanCounts), 'field_cnt');

recsWithMultipleAdjMass := yieldData(COUNT(section.spatial) > 1);
Dbg(recsWithMultipleAdjMass);
Dbg(COUNT(recsWithMultipleAdjMass), 'recsWithMultipleAdjMass_num');

j2 := TABLE
    (
        recsWithMultipleAdjMass,
        {
            field_id,
            UNSIGNED4   cnt := COUNT(GROUP)
        },
        field_id,
        MERGE
    );
Dbg(j2);
Dbg(COUNT(j2), 'j2_cnt');
