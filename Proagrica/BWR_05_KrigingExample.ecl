IMPORT ML_Core;                    //ML essential bundle
IMPORT PBblas;                     //Matrix Matipulation Bunle
IMPORT PBblas.Types AS pTypes;     //RECORD structures to hold Matrix
IMPORT ML_Core.Types AS Types;     //RECORD structures to hold ML data
IMPORT LinearRegression AS LROLS;  //Linear Regression Module

//Layout of samples
Layout := RECORD
  REAL    x;    //x axis
  REAL    y;    //y axis
  REAL    Z;    //value
END;
//Samples for Variogram
trainset := DATASET([{26,3,0.721428990472758},
                    {93,96,4.94606998559815},
                    {10,17,-1.71460298096551},
                    {57,37,0.405315507777372},
                    {95,33,-0.597326917351726},
                    {9,5,2.28253521765312},
                    {100,26,-1.28800549889374},
                    {43,83,-0.28933348713722},
                    {95,32,0.289063616723166},
                    {21,54,-3.78694465057683},
                    {17,76,-1.86052281167505},
                    {91,75,2.43534824239117},
                    {27,2,0.781781400097044},
                    {53,46,3.87714138998229},
                    {41,30,0.344668948072099},
                    {27,41,-5.71955625237288},
                    {66,16,2.0747950459435},
                    {76,32,4.47903494660965},
                    {39,9,1.7814636173904},
                    {55,18,1.69463788159808},
                    {84,85,0.37679055638637},
                    {79,10,5.75048309587219},
                    {19,53,-1.8115194421345},
                    {62,91,2.32398540416265},
                    {69,56,2.38239119411732},
                    {21,2,0.0219235982175524},
                    {93,16,2.33609294307362},
                    {97,88,6.57334138728625},
                    {100,22,0.568674572127224},
                    {100,17,1.24451907039425},
                    {1,93,3.82203931898106},
                    {79,63,3.30298911335765},
                    {38,55,-1.53479193239291},
                    {55,55,0.805945824306311},
                    {80,12,6.70429635774754},
                    {22,1,-0.164312344824588},
                    {50,14,2.06561429706319},
                    {22,32,-0.490792597619393},
                    {64,42,4.5303096556423},
                    {30,88,0.799670926056312},
                    {85,25,0.77488259793217},
                    {29,3,-2.99025816553958},
                    {32,95,4.02321765233237},
                    {49,98,6.39604542381281},
                    {95,95,5.77451862529905},
                    {79,41,4.58912097663629},
                    {67,2,3.53039983019433},
                    {45,79,-4.61797183596984},
                    {3,91,4.55223620990091},
                    {86,28,1.43780579629322},
                    {16,94,-0.27398386045217},
                    {92,19,2.10335680248896},
                    {67,24,2.5514566476364},
                    {23,65,-0.861688220872771},
                    {64,98,4.30624997108481},
                    {71,45,3.32291412841003},
                    {66,29,4.51294769035426},
                    {19,28,-2.00447100011255},
                    {97,61,4.1442660466171},
                    {100,59,0.344682532851194}]
                    , Layout);
//Sample for Interpolation
testset := DATASET([{1,1, 0},
                    {2,1, 0},
                    {1,2, 0},
                    {2,2, 0},
                    {10,15, 0},
                    {55,12, 0},
                    {61,26, 0}],Layout);

//Layout of Variogram
ClusterPair:=RECORD
    Types.t_Work_Item   wi; //ML required RECORD structure
    Types.t_RecordID    id; //ML required RECORD structure
    Types.t_RecordID    clusterid; //For distance calculation between two points
    Types.t_FieldNumber number; //id of each attribute
    Types.t_FieldReal   value01 := 0; //value 01 - value03 are scratch pad for
    Types.t_FieldReal   value02 := 0; //distance calculation
    Types.t_FieldReal   value03 := 0;
END;

//*************Step 1: Build Variogram for TWO dimentional spatial data*******************
//Helper Function: Gen_Variogram()
//Create variogram based on the distance of d1 and d2 before regression
//d1 and d2 are in the Types.NumericField Format.
//Field 1 (number = 1) is the first dimention (the x axis) of the data point
//Field 2 (number = 2) is the second dimention (the y axis) of the data point
//Field 3 (number = 3) is the value (z) of each data point
gen_variogram(DATASET(Types.NumericField) d1,
              DATASET(Types.NumericField) d2):= FUNCTION
  //Calculate the Distance of each data pair
  ClusterPair Take2(Types.NumericField le, Types.NumericField ri) := TRANSFORM
        isValue := IF(le.number = 3, TRUE, FALSE);
        SELF.wi := ri.wi;
        SELF.clusterid := ri.id;
        SELF.id := le.id;
        SELF.number := le.number;
        SELF.value01 := IF(isValue, 0,(le.value-ri.value)*(le.value-ri.value));//Distance
        SELF.value02 := IF(isValue, 0.5*(le.value-ri.value)*(le.value-ri.value), 0); //Variance
  END;
  s1 := JOIN(d1,d2,LEFT.wi = RIGHT.wi AND LEFT.number=RIGHT.number, Take2(LEFT,RIGHT));
  s2 := GROUP(s1,wi,clusterid,id,ALL);
  ClusterPair roll(ClusterPair le, DATASET(ClusterPair) gd) := TRANSFORM
    SELF.Value01 := SQRT(SUM(gd, value01));
    SELF.value02 := SUM(gd, value02);
    SELF.number := 0;
    SELF := le;
  END;
  s3 := ROLLUP(s2,GROUP,roll(LEFT,ROWS(LEFT)));
  RETURN s3;
END;

