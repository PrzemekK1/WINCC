// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Default processing for actions, requested by AS EWO
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // common definitions
#uses "AlarmScreenNg/AlarmScreenNgActions.ctl"  // constants for action names
#uses "AlarmScreenNg/classes/AsNgUserSettingDp.ctl"  // operations with user settings
#uses "AlarmScreenNg/classes/AsNgArchiveAccess.ctl"  // operations with ORACLE RDB access data

//--------------------------------------------------------------------------------
// variables and constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
 * Default (config-independent) processing of event "ctrlActionRequested" from EWO.
 * @param mArgs event arguments, it is expected that mapping contains specific keys
 *              of type string:
 *              - "ewoShape": the value is a AS EWO where event came from
 *              - "sAction": the name of action to be executed
 * @return <c>true</c> if action was completed successfully. Note that 'successfully'
 *            does not necessary mean the requested action was completed, it just means
 *            that no errors were found during processing.
 */
bool AlarmScreenNgActionProcessing_process(const mapping &mArgs)
{
  shape ewo = mArgs["ewoShape"];
  if(ewo == 0)
  {
    throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                         __FUNCTION__ + "(): EWO shape not found in arguments"));
    return false;
  }
  //DebugN(__FUNCTION__ + "(): action is " + mArgs["sAction"]);
  switch(mArgs["sAction"])
  {
  case AS_EWO_ACTION_BASIC_CONFIG_APPLIED:
    return _AlarmScreenNgActionProcessing_basicConfigApplied(ewo);
  case AS_EWO_ACTION_ORACLE_PASS_REQUEST:
    return _AlarmScreenNgActionProcessing_oraclePassRequest(mArgs, ewo);
  case AS_EWO_ACTION_SAVE_FILTER:
    return _AlarmScreenNgActionProcessing_saveFilter(ewo);
  case AS_EWO_ACTION_LOAD_FILTER:
    return _AlarmScreenNgActionProcessing_loadFilter(ewo);
  case AS_EWO_ACTION_EDIT_FILTER_SET:
    return _AlarmScreenNgActionProcessing_editFilterSet(ewo);
  case AS_EWO_ACTION_EDIT_USER_SETTINGS:
    return _AlarmScreenNgActionProcessing_editUserSettings(ewo);
  case AS_EWO_ACTION_LOAD_USER_SETTINGS:
    return _AlarmScreenNgActionProcessing_loadUserSettings(ewo);
  case AS_EWO_ACTION_SAVE_USER_SETTINGS:
    return _AlarmScreenNgActionProcessing_saveUserSettings(ewo);
  case AS_EWO_ACTION_SET_DEFAULT_SETTINGS:
    return _AlarmScreenNgActionProcessing_defaultUserSettings(ewo);
  case AS_EWO_ACTION_ADMIN_ACCESS_CONTROL:
    return _AlarmScreenNgActionProcessing_accessControl(ewo);
  case AS_EWO_ACTION_ADMIN_POPUP_MENU:
    return _AlarmScreenNgActionProcessing_popupMenuEditor(ewo);
  case AS_EWO_ACTION_ADMIN_ORACLE_RDB_SETTINGS:
    return _AlarmScreenNgActionProcessing_oracleRdbSettings(ewo);
  case AS_EWO_ACTION_ADMIN_HELP_FILE_TYPES:
    return _AlarmScreenNgActionProcessing_helpFileTypesEditor(ewo);
  }
  throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                       "Unexpected EWO action requested '" + mArgs["sAction"] + "'"));
  return false;
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**
 * Process readiness of EWO (after setting new basic config). The default
 * processing is to find default user settings (if any) and apply it to EWO.
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_basicConfigApplied(const shape &ewo)
{
  // Apply user settings
  string sBasicConfig = ewo.basicConfigDp;
  if(!sBasicConfig.isEmpty())
  {
    AsNgUserSettingDp setAccess;
    dyn_dyn_anytype ddaSetting = setAccess.getDefault(sBasicConfig, false);  // default for this user
    if(ddaSetting.isEmpty())  // not found
    {
      ddaSetting = setAccess.getDefault(sBasicConfig, true);  // default for allUsers
    }
    if(!ddaSetting.isEmpty())  // something was found
    {
      dyn_string exceptionInfo;
      uint uDefaultFilter;
      string sJson = setAccess.load(ddaSetting[AS_NG_USER_SETTING_PART_DP][1], uDefaultFilter, exceptionInfo);
      if(exceptionInfo.isEmpty() && (!sJson.isEmpty()))
      {
        ewo.applyUserSettings(sJson, uDefaultFilter);
      }
    }
  }

  return true;
}

