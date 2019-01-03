IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: EC ETL');

PATH := Std.File.ExternalLogicalFileName('10.0.0.13', '/var/lib/HPCCSystems/mydropzone/uploads/ec_combined.json');

enhancedData := Proagrica.Files.EC.Enhanced.File(PATH);
OUTPUT(enhancedData, /*RecStruct*/, Proagrica.Files.EC.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);
