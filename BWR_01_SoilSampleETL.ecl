IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Soil Sample ETL');

SOIL_FILENAME := Std.File.ExternalLogicalFileName('10.0.0.13', '/var/lib/HPCCSystems/mydropzone/uploads/soil_samples_combined.json');

enhancedData := Proagrica.Files.SoilSampling.Enhanced.File(SOIL_FILENAME);
OUTPUT(enhancedData, /*RecStruct*/, Proagrica.Files.SoilSampling.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);
