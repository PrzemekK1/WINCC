// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Set of functions to work with different configurations for NG alarm screen
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // DP type names

//--------------------------------------------------------------------------------
// variables and constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/// Get the names of all basic configurations in current system.
dyn_string AlarmScreenNgConfig_getBasicConfigs()
{
  dyn_string dsResult = dpNames(getSystemName() + "*", AS_BASIC_CONFIG_DP_TYPE);
  for(int n = dynlen(dsResult) ; n > 0 ; n--)
  {
    dsResult[n] = dpSubStr(dsResult[n], DPSUB_DP);
  }
  return dsResult;
}

/**
 * Get the names of all DPs with filter set configurations, optionally filtered
 * by the name of basic configuration for which these filter sets are built.
 * @param sBasicConfig The name of basic configuration, for which filter set
 *                    configs are requested. The empty string is interpreted as
 *                    "for non-existent basic configs"
 * @return Two 'parallel' lists:
 *          - result[1][n] = the name of nth DP with filter set configuration
 *          - result[2][n] = the name of filter set in this DP (the value of "SetName" DPE)
 */
dyn_dyn_string AlarmScreenNgConfig_getFilterSetConfigs(const string sBasicConfig = "")
{
  if(sBasicConfig == "")
  {
    return _AlarmScreenNgConfig_getFilterSetConfigsForOther();
  }

  // Find DP names
  string sQuery = "SELECT '_original.._value' FROM '*.ConfigDp' WHERE _DPT = \"" +
           AS_FILTER_SET_CONFIG_DP_TYPE + "\" AND '_original.._value' == \"" +
           sBasicConfig + "\"";
  dyn_dyn_anytype tab;
  dpQuery(sQuery, tab);
  //DebugN(__FUNCTION__ + "():", sQuery, tab);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    throwError(deErrors);
    return _AlarmScreenNgConfig_addFilterSetNames();
  }
  int iTabLen = dynlen(tab);
  if(iTabLen < 2)
  {
    return _AlarmScreenNgConfig_addFilterSetNames();  // query returned nothing
  }

  // Get names of sets for found DPs
  dyn_string dsDpNames; // The names of DPs with filter set definitions
  for(int i = 2 ; i <= iTabLen ; i++)
  {
    dynAppend(dsDpNames, dpSubStr(tab[i][1], DPSUB_SYS_DP));
  }
  return _AlarmScreenNgConfig_addFilterSetNames(dsDpNames);
}

/**
 * Create new filter set configuration for given basic config. New 'fixed'
 * name will be assigned to new filter set, assuming that later user will change
 * that name to something reasonable.
 * @param sBasicConfig The name of basic config for new filter set
 * @param exceptionInfo Any error will be written to this variable
 * @return DP name of new created filter set
 */
string AlarmScreenNgConfig_createFilterSet(const string &sBasicConfig, dyn_string &exceptionInfo)
{
  string sNameTemplate = AS_FILTER_SET_CONFIG_DP_TYPE + "_";
  string sDpName = AlarmScreenNg_createConfigDp(AS_FILTER_SET_CONFIG_DP_TYPE, sNameTemplate, exceptionInfo);
  if(sDpName == "")
  {
    return sDpName;  // Something went wrong
  }

  string sSetName = "==" + getUserName() + "==";
  time now = getCurrentTime();
  sSetName += ((string)year(now)) + ((string)month(now)) + ((string)day(now)) + "==";
  dpSet(sDpName + ".ConfigDp", sBasicConfig,
        sDpName + ".SetName", sSetName);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpSet() failed for " + sDpName + ":\n" +
                      getErrorText(deErrors), "");
    throwError(deErrors);
  }
  return sDpName;
}

/**
 * Check if DP with filter set configuration exists, if so - read the name of basic
 * config in this DP. The function is used by filter view editor to set up initial
 * selection in panel.
 * @param sDpName The name of DP to check
 * @param sBasicConfig The variable where name of basic config of given DP will be written,
 *                      provided that DP with filter set config exists
 * @return <c>true</c> if DP with given name exists and contains filter set configuration,
 *          though it is not checked if configuration is valid or not.
 */
