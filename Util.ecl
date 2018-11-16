IMPORT Std;

EXPORT Util := MODULE

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

END;