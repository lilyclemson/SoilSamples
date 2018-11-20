IMPORT Proagrica;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Soil Sample ETL');

soilSampleFilePattern := Proagrica.Files.Constants.PATH_PREFIX_SCOPE + '::soil_samples_01::*';
soilSampleFileList := NOTHOR(Std.File.LogicalFileList(soilSampleFilePattern));
SOIL_FILENAME := '~{' + Std.Str.CombineWords(SET(soilSampleFileList, name), ',') + '}';

enhancedSoilSampleRawData := Proagrica.Files.SoilSampling.Enhanced.File(SOIL_FILENAME);
distributedSoilSample := DISTRIBUTE(enhancedSoilSampleRawData, SKEW(0.05));
OUTPUT(distributedSoilSample, /*RecStruct*/, Proagrica.Files.SoilSampling.Working.DEFAULT_PATH, OVERWRITE, COMPRESSED);
