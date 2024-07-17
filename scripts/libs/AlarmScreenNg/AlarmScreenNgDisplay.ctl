// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  A set of functions for opening 'standard' panels for alarms.<br>
  The functions here are combined of fwAlarmHandling and aes functions,
  the main goal of introducing these function is removing from original code
  the dependencies on particular source (Table control with alarms), but...
  instead the functions here contain another dependency: on structure of mapping
  with alarm details from AS EWO.
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg"  // Contains for keys in mapping with alarm data
#uses "AlarmScreenNg/AlarmScreenNgActions"  // The names of actions for access control
#uses "AlarmScreenNg/classes/AsNgAccessControl"  // Alarm specific access control

//--------------------------------------------------------------------------------
// variables and constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
 * Replacement for _fwAlarmHandling_showDetails() and aes_displayDetails() functions:
 * Shown details of selected alarm
 * @param mAlarm The mapping containing properties of alarm in row where mouse was clicked
 * @param exceptionInfo The variable where details of exception will be added in case of error
 */
void AlarmScreenNgDisplay_showDetails(const mapping &mAlarmData, dyn_string &exceptionInfo)
{
  // check alarmtype - if sumalert / display sumalertdetails instead of details !
  string dpid = mAlarmData[ALARM_PROP_FULL_ALARM_DPE];
  int dpeType = dpElementType(dpid);

  if(aes_checkSumAlert(dpeType))
  {
    const string panel="vision/aes/AESSumAlertDetails.pnl";
    ChildPanelOnCentralModal(panel, "",
        makeDynString("$dpid:" + dpid ) );
  }
  else
  {
      int mode;  // Looks like mode is not used by panel???
      string panel = "vision/aes/AS_detail.pnl";
      string tim = mAlarmData[ALARM_PROP_TIME];
      int count = mAlarmData[ALARM_PROP_INDEX];
      // start child panel for detail information
      ChildPanelOnCentralModal(panel, "",
                      makeDynString("$dpid:" + dpid,
                                    "$time:" + tim,
                                    "$count:" + count,
                                    "$aesMode:" + mode));
  }
}

/**
 * Replacement for _fwAlarmScreen_showCommentPanel() function, which finally jusy calls aes_insertComment(),
 * or, in this library, calls a local replacement for that function
 * @param mAlarmData The mapping containing all properties of alarm in row where mouse was clicked
 * @param exceptionInfo The variable where details of exception will be added in case of error
 */
void AlarmScreenNgDisplay_showCommentPanel(const mapping &mAlarmData, dyn_string &exceptionInfo)
{
  // Alert with a class which is not saving the alert should not be commented
  string sAlertDp = dpSubStr(mAlarmData[ALARM_PROP_FULL_ALARM_DPE], DPSUB_SYS_DP_EL_CONF_DET);
  string sClass;
  dpGet(sAlertDp + "._class", sClass);
  bool   bArchiv;
  string sArchDpe;
  if(!sClass.isEmpty())
  {
    sArchDpe = sClass + ":_alert_class.._archive";
  }
  else
  {
    sArchDpe = AlarmScreenNg_appendDpeAttr(sAlertDp, + "_archive");
  }
  dpGet(sArchDpe, bArchiv);
  dyn_errClass err = getLastError();
  if(!err.isEmpty())
  {
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpGet() failed for " + sArchDpe +
                      ", AlertDp is: " + sAlertDp + ", class is: " + sClass, "");
    DebugN(__FUNCTION__ + "(): DP type: " + dpTypeName(sAlertDp));
    return;
  }

  // Give a comment to a DP from another system is not allowed
  if(dpSubStr(sAlertDp, DPSUB_SYS ) == "")           // check if correct system
  {
    string sWarningText = getCatStr( "sc", "noCommentSystem" );
    ChildPanelOnCentralModal("vision/MessageWarning", "", makeDynString("$1:" + sWarningText));
  }
  else if(!bArchiv)
  {
    // Alert comment will not be saved
    string sWarningText = getCatStr("sc", "noComment");
    strreplace(sWarningText, "\uA7", "\n");
    ChildPanelOnCentralModal("vision/MessageWarning", "", makeDynString("$1:" + sWarningText));
  }
  else
  {
    // Alert comment will be saved and system is ok
    AsNgAccessControl accessControl;
    int iAccessLevel = accessControl.getAccessLevel(AS_ACTION_VIEW_ALARM_COMMENT);
    if(iAccessLevel != ALARM_SCREEN_ACCESS_ACTION_ENABLE)
    {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): You do not have sufficient rights to comment this alarm", "");
    }
    else
    {
      string dpId = dpSubStr(mAlarmData[ALARM_PROP_FULL_ALARM_DPE], DPSUB_SYS_DP_EL);
      //as_commentAction(row, "vision/SC/AS_detail");
      _AlarmScreenNgDisplay_commentAction(dpId, "vision/aes/AS_detail.pnl", mAlarmData);
    }
  }
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**
 * Replacement for aes_commentAction(): open panel with alarm comments
 * @param dpId DP name for which comment to be displayed
 * @param panel The name of panel to be opened
 * @param mAlarmData Mapping with all details of current alarm from AS EWO
 */
