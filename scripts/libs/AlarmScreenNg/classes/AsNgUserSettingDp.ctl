// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Class encapsulating functionality required for operations with user setting DPs
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions

//--------------------------------------------------------------------------------
// variables and constants

/** Possible values for usage of given user setting */
//@{
const uint AS_NG_USER_SETTING_USAGE_ORDINARY = 0;  ///< ordinary setting, the main purpose is to select manually
const uint AS_NG_USER_SETTING_USAGE_USER_DEFAULT = 1;  ///< default setting for current user
const uint AS_NG_USER_SETTING_USAGE_DEFAULT = 2;  ///< default setting for all users
//@}

/** Indexes for parts of information returned by different getXxx() methods */
//@{
const int AS_NG_USER_SETTING_PART_DP = 1;  ///< DP name where user setting is found
const int AS_NG_USER_SETTING_PART_NAME = 2;  ///< Human-readable name of this setting
const int AS_NG_USER_SETTING_PART_USAGE = 3;  ///< Intended usage of this user setting
const int AS_NG_USER_SETTING_PART_USER = 4;   ///< name of user who wrote this setting
const int AS_NG_USER_SETTING_PART_DFTL_FILTER = 5;  ///< int (enum): how default filter shall be changed when these settings is applied
//@}

/** How the default filter modified when loading user settings */
//@{
const uint AS_NG_USER_SETTINGS_DFLT_FILTER_KEEP = 0;  ///< Keep previously set default filter unchanged
const uint AS_NG_USER_SETTINGS_DFLT_FILTER_RESET = 1;  ///< Reset default filter to default of filter editor
const uint AS_NG_USER_SETTINGS_DFLT_FILTER_APPLY = 2;  ///< Set the default filter to filter saved together with these user settings
//@}

/**
 * This class provides a number of public methods, required for loading and
 * saving user settings, as well as obtaining list of user settings for selection.
 */
class AsNgUserSettingDp {

