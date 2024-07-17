// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "fit_libs/fit_functions.ctl"
//--------------------------------------------------------------------------------
// Variables and Constants

const string ALI_SOLENOID_BFIELD = THIS_SYSTEM_NAME + "aliSolenoid.Bfield";
const string ALI_SOLENOID_POLARI = THIS_SYSTEM_NAME + "aliSolenoid.Polarity";
const bool                 MINUS = true;
const bool                  PLUS = false;
const bool                DEF_HV = true;
const bool               DEF_FEE = false;

const uint B_05N = 1;
const uint B_02N = 2;
const uint B_00  = 3;
const uint B_02P = 4;
const uint B_05P = 5;

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

public void BFieldChanged_CB(string configurationDP, string BfieldDPE, float Bfield, string polarityDPE, bool polarity){
  Bfield *= (polarity == MINUS ? -1. : 1.);
  uint BfieldCode = getBcode(Bfield);
  configurationDP = dpSubStr(configurationDP, DPSUB_SYS_DP);

  dpSetWait(configurationDP + ".actual.field", BfieldCode);

  changeDefault(configurationDP, BfieldCode,  DEF_HV);
  changeDefault(configurationDP, BfieldCode, DEF_FEE);
}

public int configureHVDevice(string device){
  //protocol:
  //flip _userbit1 to trigger callback
  //_userbit2 is set to true by callback when configuration is done
  //_userbit3 is true if there is an error
  //this function should reset _userbits2 to false and _userbit3 to false if necessary
  //
  //this function should return:
  //  1 if there is an error
  //  0 if successful

  bool trigbit;
  dpGet(device+".userDefined:_original.._userbit1", trigbit);
  dpSetWait(device+".userDefined:_original.._userbit1", !trigbit);

  waitUntill(device+".userDefined:_original.._userbit2", TRUE);
  dpSetWait(device+".userDefined:_original.._userbit2", FALSE);

  bool err;
  dpGet(device+".userDefined:_original.._userbit3", err);
  if (err) {
    dpSetWait(device+".userDefined:_original.._userbit3", FALSE);
    DebugTN(device + " could not be configured");
    return 1;
  } else {
    DebugTN(device + " was successfully configured");
    return 0;
  }
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

private uint getBcode(float Bfield){
  Bfield += 0.45;
  return (uint)(Bfield > 0.72 ? 5 : (Bfield < 0.18 ? 1 : (Bfield / 0.18 + 1)));
}

//type = true - change the HV settings, type = false - change the FEE settings;
private void changeDefault(string configurationDP, uint BfieldCode, bool type = DEF_HV){
  dyn_string settings; string actualSetting;
  configurationDP = dpSubStr(configurationDP, DPSUB_SYS_DP);

  dpGet(configurationDP + (type ? ".settings.HVrecipes" : ".settings.FEEconfigs"), settings,
        configurationDP + (type ? ".actual.HVrecipe" : ".actual.FEEconfig"), actualSetting);

  if(settings[BfieldCode] != actualSetting)
    dpSetWait(configurationDP + (type ? ".actual.HVrecipe" : ".actual.FEEconfig"), settings[BfieldCode]);

}


