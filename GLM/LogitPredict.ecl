﻿IMPORT $ AS GLMmod;
IMPORT GLMmod.Types;
IMPORT GLMmod.Family;
IMPORT ML_Core.Types AS Core_Types;

//aliases
Classify_Result := Core_Types.Classify_Result;
NumericField := Core_Types.NumericField;
Model_Coef := Types.Model_Coef;

/**
  * Predict the category values with the logit function and the
  * the supplied beta coefficients.
  * @param coef the model beta coefficients as returned from ExtractBeta.
  * @param independents the observations.
  * @return the predicted category values and a confidence score in Classify_Result
  *         format.
  * @see ExtractBeta
  * @see ML_Core.Types.Classify_Result
  */
EXPORT DATASET(Classify_Result)
      LogitPredict(DATASET(Model_Coef) coef,
                    DATASET(NumericField) independents) := FUNCTION
  sigmoid := GLMmod.Predict(coef, independents, Family.Binomial);
  Classify_Result score(NumericField y) := TRANSFORM
    SELF.value := IF(y.value>0.5, 1, 0);
    SELF.conf := ABS(y.value-0.5) * 2;
    SELF := y;
  END;
  scored := PROJECT(sigmoid, score(LEFT));
  RETURN scored;
END;