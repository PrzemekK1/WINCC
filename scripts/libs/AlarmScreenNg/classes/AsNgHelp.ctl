// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Class encapsulating functionally for configuring and displaying alarm-related help
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "fwConfigs/fwConfigs"
#uses "fwGeneral/fwException"
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions
#uses "AlarmScreenNg/AlarmScreenNgActions.ctl"  // The names of 'standard' actions for access control
#uses "AlarmScreenNg/classes/AsNgAccessControl.ctl"  // alarm-specific access control

//--------------------------------------------------------------------------------
// variables and constants

/** @name The keys in configuration information.
 * These string constants are made publicly available in order to allow using them in
 * panel, used for alarm help configuration.
 */
//@{

/// The name of key in configuration, containing command for opening file on Linux machine
const string AS_NG_HELP_CONFIG_KEY_CMD_LINUX = "cmdLinux";

/// The name of key in configuration, containing command for opening file on Windows machine
const string AS_NG_HELP_CONFIG_KEY_CMD_WIN = "cmdWin";

//@}

/**
 * This class implements methods for configuring and displaying alarm-related help information.
 * The implementation is based on the code found in fwAlarmHamdling/feAlarmHandling.ctl.<br>
 * Unlike the original implementation, this class also uses configuration for help stored in
 * dedicated DP, but there is only one DPE for this purpose, containing all configuration as
 * string in JSON format.<br>
 * Basically, this class combines functionalities found in two functions of JCOP AS:
 *    - fwAlarmHandling_findHelpFile()
 *    - fwAlarmHandling_openHelpFile()
 *
 * Plus some methods to support editing/saving the configuration of alarm help processing.
 */
class AsNgHelp {

  /**
   * Shown the help file for given DPE (with alarm).<br>
   * This method is a combination of two functions from fwAlarmHandling component:
   *    - fwAlarmHandling_findHelpFile()
   *    - fwAlarmHandling_openHelpFile()
   * @param sDpeName The name of DPE for which alarm-related help shall be shown
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return <c>true</c> if file was found and successfully shown
   */
  public bool showHelpOnAlarmDpe(const string &sDpeName, dyn_string &dsExceptions) {
    // Find the name of file to be shown
    string sFileName = findHelpFile(sDpeName, dsExceptions);
    if(dynlen(dsExceptions) > 0) {
      return false;
    }
    if(sFileName.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): no help file found for " + sDpeName, "");
      return false;
    }

