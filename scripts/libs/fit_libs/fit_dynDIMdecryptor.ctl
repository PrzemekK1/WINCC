// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "lookupTable_DI.ctl"
//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

public int getDeviceId(string DPE){  // -2 is error code
  if(DPE == "") return -1; //Configure ALL
  if(!dpExists(DPE)){
    DebugN("getParameterId ---> DPE does not exists: " + DPE);
    return -2;}
  if(!DPE.contains("settings")) return -2;
  if(DPE.contains("trigger")) return _getTriggerNo(DPE);
  if(DPE.contains("FEE/TCM")) return 20;

  uint PMNo = _getPMno(DPE), chNo = _getChNo(DPE), ADCno = _getADCno(DPE);
  if(chNo == 0 && PMNo == 0 && ADCno == 0) return -2;
  else return _calculateID(PMNo, chNo, ADCno);

}

public bool sendMassCommand(string parameterName, dyn_anytype &values, string dynCommandDPE){
  string comDpe;
  uint numberOfValues = _isParameterNameCorrect(parameterName, comDpe);
  if(!numberOfValues){
    DebugN("sendCommand ---> Can't define the amount of elements to check if it is correct");
    return false;
  }else{
    if(numberOfValues == dynlen(values)){
      dpSetWait( dpSubStr(dynCommandDPE, DPSUB_SYS_DP) + ".info.receivedMassCommand", true);
      dynCommandElementChanged(comDpe, values);

      //adding id = "-1" to dynamic list
      dynInsertAt(values, -1, 1);

      dpSetWait(comDpe                                             , values,
                dpSubStr(dynCommandDPE, DPSUB_SYS_DP) + ".info.receivedMassCommand", false);
      return true;
    }else{
      string res;
      sprintf(res, "sendCommand ---> Can't send command in %s: expexcted %u, received %u", comDpe, numberOfValues, dynlen(values));
      DebugN(res);
      return false;
    }
  }
}

public bool sendCommand(string dpe, int value, string dynCommandDPE){
  int id = getDeviceId(dpe);
  string par = _getDIMCommandDpe(dpe, dynCommandDPE);
  if(par && (id > -1)){
    dyn_string values = makeDynInt(id, value);
    dpSetWait(par, values);
    return true;
  }else{
    DebugN("sendCommand ---> Couldn't send a command " + par + " with id " + (string)id);
    return false;
  }
}

public string getChNameById(uint id){
  string format = "PM%c%u/Ch%02u", result;
  sprintf(result, format, (id % 20 < 10) ? 'A' : 'C', id % 10, id / 20 + 1);
  return result;

}

public getChannelsData(dyn_int &channels, fitLookUpTable &lut){

}

public getChnnelsTrigger(dyn_int &channels, fitLookUpTable &lut){

}



//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

private int _getPMno(string DPE){
  if(!DPE.contains("PM")) return 0;
  uint idx  = DPE.indexOf("PM");
  char side = DPE.at(idx + 2);
  if((side != 'C') && (side != 'A')) return 0;
  uint no   = (uint)DPE.at(idx + 3);
  if(no > 9) return 0;
  return ((uint)(side == 'C')) * 10  + no;
}

private int _getChNo(string DPE){
  if(!DPE.contains("Ch")) return 1;
  uint idx = DPE.indexOf("Ch");
  uint no  = (uint)DPE.mid(idx + 2, 2);
  if(no > 12){DebugN("_getChNo ---> Channel No is more than 12. Check the DP name"); return 0;}
  return no;
}

private int _getADCno(string DPE){
  if(!DPE.contains("ADC")) return 0;
  uint idx = DPE.indexOf("ADC");
  if(DPE.at(idx + 3) == "_") return 0;
  uint no  = (uint)DPE.at(idx + 3);
  if(no > 1) return 0;
  return DPE.contains("ADC1");
}

public int _getTriggerNo(string DPE){
  uint idx = DPE.indexOf("trigger");
  int no  = (int)DPE.at(idx + 7);
  if((no < 1) || (no > 5)) return 0;
  return no;
}

private uint _calculateID(uint PMNo, uint chNo, uint ADCno){
  return 240 * ADCno + (chNo - 1) * 20 + PMNo;
}

//return the number of neccessary elements in values list. 0 is error
private uint _isParameterNameCorrect(string parameter, string &commandDPE){
  dyn_string tmp = dpNames("dynCommands.*." + parameter, "DIM_dynCommands");
  string dpe;
  uint result = 0;
  if(dynlen(tmp) == 1){
    dpe = tmp[1];
    commandDPE = dpe;
    tmp = strsplit(dpe, ".");
    if(tmp[2] == "fitPMchannel" && tmp[3] == "ADC_RANGE") result = 480;
    else if(tmp[2] == "fitPMchannel") result = 240;
    else if(tmp[2] == "fitReadout") result = 21;
    else if(tmp[2] == "fitTrigger") result = 5;
    else if(tmp[2] == "fitPM") result = 20;
    else DebugN("_isParameterNameCorrect ---> Can't find the command dpe: " + dpe);
  }
  return result;
}

private string _getDIMCommandDpe(string dpe, string dynCommandDPE){
  string prefix = dynCommandDPE + ".";
  dpe = dpSubStr(dpe, DPSUB_SYS_DP_EL);
  dyn_string dsDpe = strsplit(dpe, ".");
  if(dynlen(dsDpe) == 3){
    if(dsDpe[3] != "ADC1_RANGE" && dsDpe[3] != "ADC0_RANGE")
      return (prefix + dpTypeName(dpe) + "." + dsDpe[3]);
    else
      return (prefix + dpTypeName(dpe) + ".ADC_RANGE");
  }else{
    DebugN("_getDIMCommandDpe ---> Bad name of dpe: " + dpe);
    return "";
  }
}

private connectParameter(string parameter){
  string commandDPE, tmp;
  int numOfelements = _isParameterNameCorrect(parameter, commandDPE);
  if(!numOfelements) {return;}
  dyn_string tmp = strsplit(commandDPE, "."), dpes = dpNames("*.settings." + parameter, tmp[2]);
  for(uint i = 1; i <= dynlen(dpes); ++i){
    dpConnect("sendCommand", false, dpes[i]);
  }
}

private disconnectParameter(string parameter){
  string commandDPE, tmp;
  int numOfelements = _isParameterNameCorrect(parameter, commandDPE);
  if(!numOfelements) {return;}
  dyn_string tmp = strsplit(commandDPE, "."), dpes = dpNames("*.settings." + parameter, tmp[2]);
  for(uint i = 1; i <= dynlen(dpes); ++i){
   dpDisconnect("sendCommand", dpes[i]);
  }
}

dynCommandElementChanged(string dpe, dyn_anytype &values){
  dpe = dpSubStr(dpe, DPSUB_DP_EL);
  dyn_string splitName = strsplit(dpe, ".");
  string dpType = splitName[2], par = splitName[3];
  if(par.contains("ADC_RANGE")) par = "ADC?_RANGE";
  dyn_string dpeToTransmit = dpNames(((dpType == "fitTrigger") ? "*trigger*" : "*") + ".settings." + par, dpType);
  for(uint i = 1; i <= dynlen(dpeToTransmit); ++i){
    dpSetWait(dpeToTransmit[i], values[getDeviceId(dpeToTransmit[i]) + (int)(dpType != "fitTrigger")]);
  }
}

// private anytype getDynServiceContent(string name){
//   anytype content;
//   dyn_string dynService("dynServices." + "")
// }
