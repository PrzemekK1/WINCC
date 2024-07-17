// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
void initTimers(){
  dyn_string timers = dpNames("*", "fitTimer");
  string tmpTimer;
  for(uint i = 1; i <= dynlen(timers); ++i){
    tmpTimer = dpSubStr(timers[i], DPSUB_SYS_DP);
    dpConnectUserData("timerInitialisation_CB", tmpTimer, false, (string)getValueFromDpe(tmpTimer + ".triggerDPE"));
  }
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

private timerInitialisation_CB(string timerDPE, string dpe, anytype value){
  if(!getValueFromDpe(timerDPE + ".active")) return;
  dyn_string values = getValueFromDpe(timerDPE + ".values");
  int idx = values.indexOf((string)value) + 1;
  if(!idx) return;

  long countDown = (long)getValueFromDpe(timerDPE + ".timeout");
  dpSetWait(timerDPE + ".inProcess", true);
  while(countDown){
    delay(1);
    dpSetWait(timerDPE + ".countDown", --countDown);
  }
  dpSetWait(timerDPE + ".countDown", getValueFromDpe(timerDPE + ".timeout"));

  callFunction((string)dynDPEvalueByIndex(timerDPE + ".instructions", idx));
  dpSetWait(timerDPE + ".inProcess", false);
}

private reduceVoltage(){
  const float rDwn     = (float)getValueFromDpe(HV_CHANNELS_REF[1] + ".readBackSettings.rDwn");
  const float actV     = (float)getValueFromDpe(HV_CHANNELS_REF[1] + ".actual.vMon");
  const float targetV  = 1590.0;
  const float targetI  = 338.0;
  unsigned del = (int)ceil(abs(actV - targetV) / rDwn) + 2;

  dpSetWait(HV_CHANNELS_REF[1] + ".settings.v0", targetV);
  delay(del);
  dpSetWait(HV_CHANNELS_REF[1] + ".settings.i0", targetI);
}

private turnOffRef(){
  for(uint i = 1; i <= dynlen(HV_CHANNELS_REF); ++i)
    dpSetWait(HV_CHANNELS_REF[i] + ".settings.onOff", false);

}
