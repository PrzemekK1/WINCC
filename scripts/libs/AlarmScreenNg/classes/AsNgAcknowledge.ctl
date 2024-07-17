// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Class encapsulating the logic of (multiple) alarms acknowledgement
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // common definitions

/**
 * The class implements the logic of (multiple) alarm acknowledgement.
 * The code is based on ETM's class AcknowledgeTable
 * (see <pvss_path>/scripts/libs/classes/AcknowledgeTable.ctl), with the following
 * major differences from original:
 *  - explicit operations with Table control are not used, as well as explicit access to
 *    properties/methods of AS EWO: the instance of this class only deals with details
 *    of alarms, not reads them from UI element
 *  - some part of implementation is skipped, in particular, I don't care here about some
 *    'old mechanism' (whatever this could mean)
 *  - some bugs are fixed (or, at least, something looking like a buf), for example, the code
 *    to check for individual acknowledgement
 *
 * The acknowledgement is executed in two steps:
 *  - first analysis is performed, the result is list of DPs (for UNICOS devices) or DPEs
 *    (for UNICOS devices) which can be acknowledged, the check for 'can be acknowledged'
 *    includes the check of user access rights
 *  - after first step is performed, the caller can use results of first step to display
 *    error/warning/confirmation to user
 *  - second step performs real acknowledgement
 */
class AsNgAcknowledge
{
  /// Create empty instance
  public AsNgAcknowledge() {
  }

  /**
   * Analyze alarms from AS EWO in order to:
   *  - check if user has permissions to acknowledge all of selected alarms
   *  - check is some alarms require individual acknowledgement
   * @param dmAlarms The list of alarm parameters from EWO which shall
   *                  be acknowledged. Every mapping contains:
   *                  - key = ID of alarm property (see ALARM_PROP_XXX constants)
   *                  - value = value of alarm property with this ID
   * @param iAckType Acknowledgement type, one of DPATTR_ACKTYPE_SINGLE/DPATTR_ACKTYPE_MULTIPLE
   * @return <c>true</c> if analysis was successful
   */
  public bool analyze(const dyn_mapping &dmAlarms, int iAckType) {
    reset();
    m_ackType = iAckType;
    if(dynlen(dmAlarms) == 0) {
      m_error = "No alarm(s) selected for acknowledgement";
      return true;  // No alarms to acknowledge, but this is not error
    }
    if(!verifyPermission(dmAlarms)) {
      return false;
    }
    return buildAtimeList(dmAlarms);
  }

  /**
   * Check if there is something to acknowledge after analysis
   * @return <c>true</c> if there is something to acknowledge
   */
  public bool canAcknowledge() {
    return ((dynlen(m_oldestAlarmsToAck) + dynlen(m_alarmsToAck)) > 0) && (m_error == "");
  }

  /**
   * Build human-readable description of analysis result.
   * Depending on result of canAcknowledge(), the string returned by this method
   * cane be used either:
   *  - as explanation why nothing can be confirmed, or
   *  - as warning to be confirmed by user
   *
   * It is assumed that result of this method will be shown to user, normally as a dialog,
   * and the message is built for using in dialog.
   * @return Human-readable description
   */
  public string getDescription() {
    if(canAcknowledge()) {
      return getAckConfirmation();
    }
    return getNoGoDescription();
  }

  /**
   * Acknowledge alarms according to result of previously processed analysis.
   * @return <c>true</c> if operation was successful
   */
  public bool acknowledge() {
    m_error = "";

    int iErrorCount = acknowledgeAtimeList(m_oldestAlarmsToAck);
    if(!iErrorCount) {
      iErrorCount = acknowledgeAtimeList(m_alarmsToAck);
    }
    if(iErrorCount > 0) {
      m_error = "Acknowledgement failed for " + iErrorCount + " alarm" + (iErrorCount > 0 ? "s" : "");
    }
    reset();  // Analysis results are only acknowledged once
    return (m_error == "");
  }

  /// Get the error description resulting from executing acknowledge() method
  public string getError() {
    return m_error;
  }

  /**
   * Check if current user has enough permissions to acknowledge all alarms
   * in the list. The logic of checking is:
   *    - find alarm classes for all alarms
   *    - find maximum permission, required to acknowledge alarms of found classes
   *    - compare with permissions level of current user
   * @param dmAlarms The list of alarm parameters from EWO which shall
   *                  be acknowledged. Every mapping contains:
   *                  - key = ID of alarm property (see ALARM_PROP_XXX constants)
   *                  - value = value of alarm property with this ID
   * @return <c>true</c> if current user may acknowledge all alarms in list
   */
  private bool verifyPermission(const dyn_mapping &dmAlarms) {
    mapping mPerSystem = splitToSystems(dmAlarms, "_class");

    // Find permissions on 'per system' basis, calculate maximum
    int iMaxPerm = 0;
    for(int n = mappinglen(mPerSystem) ; n > 0 ; n--) {
      int iPerm = getRequiredPermInSystem(mappingGetValue(mPerSystem, n), mappingGetKey(mPerSystem, n));
      if(iPerm < 0) {
        return false;
      }
      else if(iPerm > iMaxPerm) {
        iMaxPerm = iPerm;
      }
    }

    // Check if user has required permission level
    if(iMaxPerm > 0) {
      //DebugN(__FUNCTION__ + "(): checking for level " + iMaxPerm);
      if(!getUserPermission(iMaxPerm)) {
        m_error = "Current user has no permission to acknowledge some/all of alarms, required level: " + iMaxPerm;
        return false;
      }
    }
    return true;
  }