bool AlarmScreenNgConfig_filterSetExists(const string &sDpName, string &sBasicConfig)
{
  sBasicConfig = "";
  if(!dpExists(sDpName))
  {
    return false;
  }
  if(dpTypeName(sDpName) != AS_FILTER_SET_CONFIG_DP_TYPE)
  {
    return false;  // in principle DP exists, but it is not of type we want
  }
  dpGet(sDpName + ".ConfigDp", sBasicConfig);
  return true;
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**
 * Get the names of all DPs with filter set configurations, where the value of
 * "ConfigDp" DPE does not correspond to one of existing basic config DPs
 * @return Two 'parallel' lists:
 *          - result[1][n] = the name of nth DP with filter set configuration
 *          - result[2][n] = the name of filter set in this DP (the value of "SetName" DPE)
 */
private dyn_dyn_string _AlarmScreenNgConfig_getFilterSetConfigsForOther()
{
  // find ConfigDp values for all DPs
  string sQuery = "SELECT '_original.._value' FROM '*.ConfigDp' WHERE _DPT = \"" +
           AS_FILTER_SET_CONFIG_DP_TYPE + "\"";
  dyn_dyn_anytype tab;
  dpQuery(sQuery, tab);
  //DebugN(__FUNCTION__ + "():", sQuery, tab);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    throwError(deErrors);
    return _AlarmScreenNgConfig_addFilterSetNames();
  }
  int iTabLen = dynlen(tab);
  if(iTabLen < 2)
  {
    return _AlarmScreenNgConfig_addFilterSetNames();  // query returned nothing
  }

  // Filter out those referring to known basic config DPs
  dyn_string dsBasicConfigs = AlarmScreenNgConfig_getBasicConfigs();
  dyn_string dsDpNames;
  for(int n = 2 ; n <= iTabLen ; n++)
  {
    if(dynContains(dsBasicConfigs, tab[n][2]) > 0)
    {
      continue;  // references one of know basic config DPs
    }
    dynAppend(dsDpNames, dpSubStr(tab[n][1], DPSUB_SYS_DP));
  }
  return _AlarmScreenNgConfig_addFilterSetNames(dsDpNames);
}

/**
 * Find names of filter sets, add these names to overall result.
 * @param dsDpNames List of DP names with filter set definitions
 * @return Two 'parallel' lists:
 *          - result[1][n] = the name of nth DP with filter set configuration
 *          - result[2][n] = the name of filter set in this DP (the value of "SetName" DPE)
 */
private dyn_dyn_string _AlarmScreenNgConfig_addFilterSetNames(const dyn_string dsDpNames = makeDynString())
{
  // Result always contains 2 items
  dyn_dyn_string ddsResult;
  ddsResult[1] = makeDynString();
  ddsResult[2] = makeDynString();
  int iTotal = dynlen(dsDpNames);
  if(iTotal == 0)
  {
    return ddsResult;
  }

  // Read the names of filters sets from corresponding DPE
  dyn_string dpSetNameDpes;
  for(int n = 1 ; n <= iTotal ; n++)
  {
    dynAppend(dpSetNameDpes, dsDpNames[n] + ".SetName");
  }
  dyn_string dsSetNames;
  dpGet(dpSetNameDpes, dsSetNames);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    throwError(deErrors);
    return ddsResult;
  }

  // Pack results to single value, sort by sort name
  ddsResult[1] = dsDpNames;
  ddsResult[2] = dsSetNames;

  //DebugN(__FUNCTION__ + "(): original:", ddsResult);
  dynDynTurn(ddsResult);
  //DebugN(__FUNCTION__ + "(): after turn:", ddsResult);
  dynDynSort(ddsResult, 2);
  //DebugN(__FUNCTION__ + "(): after sort:", ddsResult);
  dynDynTurn(ddsResult);
  //DebugN(__FUNCTION__ + "(): after turn #2:", ddsResult);
  return ddsResult;
}
