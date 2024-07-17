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
const string FT0_SAFETY_SYSTEM_NAME = "ft0_dcs:";
const string FV0_SAFETY_SYSTEM_NAME = "fv0_dcs:";
const string FDD_SAFETY_SYSTEM_NAME = "fdd_dcs:";


//FT0 constants
const dyn_string FT0_SAFETY_HV_CHANNELS     = dpAliasesToNames(dpAliases("*FT0_{A,C}/MCP_??", "*"));
const dyn_string FT0_SAFETY_HV_CHANNELS_REF = dpAliasesToNames(dpAliases("*MCP_LC", "*"));
const dyn_string FT0_SAFETY_WIENER          = dpAliasesToNames(dpAliases("FT0/Wiener/FT0_{A,C}", "*"));

//FV0 constants
const dyn_string FV0_SAFETY_HV_CHANNELS     = dpAliasesToNames(dpAliases("FV0/HV/S{A,B,C,D,E,F,G,H}*", "*."));
const dyn_string FV0_SAFETY_HV_CHANNELS_REF = dpAliasesToNames(dpAliases("FV0/HV/SREF", "*."));
const dyn_string FV0_SAFETY_WIENER          = dpAliasesToNames(dpAliases("FV0/Wiener/alifv0wie001", "*"));

//FDD constants
const dyn_string FDD_SAFETY_HV_CHANNELS     = dpAliasesToNames(dpAliases("FDD/SIDE_{A,C}/LAYER?/PMT_?_?", "*"));
const dyn_string FDD_SAFETY_HV_CHANNELS_REF = dpAliasesToNames(dpAliases("*SIDE_?/HV_{A8,C9,C32}", "*")); //need to be checked
const dyn_string FDD_SAFETY_WIENER          = dpAliasesToNames(dpAliases("FDD/Wiener/alifddwie001", "*"));

//Type of the list, to be returned
const uint SAFETY_HV_CHS_ENUM = 1;
const uint SAFETY_HV_REF_ENUM = 2;
const uint SAFETY_WIENER_ENUM = 3;

private const string SAFETY_WIENER_STAT_POWER = ".General.Status.GetPowerOn";
private const string SAFETY_WIENER_COMM_POWER = ".General.Commands.OnOffCrate";

private const mapping safetyConstantsMap = makeMapping(
    FT0_SAFETY_SYSTEM_NAME, makeDynAnytype(FT0_SAFETY_HV_CHANNELS, FT0_SAFETY_HV_CHANNELS_REF, FT0_SAFETY_WIENER),
    FV0_SAFETY_SYSTEM_NAME, makeDynAnytype(FV0_SAFETY_HV_CHANNELS, FV0_SAFETY_HV_CHANNELS_REF, FV0_SAFETY_WIENER),
    FDD_SAFETY_SYSTEM_NAME, makeDynAnytype(FDD_SAFETY_HV_CHANNELS, FDD_SAFETY_HV_CHANNELS_REF, FDD_SAFETY_WIENER)
                                               );


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

public dyn_string getSafetyList(uint listType){
  return (dyn_string)safetyConstantsMap[getSystemName()][listType];
}

//--------------------------------------------------------------------------------
//SAFETY STATE
//--------------------------------------------------------------------------------

//check, if bit .General.Status.GetPowerOn == TRUE at least one crate from crates
public bool areWienerCratesOn(const dyn_string &crates){
  bool isOn = false;
  for(uint i = 1; i <= dynlen(crates); ++i){
    dpGet(crates[i] + SAFETY_WIENER_STAT_POWER, isOn);
    if(isOn) break;
  }
  return isOn;
}

//check, if bit .actual.isOn == TRUE at least one channel from channels
public bool areHVchannelsOn(const dyn_string &channels){
  bool isOn = false;
  for(uint i = 1; i <= dynlen(channels); ++i){
     dpGet(channels[i] + ".actual.isOn", isOn);
    if(isOn) break;
  }
  return isOn;
}

//--------------------------------------------------------------------------------
//SAFETY CONTROL
//--------------------------------------------------------------------------------

//set the control bit .General.Commands.OnOffCrate to on for all crates
public void turnWienerCrates(const dyn_string &crates, bool on){
  if(dynlen(crates) == 1){
    dpSetWait(crates[1] + SAFETY_WIENER_COMM_POWER, on);
  }else if(dynlen(crates) == 2){
    string firstCrate = crates[on ? 2 : 1],
          secondCrate = crates[on ? 1 : 2];
    bool firstIsOn;
    dpSet(firstCrate + SAFETY_WIENER_COMM_POWER, on);
    while(1){
      on ? delay(.1) : delay(1);
      dpGet(firstCrate + SAFETY_WIENER_STAT_POWER, firstIsOn);
      if(firstIsOn == on) break;
    }
    dpSet(secondCrate + SAFETY_WIENER_COMM_POWER, on);
  }
}

//set the control bit .settings.onOff to on for all channels
public void turnHVchannels(const dyn_string &channels, bool on){
  for(uint i = 1; i <= dynlen(channels); ++i){
    dpSetWait(channels[i] + ".settings.onOff", on);
  }
}


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

