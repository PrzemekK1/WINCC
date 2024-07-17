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

public const string  _TABLE_DP_TYPE = "_fitConfigurationTable";
private const string _TABLE_DP_NAME_FORMAT = "%s_%s_%s"; //format of the datapoint name - baemMode_runType_Parameter


//positions of meta fields in name of configuration table
public const uint META_BEAM_MODE = 1;
public const uint META_RUN_TYPE = 2;
public const uint META_PARAMETER = 3;

private const dyn_string _EMPTY_CONF = makeDynString("", "", "", "", "");
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

//create DPT for configuration table datapoints if one does not exist
public void initConfigurationTables(){
  if(dpTypeExists(_TABLE_DP_TYPE)) return;
  dyn_dyn_string depes = makeDynAnytype(
                                        makeDynString(_TABLE_DP_TYPE, ""),
                                        makeDynString("", "HV"),
                                        makeDynString("", "FEE")
                                        );

  dyn_dyn_int depei = makeDynAnytype(
                                     makeDynInt(DPEL_STRUCT),
                                     makeDynInt(0, DPEL_DYN_STRING),
                                     makeDynInt(0, DPEL_DYN_STRING)
                                     );

  dpTypeCreate(depes, depei);
}

//create new configuration table (datapoint)
public bool createNewConfigurationTable(const string beamMode, const string runType, const string parameter = ""){
  string dpName;
  sprintf(dpName, _TABLE_DP_NAME_FORMAT, beamMode, runType, parameter);
  if(!dpExists(dpName)){
    dpCreate(dpName, _TABLE_DP_TYPE);
    dpSetWait(dpName + ".HV", _EMPTY_CONF, dpName + ".FEE", _EMPTY_CONF);
  }
  return dpExists(dpName);
}

public bool setConfigurationTable(const string tableName, const dyn_string HV, const dyn_string FEE){
  if(!dpExists(tableName)) return false;
  return 0 == dpSetWait(tableName +  ".HV", HV, tableName + ".FEE", FEE);
}

public bool getConfigurationTable(const string tableName, dyn_string &HV, dyn_string &FEE){
  if(!dpExists(tableName)) return false;
  return 0 == dpGet(tableName + ".HV", HV, tableName + ".FEE", FEE);

}

public bool isTableExists(const string beamMode, const string runType, const string parameter = ""){
  string dpName;
  sprintf(dpName, _TABLE_DP_NAME_FORMAT, beamMode, runType, parameter);
  return dpExists(dpName);
}

public string getTableMeta(string dpName, uint meta = META_BEAM_MODE){
  dpName = dpSubStr(dpName, DPSUB_DP);
  dyn_string ds = strsplit(dpName, "_");
  return meta > dynlen(ds) ? "" : ds[meta];
}



//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

