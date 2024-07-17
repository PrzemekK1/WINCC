// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Set of functions to support operations with filters (save/load/etc.)
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"
#uses "fwGeneral/fwException.ctl"

//--------------------------------------------------------------------------------
// variables and constants

/**
 * The following constants are indices for different parts of filter information,
 * as returned by AlarmScreenNgFilters_loadNames()
 */
//@{
const int NGAS_FILTER_INFO_DP = 1;    ///< [string] The name of DP where filter is stored
const int NGAS_FILTER_INFO_NAME = 2;  ///< [string] The name of filter given when filter was saved
const int NGAS_FILTER_INFO_DATE = 3;  ///< [time] Date + time when filter was written to DP
const int NGAS_FILTER_INFO_USER = 4;  ///< [string] The name of user who saved this filter
//@}

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
 * Load names of previously saved filters, with optional selection.
 *
 * Note: the logic of this function is based on order of columns in used query text,
 * thus the change in query may require change in the code of this function.
 * @param sNameMask The mask for name filter, empty string means 'all'.
 * @param bCurrentUserOnly <c>true</c> if only filters written by current user
 *                         shall be queried
 * @param bExactNameMatch <c>true</c> if sNameMask is expected to contain exact filter name,
 *                        even if contains wildcard character(s)
 * @return information on found filter, see contents NGAS_FILTER_INFO_XXX above
 */
dyn_dyn_anytype AlarmScreenNgFilters_loadNames(const string &sNameMask, bool bCurrentUserOnly, bool bExactNameMatch = false)
{
  dyn_dyn_anytype ddaDummy;
  string sQuery = _AlarmScreenNgFilters_buildFilterNamesQuery(sNameMask, bCurrentUserOnly, bExactNameMatch);
  dyn_dyn_anytype queryResult;
  dpQuery(sQuery, queryResult);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    return ddaDummy;
  }
  if(dynlen(queryResult) < 2)
  {
    return ddaDummy;
  }

  // Remove first item of all results: the first item is header
  dynDynTurn(queryResult);
  for(int n = dynlen(queryResult) ; n > 0 ; n--)
  {
    dynRemove(queryResult[n], 1);
  }

  // Two of columns, returned by query, can be used 'as is' (name and time),
  // while DP name and user ID need conversion.
  mapping mUserConversion;
  dyn_string dsUserNames, dsDpNames;
  int iResultSize = dynlen(queryResult[NGAS_FILTER_INFO_DP]);
  for(int n = 1 ; n <= iResultSize ; n++)
  {
    dynAppend(dsDpNames, dpSubStr(queryResult[NGAS_FILTER_INFO_DP][n], DPSUB_SYS_DP));
    if(!mappingHasKey(mUserConversion, queryResult[NGAS_FILTER_INFO_USER][n]))
    {
      mUserConversion[queryResult[NGAS_FILTER_INFO_USER][n]] = getUserName(queryResult[NGAS_FILTER_INFO_USER][n]);
    }
    dynAppend(dsUserNames, mUserConversion[queryResult[NGAS_FILTER_INFO_USER][n]]);
  }
  queryResult[NGAS_FILTER_INFO_DP] = dsDpNames;
  queryResult[NGAS_FILTER_INFO_USER] = dsUserNames;
  return queryResult;
}

/**
 * Load filter definition (JSON string) from given DP
 * @param sDpName The name of DP where filter definition shall be read
 * @param exceptionInfo Error information will be added to this variable in case of error
 * @return The string read from filter definition in given DP; this function doesn't check
 *          for syntax of filter definition string.
 */
string AlarmScreenNgFilters_loadFilter(const string sDpName, dyn_string &exceptionInfo)
{
  string sResult;
  dpGet(sDpName + ".FilterJSON", sResult);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpGet(" + sDpName + ") failed", "");
    throwError(deErrors);
    return "";
  }
  return sResult;
}

/**
 * Save string with filter definition in JSON format with given filter name.
 * The filters are saved in DPs of dedicated DP type.
 * Function checks if DP, containing filter with the same name, already exists in system.
 * If such DP was written by current user, then it can be overwritten with new filter.
 * Content of DP, written by another user, can't be overwritten.
 * @param sFilterName The name of filter that shall be written together with filter definition
 * @param sFilterJson Filter definition = string in JSON format
 * @param sBasicConfig The name of DP, containing basic configuration of AS, where filter is used
 * @param exceptionInfo Error information will be added to this variable in case of error
 * @param bForce <c>true</c> if content of existing DP shall be overwritten by this call
 * @return Enumerated result of execution, see possible values of enum
 */
