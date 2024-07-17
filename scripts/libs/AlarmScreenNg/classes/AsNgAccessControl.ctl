// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  The class providing access control information for NG AlarmScreen
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // common definitions
#uses "AlarmScreenNg/AlarmScreenNgActions.ctl"  // the names of 'standard' actions for access control
#uses "fwGeneral/fwGeneral"
#uses "fwGeneral/fwException"

//--------------------------------------------------------------------------------
// variables and constants

/** Possible values for EWO's method setActionEnabled() */
//@{
public const int ALARM_SCREEN_ACCESS_ACTION_ENABLE = 0;  ///< Action shall be enabled
public const int ALARM_SCREEN_ACCESS_ACTION_DISABLE = 1;  ///< Action shall be disabled
public const int ALARM_SCREEN_ACCESS_ACTION_HIDE = 2;  ///< Action shall be disabled, and corresponding UI element shall be hidden
//@}

/** Possible keys in JSON for restrictions on particular action */
//@{
public const string ALARM_SCREEN_RESTRICTION_DOMAIN = "domain";  ///< The domain name for whom action is allowed
public const string ALARM_SCREEN_RESTRICTION_PRIVILEGE = "privilege";    ///< The privilege in domain for which action is allowed
public const string ALARM_SCREEN_RESTRICTION_OTHER = "other";  ///< The access level (disabling!) for other users, who have no access according to domain+role
//@}

/**
 * This class provides methods for checking access rights of current user
 * to different actions, related to NG Alarm Screen.<br>
 *
 * The class is supposed to be used in two major modes:
 *  - Use in panels, mainly to control availability of different UI elements in that panel.
 *     In such mode the instance of class performs dpConnect() to two main sources of information:
 *      - current user logged in
 *      - settings for access control of Alarm Screen
 *     Whenever callback arrives from either source of data, the instance shall
 *     notify the panel about changes, such that panel can adjust UIs according to new settings.
 *     However, CTRL++ doesn't have something similar to signal/slot mechanism in Qt.
 *     Thus, the notification of panel is done in a bit tricky way:
 *      - If panel needs notifications, then it calls the method setNotifier(), passing
 *        there the name of (invisible) TextEdit control in panel
 *      - when callback arrives, this class writes the new value to "text" property of
 *        passed TextEdit
 *      - and panel can make necessary processing, initiated by TextChanged() event of that control
 *  - Second mode of operation is 'one shot' check of access rights. For example, in the flow of CTRL
 *      code execution one needs to know if current user is allowed to do something. In such case
 *      the instance of this class is created and the method getAccessLevel(). The instance reads
 *      the data from DPE with restrictions (using dpGet() and returns result.
 *
 * Note that this class's full functionality depends on presence of fwAccessControl component;
 * if component is missing the result of check will be 'enabled' for any action name.
 */
class AsNgAccessControl {

  /// Constructor, makes connection to all required DPEs
  public AsNgAccessControl() {
  }

  /// Set the name of TextEdit control whose text shall be changed when callback(s) arrive
  public void setNotifier(const string &sTextEditTane) {
    m_textEditName = sTextEditTane;
  }

  /**
   * Connect to all required sources, after successful connection the instance
   * is able to provide valid data, send notifications etc.<br>
   * The reason for not doing connections in constructor is WinCC OA imitation:

   * @note Static class members of CTRL++ classes defined in CTRL libraries,
   * manager global variables ("global" in libs) and variables which get copied
   * from the libs into each script (e.g. int x = init(); in a lib) must not use
   * waiting functions in the initializers.
   *
   * Thus, in order to allow for instances of this class to be used in such contexts,
   * the connection was moved to separate method.
   *
   * @return <c>true</c> if connection was successful. In case of failure the
   *     description of error can be obtained using getError() method
   */
  public bool connect() {
    m_connected = connectToAccessControl() && connectToUser();
    return m_connected;
  }