  /**
   * Find alert classes for the list of alert DPEs, then find maximum permission
   * level required for acknowledging all alarms in the list.
   * @param dsDpeNames List of alarm DPE names, including _class config. All DPEs belong
   *                    to the same system
   * @param sSystemName The name of system where search is done, used for error messages
   * @return Maximum permission level required for alarm acknowledgement; or
   *          -1 in case of error
   */
  private int getRequiredPermInSystem(const dyn_string &dsDpeNames, const string &sSystemName) {
    // Get all alert classes
    dyn_string dsAlertClasses;
    dpGet(dsDpeNames, dsAlertClasses);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      m_error = "Failed to get alert classes for " + dynlen(dsDpeNames) + " DPE(s) in system " +
                sSystemName;
      throwError(deErrors);
      return -1;
    }
    dynSortAsc(dsAlertClasses);
    dynUnique(dsAlertClasses);
    //DebugN(__FUNCTION__ + "(): dsAlertClasses", dsAlertClasses);

    // Query permissions for all alert classes
    for(int n = dynlen(dsAlertClasses) ; n > 0 ; n--) {
      if(dsAlertClasses[n] == "") {
        dynRemove(dsAlertClasses, n);
      }
      else {
        string sDpeName = dsAlertClasses[n] + ":_alert_class.._perm";
        dsAlertClasses[n] = sDpeName;
      }
    }
    if(dynlen(dsAlertClasses) == 0) {
      return 0;  // See dynRemove() in cycle above
    }