AlarmScreenNgSaveResult AlarmScreenNgFilters_saveFilter(const string &sFilterName, const string &sFilterJson,
                                                           const string &sBasicConfig,
                                                           dyn_string &exceptionInfo, bool bForce = false)
{
  // Check parameters
  if(sFilterName == "")
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): filter name must be non-empty string", "");
    return AlarmScreenNgSaveResult::Failure;
  }
  if(sFilterJson == "")
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): filter definition (JSON) must be non-empty string", "");
    return AlarmScreenNgSaveResult::Failure;
  }
  //DebugN(__FUNCTION__ + "():", sBasicConfig, sFilterName);

  // Check if filter with such name already exists
  string sFilterDp;
  dyn_dyn_anytype ddaFilterData = AlarmScreenNgFilters_loadNames(sFilterName, false, true);
  if((dynlen(ddaFilterData) > 0) && (dynlen(ddaFilterData[NGAS_FILTER_INFO_DP]) > 0))
  {
    if(ddaFilterData[NGAS_FILTER_INFO_USER][1] != getUserName())
    {
      return AlarmScreenNgSaveResult::ExistsAlien;
    }
    else if(!bForce)
    {
      return AlarmScreenNgSaveResult::Exists;
    }
    sFilterDp = ddaFilterData[NGAS_FILTER_INFO_DP];
  }

  // Create new DP if this is not 'override existing' operation
  if(sFilterDp == "")
  {
    string sDpNameTemplate = AS_FILTER_CONFIG_DP_TYPE + "_" + getUserName() + "_";
    sFilterDp = AlarmScreenNg_createConfigDp(AS_FILTER_CONFIG_DP_TYPE, sDpNameTemplate, exceptionInfo);
    if(sFilterDp == "")
    {
      return AlarmScreenNgSaveResult::Failure;
    }
  }

  // Finally - write everything to DP
  dpSet(sFilterDp + ".FilterName", sFilterName,
        sFilterDp + ".ConfigDp", sBasicConfig,
        sFilterDp + ".FilterJSON", sFilterJson);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    throwError(deErrors);
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpSet(" + sFilterDp + ") failed", "");
    return AlarmScreenNgSaveResult::Failure;
  }

  return AlarmScreenNgSaveResult::Success;
}

/**
 * Check if filter, stored in given DP, can be already used in one of filter sets.
 * In order to be 100% sure that exactly this DP is used, the JSON definition of filter
 * set shall be parsed and analyzed.<br>
 * Here more simplified approach is used: check if string with JSON definition of some
 * filter set contains the name of this DP. There is a chance to make mistake, but mistake
 * can be in one direction only: we can decide that DP is used while in reality it is not.
 * @param sFilterDp The name of DP containing filter definition
 * @return <c>true</c> if this name appears in JSON definition for one of filter sets
 */
bool AlarmScreenNgFilters_filterAlreadyUsed(const string &sFilterDp)
{
  string sQuery = "SELECT '_original.._value'" +
                  " FROM '*.SetJSON'" +
                  " WHERE _DPT = \"" + AS_FILTER_SET_CONFIG_DP_TYPE + "\" AND" +
                  " '_original.._value' LIKE \"*" + dpSubStr(sFilterDp, DPSUB_DP) + "*\" FIRST 1";
  dyn_dyn_anytype ddaTab;
  dpQuery(sQuery, ddaTab);
  return (dynlen(ddaTab) > 1);
}

/**
 * Delete DP, containing filter definition.
 * @param sFilterDp The name of DP to be deleted
 * @param exceptionInfo The variable where error description will be added if something went wrong
 */
void AlarmScreenNgFilters_deleteFilter(const string &sFilterDp, dyn_string &exceptionInfo)
{
  if(!dpExists(sFilterDp))
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): DP does not exist " + sFilterDp, "");
    return;
  }
  // Prevent deleting by mistake DP of another type
  string sTypeName = dpTypeName(sFilterDp);
  if(sTypeName != AS_FILTER_CONFIG_DP_TYPE)
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): DP " + sFilterDp + " is not filter, but rather " +
                      sTypeName, "");
    return;
  }
  // ready to delete
  dpDelete(sFilterDp);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpDelete(" + sFilterDp + ") failed", "");
    throwError(deErrors);
  }
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**
 * Build the text of query for retrieving filter definitions , stored in DPs
 * @param sNameMask The mask for name filter, empty string means 'all'.
 * @param bCurrentUserOnly <c>true</c> if only filters written by current user
 *                         shall be queried
 * @param bExactNameMatch <c>true</c> if sNameMask is expected to contain exact filter name,
 *                        even if contains wildcard character(s)
 * @return text of query for execution
 */
private string _AlarmScreenNgFilters_buildFilterNamesQuery(const string &sNameMask, bool bCurrentUserOnly,
                                                           bool bExactNameMatch = false)
{
  string sQuery = "SELECT '_online.._value','_online.._stime','_original.._user'" +
                  " FROM '*.FilterName' " +
                  " WHERE _DPT = \"" + AS_FILTER_CONFIG_DP_TYPE + "\"";
  if(sNameMask != "")
  {
    sQuery += " AND  '_online.._value' " + (bExactNameMatch ? "==" : "LIKE") +
              " \"" + sNameMask + "\"";
  }
  if(bCurrentUserOnly)
  {
    sQuery += " AND '_original.._user' = " + getUserId();
  }
  //DebugN("sQuery:", sQuery);
  return sQuery;
}