  /**
   * Force the reading fresh set of restrictions from DPE. Normally this method shall not be used,
   * it is introduced mainly for testing.
   * @return <c>true</c> if dpGet() was successful. In case of failure the
   *     description of error can be obtained using getError() method
   */
  public bool read() {
    dyn_string dsExceptions;
    string sDpName = AlarmScreenNg_getAdminDP(dsExceptions);
    if(sDpName == "") {
      m_error = "failed to get the name of Admin DP: " + dsExceptions;
      DebugN(__FUNCTION__ + "(): error", dsExceptions);
      return false;
    }

    string sJson;
    dpGet(sDpName + ".AccessControl", sJson);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      m_error = "dpGet() failed for " + sDpName + ".AccessControl: " + getErrorText(deErrors);
      DebugN(__FUNCTION__ + "(): " + m_error);
      return false;
    }

    if(sJson == "") {  // Empty string is not an error, but rather 'no restrictions'
      m_restrictions.clear();
      m_error.clear();
    }
    else {
      m_restrictions = jsonDecode(sJson);
      dyn_errClass deErrors = getLastError();
      if(dynlen(deErrors) > 0) {
        m_error = "error parsing the value of restrictions";
        m_restrictions.clear();
      }
    }
    return true;
  }

  /// Return description of last detected error
  public string getError() {
    return m_error;
  }

  /**
   * Get the access level of current user for action with given name.
   * Note that if initialization (dpConnect()) was not successful, or if
   * JSON with restrictions couldn't be parsed, then function will always
   * return ALARM_SCREEN_ACCESS_ACTION_DISABLE.
   * @param sActionName The name of action to be checked, may be one of names
   *         AS_EWO_ACTION_xxx, or other name for customer added action.
   * @return Value for one of constants ALARM_SCREEN_ACCESS_ACTION_xxx (in this file)
   */
  public int getAccessLevel(const string &sActionName) {
    if(!(m_gotRestrictions || m_connected)) {
      read();
      m_gotRestrictions = true;
    }
    if(!m_error.isEmpty()) {
      return ALARM_SCREEN_ACCESS_ACTION_DISABLE;
    }
    if(!mappingHasKey(m_restrictions, sActionName)) {
      return ALARM_SCREEN_ACCESS_ACTION_ENABLE;  // action is not in restrictions -> enabled
    }
    return getAccessForAction(m_restrictions[sActionName]);
  }

  /// Get the current access control restrictions
  public mapping getRestriction() {
    return m_restrictions;
  }

  /**
   * Save new set of access control rules to DP
   * @param mRestrictions New access control rules to save
   * @param dsExceptions The variable where exception info will be written in case of error
   * @return <c>true</c> if operation was completed successfully
   */
  public bool save(const mapping &mRestrictions, dyn_string &dsExceptions) {
    if(!validateAllRestrictions(mRestrictions, dsExceptions)) {
      return false;
    }
    string sDpName = AlarmScreenNg_getAdminDP(dsExceptions);
    if(sDpName.isEmpty()) {
      m_error = "failed to get the name of Admin DP: " + dsExceptions;
      DebugN(__FUNCTION__ + "(): error", dsExceptions);
      return false;
    }
    dpSet(sDpName + ".AccessControl", jsonEncode(mRestrictions));
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): dpSet() failed: " +
                        getErrorText(deErrors), "");
      DebugN(dsExceptions);
      return false;
    }
    return true;
  }

  /**
   * The callback for new data from DP _NgAsAdmin.AccessControl.
   * New DPE value shall contain access control limitations in JSON format
   * @param sDpeName The name of DPE that caused callback
   @ @param sAccessControl The value of DPE: access control restrictions in JSON format
   */
  public void accessControlCb(string sDpeName, string sAccessControl) {
    // DebugN(__FUNCTION__ + "(): callback from " + sDpeName);
    if(sAccessControl == "") {  // Empty string is not an error, but rather 'no restrictions'
      m_restrictions.clear();
      m_error.clear();
    }
    else {
      m_restrictions = jsonDecode(sAccessControl);
      dyn_errClass deErrors = getLastError();
      if(dynlen(deErrors) > 0) {
        m_error = "error parsing the value of " + sDpeName;
        m_restrictions.clear();
      }
    }
    notifyPanel();
  }

  /**
   * The callback for new data from DP with the name of current user.
   * @param sDpeName The name of DPE that caused callback
   @ @param sUserName The name of new user, not used here
   */
  public void userNameCb(string sDpeName, string sUserName) {
    // DebugN(__FUNCTION__ + "(): callback from " + sDpeName);
    notifyPanel();
  }

  /// Notify the panel about change. For the moment the method of notification is:
  /// change the 'text' of TextEdit control, whose name was passed to thin instance
  /// using setNotifier() method
  private void notifyPanel() {
    if(m_connected && (!m_textEditName.isEmpty())) {
      string sText;
      getValue(m_textEditName, "text", sText);
      setValue(m_textEditName, "text", sText == "0" ? "1" : "0");
    }
  }

  /**
   * Connect to DPE with access control settings for AlarmScreen
   * @return <c>true</c> if connection was successful.
   */
  private bool connectToAccessControl() {
    dyn_string dsExceptions;
    string sDpName = AlarmScreenNg_getAdminDP(dsExceptions);
    if(sDpName == "") {
      m_error = "failed to get the name of Admin DP: " + dsExceptions;
      DebugN(__FUNCTION__ + "(): error", dsExceptions);
      return false;
    }
    dpConnect(this, this.accessControlCb, sDpName + ".AccessControl");
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      m_error = "failed to connect to " + sDpName + ".AccessControl: " + getErrorText(deErrors);
      DebugN(__FUNCTION__ + "(): " + m_error);
      return false;
    }
    return true;
  }

  /**
   * Connect to DPE with current user, in order to react on operations like login/logout
   * @return <c>true</c> if connection was successful.
   */
  private bool connectToUser() {
    string sDpeName = "_Ui_" + myManNum() + ".UserName";
    dpConnect(this, this.userNameCb, sDpeName);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      m_error = "failed to connect to " + sDpeName + ": " + getErrorText(deErrors);
      DebugN(__FUNCTION__ + "(): " + m_error);
      return false;
    }
    return true;
  }

  /**
   * Get the access level of current user for given action restrictions.
   * The restrictions is list of mapping, each of mapping shall contain two
   * fileds: "domain" and "role", such mapping explicitly specify who is allowed
   * to execute the action.<br>
   * In addition,list may contain one mapping with key "other", the value of this key
   * shall contain the integer, specifying how exactly restriction shall be limited for
   * other users: disable control, or hide control.
   * @param dmActionRestrictions List of restriction for action being checked
   * @return Allowed access level for current user and this action, one of constants
   *    ALARM_SCREEN_ACCESS_ACTION_xxx
   */
  private int getAccessForAction(const dyn_mapping &dmActionRestrictions) {
    if(!fwAccessControlAvailable()) {
      return ALARM_SCREEN_ACCESS_ACTION_ENABLE;  // there are some restrictions, but we can't check them
    }
    int result = ALARM_SCREEN_ACCESS_ACTION_DISABLE;
    for(int n = dynlen(dmActionRestrictions) ; n > 0 ; n--) {
      if(mappingHasKey(dmActionRestrictions[n], ALARM_SCREEN_RESTRICTION_DOMAIN) &&
         mappingHasKey(dmActionRestrictions[n], ALARM_SCREEN_RESTRICTION_PRIVILEGE)) {

        bool bIsGranted;
        dyn_string dsExceptions;
        string sToCheck = dmActionRestrictions[n][ALARM_SCREEN_RESTRICTION_DOMAIN] + ":" +
                          dmActionRestrictions[n][ALARM_SCREEN_RESTRICTION_PRIVILEGE];
        fwAccessControl_isGranted(sToCheck, bIsGranted, dsExceptions);
        if(bIsGranted) {
          return ALARM_SCREEN_ACCESS_ACTION_ENABLE;
        }
        if(dynlen(dsExceptions) > 0) {  // do not stop on error, but print for debugging
          DebugN(__FUNCTION__ + "(): fwAccessControl_isGranted() failed: arg, error",
                 sToCheck, dsExceptions);
        }
      }
      else if(mappingHasKey(dmActionRestrictions[n], ALARM_SCREEN_RESTRICTION_OTHER)) {
        int level = dmActionRestrictions[n][ALARM_SCREEN_RESTRICTION_OTHER];
        if((level == ALARM_SCREEN_ACCESS_ACTION_DISABLE) || (level == ALARM_SCREEN_ACCESS_ACTION_HIDE)) {
          result = level;
        }
        else {
          DebugN(__FUNCTION__ + "(): unexpected level value: " + level);
        }
      }
      else {
        DebugN(__FUNCTION__ + "() unexpected mapping content:", dmActionRestrictions[n]);
      }
    }
    return result;
  }

  /// Check if fwAccessControl is available, in particular - function fwAccessControl_isGranted
  private bool fwAccessControlAvailable() {
    if(!m_accessControlChecked) {
      m_accessControlChecked = true;
      m_accessControlAvailable = isFunctionDefined("fwAccessControl_isGranted");
      if(!m_accessControlAvailable) {
        fwGeneral_loadCtrlLib("fwAccessControl/fwAccessControl.ctc", false, true);
        m_accessControlAvailable = isFunctionDefined("fwAccessControl_isGranted");
      }
    }
    return m_accessControlAvailable;
  }

  /**
   * Validate the mapping with all restrictions before writing to DP.
   * @param mAllRestrictions All restrictions to be written
   * @param dsExceptions The variable where exception info will be written in case of error
   * @return <c>true</c> if validation was passed successfully
   */
  private bool validateAllRestrictions(const mapping &mAllRestrictions, dyn_string &dsExceptions) {
    for(int idx = mappinglen(mAllRestrictions) ; idx > 0 ; idx--) {

      if(getType(mappingGetKey(mAllRestrictions, idx)) != STRING_VAR) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): unexpected key type " +
                          getTypeName(mappingGetKey(mAllRestrictions, idx)) +
                          " for restrictions mapping, only strings are expected", "");
        return false;
      }

      int iType = getType(mappingGetValue(mAllRestrictions, idx));
      if((iType != DYN_MAPPING_VAR) && (iType != DYN_ANYTYPE_VAR)) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): unexpected value type " +
                          getTypeName(mappingGetValue(mAllRestrictions, idx)) +
                          " for restrictions on " + mappingGetKey(mAllRestrictions, idx) +
                          ", expected type is dyn_mapping/dyn_anytype", "");
        return false;
      }
      dyn_mapping dmRestrictions = mappingGetValue(mAllRestrictions, idx);
      if(!validateActionRestrictions(mappingGetKey(mAllRestrictions, idx), dmRestrictions, dsExceptions)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Validate restrictions for one mapping before writing to DP. The list must be non-empty,
   * and it shall contain at least 2 items. Every mapping in the list of restrictions must be
   * one of:
   *  - mapping with two keys: 'domain' and 'privilege' to specify which privilege is required
   *      for executing action. Both values must be strings. TODO: we can also check that values
   *      are valid domain and privilege names
   *  - mapping with one key 'other' to specify what shall happen with UI control for other users,
   *      the value must be int (1 or 2) in such case
   * @param sActionName The name of action whose restrictions are validated
   * @param dmRestrictions The list of restrictions for this action
   * @param dsExceptions The variable where exception info will be written in case of error
   * @return <c>true</c> if validation was passed successfully
   */
  private bool validateActionRestrictions(const string &sActionName, const dyn_mapping &dmRestrictions,
                                          dyn_string &dsExceptions) {
    if(dynlen(dmRestrictions) < 2) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): restrictions for " +
                          sActionName + " contain " + dynlen(dmRestrictions) +
                          " item(s), while at least 2 items are expected", "");
        return false;
    }
    for(int idx = dynlen(dmRestrictions) ; idx > 0 ; idx--) {
      bool bSuccess;
      switch(mappinglen(dmRestrictions[idx])) {
        case 1:
          bSuccess = validateRestrictionForOther(sActionName, dmRestrictions[idx], dsExceptions);
          break;
        case 2:
          bSuccess = validateRestrictionEnabled(sActionName, dmRestrictions[idx], dsExceptions);
          break;
        default:
          fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): restrictions for " +
                            sActionName + " contain mapping with " + mappinglen(dmRestrictions[idx]) +
                            " item(s), while expecting 1 or 2", "");
          bSuccess = false;
        }
      if(!bSuccess) {
        return false;
      }
    }
    return true;
  }

  /**
   * Validate restriction value with 2 keys. The mapping shall contain keys
   * 'domain' and 'privilege' to specify which privilege is required for executing action.
   * Both values must be strings. TODO: we can also check that values are valid domain and
   * privilege names.
   * @param sActionName The name of action whose restrictions are validated
   * @param mRestriction The mapping with restriction
   * @param dsExceptions The variable where exception info will be written in case of error
   * @return <c>true</c> if validation was passed successfully
   */
  private bool validateRestrictionEnabled(const string &sActionName, const mapping &mRestriction,
                                          dyn_string &dsExceptions) {
    if(!validateValueType(sActionName, mRestriction, ALARM_SCREEN_RESTRICTION_DOMAIN, STRING_VAR, dsExceptions)) {
      return false;
    }
    if(!validateValueType(sActionName, mRestriction, ALARM_SCREEN_RESTRICTION_PRIVILEGE, STRING_VAR, dsExceptions)) {
      return false;
    }
    return true;
  }

  /**
   * Validate restriction value with 1 keys. The mapping shall contain key 'other' to
   * specify what shall happen with UI control for other users, the value must be int
   * (1 or 2) in such case
   * @param sActionName The name of action whose restrictions are validated
   * @param mRestriction The mapping with restriction
   * @param dsExceptions The variable where exception info will be written in case of error
   * @return <c>true</c> if validation was passed successfully
   */
  private bool validateRestrictionForOther(const string &sActionName, const mapping &mRestriction,
                                          dyn_string &dsExceptions) {
    if(!validateValueType(sActionName, mRestriction, ALARM_SCREEN_RESTRICTION_OTHER, INT_VAR, dsExceptions)) {
      return false;
    }
    switch(mRestriction[ALARM_SCREEN_RESTRICTION_OTHER]) {
      case ALARM_SCREEN_ACCESS_ACTION_DISABLE:
      case ALARM_SCREEN_ACCESS_ACTION_HIDE:
        break;
      default:
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): restriction for " +
                          sActionName + " contains unexpected value " +
                          mRestriction[ALARM_SCREEN_RESTRICTION_OTHER] +
                          " for key '" + ALARM_SCREEN_RESTRICTION_OTHER + "'", "");
        return false;
    }
    return true;
  }

  /**
   * Check that mapping with restriction for given action contains expected key and
   * that the value for this key has expected type.
   * @param sActionName The name of action whose restrictions are validated
   * @param mRestriction The mapping with restriction
   * @param sKey The name of key to be checked
   * @param iExpectedType Expect type of value for this key
   * @param dsExceptions The variable where exception info will be written in case of error
   * @return <c>true</c> if validation was passed successfully
   */
  private bool validateValueType(const string &sActionName, const mapping &mRestriction,
                                 const string &sKey, int iExpectedType, dyn_string &dsExceptions) {
    if(!mappingHasKey(mRestriction, sKey)) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): restriction for " +
                        sActionName + " doesn't contain key '" + sKey + "'", "");
      return false;
    }
    // There is one tricky thing: originally the value of 'other' key is integer.
    // However, after encoding to JSON and decoding back it usually becomes float
    int iSecondExpectedType = iExpectedType == INT_VAR ? FLOAT_VAR : iExpectedType;
    int iValueType = getType(mRestriction[sKey]);
    if((iValueType != iExpectedType) && (iValueType != iSecondExpectedType)) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ + "(): restriction for " +
                        sActionName + " has type of value for key '" + sKey + "' == " +
                        getTypeName(mRestriction[sKey]), "");
      return false;
    }
    return true;
  }

  private string m_error;          ///< The description of last detected error
  private bool m_connected;        ///< Flag indicating if all required dpConnect() were done successfully
  private bool m_gotRestrictions;  ///< The flag indicating that this instance already read restrictions from
                                   ///< dedicated DPE and not it can make check using cached value.
  private bool m_accessControlChecked;  ///< Flag indicating if this instance already checked the presense of
                                       ///< fwAccessControl component, and there is no need to repeat such check
  private bool m_accessControlAvailable;  ///< Flag indicating if fwAccessControl component is available, set as s result of check
  private mapping m_restrictions;  ///< The result of parsing content of AccessControl DPE
  private string m_textEditName;   ///< The name of TextEdit control where text shall be changed to notify panel
};
