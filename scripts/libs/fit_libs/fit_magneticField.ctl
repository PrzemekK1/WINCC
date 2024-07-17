// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author User
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)




//--------------------------------------------------------------------------------
// Variables and Constants
const dyn_string configDPE = dpNames("*", "FIT_DEFAULT_CONFIG");
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

public void initMagneticFieldDPEs(){
  while(1){
    if(dpConnect("solenoidValuesConnection", "dcs_globals:Magnet/ALICESolenoid.Current", "dcs_globals:Magnet/ALICESolenoid.RampingSts", "dcs_globals:Magnet/ALICESolenoid.Polarity")){
      DebugN("initMagneticFieldDPEs --> Could not connect to dcs_globals: restart in 5 seconds");
      delay(5);
    }else{
      DebugN("initMagnetFieldDPEs --> Connected");
      break;
    }
  }
  dpConnect("currentChanged_CB", dpSubStr("aliSolenoid.current", DPSUB_SYS_DP_EL));
  dpConnect("BfieldChanged_CB",  dpSubStr("aliSolenoid.Bfield", DPSUB_SYS_DP_EL), dpSubStr("aliSolenoid.polarity", DPSUB_SYS_DP_EL));

}


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

//connection local DPs with magnetDPs
private void solenoidValuesConnection( string dpe, float value, string dpe2, bool rampState, string dpe3, bool polarity){
  dpSetWait(dpSubStr("aliSolenoid.current", DPSUB_SYS_DP_EL), value,
            dpSubStr("aliSolenoid.rampingState", DPSUB_SYS_DP_EL), rampState,
            dpSubStr("aliSolenoid.polarity", DPSUB_SYS_DP_EL), polarity);
}

private void currentChanged_CB(string dpe, float value){
  dpSetWait(dpSubStr("aliSolenoid.Bfield", DPSUB_SYS_DP_EL), value * 0.45 / 30000);
}


private void BfieldChanged_CB(string dpe, float B, string dpep, bool polarity){
  string mode;
  if(polarity){
    if(B < 0.445) mode = "a02T";
    else mode = "a05T";
  }
  else{
    if(B < 0.445) mode = "c02T";
    else mode = "c05T";
  }
  if(B < 0.175) mode = "n00T";
  dpSetWait(configDPE + ".mode", mode);
}
