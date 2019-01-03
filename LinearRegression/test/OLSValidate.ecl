/*##############################################################################
## HPCC SYSTEMS software Copyright (C) 2017 HPCC Systems�.  All rights reserved.
############################################################################## */

// Validate Regression against a standard set of datasets with known results
// Note that the datasets include:
// - Raw data from public dataset
// - All regression analytics as generated by Python statsmodels.OLS
// The statsmodels analytic results are automatically inserted into the datafiles
// using the LinearRegression/test/Python/processDatafile.py program.
// This file compares the statsmodels.OLS analytic results with those generated
// by this ECL LinearRegression module: LinearRegression/OLS.ecl
// Each analytic produces its own output, and they are summarized by the
// summary output.

IMPORT Std;
IMPORT ML_Core;
IMPORT ML_Core.Types;

IMPORT $ AS test;
IMPORT test.Datasets AS datasets;
IMPORT test.Utils AS Utils;

IMPORT $.^ AS LR;

NumericField := Types.NumericField;
t_work_item := Types.t_work_item;

epsilon := 0.000001;

SET OF STRING regressionDatasetNames := ['AbaloneDS', 'friedman1DS', 'friedman2DS', 'friedman3DS', 'housingDS', 'servoDS'];

INTEGER r_no_of_elements := COUNT(regressionDatasetNames);

// Transform to set the work-item to a new value
NumericField setWI(NumericField l, t_work_item wi) := TRANSFORM
  SELF.wi := wi;
  SELF    := l;
END;

NumericField Real2NF(REAL8 v, t_work_item wi) := TRANSFORM
  SELF.wi := wi;
  SELF.id := 1;
  SELF.number := 1;
  SELF.value := v;
END;
NumericField Set2NF(SET OF REAL8 values, t_work_item wi) := FUNCTION
  dummy := DATASET([{1, 1, 1, 1}], NumericField);
  NumericField Value2NF(NumericField l, UNSIGNED c) := TRANSFORM
    SELF.wi := wi;
    SELF.id := c;
    SELF.number := 1;
    SELF.value := values[c];
  END;
  outFields := NORMALIZE(dummy, COUNT(values), Value2NF(LEFT, COUNTER));
  return outFields;
END;
// Form a myriad of all of the datasets and execute them in a single call to OLS

// Macro to expand the test for each dataset.
doTest(dsName, wi) := MACRO
  #DECLARE(outStr);
  #SET(outStr, '');
  #APPEND(outStr, 'dsName_' + wi + ' := \'' + dsName + '\';\n');
  #APPEND(outStr, 'dsPath_' + wi + ' := datasets.' + dsName + ';\n');
  // Work item to use for this dataset
  #APPEND(outStr, 'wi_' + wi + ' := ' + wi + ';\n');
  #APPEND(outStr, 'content_' + wi + ' := dsPath_' + wi + '.content;\n');
  // Extract the independent fields
  #APPEND(outStr, 'UTILS.ExtractIndeps(content_' + wi + ', ind_' + wi + ');\n');
  // Convert them to Numeric Fields
  #APPEND(outStr, 'ML_Core.ToField(ind_' + wi + ', ind_' + wi + 'NF, wivalue:= ' + wi + ');\n');
  // Extract the dependent field(s)
  #APPEND(outStr, 'UTILS.ExtractDeps(content_' + wi + ', dep_' + wi + ');\n');
  // Convert them to Numeric Fields
  #APPEND(outStr, 'ML_Core.ToField(dep_' + wi + ', dep_' + wi + 'NF, wivalue:= ' + wi + ');\n');
  // Extract the Betas as determined by scikit-learn (reference implementation)
  #APPEND(outStr, 'skbetas_' + wi + ' := PROJECT(dsPath_' + wi + '.betas, setWI(LEFT, wi_' + wi + '));\n');
  #APPEND(outStr, 'skRSquared_' + wi + ' := Real2NF(dsPath_' + wi + '.Rsquared, ' + wi + ');\n');
  #APPEND(outStr, 'skAdjRSquared_' + wi + ' := Real2NF(dsPath_' + wi + '.AdjRsquared, ' + wi + ');\n');
  #APPEND(outStr, 'skTotal_SS_' + wi + ' := Real2NF(dsPath_' + wi + '.Total_SS, ' + wi + ');\n');
  #APPEND(outStr, 'skModel_SS_' + wi + ' := Real2NF(dsPath_' + wi + '.Model_SS, ' + wi + ');\n');
  #APPEND(outStr, 'skError_SS_' + wi + ' := Real2NF(dsPath_' + wi + '.Error_SS, ' + wi + ');\n');
  #APPEND(outStr, 'skTotal_DF_' + wi + ' := Real2NF(dsPath_' + wi + '.Total_DF, ' + wi + ');\n');
  #APPEND(outStr, 'skModel_DF_' + wi + ' := Real2NF(dsPath_' + wi + '.Model_DF, ' + wi + ');\n');
  #APPEND(outStr, 'skError_DF_' + wi + ' := Real2NF(dsPath_' + wi + '.Error_DF, ' + wi + ');\n');
  #APPEND(outStr, 'skModel_MS_' + wi + ' := Real2NF(dsPath_' + wi + '.Model_MS, ' + wi + ');\n');
  #APPEND(outStr, 'skError_MS_' + wi + ' := Real2NF(dsPath_' + wi + '.Error_MS, ' + wi + ');\n');
  #APPEND(outStr, 'skModel_F_' + wi + ' := Real2NF(dsPath_' + wi + '.Model_F, ' + wi + ');\n');
  #APPEND(outStr, 'skAIC_' + wi + ' := Real2NF(dsPath_' + wi + '.AIC, ' + wi + ');\n');
  #APPEND(outStr, 'skFtest_' + wi + ' := Real2NF(dsPath_' + wi + '.Ftest, ' + wi + ');\n');
  #APPEND(outStr, 'skSE_' + wi + ' := Set2NF(dsPath_' + wi + '.SE, ' + wi + ');\n');
  #APPEND(outStr, 'skTstat_' + wi + ' := Set2NF(dsPath_' + wi + '.Tstat, ' + wi + ');\n');
  #APPEND(outStr, 'skPval_' + wi + ' := Set2NF(dsPath_' + wi + '.Pval, ' + wi + ');\n');
  #APPEND(outStr, 'skConfintStarts_' + wi + ' := Set2NF(dsPath_' + wi + '.ConfintStarts, ' + wi + ');\n');
  #APPEND(outStr, 'skConfintEnds_' + wi + ' := Set2NF(dsPath_' + wi + '.ConfintEnds, ' + wi + ');\n');
  %outStr%
