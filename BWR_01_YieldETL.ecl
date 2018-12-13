IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Yield ETL');

PATH := Std.File.ExternalLogicalFileName('10.0.0.13', '/var/lib/HPCCSystems/mydropzone/uploads/yield_combined.json');

enhancedData := Proagrica.Files.Yield.Enhanced.File(PATH);
OUTPUT(enhancedData, /*RecStruct*/, Proagrica.Files.Yield.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);