/**
 * Process decoding of password read by EWO from configuration DPE
 * @param mArgs event arguments, it is expected that mapping contains specific keys
 *              of type string:
 *              - "sPassEncoded": encoded password, to be decoded and passed back to EWO
 *              - "ewoShape": the value is a AS EWO where event came from
 *              - "sAction": the name of action to be executed
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_oraclePassRequest(const mapping &mArgs, const shape &ewo)
{
  string sPass, sKey = "sPassEncoded";
  if(mappingHasKey(mArgs, sKey))
  {
    sPass = mArgs[sKey];
  }
  else
  {
    DebugN(__FUNCTION__ + "(): argument doesn't contain key " + sKey, mArgs);
    return false;
  }
  // Apply settings for ORACLE RDB access
  AsNgArchiveAccess rdbAccess;
  ewo.setOracleRdbPass(rdbAccess.decodePwd(sPass));
  return true;
}

/**
 * Save current filter from EWO into DPE
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_saveFilter(const shape &ewo)
{
  string sBasicConfig = ewo.basicConfigDp;
  string sFilter = ewo.getFilter(true);  // true = compact JSON
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AlarmScreenNgFilterSaveLoad.pnl", "FilterAccess",
                           makeDynString("$bSaveMode:" + true,
                                         "$sBasicConfig:" + sBasicConfig,
                                         "$sFilter:" + sFilter));
  return true;  // Was filter saved or not - that was user's choice
}

/**
 * Load the filter definition from DP, apply it to AS EWO
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_loadFilter(const shape &ewo)
{
  string sBasicConfig = ewo.basicConfigDp;
  dyn_string dsReturn;
  dyn_float dfReturn;
  ChildPanelOnCentralModalReturn("vision/AlarmScreenNg/AlarmScreenNgFilterSaveLoad.pnl", "FilterAccess",
                           makeDynString("$bSaveMode:" + false,
                                         "$sBasicConfig:" + sBasicConfig),
                           dfReturn, dsReturn);
  if(dynlen(dsReturn) < 1)
  {
    return true;  // Cancel operation == user's choice
  }
  string sError = ewo.applyFilter(dsReturn[1]);
  if(sError != "")
  {
    throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 81,  // 00081,Syntax error
                         "Applying filter failed: " + sError));
  }
  return true;
}

/**
 * Open the panel for editing filters statistics set (== filter view),
 * passing as argument the name of filter set DP used in EWO
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_editFilterSet(const shape &ewo)
{
  string sBasicConfig = ewo.basicConfigDp;
  string sFilterSetDp = ewo.filterSetDp;
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AlarmScreenNgFilterViewEditor.pnl", "FilterViewEditor",
                                 makeDynString("$sBasicConfig:" + sBasicConfig,
                                               "$sFilterSetDp:" + sFilterSetDp));
  return true;  // open the panel - and that's it
}

/**
 * Open the panel for editing current user settings of AS EWO
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_editUserSettings(const shape &ewo)
{
  const string sBaseName = "NgAsUserSettingsEditor";
  string sModuleName = sBaseName + "_" + ewo.getUniqueId();  // Unique module name for every EWO instance
  string sPanelName = "vision/AlarmScreenNg/AsNgUserSetting.pnl";
  if(isModuleOpen(sModuleName))
  {
    if(isPanelOpen(sBaseName, sModuleName))
    {
      moduleRaise(sModuleName);
      return true;  // Module and panel already (still?) exists, simply raise it
    }
  }
  else  // New module with default position at the center of panel with EWO
  {
    int iPanelX, iPanelY, iPanelWidth, iPanelHeight;
    panelPosition("", "", iPanelX, iPanelY);
    panelSize("", iPanelWidth, iPanelHeight, true);
    dyn_int diNewPanelSize = getPanelSize(sPanelName);
    int iNewPanelX = iPanelX + (iPanelWidth / 2) - (diNewPanelSize[1] / 2);
    if(iNewPanelX < 0)
    {
      iNewPanelX = 0;
    }
    int iNewPanelY = iPanelY + (iPanelHeight / 2) - (diNewPanelSize[2] / 2);
    if(iNewPanelY < 0)
    {
      iNewPanelY = 0;
    }
    ModuleOn(sModuleName, iNewPanelX, iNewPanelY);
  }
  RootPanelOnModule(sPanelName, sBaseName, sModuleName, makeDynString());

  // Opened panel contains another panels reference = shape with name 'editor'
  // wait for that shape to appear
  string sFullShapeName = sModuleName + "." + sBaseName + ":editor";
  time tStart = getCurrentTime();
  while(!shapeExists(sFullShapeName))
  {
    delay(0, 200);
    time tNow = getCurrentTime();
    if((tNow - tStart) > 5) // Wait for at most 5 seconds
    {
      string sError = "Editor panel does not appear after 5 sec, giving up...";
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): " + sError));
      ChildPanelOnCentralModal(
          "vision/MessageWarning",
          getCatStr("sc", "attention"),
          makeDynString("$1:" + sError));
      ModuleOff(sModuleName);
      return false;
    }
  }

  // Pass EWO shape to editor panel, then editor panel will do the rest
  shape editor = getShape(sFullShapeName);
  editor.setShape(myModuleName(), myPanelName(), ewo);
  return true;
}

/**
 * Open panel for loading previously saved user settings from dedicated DP,
 * loaded setting is applied to AS EWO.
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_loadUserSettings(const shape &ewo)
{
  string sBasicConfig = ewo.basicConfigDp;
  if(sBasicConfig == "")
  {
    ChildPanelOnCentralModal(
        "vision/MessageWarning",
        getCatStr("sc", "attention"),
        makeDynString("$1:AS EWO has empty basic config, user settings can't be loaded"));
    return false;
  }
  dyn_float dfReturn;
  dyn_string dsReturn;
  ChildPanelOnCentralModalReturn("vision/AlarmScreenNg/AsNgUserSettingSaveLoad.pnl", "UserSettingSaveLoad",
                                 makeDynString("$bSaveMode:false",
                                               "$sBasicConfig:" + sBasicConfig),
                                 dfReturn, dsReturn);
  if(dynlen(dfReturn) > 1)
  {
    if(dfReturn[1] != 0)
    {
      if(dynlen(dsReturn) > 0)
      {
        uint uDefaultFilter = dfReturn[2];
        string sError = ewo.applyUserSettings(dsReturn[1], uDefaultFilter);
        if(sError != "")
        {
          throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                               __FUNCTION__ + "(): applyUserSettings() returned: " + sError));
        }
      }
    }
  }
  return true;  // open the panel - and that's it
}

/**
 * Open panel for saving current user settings of AS EWO into dedicated DP
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_saveUserSettings(const shape &ewo)
{
  string sBasicConfig = ewo.basicConfigDp;
  if(sBasicConfig == "")
  {
    ChildPanelOnCentralModal(
        "vision/MessageWarning",
        getCatStr("sc", "attention"),
        makeDynString("$1:AS EWO has empty basic config, user settings can't be saved"));
    return false;
  }
  string sSettings = ewo.getUserSettings(true);  // true = compact JSON
  string sSettingDp = ewo.userSettingsDp;  // This will be default DP name for saving
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AsNgUserSettingSaveLoad.pnl", "UserSettingSaveLoad",
                           makeDynString("$bSaveMode:true",
                                         "$sBasicConfig:" + sBasicConfig,
                                         "$sSetting:" + sSettings,
                                         "$sSettingDp:" + sSettingDp));
  return true;  // open the panel - and that's it
}

/**
 * Open panel for setting default user settings
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_defaultUserSettings(const shape &ewo)
{
  string sBasicConfig = ewo.basicConfigDp;
  if(sBasicConfig == "")
  {
    ChildPanelOnCentralModal(
        "vision/MessageWarning",
        getCatStr("sc", "attention"),
        makeDynString("$1:AS EWO has empty basic config, can't work with user settings"));
    return false;
  }
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AsNgUserSettingSaveLoad.pnl", "UserSettingSaveLoad",
                           makeDynString("$bSetDefault:true",
                                         "$sBasicConfig:" + sBasicConfig));
  return true;  // open the panel - and that's it
}

/**
 * Open panel for editing access control
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_accessControl(const shape &ewo)
{
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AsNgAccessControl.pnl", "Alarm Screen Access Control",
                           makeDynString());
  return true;  // open the panel - and that's it
}

/**
 * Open panel for editing popup menu definition
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_popupMenuEditor(const shape &ewo)
{
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AsNgPopupMenu.pnl", "Alarm Popup menu",
                           makeDynString());
  return true;  // open the panel - and that's it
}

/**
 * Open panel for editing parameters for connecting to ORACLE archive database
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_oracleRdbSettings(const shape &ewo)
{
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AsNgOracleRdbParams.pnl", "ORACLE RDB Connection",
                           makeDynString());
  return true;  // open the panel - and that's it
}

/**
 * Open panel for editing editing commands for opening different help file types
 * @param ewo AS EWO which initiated this call
 * @return <c>true</c> if operation was completed successfully
 */
private bool _AlarmScreenNgActionProcessing_helpFileTypesEditor(const shape &ewo)
{
  ChildPanelOnCentralModal("vision/AlarmScreenNg/AsNgHelpFileSetup.pnl", "Alarm Help File types",
                           makeDynString());
  return true;  // open the panel - and that's it
}