ENDMACRO;

// Run the doTest macro for each dataset, providing each a unique work-item number
doTest('AbaloneDS', '1');
doTest('friedman1DS', '2');
doTest('friedman2DS', '3');
doTest('friedman3DS', '4');
doTest('housingDS', '5');
doTest('servoDS', '6');

dsNames := [dsName_1, dsName_2, dsName_3, dsName_4, dsName_5, dsName_6];
// Form a myriad for independents, dependents and reference betas (from scikit-learn)
//indeps := ind_1NF + ind_2NF + ind_3NF + ind_4NF + ind_5NF + ind_6NF;
//deps := dep_1NF + dep_2NF + dep_3NF + dep_4NF + dep_5NF + dep_6NF;
//skbetas := skbetas_1 + skbetas_2 + skbetas_3 + skbetas_4 + skbetas_5 + skbetas_6;
indeps := ind_1NF + ind_2NF + ind_3NF + ind_4NF + ind_5NF + ind_6NF;
deps := dep_1NF + dep_2NF + dep_3NF + dep_4NF + dep_5NF + dep_6NF;
// Fit the regression for all of the myriads and get a composite set of Betas (i.e. one
//  set per work-item)
olsmod := LR.OLS(indeps, deps);

// Accuracy record
cmp_rec := RECORD
  STRING12 dsName;
  INTEGER id;
  INTEGER number;
  t_work_item wi;
  REAL ecl_value;
  REAL scikit_value;
  STRING7 result; // 'SUCCESS' or 'FAIL'
END;

//
cmp_rec make_cmp(NumericField l, NumericField r, REAL8 e=epsilon) := TRANSFORM
  SELF.dsName    := dsNames[l.wi];
  SELF.id        := l.id;
  SELF.number    := l.number;
  SELF.wi        := l.wi;
  SELF.ecl_value := l.value;
  SELF.scikit_value := r.value;
  err := ABS(l.value - r.value);
  errpct := err / ABS(r.value);
  SELF.result := IF(err < e OR errpct < e, 'SUCCESS', 'FAIL');
END;
// Join the OLS result betas and the scikit-learn betas to assess the accuracy