  /**
   * Get existing user settings for selection
   * @param sBasicConfig The name of basic configuration DP for which user settings are requested
   * @param bCurrentUser <c>true</c> if only settings created by/suitable for current
   *                      WinCC OA user are requested
   * @return List of available user settings, the format of returned list is (see constants
   *          AS_NG_USER_SETTING_PART_xxx above):
   *      - result[1][n]: [string] DP name containing nth user setting
   *      - result[2][n]: [string]  human-readable name/description of nth setting
   *      - result[3][n]: [uint] the usage of nth setting, see AS_NG_USER_SETTING_USAGE_xxx constants
   *      - result[4][n]: [string] The name of user who written nth setting
   *      - result[5][n]: [uint] how default filter shall be changed when this settings is applied
   */
  public dyn_dyn_anytype getExisting(const string &sBasicConfig, bool bCurrentUser = true) {

    // Query DP names for given configuration, additionally filtered by DP name template
    string sDpNameTemplate = bCurrentUser ? getDpNameTemplate() : getNeutralDpNameTemlate();
    string sQuery = "SELECT '_original.._value', '_original.._user' FROM '*.ConfigDp' " +
                    " WHERE _DPT = \"" + AS_USER_SETTING_DP_TYPE + "\"" +
                    " AND _DP LIKE \"" + sDpNameTemplate + "*\"" +
                    " AND '_original.._value' == \"" + sBasicConfig + "\"";
    dyn_dyn_anytype queryTab;
    dpQuery(sQuery, queryTab);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors)) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpQuery() failed"));
      throwError(deErrors);
      return makeDynAnytype();
    }
    dyn_string dsDpNames, dsUserNames, dsNames;
    dyn_uint duUsages, duDfltFilters;
    for(int idx = dynlen(queryTab) ; idx > 1 ; idx--) {
      dynAppend(dsDpNames, dpSubStr(queryTab[idx][1], DPSUB_SYS_DP));
      dynAppend(dsUserNames, findUserName(queryTab[idx][1], queryTab[idx][2]));
      dynAppend(dsNames, "");
      dynAppend(duUsages, AS_NG_USER_SETTING_USAGE_ORDINARY);
      dynAppend(duDfltFilters, AS_NG_USER_SETTINGS_DFLT_FILTER_KEEP);
    }
    dyn_dyn_anytype ddaResult = completeExisting(dsDpNames, dsNames, duUsages, dsUserNames, duDfltFilters);

    // Add 'default for all users', even if this is request for particular user
    if(bCurrentUser) {
      if(dynContains(ddaResult[AS_NG_USER_SETTING_PART_USAGE], AS_NG_USER_SETTING_USAGE_DEFAULT) < 1) {
        dyn_anytype daDefault = getDefault(sBasicConfig, true);
        if(dynlen(daDefault) > 0) {
          dynAppend(ddaResult[AS_NG_USER_SETTING_PART_DP], daDefault[AS_NG_USER_SETTING_PART_DP]);
          dynAppend(ddaResult[AS_NG_USER_SETTING_PART_NAME], daDefault[AS_NG_USER_SETTING_PART_NAME]);
          dynAppend(ddaResult[AS_NG_USER_SETTING_PART_USAGE], daDefault[AS_NG_USER_SETTING_PART_USAGE]);
          dynAppend(ddaResult[AS_NG_USER_SETTING_PART_USER], daDefault[AS_NG_USER_SETTING_PART_USER]);
          dynAppend(ddaResult[AS_NG_USER_SETTING_PART_DFTL_FILTER], daDefault[AS_NG_USER_SETTING_PART_DFTL_FILTER]);
        }
      }
    }
    return ddaResult;
  }

  /**
   * Find DP with default setting - either for current user only, or for all users
   * @param sBasicConfig The name of basic configuration DP for which user settings are requested
   * @param bForAll <c>true</c> if default applicable to al users is required
   * @return Information for default user setting, for interpretation of different parts of
   *     this information see contants AS_NG_USER_SETTING_PART_xxx above;
   *     or empty dyn_anytype if 'default for all' is not found.
   */
  public dyn_anytype getDefault(const string sBasicConfig, bool bForAll) {

    string sQuery = "SELECT '_original.._value', '_original.._user', '_original.._stime'" +
                    " FROM '*.Usage' WHERE _DPT = \"" + AS_USER_SETTING_DP_TYPE + "\"";
    if(!bForAll) {
      sQuery += " AND _DP LIKE \"" + getDpNameTemplate() + "*\"";
    }
    uint uUsage = bForAll ? AS_NG_USER_SETTING_USAGE_DEFAULT : AS_NG_USER_SETTING_USAGE_USER_DEFAULT;
    sQuery += " AND '_original.._value' == " + uUsage + " SORT BY 3 DESC";

    dyn_dyn_anytype queryTab;
    dpQuery(sQuery, queryTab);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors)) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpQuery() failed"));
      throwError(deErrors);
      return makeDynAnytype();
    }

    if(dynlen(queryTab) < 2) {
      return makeDynAnytype();  // not found
    }

    // Find which of queried DPs is for required basic config
    dyn_string dsDpeNames;
    int iTotal = dynlen(queryTab);
    for(int idx = 2 ; idx <= iTotal ; idx++) {
      dynAppend(dsDpeNames, dpSubStr(queryTab[idx][1], DPSUB_SYS_DP) + ".ConfigDp");
    }
    dyn_string dsConfigDps;
    dpGet(dsDpeNames, dsConfigDps);
    deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpGet(ConfigDp) failed for " + dynlen(dsDpeNames) +
                           " DPE(s)"));
      throwError(deErrors);
      return makeDynAnytype();
    }
    int iDpIdx = dynContains(dsConfigDps, sBasicConfig);
    if(iDpIdx < 1) {
      return makeDynAnytype();  // not found for this config
    }

    // Build the final result, plus query setting name
    dyn_anytype daResult = makeDynAnytype(
        dpSubStr(dsDpeNames[iDpIdx], DPSUB_SYS_DP),  // DP name
        "",                                          // setting name, not known yet
        AS_NG_USER_SETTING_USAGE_DEFAULT,            // Usage
        findUserName(dsDpeNames[iDpIdx], queryTab[iDpIdx + 1][2]));        // user name
    string sName;
    int defaultFilter;
    dpGet(daResult[1] + ".SettingName", sName,
          daResult[1] + ".DefaultFilter", defaultFilter);
    deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpGet() failed for " + daResult[1] + ".SettingName"));
      throwError(deErrors);
    }
    daResult[AS_NG_USER_SETTING_PART_NAME] = sName;
    daResult[AS_NG_USER_SETTING_PART_DFTL_FILTER] = defaultFilter;
    return daResult;
  }

  /**
   * Load user settings definition (JSON string) from given DP
   * @param sDpName The name of DP where user settings definition shall be read
   * @param uDefaultFilter The variable where default filter action will be returned
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @return The string read from user settings definition in given DP; this method doesn't check
   *          for syntax of return string.
   */
  public string load(const string &sDpName, uint &uDefaultFilter, dyn_string &exceptionInfo) {
    string sResult;
    dpGet(sDpName + ".SettingJSON", sResult,
          sDpName + ".DefaultFilter", uDefaultFilter);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpGet(" + sDpName + ") failed", "");
      throwError(deErrors);
      return "";
    }
    return sResult;
  }

  /**
   * Delete a DP containing user settings.
   * @param sSettingsDp User settings DP to be deleted
   * @param exceptionInfo The variable where error description will be added if something went wrong
   */
  public void deleteSettingsDp(const string &sSettingsDp, dyn_string &exceptionInfo)
  {
    if(!dpExists(sSettingsDp))
    {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): DP does not exist " + sSettingsDp, "");
      return;
    }
    // Prevent deleting by mistake DP of another type
    string sTypeName = dpTypeName(sSettingsDp);
    if(sTypeName != AS_USER_SETTING_DP_TYPE)
    {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): DP " + sSettingsDp + " is not of user settings DPT, but rather " +
                        sTypeName, "");
      return;
    }
    // ready to delete
    dpDelete(sSettingsDp);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0)
    {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpDelete(" + sSettingsDp + ") failed", "");
      throwError(deErrors);
    }
  }

  /**
   * Read user settings usage from given DP
   * @param sDpName The name of DP where user settings usage shall be read
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @return The value read from user settings usage in given DP.
   */
  public uint getUsageForDp(const string &sDpName, dyn_string &exceptionInfo) {
    uint uResult = AS_NG_USER_SETTING_USAGE_ORDINARY;
    dpGet(sDpName + ".Usage", uResult);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpGet(" + sDpName + ") failed", "");
      throwError(deErrors);
      return "";
    }
    return uResult;
  }

  /**
   * Save JSON string with user settings with given setting name.
   * The user settings are saved in DPs of dedicated DP type.
   * Function checks if DP, containing user settings with the same name, already exists in system.
   * If such DP was written by current user, then it can be overwritten with new settings.
   * Content of DP, written by another user, can't be overwritten.
   * @param sName The name of user setting that shall be written together with JSON definition
   * @param sBasicConfig The name of DP, containing basic configuration of AS, where user setting is used
   * @param sJson User settings to save = string in JSON format
   * @param uDefaultFilter What shall happen with default filter when configuration is loaded, must be
   *                       one of constants AS_NG_USER_SETTINGS_DFLT_FILTER_XXX
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @param bForce <c>true</c> if content of existing DP shall be overwritten by this call
   * @return Enumerated result of execution, see possible values of enum
   */
  public AlarmScreenNgSaveResult save(const string sName, const string &sBasicConfig,
                                      const string sJson, uint uDefaultFilter,
                                      dyn_string &exceptionInfo, bool bForce = false) {
    if(!checkParametersForSave(sName, sBasicConfig, sJson, exceptionInfo)) {
      return AlarmScreenNgSaveResult::Failure;
    }
    //DebugN(__FUNCTION__ + "():", sBasicConfig, sName);

    string sDpName;
    AlarmScreenNgSaveResult result = findDpToSave(sName, sBasicConfig, bForce, sDpName, exceptionInfo);
    if(result != AlarmScreenNgSaveResult::Success) {
      return result;
    }

    dpSet(sDpName + ".ConfigDp", sBasicConfig,
          sDpName + ".SettingName", sName,
          sDpName + ".SettingJSON", sJson,
          sDpName + ".DefaultFilter", uDefaultFilter);
    // Don't write Usage - leave it unchanged, default value 0 is good default for new DP

    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpSet(" + sDpName + ") failed", "");
      return AlarmScreenNgSaveResult::Failure;
    }
    return AlarmScreenNgSaveResult::Success;
  }

  /**
   * Set usage value for given DP.
   * @param sDpName The name of DP to set
   * @param uUsage The usage of this setting, see AS_NG_USER_SETTING_USAGE_xxx constants
   * @param exceptionInfo Error information will be added to this variable in case of error
   */
  public bool setUsage(const string &sDpName, uint uUsage, dyn_string &exceptionInfo) {
    if(!checkUsageValue(uUsage, exceptionInfo)) {
      return false;
    }
    dpSet(sDpName + ".Usage", uUsage);

    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpSet(" + sDpName + ") failed", "");
      return false;
    }
    return true;
  }

  /// Get the short name of action for default filter when loading user settings
  public string getShortNameOfDefaultFilterAction(uint action) {
    switch(action) {
      case AS_NG_USER_SETTINGS_DFLT_FILTER_KEEP:
        return "Keep";
      case AS_NG_USER_SETTINGS_DFLT_FILTER_RESET:
        return "Reset";
      case AS_NG_USER_SETTINGS_DFLT_FILTER_APPLY:
        return "Apply";
      }
    return "??? " + action;
  }

  /**
   * Pack result of searching existing user settings to single variable for return,
   * add missing information on settings names and their usages
   * @param dsDpNames List of DP names with user settings
   * @param dsNames List of human-readable names, empty string, to be filled
   * @param duUsages List of usages for settings, to be filled
   * @param dsUserNames List of user names who wrote these settings
   * @param duDfltFilters How default filter shall be updated when loading settings
   * @return results packed to single variable, see description of getExisting()
   */
  private dyn_dyn_anytype completeExisting(const dyn_string &dsDpNames, const dyn_string &dsNames,
                                           const dyn_uint &duUsages, const dyn_string &dsUserNames,
                                           const dyn_uint &duDfltFilters) {
    dyn_dyn_anytype ddaResult;
    ddaResult[AS_NG_USER_SETTING_PART_DP] = dsDpNames;
    ddaResult[AS_NG_USER_SETTING_PART_NAME] = dsNames;
    ddaResult[AS_NG_USER_SETTING_PART_USAGE] = duUsages;
    ddaResult[AS_NG_USER_SETTING_PART_USER] = dsUserNames;
    ddaResult[AS_NG_USER_SETTING_PART_DFTL_FILTER] = duDfltFilters;
    int iTotal = dynlen(dsDpNames);
    if(iTotal == 0) {
      return ddaResult;
    }

    // Get visible names of all user settings
    dyn_string dsDpeNames;
    for(int idx = 1 ; idx <= iTotal ; idx++) {
      dynAppend(dsDpeNames, dsDpNames[idx] + ".SettingName");
    }
    dyn_string dsRealNames;
    dpGet(dsDpeNames, dsRealNames);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpGet(SettingName) failed for " + iTotal + " DPE(s)"));
      throwError(deErrors);
      return ddaResult;
    }
    ddaResult[AS_NG_USER_SETTING_PART_NAME] = dsRealNames;

    // Get usages for all user settings
    dynClear(dsDpeNames);
    for(int idx = 1 ; idx <= iTotal ; idx++) {
      dynAppend(dsDpeNames, dsDpNames[idx] + ".Usage");
    }
    dyn_uint duRealUsages;
    dpGet(dsDpeNames, duRealUsages);
    deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpGet(Usage) failed for " + iTotal + " DPE(s)"));
      throwError(deErrors);
      return ddaResult;
    }
    ddaResult[AS_NG_USER_SETTING_PART_USAGE] = duRealUsages;

    // Get actions for default filter when loading/applying user settings
    dynClear(dsDpeNames);
    for(int idx = 1 ; idx <= iTotal ; idx++) {
      dynAppend(dsDpeNames, dsDpNames[idx] + ".DefaultFilter");
    }
    dyn_uint duRealDefaultFilter;
    dpGet(dsDpeNames, duRealDefaultFilter);
    deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): dpGet(Usage) failed for " + iTotal + " DPE(s)"));
      throwError(deErrors);
      return ddaResult;
    }
    ddaResult[AS_NG_USER_SETTING_PART_DFTL_FILTER] = duRealDefaultFilter;

    return ddaResult;
  }

  /**
   * Check parameters passed for saving user settings into SP. Normally one of inconsistencies,
   * detected by this method, can only come as a result of mistake in code, user actions should
   * not lead to such errors.
   * @param sName The name of user setting that shall be written together with JSON definition
   * @param sBasicConfig The name of DP, containing basic configuration of AS, where user setting is used
   * @param sJson User settings to save = string in JSON format
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @return Enumerated result of execution, see possible values of enum
   */
  private bool checkParametersForSave(const string sName, const string &sBasicConfig,
                                      const string sJson, dyn_string &exceptionInfo) {
    // Check parameters
    if(sBasicConfig == "") {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): the name of basic config must be non-empty string", "");
      return false;
    }
    if(sName == "") {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): setting name must be non-empty string", "");
      return false;
    }
    if(sJson == "") {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): user setting (JSON) must be non-empty string", "");
      return false;
    }
    return true;
  }

  /**
   * Check the value of usage before writing it to DP
   * @param uUsage The usage of this setting, see AS_NG_USER_SETTING_USAGE_xxx constants
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @return <c>true</c> if value is correct
   */
  private bool checkUsageValue(uint uUsage, dyn_string &exceptionInfo) {
    switch(uUsage) {
      case AS_NG_USER_SETTING_USAGE_ORDINARY:
      case AS_NG_USER_SETTING_USAGE_USER_DEFAULT:
      case AS_NG_USER_SETTING_USAGE_DEFAULT:
        return true;
    }
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): unexpected usage value: " + uUsage, "");
    return false;
  }

  /**
   * Find the name of DP where user settings with given name shall be stored. The following
   * main variants are possible:
   *  - such name is already used for user settings of current user, the question can be
   *      asked if user wants to override existing setting
   *  - such name is already used for user settings of another user, we can't override settings
   *      of another user
   *  - settings with such name does not exist, new DP shall be created
   * In all cases the search is limited to settings for given basic config, in this sense the
   * name of basic config DP plays a role of 'name space'.
   * @param sName The name of user setting that shall be written together with JSON definition
   * @param sBasicConfig The name of DP, containing basic configuration of AS, where user setting is used
   * @param bForce <c>true</c> if content of existing DP is allowed to be overwritten
   * @param sDpName Found DP name will be written to this variable
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @return Enumerated result of execution, see possible values of enum
   */
  private AlarmScreenNgSaveResult findDpToSave(const string &sName, const string &sBasicConfig, bool bForce,
                                               string &sDpName, dyn_string &exceptionInfo) {
    dyn_dyn_anytype ddaExisting = findByName(sName, sBasicConfig, exceptionInfo);
    if(dynlen(exceptionInfo) > 0) {
      return AlarmScreenNgSaveResult::Failure;
    }
    if(dynlen(ddaExisting[AS_NG_USER_SETTING_PART_DP]) > 0) {  // DP was found
      if(ddaExisting[AS_NG_USER_SETTING_PART_USER][1] == getUserName()) {  // this is my setting
        if(bForce) {
          sDpName = ddaExisting[AS_NG_USER_SETTING_PART_DP][1];
          return AlarmScreenNgSaveResult::Success;
        }
        else {
          return AlarmScreenNgSaveResult::Exists;
        }
      }
      else {  // DP belongs to somebody else
        return AlarmScreenNgSaveResult::ExistsAlien;
      }
    }

    // DP does not exist, we have to create new one
    string sTemplate = getDpNameTemplate();
    sDpName = AlarmScreenNg_createConfigDp(AS_USER_SETTING_DP_TYPE, sTemplate, exceptionInfo);
    if(sDpName == "") {
      return AlarmScreenNgSaveResult::Failure;
    }
    return AlarmScreenNgSaveResult::Success;
  }

  /**
   * Find information for existing user setting with given name.
   * @param sName The name of user setting that shall be written together with JSON definition
   * @param sBasicConfig The name of DP, containing basic configuration of AS, where user setting is used
   * @param exceptionInfo Error information will be added to this variable in case of error
   * @return information for found setting, see description of getExisting() for format of result
   */
  private dyn_dyn_anytype findByName(const string &sName, const string &sBasicConfig, dyn_string &exceptionInfo) {

    dyn_string dsDpNames, dsNames, dsUserNames;
    dyn_uint duUsages, duDfltFilters;

    string sQuery = "SELECT '_original.._value', '_original.._user' FROM '*.SettingName'" +
                    " WHERE _DPT = \"" + AS_USER_SETTING_DP_TYPE + "\"" +
                    " AND  '_original.._value' == \"" + sName + "\"";
    dyn_dyn_anytype queryTab;
    dpQuery(sQuery, queryTab);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpQuery() failed", "");
      return completeExisting(dsDpNames, dsNames, duUsages, dsUserNames, duDfltFilters);
    }
    int iTotal = dynlen(queryTab);
    if(iTotal < 2) {  // not found
      return completeExisting(dsDpNames, dsNames, duUsages, dsUserNames, duDfltFilters);
    }

    // Find which of found settings is for this basic config
    dyn_string dsDpeNames;
    for(int idx = 2 ; idx <= iTotal ; idx++) {
      dynAppend(dsDpeNames, dpSubStr(queryTab[idx][1], DPSUB_SYS_DP) + ".ConfigDp");
    }
    dyn_string dsConfigNames;
    dpGet(dsDpeNames, dsConfigNames);
    deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpGet(ConfigDp) failed", "");
      return completeExisting(dsDpNames, dsNames, duUsages, dsUserNames, duDfltFilters);
    }

    int iUseful = dynContains(dsConfigNames, sBasicConfig);
    if(iUseful > 0) {
      dynAppend(dsDpNames, dpSubStr(dsDpeNames[iUseful], DPSUB_SYS_DP));
      dynAppend(dsNames, sName);
      dynAppend(duUsages, AS_NG_USER_SETTING_USAGE_ORDINARY);
      dynAppend(dsUserNames, findUserName(dsDpNames[1], queryTab[iUseful + 1][3]));
    }
    return completeExisting(dsDpNames, dsNames, duUsages, dsUserNames, duDfltFilters);
  }

  /**
   * Find the namer of user who created user setting DP with given name.
   * Normally the name of user could be extracted from DP name itself because
   * DP names are built according to certain rules (see getDpNameTemplate()).
   * Just in (unusual) case of 'wrong' DP name, we can try to find the owner
   * using the user ID who wrote (one of) DPEs of this DP.
   * @param sDpName The name of DP for which user name shall be found
   * @param uUserId The ID of user who wrote DPE value, used as spare variant
   *                for finding user name
   * @return Calculated user name
   */
  private string findUserName(const string &sDpName, uint uUserId) {
    string sResult, sName = dpSubStr(sDpName, DPSUB_DP);

    string sPrefix = getNeutralDpNameTemlate();
    if(sName.startsWith(sPrefix)) {
      sName = sName.right(sName.length() - sPrefix.length());
      // Remove digits at the end of string
      string sLastChar = sName.at(sName.length() - 1);
      while(("0" <= sLastChar) && (sLastChar <= "9")) {
        sName.chop(1);
        sLastChar = sName.at(sName.length() - 1);
      }
      // If last character is '_' after removing digits - then the rest of string before '_' must be the name
      if(sName.endsWith("_")) {
        sResult = sName.left(sName.length() - 1);
      }
    }
    //DebugN(__FUNCTION__ + "(): result #1", sDpName, sResult);
    if(sResult.isEmpty()) {
      sResult = getUserName(uUserId);
    }
    return sResult;
  }

  /**
   * Get template for DP name of user settings for current user. The rule for building
   * the final DP name is: <template>_<number>
   * @return The constant part of user setting DP name for current user
   */
  private string getDpNameTemplate() {
    string sResult = AS_USER_SETTING_DP_TYPE + "_" + getUserName() + "_";
    nameCheck(sResult, NAMETYPE_DP);  // Make sure the name doesn't contain wrong chars
    return sResult;
  }

  /**
   * Get template for DP name of user settings for any user. The rule for building
   * the final DP name is: <template>_<number>
   * @return The constant part of user setting DP name for any user
   */
  private string getNeutralDpNameTemlate() {
    return AS_USER_SETTING_DP_TYPE + "_";
  }
};