    //check if this is a relative path or absolute path
    if(!(sFileName.contains(":") || sFileName.startsWith("/") || sFileName.startsWith("\\"))) {
      sFileName = getPath(HELP_REL_PATH, HELP_PATH_ROOT + sFileName);
    }
    if(sFileName.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): No valid file name for an alarm help file", "");
      return false;
    }

    //if not http then assume it is a file
    if(!(sFileName.startsWith("http://") || sFileName.startsWith("https://"))) {
      //check file is accessible
      if(access(sFileName, F_OK) != 0) {
        	fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): The help file could not be found: " + sFileName, "");
        	return false;
      }
    }

    //find file suffix. TODO: if file name starts with "http://" or "https://" - do we need to care about suffixes?
    string sSuffix = getExt(sFileName);
    // By some reason, the JCOP AS used settings not for 'pure' suffix (like "html"), but for suffix with
    // dot in front (like ".html"). Let's keep that tradition, even though the reason is not clear to me
    sSuffix.insert(0, ".");
    string sCmd = getCommandForSuffix(sSuffix, dsExceptions);
    if(dynlen(dsExceptions) > 0) {
      return false;
    }
    if(sCmd.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): not found command to open help file " + sFileName, "");
      return false;
    }

    // Open using found command
    int iReplaced = strreplace(sCmd, "$1", sFileName);
    if(iReplaced == 0) {
      sCmd = sCmd + " " + sFileName;
    }
    // Using system() to open help file blocks panel from processing of further mouse events from AS EWO:
    //  - the panel waits for finish of event processing
    //  - which in turn waits for result of system() call
    if(!systemDetached(sCmd)) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): failed to start help: " + sCmd, "");
      return false;
    }
    return true;
  }

  /**
   * Get JCOP default command for starting browser that (hopefully) fill be able to display
   * help file.
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return The string with default command to use
   */
  public string getDefaultBrowserCommand(dyn_string &dsExceptions) {
    string sResult;
    mapping mDefault = getDefaultCommands(dsExceptions);
    if(dynlen(dsExceptions) == 0) {
      sResult = mDefault.value(_UNIX ? AS_NG_HELP_CONFIG_KEY_CMD_LINUX : AS_NG_HELP_CONFIG_KEY_CMD_WIN);
    }
    return sResult;
  }

  /**
   * Get JCOP default command for starting browser that (hopefully) fill be able to display
   * help file.
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return The mapping with two keys:
   *          - "cmdLinux": the value is string with default command for Linux
   *          - "cmdWin": the value is string with default command for Windows
   *      See constants AS_NG_HELP_CONFIG_KEY_CMD_xxx
   */
  public mapping getDefaultCommands(dyn_string &dsExceptions) {
    mapping mResult = getEmptyTypeConfig();

    dyn_string dsDpeNames = makeDynString(FW_GENERAL_HELP_BROWSER_CMD_LIN_DPE, FW_GENERAL_HELP_BROWSER_CMD_WIN_DPE);
    dyn_string dsCommands;
    dpGet(dsDpeNames, dsCommands);
    dyn_errClass deErrors = getLastError();
    if(!deErrors.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): failed to read default browser commands: " +
                        getErrorText(deErrors), "");
      throwError(deErrors);
    }
    else {
      // the same order as order of DPE names in dsDpeNames !
      mResult.insert(AS_NG_HELP_CONFIG_KEY_CMD_LINUX, dsCommands[1]);
      mResult.insert(AS_NG_HELP_CONFIG_KEY_CMD_WIN, dsCommands[2]);
    }
    return mResult;
  }

  /**
   * Read, parse and return current configuration. Not required for 'ordinary user',
   * intend for editor of commands for opening help files
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return The mapping with string keys, corresponding to help filter types (file name suffix including '.').
   *         The value for every key (suffix) is a mapping with two keys:
   *          - "cmdLinux": the value is string with default command for Linux
   *          - "cmdWin": the value is string with default command for Windows
   *      See constants AS_NG_HELP_CONFIG_KEY_CMD_xxx
   */
  public mapping read(dyn_string &dsExceptions) {
    readFileTypesConfig(dsExceptions);
    return m_config;
  }

  /**
   * Save given set of settings to DPE, validate before saving and check if user has enough privileges
   * @param mSettings set of settings to save
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return <c>/true</c> if settings were saved successfully
   */
  public bool save(const mapping &mSettings, dyn_string &dsExceptions) {
    if(!validateSettings(mSettings, dsExceptions)) {
      return false;
    }
    AsNgAccessControl accessControl;
    if(accessControl.getAccessLevel(AS_ACTION_EDIT_HELP_FILE_TYPES) != ALARM_SCREEN_ACCESS_ACTION_ENABLE) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): You don't have permissions to modify command(s) for opening help files", "");
      return false;
    }

    string sJson;
    if(!mSettings.isEmpty()) {
      sJson = jsonEncode(mSettings);
    }
    string sDpeName = getConfigDpe(dsExceptions);
    if(sDpeName.isEmpty()) {
      return false;
    }
    dpSet(sDpeName, sJson);
    dyn_errClass deErrors = getLastError();
    if(!deErrors.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): failed to save alarm help file types configuration to "+
                        sDpeName + ": " + getErrorText(deErrors), "");
      throwError(deErrors);
      return false;
    }
    return true;
  }

  /**
   * Write default file types, the method is only supposed to be used during post-installation.<br>
   * The reason for adding default (with empty commands!) is: only 'registered' file types are searched.
   * Here the 'most commonly used' file types are registered.
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return <c>/true</c> if settings were saved successfully
   */
  public bool setDefaultIfEmpty(dyn_string &dsExceptions) {
    if(!readFileTypesConfig(dsExceptions)) {
      return false;
    }
    if(!m_config.isEmpty()) {
      return true;  // There are already some settings and they can already be edited by end user
    }
    mapping mSettings;
    mSettings.insert(".htm", getEmptyTypeConfig());
    mSettings.insert(".html", getEmptyTypeConfig());
    mSettings.insert(".xml", getEmptyTypeConfig());
    mSettings.insert(".pdf", getEmptyTypeConfig());
    return save(mSettings, dsExceptions);
  }

  /**
   * Find the name of file, containing help information for alarm of given DPE. The logic is copied
   * from fwAlarmHandling_findHelpFile()
   * @param sDpeName The name of DPE for which help file shall be found
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return Absolute path to help file for given DPE, or empty string in case of error
   */
  private string findHelpFile(const string sDpeName, dyn_string &dsExceptions) {

    string sResult = getCustomHelpFile(sDpeName, dsExceptions);
    if((!sResult.isEmpty()) || (dynlen(dsExceptions) > 0)) {
      return sResult;
    }

    // possible (supported) file name suffixes
    dyn_string dsFileSuffixes = getFileSuffixes(dsExceptions);
    if(dynlen(dsExceptions) > 0) {
      return "";
    }
    dynAppend(dsFileSuffixes, "");

    // What and where to search
    dyn_string dsSearchPatterns = buildSearchPatternsForDpe(sDpeName);
    dyn_string dsSearchDirectories = getSearchDirectories();

    // Search
    for(int i = 0 ; i < dsSearchPatterns.count(); i++) {
      string sFileNameToFind =	convertDpNameToFileName(dsSearchPatterns.at(i));

      for(int j = 0 ; j < dsFileSuffixes.count() ; j++) {
        // note: number of elements in dsSearchPatterns and dsSearchDirectories must match!!!
        string sPathToFind = HELP_PATH_ROOT + dsSearchDirectories.at(i) + sFileNameToFind + dsFileSuffixes.at(j);
        string sFileName = getPath(HELP_REL_PATH, sPathToFind);
        //DebugN(__FUNCTION__ + "(): search for file, and result", sPathToFind, sFileName);
        	if(!sFileName.isEmpty()) {
          return sFileName;
        	}
      }
    }

    // Nothing specific was found, return default help file
    return getPath(HELP_REL_PATH, HELP_PATH_ROOT + HELP_FILE_DEFAULT);
  }

  /**
   * Get the customer specific name of file for alarm help for given DPE. The logic of method
   * is copied from function fwAlarmHandling_getManyCustomHelpFile().
   * @param sDpeName The name of DPE for which customer specific help file is requested
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwExceptio_raise()
   * @return The name of help file, or empty string if not found
   */
  private string getCustomHelpFile(const string sDpeName, dyn_string &dsExceptions) {

    /// Check if DPE has _general config
    dyn_int diConfigTypes;
    _fwConfigs_getConfigTypeAttribute(makeDynString(sDpeName), fwConfigs_PVSS_GENERAL, diConfigTypes, dsExceptions);
    if(dynlen(dsExceptions) > 0) {
      return "";
    }
    if(diConfigTypes[1] == DPCONFIG_NONE) {
      return "";
    }

    // read specific attribute of config that may contain customer-specific help file name
    dyn_string dsHelpStrings;
    _fwConfigs_getConfigTypeAttribute(makeDynString(sDpeName), fwConfigs_PVSS_GENERAL, dsHelpStrings, dsExceptions, HELP_PATH_ATTRIBUTE);
    if(dynlen(dsExceptions) > 0) {
      return "";
    }
    return dsHelpStrings[1];
  }

  /**
   * Convert the name of file name pattern (built from DPE/DP names/aliases/descriptions)
   * to file name.<br>
   * The logic is copied from function _fwAlarmHandling_convertDpNameToFileName()
   * @param sDpBasedName The name built from DPE/DP names/aliases/descriptions
   * @return Corresponding file name.
   */
  private string convertDpNameToFileName(const string &sDpBasedName) {
    string sResult = sDpBasedName;
    strreplace(sResult, fwDevice_HIERARCHY_SEPARATOR, "_");
    strreplace(sResult, ":", "_");
    return sResult;
  }

  /**
   * Find the command for opening file with given suffix
   * @param sSuffix File suffix for which command shall be found
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwExceptio_raise()
   * @return The string with command for opening file with given suffix, or empty string if not found
   */
  private string getCommandForSuffix(const string &sSuffix, dyn_string &dsExceptions) {
    string sResult;
    if(!m_gotConfig) {
      if(!readFileTypesConfig(dsExceptions)) {
        return sResult;
      }
    }
    if(m_config.contains(sSuffix)) {
      mapping mSuffixConfig = m_config.value(sSuffix);
      sResult = mSuffixConfig.value(_UNIX ? AS_NG_HELP_CONFIG_KEY_CMD_LINUX : AS_NG_HELP_CONFIG_KEY_CMD_WIN);
    }

    // If at this point result is still empty, then alarm-specific command was not found, let's try to read/use JCOP default
    if(sResult.isEmpty()) {
      sResult = getDefaultBrowserCommand(dsExceptions);
    }
    return sResult;
  }

  /// Get all possible file names with alarm help for given DPE
  private dyn_string buildSearchPatternsForDpe(const string &sDpeName) {

    // Collect information about DPE in order to build resulting file names
    string sDpSystem = dpSubStr(sDpeName, DPSUB_SYS);
    string sDpName = dpSubStr(sDpeName, DPSUB_SYS_DP);
    string sDpType = dpTypeName(sDpName);
    string sDpAlias = dpGetAlias(sDpName);
    string sDpDescription = dpGetDescription(sDpName);
    string sDpElement = dpSubStr(sDpeName, DPSUB_SYS_DP_EL);
    strreplace(sDpElement, dpSubStr(sDpeName, DPSUB_SYS_DP), "");
    string sDpElementAlias = dpGetAlias(sDpName + sDpElement);
    string sDpElementDescription = dpGetDescription(sDpName + sDpElement);

    // Build and return result. The order is important - this will determine the order of search:
    // from more detailed to more generic
    return makeDynString(
        // dpe/dp descriptions
        sDpSystem + sDpElementDescription + sDpElement,
        sDpElementDescription + sDpElement,
        sDpSystem + sDpDescription + sDpElement,
        sDpDescription + sDpElement,
        //dpe/dp aliases
        sDpSystem + sDpElementAlias + sDpElement,
        sDpElementAlias + sDpElement,
        sDpSystem + sDpAlias + sDpElement,
        sDpAlias + sDpElement,
        //dpe/dp names
        dpSubStr(sDpeName, DPSUB_SYS_DP_EL),
        dpSubStr(sDpeName, DPSUB_DP_EL),
        dpSubStr(sDpeName, DPSUB_SYS_DP),
        dpSubStr(sDpeName, DPSUB_DP),
        //dp types
        sDpSystem + sDpType + sDpElement,
        sDpType + sDpElement,
        sDpSystem + sDpType,
        sDpType);
  }

  /**
   * Get list of directories where we will search for alarm help files. The order is
   * important: the directories will be searched in this order, from more to less specific.
   * @note the number of elements in the list, returned by this method, shall match number
   *       of elements returned by buildSearchPatternsForDpe(): each file pattern will be
   *       searched in corresponding directory.
   */
  private dyn_string getSearchDirectories() {
    return makeDynString(
        //dpe/dp descriptions
        HELP_PATH_DEVICE_DESCRIPTION_ELEMENT,
        HELP_PATH_DEVICE_DESCRIPTION_ELEMENT,
        HELP_PATH_DEVICE_DESCRIPTION,
        HELP_PATH_DEVICE_DESCRIPTION,
        //dpe/dp aliases
        HELP_PATH_DEVICE_ALIAS_ELEMENT,
        HELP_PATH_DEVICE_ALIAS_ELEMENT,
        HELP_PATH_DEVICE_ALIAS,
        HELP_PATH_DEVICE_ALIAS,
        //dpe/dp names
        HELP_PATH_DEVICE_ELEMENT,
        HELP_PATH_DEVICE_ELEMENT,
        HELP_PATH_DEVICE,
        HELP_PATH_DEVICE,
        //dp types
        HELP_PATH_DEVICE_TYPE_ELEMENT,
        HELP_PATH_DEVICE_TYPE_ELEMENT,
        HELP_PATH_DEVICE_TYPE,
        HELP_PATH_DEVICE_TYPE);
  }

  /**
   * Get all supported suffixes for help files
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwExceptio_raise()
   * @return The list of all supported suffix names, or empty list in case of fatal error
   */
  private dyn_string getFileSuffixes(dyn_string &dsExceptions) {
    dyn_string dsResult;
    if(!m_gotConfig) {
      if(!readFileTypesConfig(dsExceptions)) {
        return dsResult;
      }
    }
    for(int i = 0 ; i < m_config.count() ; i++ ) {
      string sSuffix = m_config.keyAt(i);
      if(!sSuffix.isEmpty()) {
        dsResult.append(sSuffix);
      }
    }
    return dsResult;
  }

  /**
   * Read alarm help configuration from DPE as JSON string, parse this string and store
   * result in m_config.
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwExceptio_raise()
   * @return <c>true</c> if reading/parsing was successful
   */
  private bool readFileTypesConfig(dyn_string &dsExceptions) {
    m_gotConfig = true;  // Only one attempt to read
    m_config.clear();

    string sJson, sDpeName = getConfigDpe(dsExceptions);
    if(sDpeName.isEmpty()) {
      return false;
    }
    dpGet(sDpeName, sJson);
    dyn_errClass deErrors = getLastError();
    if(!deErrors.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): failed to read alarm help file types configuration from "+
                        sDpeName + ": " + getErrorText(deErrors), "");
      throwError(deErrors);
      return false;
    }

    if(sJson.isEmpty()) {
      return true;  // empty configuration is not error
    }

    m_config = jsonDecode(sJson);
    deErrors = getLastError();
    if(!deErrors.isEmpty()) {
      m_config.clear();
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): failed to parse alarm help file types configuration from "+
                        sDpeName + ": " + getErrorText(deErrors), "");
      throwError(deErrors);
      return false;
    }

    return true;
  }

  /**
   * Validate set of settings: commands for opening help files of different types.
   * @param mSettings Settings to be validated
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwException_raise()
   * @return <c>/true</c> if settings passed validation
   */
  private bool validateSettings(const mapping &mSettings, dyn_string &dsExceptions) {
    for(int i = 0 ; i < mSettings.count() ; i++) {
      string sType = mSettings.keyAt(i);
      if(sType.isEmpty()) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): empty file type for rule " + (i+1) + " of " +
                          mSettings.count(), "");
        return false;
      }
      if(!sType.startsWith(".")) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): the file type '" + sType +
                          "' doesn't start with '.' character for rule " + (i+1) + " of " + mSettings.count(), "");
        return false;
      }
      mapping mCmds = mSettings.valueAt(i);
      if(mCmds.count() != 2) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): settings for file type '" + sType +
                          "' contains " + mCmds.count() + " entries, while 2 are expected", "");
        return false;
      }
      if(!mCmds.contains(AS_NG_HELP_CONFIG_KEY_CMD_LINUX)) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): settings for file type '" + sType +
                          "' doesn't contain '" + AS_NG_HELP_CONFIG_KEY_CMD_LINUX + "' entry", "");
        return false;
      }
      if(!mCmds.contains(AS_NG_HELP_CONFIG_KEY_CMD_WIN)) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): settings for file type '" + sType +
                          "' doesn't contain '" + AS_NG_HELP_CONFIG_KEY_CMD_WIN + "' entry", "");
        return false;
      }
    }
    return true;
  }

  /**
   * Make empty configuration for processing of single file type: mapping with required
   * keys in place, but with empty values for this keys.
   * @return mapping with empty configuration
   */
  public mapping getEmptyTypeConfig() {
    mapping mResult;
    mResult.insert(AS_NG_HELP_CONFIG_KEY_CMD_LINUX, "");
    mResult.insert(AS_NG_HELP_CONFIG_KEY_CMD_WIN, "");
    return mResult;
  }

  /**
   * Get the name of DPE that shall contain alarm help configuration as string in JSON format
   * @param dsExceptions The variable where error information will be added in case of error,
   *                      see fwExceptio_raise()
   * @return Name of DPE, or empty string in case of error
   */
  private string getConfigDpe(dyn_string &dsExceptions) {
    string sDpName = AlarmScreenNg_getAdminDP(dsExceptions);
    if(sDpName.isEmpty()) {
      return "";
    }
    return (sDpName + "." + HELP_CONFIG_DPE);
  }

  /// Flag indicating if help configuration was read from DPE. Even if reading failed - there is one attempt only
  private bool m_gotConfig;

  /**
   * The configuration for alarm help: result of parsing string in JSON format, read from DPE HELP_CONFIG_DPE.
   * The JSON string shall contain mapping, where:
   *  - key is string = supported suffix of help file
   *  - value is mapping with 2 keys (both of type string):
   *    - "cmdLinux": the value is string with command to open file with such suffix on Linux machine
   *    - "cmdWin": the value if string with command to open file with such suffix on Windows machine
   *
   * The result of parsing such JSON is dyn_mapping, with every mapping having 3 keys above
   */
  private mapping m_config;

  /// The name of DPE, containing configuration of alarm help as string in JSON format
  private static const string HELP_CONFIG_DPE = "HelpConfig";


  /// The name of attribute of _general config of DPE where the name of custom-specific file with alarm help can be stored
  private static const string HELP_PATH_ATTRIBUTE = ".._string_05";

  /** @name Names of directories where help files are located.
   * The values of constants are borrowed from fwAlarmHandling/fwAlarmHandling.ctl with the aim
   * of reusing help files, prepared from JCOP AS, by NG AS
   */
  //@{

  /// The name of root directory for alarm-related help files, relative to HELP_REL_PATH (see WinCC OA help on getPath())
  private static const string HELP_PATH_ROOT = "AlarmHelp/";

  /// The name of subdirectory, containing alarm-related help files, based on DPE description
  private static const string HELP_PATH_DEVICE_DESCRIPTION_ELEMENT = "DeviceDescriptionDPE/";

  /// The name of subdirectory, containing alarm-related help files, based on DP (device) description
  private static const string HELP_PATH_DEVICE_DESCRIPTION = "DeviceDescription/";

  /// The name of subdirectory, containing alarm-related help files, based on DPE alias
  private static const string HELP_PATH_DEVICE_ALIAS_ELEMENT = "DeviceDescriptionDPE/";

  /// The name of subdirectory, containing alarm-related help files, based on device (DP) alias
  private static const string HELP_PATH_DEVICE_ALIAS = "DeviceDescription/";

  /// The name of subdirectory, containing alarm-related help files, based on DPE name
  private static const string HELP_PATH_DEVICE_ELEMENT = "DeviceDPE/";

  /// The name of subdirectory, containing alarm-related help files, based on device (DP) name
  private static const string HELP_PATH_DEVICE = "Device/";

  /// The name of subdirectory, containing alarm-related help files, based on DPE name in DP type (i.e. for given DPE in all DPs of this type)
  private static const string HELP_PATH_DEVICE_TYPE_ELEMENT = "DeviceTypeDPE/";

  /// The name of subdirectory, containing alarm-related help files, based on DP type (i.e. for all DPs of this type)
  private static const string HELP_PATH_DEVICE_TYPE = "DeviceType/";

  //@}

  /// The name of 'default' help file, if no specific help file found in one of directories above
  private static const string HELP_FILE_DEFAULT = "fwAlarmHandlingDefault.xml";
};
