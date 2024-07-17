// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "fit_libs/fit_functions"


//--------------------------------------------------------------------------------
// Variables and Constants
const int RUN_OK           = 1;
const int SOR_PROGRESSING  = 2;
const int EOR_PROGRESSING  = 3;
const int EOR_FAILURE      = 4;
const int SOR_FAILURE      = 5;
const int RUN_INHIBIT      = 6;

const int NO_RUN    = 0;
const int PHYSICS   = 1;
const int COSMICS   = 2;
const int SYNTHETIC = 3;
const int TECHNICAL = 4;
const int LASER     = 5;


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
void aliDcsRun_stateChanged_CB(string aliDcsRunDpe, int state){
 if(state != SOR_PROGRESSING) return; //the function is executed only by SOR command

 string parameterString = getParameterString();
 int tunType = getRunType();



}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
private int getRunType(string runDPname = ""){

  const int ERR_EXEC = -1;
  if(runDPname.isEmpty()){
    dyn_string runUnits = dpNames("aliDcsRun_*","AliDcsRun");
    if(!dynlen(runUnits)) return ERR_EXEC;
    runDPname = runUnits[1];
  }

  runDPname = dpSubStr(runDPname, DPSUB_SYS_DP) + ".runType";
  if(!dpExists(runDPname)) return ERR_EXEC;
  string runType = getValueFromDpe(runDPname);
  switch(runType){
    case "COSMICS":   return COSMICS;
    case "PHYSICS":   return PHYSICS;
    case "TECHNICAL": return TECHNICAL;
    case "SYNTHETIC": return SYNTHETIC;
    case "LASER":     return LASER;
    default:          return NO_RUN;
  }
}

string getParameterString(){
  dyn_string parameterSearch = dpNames("*", "AliDcsRunAdditionalParameter");
  return dynlen(parameterSearch) ? dpSubStr(parameterSearch[1], DPSUB_SYS_DP) : "";
}
