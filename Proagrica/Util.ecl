IMPORT Proagrica;
IMPORT Std;

EXPORT Util := MODULE

    EXPORT MakePath(STRING fileLeafName) := Proagrica.Files.Constants.PATH_PREFIX + '::' + fileLeafName;

    //--------------------------------------------------------------------------

    EXPORT StringToTimestamp(STRING timestampString) := FUNCTION
        // Example input: 2016-05-03T14:36:43.905044Z
        date := Std.Date.FromStringToDate(timestampString[..10], '%Y-%m-%d');
        time := Std.Date.FromStringToTime(timestampString[12..], '%H:%M:%S');
        fractionalTimeStr1 := REGEXFIND('\\.(\\d{1,6})Z$', timestampString, 1);
        fractionalTimeStr2 := fractionalTimeStr1 + '000000'[(LENGTH(fractionalTimeStr1) + 1)..];
        fractionalTime := (UNSIGNED4)fractionalTimeStr2;

        timestamp := Std.Date.SecondsFromParts
            (
                Std.Date.Year(date),
                Std.Date.Month(date),
                Std.Date.Day(date),
                Std.Date.Hour(time),
                Std.Date.Minute(time),
                Std.Date.Second(time)
            ) * 1000000 + fractionalTime;

        RETURN timestamp;
    END;

    //--------------------------------------------------------------------------

    EXPORT PointToLatLon(STRING p) := FUNCTION
        // Example input:  POINT (-89.079033000384811 43.255562334527198)
        parsedInput := REGEXREPLACE('POINT *?\\((.+?)\\)', p, '$1', NOCASE);
        foundValues := REGEXFINDSET('-?\\d+(\\.\\d+)?', parsedInput);
        foundValid := COUNT(foundValues) = 2;

        result := MODULE
            EXPORT BOOLEAN      isValid := foundValid;
            EXPORT DECIMAL9_6   longitude := IF(foundValid, (DECIMAL9_6)foundValues[1], 0);
            EXPORT DECIMAL9_6   latitude := IF(foundValid, (DECIMAL9_6)foundValues[2], 0);
        END;

        RETURN result;
    END;

    //--------------------------------------------------------------------------

    EXPORT PointToUTM(STRING p) := FUNCTION
        // Example input:  POINT (-89.079033000384811 43.255562334527198)
        parsedInput := REGEXREPLACE('POINT *?\\((.+?)\\)', p, '$1', NOCASE);
        foundValues := REGEXFINDSET('-?\\d+(\\.\\d+)?', parsedInput);
        foundValid := COUNT(foundValues) = 2;

        result := MODULE
            EXPORT BOOLEAN      isValid := foundValid;
            EXPORT DECIMAL14_6  x := IF(foundValid, (DECIMAL14_6)foundValues[1], 0);
            EXPORT DECIMAL14_6  y := IF(foundValid, (DECIMAL14_6)foundValues[2], 0);
        END;

        RETURN result;
    END;

    //--------------------------------------------------------------------------

    EXPORT UTMDistance(DECIMAL14_6 x1, DECIMAL14_6 y1, DECIMAL14_6 x2, DECIMAL14_6 y2) := FUNCTION
        x := (x1 - x2) * (x1 - x2);
        y := (y1 - y2) * (y1 - y2);

        RETURN SQRT((REAL4)x + (REAL4)y);
    END;

END;