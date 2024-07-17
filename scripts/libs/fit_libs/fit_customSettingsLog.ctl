// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "alidcsUi/dcsUiLibrary.ctl"
#uses "alidcsUi/dcsUiFSMLibrary.ctl"
#uses "alidcsUi/dcsUiObjectLibrary.ctl"
#uses "alidcsUi/dcsUiScopeLibraryV2.ctl"


//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
void getSettingsDPEs(dyn_string &names, const string systName){
  names = dpNames(systName + "FEE/PM??/Ch??.actual.{ADC0_RANGE,ADC1_RANGE,ADC_DELAY,ADC_ZERO,CFD_THRESHOLD,TIME_ALIGN,THRESHOLD_CALIBR}", "fitPMchannel");
  dynAppend(names, dpNames(systName + "FEE/PM??/Ch??.settings.*", "fitPMchannel"));
  dynAppend(names, dpNames(systName + "FEE/PM??.settings.*", "fitPM"));
  dynAppend(names, dpNames(systName + "FEE/PM??/Readout.settings.*", "fitReadout"));
  dynAppend(names, dpNames(systName + "FEE/TCM.settings.*", "fitTCM"));
  dynAppend(names, dpNames(systName + "FEE/TCM/trigger*.settings.*", "fitTrigger"));
  dynAppend(names, dpNames(systName + "fcb??.commands.*", "FIT_FCB"));
  dynAppend(names, dpNames(systName + "fcbFIT.writeBlock", "_fcbProperties"));
  dynAppend(names, dpNames(systName + "CAEN/FT0_HV/board??/channel0??.settings.*", "FwCaenChannelA7030"));
  dynAppend(names, dpNames(systName + "CAEN/FT0_HV.Commands.*", "FwCaenCrateSY1527"));
  dynAppend(names, dpNames(systName + "Wiener/FT0_?.General.Commands.*", "FwWienerCrate"));
  dynAppend(names, dpNames(systName + "ft0*.collitionRate.integrationTime", "Lhc_Lum_ALILuminositySource"));
  dynAppend(names, dpNames(systName + "ft0_calibration.busy", "fit_calibration"));
  dynAppend(names, dpNames(systName + "ft0BadChannelMapControl.status.state", "fitBadChannelMapControl"));

}

settingsFields_CB(const string topNodeWithSystem, string dpe, anytype value){
  string ownerID;
  dpGet(topNodeWithSystem + ".mode.owner", ownerID);
  dyn_string tmp = strsplit(dpe, ":");
  if(dynlen(tmp) >1)
    writeLog(tmp[2], value, ownerID ? fwUi_getManagerIdInfo(ownerID) : "admin", topNodeWithSystem.left(8));
}

private void writeLog(string dpeName, anytype value, string user, string systName, time t = getCurrentTime()){
  //Take date pieces for file naming (one file one day)
//   int d = day(t), m = month(t), y = year(t);
  string pathToFile = getLogFileName(t, systName);
  file f = fopen(pathToFile, "a");
  fputs(dpeName + "," + (string)value + "," + (string)t + "," + user + "\n",f);
  fclose(f);
}

void readLog(dyn_dyn_string &logContent, string systName, time t = getCurrentTime()){
  string pathToFile = getLogFileName(t, systName), line;
  DebugN(pathToFile);
  file f = fopen(pathToFile, "r");
//   uint lineCnt = 1;
  while (feof(f) == 0){
      fgets(line, 200, f);
      if(strlen(line)){
        line.remove(line.length() - 1, 1);
        dynAppend(logContent, strsplit(line, ","));
      }
  }
  fclose(f);
}

string getLogFileName(time t = getCurrentTime(), string systName = ""){
  return PROJ_PATH + "log/" + systName.left(7) + "/" + (string)day(t) + "_" + (string)month(t) + "_" + (string)year(t);
}

initLogWriting(const string systName, const string TOP_NODE_NAME){
  dyn_string dpesToLog;
  getSettingsDPEs(dpesToLog, systName);
  for(uint i = 1; i <= dynlen(dpesToLog); ++i)
    dpConnectUserData("settingsFields_CB", systName + "fwCU_" + TOP_NODE_NAME, false, dpesToLog[i]);
}


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