    dyn_int diPerm;
    dpGet(dsAlertClasses, diPerm);
    deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      m_error = "Failed to get permissions for " + dynlen(dsAlertClasses) + " alert class(es) in system " +
                sSystemName;
      throwError(deErrors);
      return -1;
    }
    //DebugN(__FUNCTION__ + "(): diPerm", diPerm);

    // Result is simply the maximum
    return dynMax(diPerm);
  }

  /**
   * Split the list of alarm details to several lists of DPE names, one DPE list per
   * system. The resulting lists will be used in dpGet() call that only accepts DPEs of
   * one system.
   * @param dmAlarms The list of alarm parameters to split from EWO. Every mapping contains:
   *                  - key = ID of alarm property (see ALARM_PROP_XXX constants)
   *                  - value = value of alarm property with this ID
   * @param sAttrName The name of DPE attribute which shall be used when forming lists of DPE names
   * @return mapping with: key = system name, value = dyn_string (list of DPE names for this system)
   */
  private mapping splitToSystems(const dyn_mapping &dmAlarms, const string &sAttrName) {
    mapping mResult;
    for(int n = dynlen(dmAlarms) ; n > 0 ; n--) {
      string sSystemName = dmAlarms[n][ALARM_PROP_SYSTEM];
      if(!mappingHasKey(mResult, sSystemName)) {
        mResult[sSystemName] = makeDynString();
      }
      string sDpeName = dmAlarms[n][ALARM_PROP_FULL_ALARM_DPE];
      sDpeName = AlarmScreenNg_appendDpeAttr(sDpeName, sAttrName);
      dynAppend(mResult[sSystemName], sDpeName);
    }
    return mResult;
  }

  /**
   * Build list of atime from alarm data
   * @param dmAlarms The list of alarm parameters to split from EWO. Every mapping contains:
   *                  - key = ID of alarm property (see ALARM_PROP_XXX constants)
   *                  - value = value of alarm property with this ID
   * @return Resulting list of atime
   */
  private dyn_atime buildAtimeList(const dyn_mapping &dmAlarms) {
    int iTotal = dynlen(dmAlarms);
    for(int n = 1 ; n <= iTotal ; n++) {
      string sDpeName = dmAlarms[n][ALARM_PROP_FULL_ALARM_DPE];
      bool bAddThisAlarm = (m_ackType != DPATTR_ACKTYPE_MULTIPLE);

      if(!bAddThisAlarm) {
        string sDpeToCheck = AlarmScreenNg_appendDpeAttr(sDpeName, "_single_ack");
        bool bSingleAck;
        alertGet(dmAlarms[n][ALARM_PROP_TIME], dmAlarms[n][ALARM_PROP_INDEX], sDpeToCheck, bSingleAck);
        dyn_errClass deErrors = getLastError();
        if(dynlen(deErrors) > 0) {
          m_error = "Failed to read _single_ack for " + makeATime(dmAlarms[n][ALARM_PROP_TIME],
                                                                  dmAlarms[n][ALARM_PROP_INDEX],
                                                                  sDpeToCheck);
          throwError(deErrors);
          return false;  // Fatal error
        }
        if(bSingleAck) {
          m_requireIndividual++;
        }
        else {
          bAddThisAlarm = true;
        }
      }

      if(bAddThisAlarm) {
        sDpeName = AlarmScreenNg_appendDpeAttr(sDpeName,  "_ack_state");
        atime aTime = makeATime(dmAlarms[n][ALARM_PROP_TIME],
                                dmAlarms[n][ALARM_PROP_INDEX],
                                sDpeName);
        if(dmAlarms[n][ALARM_PROP_ACK_STATE_SUMMARY] == ALARM_ACK_STATE_SUMMARY_ACKABLE_OLDEST) {
          dynAppend(m_oldestAlarmsToAck, aTime);
        }
        else {
          dynAppend(m_alarmsToAck, aTime);
        }
      }
    }
    if(dynlen(m_oldestAlarmsToAck) > 0) {
      dynSort(m_oldestAlarmsToAck);
    }
    if(dynlen(m_alarmsToAck) > 0) {
      dynSort(m_alarmsToAck);
    }
    return true;
  }

  /**
   * Acknowledge all alarms in the list
   * @param daToAck List of alarms to be acknowledged
   * @return Number of errors detected during acknowledgement
   */
  private int acknowledgeAtimeList(dyn_atime &daToAck) {
    if(dynlen(daToAck) == 0) {
      return 0;
    }

    // First step: 'non-standard' acknowledgement
    dyn_atime daCopy = daToAck;  // Make copy because isAckable() will call dynUnicque(), which
                                 // works in very special way for dyn_atime - see note in WinCC OA
                                 // help for dynContains()
    int iAckable;
    isAckable(1, daCopy, iAckable);
    if(!iAckable) {
      return 0;  // all alarms have been processed by isAckable()
    }

    // Finally - acknowledge all remaining in list
    int iTotal = dynlen(daToAck);
    int iErrorCount = 0;
    for(int n = 1 ; n <= iTotal ; n++) {
      if(dynContains(daCopy, daToAck[n]) < 1) {
        continue;  // alarm was processed by isAckable()
      }
      //DebugN(__FUNCTION__ + "(): acking " + n + " of " + iTotal +":", daToAck[n]);
      alertSet((time)daToAck[n], getACount(daToAck[n]), getAIdentifier(daToAck[n]), m_ackType);
      dyn_errClass deErrors = getLastError();
      if(dynlen(deErrors) > 0) {
        iErrorCount++;
        throwError(deErrors);
      }
    }
    return iErrorCount;
  }

  /// clear content of this instance, the resulting state is 'empty, no error'
  private void reset() {
    m_error = "";
    m_requireIndividual = 0;
    dynClear(m_oldestAlarmsToAck);
    dynClear(m_alarmsToAck);
  }

  /**
   * Build human-readable description of analysis result explaining
   * the reason why there is nothing to be acknowledged.
   * @return string with human-readable description
   */
  private string getNoGoDescription() {
    if(m_error != "") {
      return m_error;
    }
    if(m_requireIndividual > 0) {
      return "Selected alarms require individual acknowledgement";
    }
    return "Unexpected state: this should not happen";  // No other known reason
  }

  /**
   * Build human-readable confirmation message for acknowledgements which
   * can be executed after analysis
   * @return string with confirmation message
   */
  private string getAckConfirmation() {
    int iTotal = dynlen(m_oldestAlarmsToAck) + dynlen(m_alarmsToAck);
    string sResult = "You are going to acknowledge " + iTotal + " alarm" + (iTotal > 1 ? "s" : "");
    if(m_requireIndividual > 0) {
      sResult += "\n " + m_requireIndividual + " alarm " + (m_requireIndividual > 1 ? "s" : "") +
                 " require individual acknowledgement";
    }
    return sResult;
  }


  /// Error description of execution, can be read using getError() method if execution completed with error
  private string m_error;

  /// Acknowledgement type, one of DPATTR_ACKTYPE_SINGLE/DPATTR_ACKTYPE_MULTIPLE
  private int m_ackType;

  /// Number of selected alarms, which require individual acknowledgement
  private int m_requireIndividual;

  /// List of oldest alarms to be acknowledged, the list is built by analyze() method
  private dyn_atime m_oldestAlarmsToAck;

  /// List of alarms to be acknowledged, the list is built by analyze() method
  private dyn_atime m_alarmsToAck;
};