private void _AlarmScreenNgDisplay_commentAction(const string &dpId, const string &panel, const mapping &mAlarmData)
{
  string comment;
  if(mappingHasKey(mAlarmData, ALARM_PROP_COMMENT))  // may be missing in alarm from archive
  {
    comment = mAlarmData[ALARM_PROP_COMMENT];
  }
  atime ti = makeATime(mAlarmData[ALARM_PROP_TIME], mAlarmData[ALARM_PROP_INDEX],
                       mAlarmData[ALARM_PROP_FULL_ALARM_DPE]);
  bool ackable = mAlarmData[ALARM_PROP_ACKABLE];
  bool oldest;
  if(mappingHasKey(mAlarmData, ALARM_PROP_OLDEST_ACK))
  {
    oldest = mAlarmData[ALARM_PROP_OLDEST_ACK];
  }

  _AlarmScreenNgDisplay_queryComment(ti, mAlarmData, comment);

  // start child panel for comment input                 /// panel jetzt AESComments.pnl
  dyn_string ds;
  dyn_float df;
  string tim, count;  // string for automatic conversion
  ChildPanelOnCentralModalReturn("vision/aes/AESComments.pnl", getCatStr("STD_Symbols","Komentareingabe"),    // blubbersatzpanelname
       makeDynString("$comment:" + comment,
                     "$dpid:" + dpSubStr(getAIdentifier(ti), DPSUB_SYS_DP_EL_CONF_DET),
                     "$time:" + (tim = ti),
                     "$count:" + (count = getACount(ti)),
                     "$ackable:" + ackable,
                     "$oldest:" + oldest,
                     "$detailPanel:" + panel,
                     "$mode:SINGLE"),
                     df, ds);

  if(dynlen(df) == 1 && df[1] == 1)
  {
    strreplace(ds[1], "<>", recode((char)0xA7, "ISO-8859-1"));
    dyn_string dsTemp = strsplit(ds[1], recode((char)0xA7, "ISO-8859-1"));
    time t = ti;

    int ret = alertSet(t, getACount(ti), dpSubStr(getAIdentifier(ti), DPSUB_SYS_DP_EL_CONF_DET) + "._comment", ds[1]);
    dyn_errClass err = getLastError();

    if(ret == -1)
    {
      std_error(0, ERR_SYSTEM, PRIO_SEVERE, 0, __FUNCTION__ + "(): alertSet( ... _comment ...)");
    }

    if(dynlen(err))
    {
      errorDialog(err);
    }
    else
    {
      // The original function aes_commentAction() makes here 2 more things:
      //  1) calls this.updateLine() to display new alarm and count in table. The idea is not
      //      clear because alarm table will be updated by callback
      //  2) calls disRecSystem_aesSyncAlertComments(), whose definition was not found with grep

      //IM 116232 synchronize comments in DRS
      /* TODO: L.Kopylov: may be AS EWO will also have 'not current' mode one day... but in such case
         I would pass the mode as one of parameters in callback from AS EWO
      int mode;
      string propDp;
      aes_getPropDpName4TabType(AESTAB_TOP,propDp);
      aes_getPropMode( propDp, mode );   // (type) open, closed, current
      if(mode != AES_MODE_CURRENT)//aktuelle Alarme werden im DRS Script synchronizers
      */
      {
        if(isFunctionDefined("disRecSystem_aesSyncAlertComments") && dpExists("_2x2Redu"))
        {
          disRecSystem_aesSyncAlertComments(ti,ds[1]);
        }
      }
      //IM 116232 synchronize alert comments
    }
  }
}


/**
 * Query current comment string for alarm, part of function aes_commentAction().<br>
 * I don't understand why comment string shall be queried from archive, while we have
 * the current comment in alarm data from AS EWO (or from Table in original version).
 * The only idea is: this was introduced in order to cover the case when menu was opened
 * for long enough time, before selection was made? But still this doesn't look reasonable:
 * I opened menu for what I've seen in the table...
 * @param ti Alarm time
 * @param mAlarmData Mapping containing all columns for selected alarm
 * @param comment The variable where resulting comment will be written
 */
private void _AlarmScreenNgDisplay_queryComment(const atime &ti, const mapping &mAlarmData, string &comment)
{
  dyn_int counts;
  dyn_string dpes1, comments;
  dyn_time times;

  // get attributes of alert
  alertGetPeriod(ti, ti, times, counts,
                 dpSubStr(mAlarmData[ALARM_PROP_FULL_ALARM_DPE], DPSUB_SYS_DP_EL_CONF_DET) + "._comment",
                 dpes1, comments);

  int count = getACount(ti);
  int i = dynContains(counts, count);

  if(i <= 0)
  {
    std_error("", ERR_IMPL, PRIO_WARNING, 0, __FUNCTION__ + ":alertGetPeriod("+ dpSubStr(getAIdentifier(ti), DPSUB_SYS_DP_EL_CONF_DET) +
              "): count " + count + " not found in returned " + dynlen(counts) + " count(s)");
  }
  else
  {
    comment = comments[i];
  }
}