skbetas := skbetas_1 + skbetas_2 + skbetas_3 + skbetas_4 + skbetas_5 + skbetas_6;
betas := olsmod.Betas();
betas_cmp := JOIN(betas, skbetas, LEFT.id = RIGHT.id AND LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skRsquared := DATASET([skRsquared_1, skRsquared_2, skRsquared_3, skRsquared_4, skRsquared_5, skRsquared_6]);
RSquaredNF := PROJECT(olsmod.RSquared, REAL2NF(LEFT.Rsquared, LEFT.wi));
RSquared_cmp := JOIN(RSquaredNF, skRsquared, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skAdjRsquared := DATASET([skAdjRsquared_1, skAdjRsquared_2, skAdjRsquared_3, skAdjRsquared_4,
                            skAdjRsquared_5, skAdjRsquared_6]);
AdjRSquaredNF := PROJECT(olsmod.AdjRSquared, REAL2NF(LEFT.Rsquared, LEFT.wi));
AdjRSquared_cmp := JOIN(AdjRSquaredNF, skAdjRsquared, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

ANOVA := olsmod.ANOVA;

skTotal_SS := DATASET([skTotal_SS_1, skTotal_SS_2, skTotal_SS_3, skTotal_SS_4, skTotal_SS_5, skTotal_SS_6]);
Total_SS := PROJECT(ANOVA, REAL2NF(LEFT.Total_SS, LEFT.wi));
TotalSS_cmp := JOIN(Total_SS, skTotal_SS, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skModel_SS := DATASET([skModel_SS_1, skModel_SS_2, skModel_SS_3, skModel_SS_4, skModel_SS_5, skModel_SS_6]);
Model_SS := PROJECT(ANOVA, REAL2NF(LEFT.Model_SS, LEFT.wi));
ModelSS_cmp := JOIN(Model_SS, skModel_SS, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skError_SS := DATASET([skError_SS_1, skError_SS_2, skError_SS_3, skError_SS_4, skError_SS_5, skError_SS_6]);
Error_SS := PROJECT(ANOVA, REAL2NF(LEFT.Error_SS, LEFT.wi));
ErrorSS_cmp := JOIN(Error_SS, skError_SS, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skTotal_DF := DATASET([skTotal_DF_1, skTotal_DF_2, skTotal_DF_3, skTotal_DF_4, skTotal_DF_5, skTotal_DF_6]);
Total_DF := PROJECT(ANOVA, REAL2NF(LEFT.Total_DF, LEFT.wi));
TotalDF_cmp := JOIN(Total_DF, skTotal_DF, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skModel_DF := DATASET([skModel_DF_1, skModel_DF_2, skModel_DF_3, skModel_DF_4, skModel_DF_5, skModel_DF_6]);
Model_DF := PROJECT(ANOVA, REAL2NF(LEFT.Model_DF, LEFT.wi));
ModelDF_cmp := JOIN(Model_DF, skModel_DF, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skError_DF := DATASET([skError_DF_1, skError_DF_2, skError_DF_3, skError_DF_4, skError_DF_5, skError_DF_6]);
Error_DF := PROJECT(ANOVA, REAL2NF(LEFT.Error_DF, LEFT.wi));
ErrorDF_cmp := JOIN(Error_DF, skError_DF, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skModel_MS := DATASET([skModel_MS_1, skModel_MS_2, skModel_MS_3, skModel_MS_4, skModel_MS_5, skModel_MS_6]);
Model_MS := PROJECT(ANOVA, REAL2NF(LEFT.Model_MS, LEFT.wi));
ModelMS_cmp := JOIN(Model_MS, skModel_MS, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skError_MS := DATASET([skError_MS_1, skError_MS_2, skError_MS_3, skError_MS_4, skError_MS_5, skError_MS_6]);
Error_MS := PROJECT(ANOVA, REAL2NF(LEFT.Error_MS, LEFT.wi));
ErrorMS_cmp := JOIN(Error_MS, skError_MS, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skModel_F := DATASET([skModel_F_1, skModel_F_2, skModel_F_3, skModel_F_4, skModel_F_5, skModel_F_6]);
Model_F := PROJECT(ANOVA, REAL2NF(LEFT.Model_F, LEFT.wi));
ModelF_cmp := JOIN(Model_F, skModel_F, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skAIC := DATASET([skAIC_1, skAIC_2, skAIC_3, skAIC_4, skAIC_5, skAIC_6]);
AICNF := PROJECT(olsmod.AIC, REAL2NF(LEFT.AIC, LEFT.wi));
AIC_cmp := JOIN(AICNF, skAIC, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skFtest := DATASET([skFtest_1, skFtest_2, skFtest_3, skFtest_4, skFtest_5, skFtest_6]);
FtestNF := PROJECT(olsmod.Ftest, REAL2NF(LEFT.pValue, LEFT.wi));
Ftest_cmp := JOIN(FtestNF, skFtest, LEFT.wi = RIGHT.wi, make_cmp(LEFT, RIGHT));

skSE := skSE_1 + skSE_2 + skSE_3 + skSE_4 + skSE_5 + skSE_6;
SE := olsmod.SE;
SE_cmp := JOIN(SE, skSE, LEFT.wi = RIGHT.wi AND LEFT.id = RIGHT.id, make_cmp(LEFT, RIGHT));

skTstat := skTstat_1 + skTstat_2 + skTstat_3 + skTstat_4 + skTstat_5 + skTstat_6;
Tstat := olsmod.Tstat;
Tstat_cmp := JOIN(Tstat, skTstat, LEFT.wi = RIGHT.wi AND LEFT.id = RIGHT.id, make_cmp(LEFT, RIGHT));

skPval := skPval_1 + skPval_2 + skPval_3 + skPval_4 + skPval_5 + skPval_6;
Pval := olsmod.Pval;
Pval_cmp := JOIN(Pval, skPval, LEFT.wi = RIGHT.wi AND LEFT.id = RIGHT.id, make_cmp(LEFT, RIGHT));

skConfintStarts := skConfintStarts_1 + skConfintStarts_2 + skConfintStarts_3 + skConfintStarts_4
                    + skConfintStarts_5 + skConfintStarts_6;
skConfintEnds := skConfintEnds_1 + skConfintEnds_2 + skConfintEnds_3
                    + skConfintEnds_4 + skConfintEnds_5 + skConfintEnds_6;
Confint := olsmod.Confint(95);
ConfintStarts := PROJECT(Confint, TRANSFORM(NumericField,
                                              SELF.wi := LEFT.wi,
                                              SELF.id := LEFT.id,
                                              SELF.number := LEFT.number,
                                              SELF.value := LEFT.LowerInt));
ConfintEnds := PROJECT(Confint, TRANSFORM(NumericField,
                                              SELF.wi := LEFT.wi,
                                              SELF.id := LEFT.id,
                                              SELF.number := LEFT.number,
                                              SELF.value := LEFT.UpperInt));
// Note: We allow a greater margin of error (.001) for confidence interval so that we do not
// need to use super-fine granularity in the inverse T distribution
ConfintStarts_cmp := JOIN(ConfintStarts, skConfintStarts, LEFT.wi = RIGHT.wi AND LEFT.id = RIGHT.id, make_cmp(LEFT, RIGHT, .001));
ConfintEnds_cmp := JOIN(ConfintEnds, skConfintEnds, LEFT.wi = RIGHT.wi AND LEFT.id = RIGHT.id, make_cmp(LEFT, RIGHT, .001));

OUTPUT(betas_cmp, NAMED('Betas'));
OUTPUT(RSquared_cmp, NAMED('RSquared'));
OUTPUT(AdjRSquared_cmp, NAMED('AdjRSquared'));

OUTPUT(TotalSS_cmp, NAMED('Total_SS'));
OUTPUT(ModelSS_cmp, NAMED('Model_SS'));
OUTPUT(ErrorSS_cmp, NAMED('Error_SS'));

OUTPUT(TotalDF_cmp, NAMED('Total_DF'));
OUTPUT(ModelDF_cmp, NAMED('Model_DF'));
OUTPUT(ErrorDF_cmp, NAMED('Error_DF'));

OUTPUT(ModelMS_cmp, NAMED('Model_MS'));
OUTPUT(ErrorMS_cmp, NAMED('Error_MS'));
OUTPUT(ModelF_cmp, NAMED('Model_F'));

OUTPUT(AIC_cmp, NAMED('AIC'));

OUTPUT(Ftest_cmp, NAMED('Ftest'));

OUTPUT(SE_cmp, NAMED('StandardError'));

OUTPUT(Tstat_cmp, NAMED('Tstat'));

OUTPUT(Pval_cmp, NAMED('Pval'));

OUTPUT(ConfintStarts_cmp, NAMED('ConfIntLower'));
OUTPUT(ConfintEnds_cmp, NAMED('ConfIntUpper'));

all_cmp := betas_cmp + RSquared_cmp + AdjRSquared_cmp + TotalSS_cmp + ModelSS_cmp + ErrorSS_cmp
           + TotalDF_cmp + ModelDF_cmp + ErrorDF_cmp
           + ModelMS_cmp + ErrorMS_cmp + ModelF_cmp
           + AIC_cmp + Ftest_cmp
           + SE_cmp + Tstat_cmp + Pval_cmp
           + ConfintStarts_cmp + ConfintEnds_cmp;
// Produce overall assessment (i.e. SUCCESS if all results match, otherwise FAIL
summ_rec := RECORD
  UNSIGNED success_cnt;
  UNSIGNED total_cnt;
  UNSIGNED errors;
  STRING   status;
END;
success_cnt := COUNT(all_cmp(result='SUCCESS'));
total_cnt := COUNT(all_cmp);
errors := total_cnt - success_cnt;
status := IF(errors > 0, 'FAIL', 'SUCCESS');
summary := DATASET([{success_cnt, total_cnt, errors, status}], summ_rec);
OUTPUT(summary, NAMED('Summary'));
