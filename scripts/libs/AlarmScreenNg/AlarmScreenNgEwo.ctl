// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Processing of event fired by AS EWO. The main purpose of functions in this library
  is just loading appropriate CTRL library and calling CTRL function in that library,
  not performing any alarm-related processing.<br>
  The general idea of processing is: the argument to events contain the name of CTRL
  library and CTRL function to be called; this is not magic: the names are supplied
  configuration for EWO.<br>
  This file also contains the 'default' callback functions which shall be used if nothing
  is specified in configuration (i.e. if empty strings will arrive in event parameters).
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
//--------------------------------------------------------------------------------
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // common definitions
#uses "AlarmScreenNg/AlarmScreenNgActions.ctl"  // The names of actions
#uses "AlarmScreenNg/AlarmScreenNgActionProcessing.ctl"  // Default processing for actions

//--------------------------------------------------------------------------------
// variables and constants

/** @name Possible operation modes of data source for AS EWO, the values correspond to enum SourceMode in C++ code */
//@{
public const int AS_NG_EWO_MODE_NONE = 0;  ///< AS EWO operates without data source, i.e. it does not display any alarms
public const int AS_NG_EWO_MODE_ONLINE = 1;  ///< AS EWO operates with online data from WinCC OA
public const int AS_NG_EWO_MODE_ARCHIVE = 2;  ///< AS EWO operates with offline data from archive
//@}

/** @name Possible states of data source for AS EWO, the values correspond to num SourceState in C++ code */
//@{
public const int AS_NG_EWO_SOURCE_INVALID = 0;         ///< The configuration for source is not valid
public const int AS_NG_EWO_SOURCE_IDEL = 1;            ///< Initial state, source with valid configuration is doing nothing
public const int AS_NG_EWO_SOURCE_PREPARE = 2;         ///< The source is preparing (connection, query, etc.)
public const int AS_NG_EWO_SOURCE_CONNECT = 3;         ///< The source is connecting to alarms (online, archive...)
public const int AS_NG_EWO_SOURCE_CONNECTED = 4;       ///< The source has been connected (online, archive...)
public const int AS_NG_EWO_SOURCE_QUERY = 5;           ///< The source has submitted query to archive
public const int AS_NG_EWO_SOURCE_QUERY_RESULT = 6;    ///< The source is processing the results returned by query
public const int AS_NG_EWO_SOURCE_QUERY_FINISHED = 7;  ///< The query has been completed successfully, all results have been processed
public const int AS_NG_EWO_SOURCE_QUERY_FAILED = 8;    ///< Query execution has failed
public const int AS_NG_EWO_SOURCE_QUERY_ABORTED = 9;   ///< The query has been aborted
//@]

/** @name Possible settings for 'timeSpec' property of AS EWO; finally these are converted
    to QDateTime::timeSpec inside EWO */
//@{
public const string AS_NG_EWO_TIMESPEC_LOCAL = "LocalTime";  ///< Local time
public const string AS_NG_EWO_TIMESPEC_UTC = "UTC";  ///< Local time
//@}

/** @name The names of filterKey argument for setQueryFilterParams() which are known to alarm source.
  See NG AS documentation for more details, in particular, see JSON syntax for alarm source configuration */
//@{
public const string AS_NG_EWO_QUERY_FILTER_ONLINE_FROM = "onlineFrom";
public const string AS_NG_EWO_QUERY_FILTER_ONLINE_WHERE = "onlineWhere";
public const string AS_NG_EWO_QUERY_FILTER_ORACLE_WHERE_ELEMENTS = "oracleWhereElements";
public const string AS_NG_EWO_QUERY_FILTER_ORACLE_WHERE_ALERTS = "oracleWhereAlerts";
//@}

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
 * Process "mouseEvent" event of AS EWO
 * @param mArgs event arguments, the mapping contains the following keys of type string:
 *        - "sCtrlLib": the value is a name of CTRL library to be loaded for processing this event
 *        - "sCtrlFunc": the value is a name of CTRL function to be called
 *        - "sourceMode": the value is int, corresponding to one of constants AS_NG_EWO_MODE_xxx
 *        - "mSource": the value is mapping with information on event source, contains the following keys of type string:
 *            - "button": the value is int, indicating which mouse button caused this event
 *            - "screenX": the value is int, X-coordinate of mouse event that caused this event.
 *                          The coordinate is in screen's coordinate system
 *            - "screenY": the value is int, Y-coordinate of mouse event that caused this event.
 *                          The coordinate is in screen's coordinate system
 *            - "row": the value is dyn_int, containing the index of table row where mouse event occurred.
 *                      In case of flat table dyn_int only contains single value: row index in table.
 *                      In case of tree dyn_int contains the indices of table rows from the root of hierarchy
 *                      down to the row with particular alarm
 *            - "columnSource": the value is int, source for information for column where mouse event occurred;
 *                      the values corresponds to one of constants AS_TABLE_SOURCE_xxx
 *            - "columnId": the value is string, identifying the alarm property shown in column where
 *                      mouse event occurred, see constants ALARM_PROP_xxx (plus possible extensions for
 *                      JCOP/UNICOS/...)
 *        - "mAlarm": the value is mapping with all properties of alarm in a row where mouse event occurred
 *     Before calling other functions, this one adds to <c>mArgs</c> one more key:
 *        - "ewoShape": the AS EWO shape from where event was originated.
 */
void AlarmScreenNgEwo_mouseEvent(mapping &mArgs)
{
  mArgs["ewoShape"] = this;  // The event was initiated from AS EWO
  if((mArgs["sCtrlLib"] == "") || (mArgs["sCtrlFunc"] == ""))
  {
    throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                         "missing CTRL library and/or function for mouseEvent processing"));
    return;
  }
  _AlarmScreenNgEwo_processEvent(mArgs);
}

/**
 * Process "ctrlActionRequested" event of AS EWO
 * @param mArgs See description of AlarmScreenNgEwo_mouseEvent(); for this event keys
 *            "mSource" and "mAlarm" are missing in mapping argument.
 *     Before calling other functions, this one adds to <c>mArgs</c> one more key:
 *        - "ewoShape": the AS EWO shape from where event was originated.
 */
void AlarmScreenNgEwo_ctrlActionRequested(mapping &mArgs)
{
  mArgs["ewoShape"] = this;  // The event was initiated from AS EWO
  if((mArgs["sCtrlLib"] == "") || (mArgs["sCtrlFunc"] == ""))
  {
    AlarmScreenNgActionProcessing_process(mArgs);  // Default processing
    return;
  }
  _AlarmScreenNgEwo_processEvent(mArgs);
}


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**
 * Process EWO event by executing script which loads given CTRL library
 * and calls given CTRL function
 * @param mArgs see description of AlarmScreenNgEwo_mouseEvent() and AlarmScreenNgEwo_ctrlActionRequested(),
 *            this function only uses "sCtrlLib" and "sCtrlFunc" of mapping.
 */
private void _AlarmScreenNgEwo_processEvent(const mapping &mArgs)
{
  string sScript = "#uses \"" + mArgs["sCtrlLib"] +"\"" +
                   "void main(const mapping &mArgs)" +
                   "{" +
                   "  " + mArgs["sCtrlFunc"] + "(mArgs);" +
                   "}";
  execScript(sScript, makeDynString(), mArgs);
}
