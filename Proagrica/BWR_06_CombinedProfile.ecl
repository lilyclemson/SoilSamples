IMPORT Proagrica;
IMPORT DataPatterns;
IMPORT Std;

#WORKUNIT('name', 'Proagrica: Combined Data Profile');

combinedData := Proagrica.Files.Combined.Working.File();

combinedProfile := DataPatterns.Profile
    (
        combinedData,
        features := 'fill_rate,best_ecl_types,cardinality,modes,lengths,patterns,min_max,mean,std_dev,quartiles'
    );

OUTPUT(combinedProfile, /* RecStruct */, Proagrica.Files.Constants.PATH_PREFIX + '::combined_profile', OVERWRITE);
