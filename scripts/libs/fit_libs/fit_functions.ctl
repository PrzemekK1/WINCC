// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//this functions are used in project or make the development more convinient
//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "csv"
#uses "fit_libs/fit_constants.ctl"
#uses "lookUpTable_DI.ctl"
//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Same as dynAppend but input of 2 dyn_string lists and more

  @param [dyn_string, ...] - dyn_string lists one by one with comma, in the required order of concatenation
  @return concatenated dyn_string

*/
public dyn_string concatenateDyn(...){
  dyn_string result = makeDynString();
  va_list parameters;
  uint len = va_start(parameters);
  for(uint i = 1; i <= len; ++i)
    dynAppend(result, parameters[i]);
  va_end(parameters);
  return result;
}

//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Modify the list of datapoints to the list of datapoint elements in the same oreder

  @param DPs - list of datapoints to be modifyed
  @param [dyn_string, ...] - list of elements to be modifyed
  @return [dyn_string]list of modifyed datapoints

  NOTE: the function does not check if the datapoint element exists

*/
public dyn_string modifyDPtoDPEelements(dyn_string DPs, ...){
  dyn_string result = makeDynString();
  va_list parameters;
  uint len = va_start(parameters);
  for(uint i = 1; i <= len; ++i){
    for(uint k = 1; k <= dynlen(DPs); ++k){
      dynAppend(result, dpSubStr(DPs[k], DPSUB_SYS_DP) + withDotNotation(parameters[i]));
    }
  }
  va_end(parameters);
  return result;
}

public void activateAllFEEchannels(const fitLookUpTable &lut, string dynCommand, bool turnOn = true){
  const fitLookUpTableEntry _LUT_CH_NO = fitLookUpTableEntry("channel #", lut);
  const fitLookUpTableEntry _LUT_LK_ID = fitLookUpTableEntry("Link ID",   lut);
  const fitLookUpTableEntry _LUT_EP_ID = fitLookUpTableEntry("EP ID"  ,   lut);
  const fitLookUpTableEntry _LUT_PM_CH = fitLookUpTableEntry("PM channel",lut);
   dyn_bit32 command = makeDynBit32(-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                   0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
   dyn_uint channels = _LUT_CH_NO.getData();
   for(uint i = 1; i <= dynlen(channels); ++i){
     setBit(command[_LUT_LK_ID.getCorrespondingProperty(_LUT_CH_NO, channels[i]) + 2 + 10 * _LUT_EP_ID.getCorrespondingProperty(_LUT_CH_NO, channels[i])], _LUT_PM_CH.getCorrespondingProperty(_LUT_CH_NO, channels[i]) - 1, turnOn);
   }
   dpSetWait(dynCommand, command);
}


//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Same as dynlen but require dtapoint element name with dyn type;

  @param dpe - datapoint element name
  @return [int]size of dynemic datapoint element
  \li -1 - when datapoint element does not exist

*/
public int dynlenDPE(string dpe){
  dyn_anytype dn;
  if(dpExists(dpe)){
    dpGet(dpe, dn);
  }else{
    return -1;
  }
  return dynlen(dn);
}

//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Rewrite the datapoint element to update it's timestamp or trigger the CB function

  @param dpName - datapoint element name
  @return [int]result of dpSetWait()

*/
public int refreshDP(string dpName){
  anytype value;
  dpGet(dpName, value);
  return dpSetWait(dpName, value);
}

//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Returns the element on the specidied position of the dynamic datapoint element

  @param dpeName - datapoint element name
  @param position - position of the element in list (begins with 1)
  @return [anytype] content at this position

*/
public anytype dynDPEvalueByIndex(string dpeName, uint position){
  dyn_anytype da;
  dpGet(dpeName, da);
  return da[position];
}

//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Returns the the alias and dpName not depending on what was specified in input

  @param input - datapoint element or alias
  @param dpName - set output for dpName
  @param alias  - set output for alias
  @return [void]

*/
public getAliasAndDPname(string input, string &dpName, string &alias){
  if(dpExists(input)){
    dpName = input;
    alias  = dpNameToAlias(dpName);
  }else if(aliasExists(input)){
    alias  = input;
    dpName = dpAliasToName(alias);
  }
}


//---------------------------------------------------------------------------------------------------------------------------------------
/**
  The same as dpGet but return the content of the specified element

  @param datapointName - the name of datapoint where the required value stored
  @return [anytype] the value of the datapoint element

*/
public anytype getValueFromDpe(string datapointName){
  anytype value;
  dpGet(datapointName, value);
  return value;
}


//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Make a pause in script execution untill the specified datapoint element value won't be equal to required value

  @param dpe - the name of datapothe name of datapoint where the required value storedint where the required value stored
  @param value - the value, which is rquired from dpe to continue the script execution
  @param stepTime - Seconds. The time between the checks of datapont element
  @param timeout - Seconds. Maximum time for the pause in this code.
  @return [bool] code
  \li TRUE - the event happened before timeout
  \li FALSE - the event did not happened

*/
public bool waitUntill(string dpe, anytype value, uint stepTime = 1, uint timeout = 10){
  anytype getvalue;
  uint count = 0;
  while(true){
    if(count >= timeout) return false;
    dpGet(dpe, getvalue);
    if(getvalue == value) return true;
    delay(stepTime);
    count+=stepTime;
  }
}

//Do not remember why do we need it
public string getSourcePath(){
  return (getSystemName() == THIS_SYSTEM_NAME ? PROJ_PATH : "Z:/DCS_Common/dcs_share/ft0_share/");
}
/*
  Convert dyn list of aliases to the list of DP names without dot on the end. Used for constant definition etc.
  @param aliases - list of aliases to be converted
*/
public dyn_string dpAliasesToNames(dyn_string aliases){
  dyn_string names;
  string nm;
  for(uint i = 1; i <= dynlen(aliases); ++i){
    nm = dpAliasToName(aliases[i]);
    nm.chop(1);
    names.append(nm);
  }
  return names;
}

/*
  Check if the process procName is in the tasklist of the system
  @param procName - name of the process to find in task list
*/
public bool isInTaskList(string procName){
  string output;
  system("tasklist /FI \"IMAGENAME eq " + procName + "*\"", output);
  return output.contains(procName);
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------------------------------
/**
  Returns the same string str but with dot in the position 1 if needed

*/
private string withDotNotation(string str){
  return str.at(0) == "." ? str : ("." + str);
}










