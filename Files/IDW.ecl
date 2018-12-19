IMPORT Proagrica;

EXPORT IDW := MODULE

    EXPORT WIDTH_RANGE := 24; // meters
    EXPORT IDW_EXP := 1;

    EXPORT Layout := RECORD
        UNSIGNED1       utm_zone;
        DECIMAL14_6     utm_x;
        DECIMAL14_6     utm_y;
        DECIMAL14_6     other_utm_x;
        DECIMAL14_6     other_utm_y;
        DECIMAL9_6      distance;
        DECIMAL7_6      idw;
    END;

    EXPORT DEFAULT_PATH := Proagrica.Files.Constants.PATH_PREFIX + '::idw_lookup_data';

    EXPORT File(STRING path = DEFAULT_PATH) := DATASET(path, Layout, FLAT);

END;