//Generate Variograms for training set and testing set
//Generate Variogram for Trainset
ML_Core.AppendSeqID(trainset,id, sp);
ML_Core.ToField(sp, NFsp);
//Generate Variogram for Testset
variogramTrain := gen_variogram(nfsp, nfsp);
//offid is used to avoid the id overlay with trainset
offid := MAX(NFsp, id);
ML_Core.AppendSeqID(testset,id, tt);
ML_Core.ToField(tt, tt1);
NFtt := PROJECT(tt1, TRANSFORM(Types.NumericField, SELF.id := LEFT.id + offid, SELF:= LEFT));
variogramTest := gen_variogram(NFtt, NFsp);

//****************************Step 2: Linear Regression******************************
//Add ID for each record in variogram
//The result dataset is defined as preTrain.
ML_Core.AppendSeqID(variogramTrain, value03, preTrain);
//TRANSFORM the preTrain to the right format (Types.NumericField) before running Linear Regression
//The result dataset is defined as Train.
ML_Core.ToField(PreTrain, train,value03,wi,,'value01,value02');
//Extract the independence field(s) from the Train dataset.
//In our example the field number is 1.
TrainInd := Train(number =1);
//Extract the dependence field(s) from the Train dataset.
//In our example the field number is 2.
TrainDpt := PROJECT(Train(number =2), TRANSFORM(Types.NumericField,
SELF.number := 1, SELF := LEFT));

//Now we are ready to run Linear Regression
//lr is the trained Linear Regression model
lr := LROLS.OLS(TrainInd,TrainDpt);
coef := lr.GetModel();

//Apply the above trained Linear Regression model to the Testset
ML_Core.AppendSeqID(variogramTest, value03, preTest);
ML_Core.ToField(PreTest, test,value03,wi,,'value01,value02');
TestInd := Test(number =1);
//Get the semi-variance for trainset based on previously trained Linear Model lr
lrtrain := lr.Predict(TrainInd);
//Get the semi-variance for testset based on previously trained Linear Model lr
lrtest := lr.Predict(TestInd);

//******************************Step 3: Kriging the Weights **********************
//Creat Matrix A
//TRANSFORM the variogram of trainset to the right format (pTypes.Layout_cell)
mTrain := JOIN(preTrain, lrTrain, LEFT.wi = RIGHT.wi AND LEFT.value03 = RIGHT.id, TRANSFORM(pTypes.Layout_Cell,
SELF.x := LEFT.id,
SELF.y := LEFT.clusterid,
SELF.v := RIGHT.value,
SELF := LEFT;
));
//Add one more extral row to solve the matrix
ro := COUNT(trainset) + 1;
//Creat the frame of Matrix A
A0 := PBblas.Test.MakeTestMatrix.Matrix(ro,ro);
//Fill the frame with the variogram values
A := JOIN(A0, mtrain, LEFT.wi_id = RIGHT.wi_id AND LEFT.x = RIGHT.x
                      AND LEFT.y = RIGHT.y, TRANSFORM(RECORDOF(A0),
                      SELF.v := MAP(LEFT.x = ro AND LEFT.y = ro => 0,
                                    LEFT.x = ro OR LEFT.y = ro => 1,
                                    // LEFT.x = RIGHT.y =>coef(number = 1).value,//nugget
                                    RIGHT.v),
                      SELF := LEFT), LEFT OUTER);

//Creat Matrix B
//Apply the same steps of creating matrix A to creat Matrix B
mTest := JOIN(preTest, lrTest, LEFT.wi = RIGHT.wi AND LEFT.value03 = RIGHT.id, TRANSFORM(pTypes.Layout_Cell,
SELF.x := LEFT.clusterid, // the id of training data
SELF.y := LEFT.id - offid, //the id of test data
SELF.v := RIGHT.value,
SELF := LEFT;
));
co := COUNT(testset);
B0 := PBblas.Test.MakeTestMatrix.Matrix(ro,co);
B := JOIN(B0, mtest, LEFT.wi_id = RIGHT.wi_id AND LEFT.x = RIGHT.x
                      AND LEFT.y = RIGHT.y, TRANSFORM(RECORDOF(B0),
                      SELF.v := IF(LEFT.x = ro, 1, RIGHT.v),
                      SELF := LEFT), LEFT OUTER);
//Solve Aw = B
//Get the weights via the matrix manipulation bundle: PBblas
//The Types we need use for matrix manipulation for our problem
side := PBblas.Types.Side;
Triangle := PBblas.Types.Triangle;
Diagonal:= PBblas.Types.Diagonal;
//Sovle the matrix manipulation via the upper and the lower tra-angle matrices
ata := PBblas.gemm(TRUE, FALSE, 1.0, A, A) ;
atb := PBblas.gemm(TRUE, FALSE, 1.0, A, B) ;
L := PBblas.potrf(Triangle.Lower, ata);
UW := PBblas.trsm(Side.Ax, Triangle.Lower, FALSE, Diagonal.NotUnitTri, 1.0, L, atb);
//w is defined as the weights we need to interpolate the testset
w := PBblas.trsm(Side.Ax, Triangle.Upper, TRUE, Diagonal.NotUnitTri, 1.0,L , UW);

//********************************Step 4: Interpolate the values of test set******************
//Calculate the testset values with the weights and trainset values
//Trainset values: field number (z) is 3.
spValues := NFsp(number = 3);
spValues_mx := PROJECT(spValues, TRANSFORM(PBblas.Types.Layout_Cell,
SELF.x := LEFT.id,
SELF.y := 1;
SELF.v := LEFT.value,
SELF := LEFT));
//Final result: the interpolated values of test set.
testValues := PBblas.Gemm(TRUE, FALSE, 1.0, spValues_mx , w(x < ro));
OUTPUT(testValues, NAMED('Interpolated_Values'));

//****************************Goal Achieved**********************************************