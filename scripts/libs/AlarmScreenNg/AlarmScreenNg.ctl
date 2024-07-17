/** @file AlarmScreenNg.ctl

  This file contains commonly used declarations (constants, enums) used for
  NextGet AlarmScreen component. Plus some commonly used simple functions.
*/
#uses "fwGeneral/fwException"

/// The name of DP type containing admin settings for AS EWO
/// DP elements are:
///  - AccessControl: settings for access control in JCOP format
///  - PopupMenuJCOP: definition of popup menu for JCOP in JSON format
const string AS_ADMIN_DP_TYPE = "_NgAsAdmin";

/// The name of DP type containing basic configuration for AS EWO
/// DP elements are:
///  - ConfigJSON: basic configuration in JSON format
const string AS_BASIC_CONFIG_DP_TYPE = "_NgAsConfig";

/// The name of DP type containing user settings for AS EWO
/// DP elements are:
///  - ConfigDp: the name of DP with basic configuration for which these user setting is created
///  - SettingName: human-readable name of this user setting
///  - SettingJSON: user settings in JSON format
///  - Usage: the type of this user setting, 3 types are foreseen:
///      - 0: one of settings for user who created/written this DP
///      - 1: default user settings for user who created/written this DP
///      - 2: default settings for all users
const string AS_USER_SETTING_DP_TYPE = "_NgAsUserSetting";

/// The name of DP type containing configuration of single filter for AS EWO
/// DP elements are:
///  - ConfigDp: the name of DP with basic configuration for which these filter is created
///  - FilterName: human-readable name of this filter
///  - Delete: not used yet, the idea was not to delete DPs, but rather to mark them as 'deleted'
///  - FilterJSON: filter content in JSON format
const string AS_FILTER_CONFIG_DP_TYPE = "_NgAsFilter";

/// The name of DP type containing configuration of set of filters for AS EWO
/// DP elements are:
///  - SetName: human-readable name of this filter set
///  - ConfigDp: the name of DP with basic configuration for which these filter is created
///  - SetJSON: filter set definition in JSON format
const string AS_FILTER_SET_CONFIG_DP_TYPE = "_NgAsFilterSet";

/**
 * Enumeration - the type of filter completions for single filter field
 */
enum FilterCompletionsType
{
  None = 0,       ///< No completions for this alarm attribute
  Static = 1,     ///< The completions is a static list of strings
  Dynamic = 2,    ///< The completions for this attribute depend on the filter value
                  ///< for other alarm attribute(s)
  SysRelated = 3  ///< The completions for this attribute depend on connected system(s)
};

/// Possible results of 'save' operations (for filters, user settings etc.)
enum AlarmScreenNgSaveResult
{
  Success = 0,   ///< Filter was saved successfully
  Exists,        ///< Filter with such name already exists, it was written by current user,
                 ///< hence we still can overwrite it after user confirmation
  ExistsAlien,   ///< Filter with such name exists, it was written by different user
  Failure        ///< Operation failed (unexpected error)
};

/** @name Possible values for source mode, the value arrives as 'sourceMode' <b>string</b> value in mapping, passed to events of EWO.
  * The value is enum type in C++ code, but it is converted to string when passing from EWO to CTRL code */
//@{
const string AS_SOURCE_MODE_NONE = "None";                     ///< No source, which most probably means badly configured EWO
const string AS_SOURCE_MODE_ONLINE = "Online";                 ///< Alarm source for online alarms from running system
const string AS_SOURCE_MODE_ARCHIVE_ORACLE = "ArchiveOracle";  ///< Alarm source for archived data from ORACLE RDB
const string AS_SOURCE_MODE_ARCHIVE_VALARCH = "ArchiveValarch";  ///< Alarm source for archived data from valarch
//@}

/** @name Possible values for state of alarm source, the value arrives as 'iState' <b>string</b> value in mapping, passed to
 * sourceStateChanged() event of EWO, as well as sourceState readonly property of EWO.
 * The value is enum type in C++ code, but it is converted to string when passing from EWO to CTRL code */
//@{
const string AS_SOURCE_STATE_INVALID = "Invalid";        ///< The configuration for source is not valid
const string AS_SOURCE_STATE_IDLE = "Idle";           ///< Initial state, source with valid configuration is doing nothing
const string AS_SOURCE_STATE_PREPARE = "Prepare";        ///< The source is preparing (connection, query, etc.)
const string AS_SOURCE_STATE_CONNECT = "Connect";        ///< The source is connecting to alarms (online, archive...)
const string AS_SOURCE_STATE_CONNECTED = "Connected";      ///< The source has been connected (online, archive...)
const string AS_SOURCE_STATE_QUERY = "Query";          ///< The source has submitted query to archive
const string AS_SOURCE_STATE_QUERY_RESULT = "QueryResult";   ///< The source is processing the results returned by query
const string AS_SOURCE_STATE_QUERY_FINISHED = "QueryFinished"; ///< The query has been completed successfully, all results have been processed
const string AS_SOURCE_STATE_QUERY_FAILED = "QueryFailed";   ///< Query execution has failed
const string AS_SOURCE_STATE_QUERY_ABORTED = "QueryAborted";  ///< The query has been aborted
//@}

/** @name The keys for result returned by CTRL function returning filter completions.
  Such functions return @c mapping with 3 fields (at most). This set of constants define
  the allowed keys in returned mapping.
  This keys are expected by C++ code that will interpret the result returned by CTRL function.
*/
//@{
const string AS_FILTER_COMPLETION_KEY_TYPE = "type";  ///< Completion type, the value must be one of enum FilterCompletionsType values
const string AS_FILTER_COMPLETION_KEY_LIST = "list";  ///< The list of completions for type = Static; the list of 'master' alarm property names
                                                      ///< for type = Dynamic. In either case the value is @c dyn_string
const string AS_FILTER_COMPLETION_KEY_MAP = "map";    ///< Possible completions if type = SysRelated. The value shall be @c mapping where
                                                      ///< key = system name [@c string ], value = filter completions [@c dyn_string ]
//@}

/** @name The keys for mapping used during calculation of menu item appearance.
  The function, calculating appearance of menu item, receives as argument mapping
  with all these keys filled. Function shall return mapping with keys, corresponding
  to the values which shall be changed. The same key names are used for both argument
  and return value
*/
//@{
const string AS_MENU_ITEM_KEY_ACCESS = "access";  ///> The value for this key is integer, one of constants ALARM_SCREEN_ACCESS_ACTION_xxx
const string AS_MENU_ITEM_KEY_LABEL = "label";  ///< The value for this key is <c>string</c>, contains label text for menu item
//@}

/** @name The names of single alarm properties, used in AS
  This set defines commonly used property names. Particular systems (JCOP, UNICOS, ...)
  may add own names in extension CTRL library.
*/
//@{
const string ALARM_PROP_ABBREVIATION = "Abbreviation";        ///< _alert_hdl.._abbr
const string ALARM_PROP_ACK_STATE = "AckState";               ///< _alert_hdl.._ack_state
const string ALARM_PROP_ACK_TIME = "AckTime";                 ///< _alert_hdl.._ack_time
const string ALARM_PROP_ACK_TYPE = "AckType";                 ///< _alert_hdl.._ack_type
const string ALARM_PROP_ACKABLE = "Ackable";                  ///< _alert_hdl.._ackable
const string ALARM_PROP_ADD_VALUE_1 = "AddValue1";            ///< _alert_hdl.._add_value_1
const string ALARM_PROP_ADD_VALUE_2 = "AddValue2";            ///< _alert_hdl.._add_value_2
const string ALARM_PROP_ADD_VALUE_3 = "AddValue3";            ///< _alert_hdl.._add_value_3
const string ALARM_PROP_ADD_VALUE_4 = "AddValue4";            ///< _alert_hdl.._add_value_4
const string ALARM_PROP_ALERT_COLOR = "AlertColor";           ///< _alert_hdl.._alert_color
const string ALARM_PROP_ALERT_FONT_STYLE = "AlertFontStyle";  ///< _alert_hdl.._alert_font_style
const string ALARM_PROP_ALERT_FORE_COLOR = "AlertForeColor";  ///< _alert_hdl.._alert_fore_color
const string ALARM_PROP_ALARM_ID = "AlarmId";                 ///< _alert_hdl.._alert_id
const string ALARM_PROP_COMMENT = "Comment";                  ///< _alert_hdl.._comment
const string ALARM_PROP_DESTINATION = "Destination";          ///< _alert_hdl.._dest
const string ALARM_PROP_DIRECTION = "Direction";              ///< _alert_hdl.._direction
const string ALARM_PROP_FILTERED = "Filtered";                ///< _alert_hdl.._filtered
const string ALARM_PROP_FORCE_FILTERED = "ForceFiltered";     ///< _alert_hdl.._force_filtered
const string ALARM_PROP_MULTI_INSTANCE = "MultiInstance";     ///< _alert_hdl.._multi_instance
const string ALARM_PROP_OBSOLETE = "Obsolete";                ///< _alert_hdl.._obsolete
const string ALARM_PROP_PARTNER_TIME = "PartnerTime";         ///< _alert_hdl.._partner
const string ALARM_PROP_PARTNER_TIME_IDX = "PartnerTimeIdx";  ///< _alert_hdl.._partn_idx
const string ALARM_PROP_PROPRITY = "Priority";                ///< _alert_hdl.._prior
const string ALARM_PROP_SUM = "Sum";                          ///< _alert_hdl.._sum
const string ALARM_PROP_TEXT = "Text";                        ///< _alert_hdl.._text
const string ALARM_PROP_VALUE = "Value";                      ///< _alert_hdl.._value
const string ALARM_PROP_VISIBLE = "Visible";                  ///< _alert_hdl.._visible
const string ALARM_PROP_OLDEST_ACK = "OldestAck";             ///< _alert_hdl.._oldest_ack
const string ALARM_PROP_ACK_OBLIG = "AckOblig";               ///< _alert_hdl.._ack_oblig
const string ALARM_PROP_PANEL = "Panel";                      ///< _alert_hdl.._panel
const string ALARM_PROP_PANEL_PARAM = "PanelParam";           ///< _alert_hdl.._panel_param

/// The summary of alarm ackable/acknowledged state, corresponds to column with strings "!!!", "***" etc.
const string ALARM_PROP_ACK_STATE_SUMMARY = "AckStateSummary";

/// Number of comments - result of splitting _alert_hdl.._comment using certain rules
const string ALARM_PROP_COMMENTS_COUNT = "nofComments";

/// This 'property' always contains fixed string "...", this is just a column in table
/// that shall open alarm details when clicked
const string ALARM_PROP_DETAILS = "Details";

/// Live value of DPE, that produced alarm: the value comes not from alarm, but rather from DPE itself
const string ALARM_PROP_LIVE_DPE_VALUE = "liveDpeValue";


const string ALARM_PROP_NON_EXISTENT = "NonExistent";         ///< Boolean, <c>true</c> if DPE of alarm does not exist
const string ALARM_PROP_SYSTEM = "SystemName";                ///< System name
const string ALARM_PROP_DP = "DataPointName";                 ///< Data point name
const string ALARM_PROP_DPE = "ElementName";                  ///< DPE name (without system and DP)
const string ALARM_PROP_FULL_ALARM_DPE = "FullAlarmDpe";      ///< Full DPE name, including system, DP, DPE, config names
const string ALARM_PROP_FULL_DPE = "dpElement";               ///< Full DPE name, including system, DP, DPE names
const string ALARM_PROP_TIME = "AlarmTime";                   ///< Alarm time
const string ALARM_PROP_INDEX = "Index";                      ///< Alarm index within 1 msec of ALARM_PROP_TIME

const string ALARM_PROP_ROW = "row";  ///< The 'row' of this alarm in EWO table, the value is dyn_int (for tree more ethan one 'row' values are needed)
//@}

/** @name The following are not 'real' properties, but rather some extra values
  calculated while AS EWO prepares list of alarms to be acknowledged by CTRL code.
*/
//@{
const string ALARM_PROP_THIS_TO_ACK = "ThisToAck";    ///< The value is true if this alarm needs acknowledgement
const string ALARM_PROP_NO_PARTNER_DATA = "NoPartnerData"; ///< The value is true if model doesn't contain partner
                                                           ///< data, hence, model doesn't know if partner shall be
                                                           ///< acknowledged or not
//@}

/** @name Possible values for alarm property ALARM_PROP_ACK_STATE_SUMMARY = "AckStateSummary"
 * when alarm data are presented in edit mode. In display mode the value is string with
 * almost meaningless values like " !!! ", " xxx " etc. In edit mode the value is int
 * with the following possible values (correspond to AckSummaryStates in C++ code).
 */
//@{
const int ALARM_ACK_STATE_SUMMARY_NONE = 0;            ///< Not acknowledged, and does not need acknowledgement: ""
const int ALARM_ACK_STATE_SUMMARY_ACKED_SINGLE = 1;    ///< _ack_state == DPATTR_ACKTYPE_SINGLE: "  x  "
const int ALARM_ACK_STATE_SUMMARY_ACKED_MULTIPLE = 2;  ///< _ack_state == DPATTR_ACKTYPE_MULTIPLE: " xxx "
const int ALARM_ACK_STATE_SUMMARY_ACKABLE_OLDEST = 3;  ///< not acked, ackable, _oldest_ack == TRUE: " !!! "
const int ALARM_ACK_STATE_SUMMARY_ACKABLE = 4;         ///< not acked, ackable, _oldest_ack == FALSE: "  !  "
const int ALARM_ACK_STATE_SUMMARY_ACK_OBLIG = 5;       ///< not ackable, _ack_oblig == TRUE: " --- "
//@}

/** @name The names of table column properties, returned by AS EWO
*/
//@{
const string AS_TABLE_COL_SOURCE = "source";      ///< Source of alarm property for this column, int:
                                                  ///<   - 0: this alarm (main alarm for this table row)
                                                  ///<   - 1: partner alarm
                                                  ///<   - 2: CAME alarm
                                                  ///<   - 3: WENT alarm
const string AS_TABLE_COL_ID = "id";              ///< ID of alarm property shown in this column, string, corresponds to one of ALARM_PROP_XXX constants,
                                                  ///< or to one of alarm propertiy names of extension (JCOP, UNICOS...)
const string AS_TABLE_COL_TITLE = "title";        ///< Title shown in column header, string
const string AS_TABLE_COL_WIDTH = "width";        ///< The width of this column in pixels, int
const string AS_TABLE_COL_HIDEABLE = "hideable";  ///< Flag indicating if this columkn visibility can be switched by user, bool
const string AS_TABLE_COL_VISIBLE = "visible";    ///< Flag indicating if this column is visible now, bool
const string AS_TABLE_COL_VISIBILITY = "visibility";  ///< Visibiltiy setting for this column, string. May contain one of strings:
                                                      ///< necer, always, online, history, oldmeta
const string AS_TABLE_COL_OLD = "old";            ///< Flag indicating if this column is added automatically in order to display
                                                  ///< old metadata for other column with the same source+id
const string AS_TABLE_COL_MISSING_IN_HISTORY = "missingInHistory";  ///< Flag indicating if content for this column is missing
                                                                    ///< when EWO is used with history (archive) source
//@}

/** Possible values for "source" in column definition, see above */
//@{
const int AS_TABLE_SOURCE_THIS = 0;  ///< The source is 'this' alarm, i.e. alarm shown in table row
const int AS_TABLE_SOURCE_PARTNER = 1;  ///< The source is partner of alarm shown in table row
const int AS_TABLE_SOURCE_CAME = 2;  ///< The source is CAME alarm, can be this or partner, depending on what alarm is shown in this row
const int AS_TABLE_SOURCE_WENT = 2;  ///< The source is WENT alarm, can be this or partner, depending on what alarm is shown in this row
//@}

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
 * When alarms for acknowledgement are requested from AS EWO, in some cases
 * the response can be 'uncertain'. One example is:
 *  - user has requested acknowledgement of all GONE alarms
 *  - EWO has found WENT alarm in model data, but CAME alarm is not in model
 * In such case EWO just doesn't know if CAME alarm shall be acknowledged or not.
 * What EWO does in such case: it adds to the list CAME alarm plus flag saying
 * "I don't know what about WENT" (see ALARM_PROP_NO_PARTNER_DATA constant).
 * Then it is CTRL's code responsibility to decide if partner shall be acknowledged
 * or not. And this is the main purpose of this function.
 * @param dmAlarms The list of alarm parameters from EWO which shall
 *                  be acknowledged. Every mapping contains:
 *                  - key = ID of alarm property (see ALARM_PROP_XXX constants)
 *                  - value = value of alarm property with this ID
 *      This function can remove some entries from the list, or it can add some
 *      entries which are originally missing/
 */
public void AlarmScreenNg_checkForPartnersToAck(dyn_mapping &dmAlarms)
{
  for(int idx = dynlen(dmAlarms) ; idx > 0 ; idx--)
  {
    if(!mappingHasKey(dmAlarms[idx], ALARM_PROP_NO_PARTNER_DATA))
    {
      continue;  // this shall not happen, may be the check is paranoiac?
    }
    if(!dmAlarms[idx][ALARM_PROP_NO_PARTNER_DATA])
    {
      continue;  // AS EWO doesn't miss information on partner
    }
    mapping mPartner = _AlarmScreenNg_partnerToAck(dmAlarms[idx]);
    if(mappinglen(mPartner) > 0)  // There is partner to acknowledge
    {
      dynInsertAt(dmAlarms, mPartner, idx);
      if(!dmAlarms[idx+1][ALARM_PROP_THIS_TO_ACK])
      {
        dynRemove(dmAlarms, idx + 1);
      }
    }
    else if(!dmAlarms[idx][ALARM_PROP_THIS_TO_ACK])
    {
      dynRemove(dmAlarms, idx);
    }
  }
}

/**
 * Append attribute name to DPE name. DPE name comes from "FullAlarmDpe" property
 * (see constant ALARM_PROP_FULL_ALARM_DPE) of alarm from AS EWO; the trick is:
 * this DPE name may contain detail, or detail can be missing.
 * The logic of this function is taken from the code with comment 'do some magic ...'
 * in WinCC OA library <pvss_path>/libs/classes/AcknowledgeTable.ctl
 * @param sDpeName The name of DPE as read from "FullAlarmDpe" property
 * @param sAttrName The name of attribute that shall be added
 * @return Resulting DPE name with attribute
 */
public string AlarmScreenNg_appendDpeAttr(const string &sDpeName, const string &sAttrName)
{
  //DebugN(__FUNCTION__ + "(" + sDpeName + ")", dpSubStr(sDpeName, DPSUB_CONF_DET), dpSubStr(sDpeName, DPSUB_CONF));
  string sResult = dpSubStr(sDpeName, DPSUB_SYS_DP_EL_CONF_DET);
  if(sResult == dpSubStr(sDpeName, DPSUB_SYS_DP_EL_CONF))
  {
    sResult += ".";
  }
  sResult += ".";
  sResult += sAttrName;
  //DebugN(__FUNCTION__ + "(): result is", sResult);
  return sResult;
}

/**
 * Get the name of DP with admin settings for NG AS. If DP does not exists, then
 * it will be created by this function.
 * @param exceptionInfo The variable where error description will be added if something went wrong
 * @return The name of created DP
 */
public string AlarmScreenNg_getAdminDP(dyn_string &exceptionInfo)
{
  // The name of DP is the same as the name of DP type
  string sDpName = AS_ADMIN_DP_TYPE;
  if(!dpExists(sDpName))
  {
    dpCreate(sDpName, AS_ADMIN_DP_TYPE);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0)
    {
      fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): failed to create DP '" +
                        sDpName + "': " + getErrorText(deErrors), "");
      throwError(deErrors);
      return "";
    }
    while(!dpExists(sDpName))
    {
      delay(0, 100);
    }
  }
  return sDpName;
}

/**
 * The replacement for function _fwAlarmHandling_createPlotDp(string plotName).
 * Create and fill DP with trend configuration used in panel vision/AlarmScreenNg/AsNgTrend.pnl
 * The name of DP with configuration is just hardcoded because the name is used in 2 places only:
 *  - this function
 *  - the value of $-parameter in function mentioned
 *
 * @note The direct <c>#uses "fwTrending/fwTrending.ctl"</c> is missing in this library. This function
 * is supposed to be called only when 'open trend from alarm' is requested, for the moment this is in one
 * place only: AlarmScreenMenuJCOP_itemAppearance(), and it is 'the user' who is responsible for loading
 * fwTrending library if it is needed.
 */
public void AlarmScreenNg_createPlotDp()
{
  if(!isFunctionDefined("fwTrending_createPlot"))
  {
    return;  // missing fwTrending component ?
  }

  string sDpName = "_AlarmScreenNgPlot";
  if(dpExists(sDpName))
  {
    return;  // If DP already exists, then most probably it was already properly configured
  }

  dyn_dyn_anytype plotData;

  plotData[fwTrending_PLOT_OBJECT_MODEL][1] = fwTrending_YT_PLOT_MODEL;
  plotData[fwTrending_PLOT_OBJECT_TITLE][1] = "Settings for Alarm Screen Plot";
  plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1] = FALSE;
  plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1] = "FwTrendingTrendBackground";
  plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1] = "FwTrendingTrendForeground";
  plotData[fwTrending_PLOT_OBJECT_DPES] = makeDynString("{dpe1}", "{dpe2}", "{dpe3}", "{dpe4}", "{dpe5}", "{dpe6}", "{dpe7}", "{dpe8}");
  plotData[fwTrending_PLOT_OBJECT_DPES_X] = makeDynString();
  plotData[fwTrending_PLOT_OBJECT_LEGENDS] = makeDynString("{dpe1}", "{dpe2}", "{dpe3}", "{dpe4}", "{dpe5}", "{dpe6}", "{dpe7}", "{dpe8}");
  plotData[fwTrending_PLOT_OBJECT_LEGENDS_X] = makeDynString();
  plotData[fwTrending_PLOT_OBJECT_COLORS] = makeDynString("FwTrendingCurve2", "FwTrendingCurve3", "FwTrendingCurve4",
                                                          "FwTrendingCurve5", "FwTrendingCurve7", "FwTrendingCurve1",
                                                          "FwTrendingCurve6", "FwTrendingCurve8");
  plotData[fwTrending_PLOT_OBJECT_AXII] = makeDynBool(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);
  plotData[fwTrending_PLOT_OBJECT_AXII_X] = makeDynBool();
  plotData[fwTrending_PLOT_OBJECT_IS_TEMPLATE][1] = FALSE;
  plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] = makeDynBool(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);;
  plotData[fwTrending_PLOT_OBJECT_RANGES_MIN] = makeDynInt(0, 0, 0, 0, 0, 0, 0, 0);
  plotData[fwTrending_PLOT_OBJECT_RANGES_MAX] = makeDynInt(0, 0, 0, 0, 0, 0, 0, 0);
  plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X] = makeDynInt();
  plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X] = makeDynInt();
  plotData[fwTrending_PLOT_OBJECT_TYPE][1] = fwTrending_PLOT_TYPE_STEPS;
  plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1] = 3600;
  plotData[fwTrending_PLOT_OBJECT_TEMPLATE_NAME][1] = "";
  plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1] = FALSE;
  plotData[fwTrending_PLOT_OBJECT_GRID][1] = TRUE;
  plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES] = makeDynInt(fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                            fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                            fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                            fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS);
  plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1] = fwTrending_MARKER_TYPE_FILLED_CIRCLE;
  plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1] = "";
  plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW] = makeDynString(1, 0, 0, 0, 0, 0, 0, 0);
  plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1] = 3;
  plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] = fwTrending_DEFAULT_FONT;
  plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1] = "[solid,oneColor,JoinMiter,CapButt,2]";

  dyn_string exceptionInfo;
  fwTrending_createPlot(sDpName, exceptionInfo);
  if(dynlen(exceptionInfo) > 0)
  {
    DebugN(__FUNCTION__ + "(): fwTrending_createPlot() failed:", exceptionInfo);
    return;
  }

  while(!dpExists(sDpName))
  {
    delay(0, 100);
  }
  fwTrending_setPlot(sDpName, plotData, exceptionInfo);
  if(dynlen(exceptionInfo) > 0)
  {
    DebugN(__FUNCTION__ + "(): fwTrending_setPlot() failed:", exceptionInfo);
  }
}

/**
 * Create new DP for saving some configuration.
 * The names for new DPs are generated according to the following rule:
 * <template><incrementing index> (see UNAESCRN-144)
 * @param sDpType The name of DP type for new DP to be created
 * @param sTemplate Template = constant part of DP name
 * @param exceptionInfo The variable where error description will be added if something went wrong
 * @return The name of created DP
 */
public string AlarmScreenNg_createConfigDp(const string &sDpType, const string &sTemplate, dyn_string &exceptionInfo)
{
  string sDpNameTemplate = sTemplate;
  nameCheck(sDpNameTemplate, NAMETYPE_DP);  // Make sure the name doesn't contain wrong chars
  int iDpNumber = _AlarmScreenNg_findFreeDpNumber(sDpNameTemplate);
  string sDpName = sDpNameTemplate + iDpNumber;
  dpCreate(sDpName, sDpType);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    throwError(deErrors);
    fwException_raise(exceptionInfo, "ERROR", __FUNCTION__ + "(): dpCreate(" + sDpName + ") failed", "");
    return "";
  }
  while(!dpExists(sDpName))
  {
    delay(0, 100);
  }
  return sDpName;
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

/**
 * Find free DP number to create new DP, assuming the name of DP is built as
 * <template><number>.
 * The algorithm searches for number, for which DP name, built according to this rules,
 * does not exists. The e3existence of DP is checked using simply dpExists(), the algorithm
 * for searching free number tries to find free DP name after as small as possible number
 * of dpExists() calls.
 * @param sDpNameTemplate The constant part of DP name, number is added to this part in order
 *                        to produce the final DP name
 * @param iStep Initial step for searching free DP number
 * @return Free DP number, DP with name built from this number does not exists yet.
 */
private int _AlarmScreenNg_findFreeDpNumber(const string &sDpNameTemplate, int iStep = 256)
{
  int iDpNumber = 1;
  // First increment DP number with large step until free 'range' is found
  while(dpExists(sDpNameTemplate + iDpNumber))
  {
    iDpNumber += iStep;
  }
  if(iDpNumber == 1)
  {
    return iDpNumber;  // number 1 is not used yet
  }
  // next search back from found free DP number
  int bDpExists = false;
  while(iStep > 1)
  {
    iStep /= 2;
    if(bDpExists)
    {
      iDpNumber += iStep;
    }
    else
    {
      iDpNumber -= iStep;
    }
    bDpExists = dpExists(sDpNameTemplate + iDpNumber);
  }
  if(bDpExists)
  {
    // Finally, if we are at 'busy' number - move in direction to higher numbers with step 1
    for( ; dpExists(sDpNameTemplate + iDpNumber) ; iDpNumber++);
  }
  return iDpNumber;
}

/**
 * Check if partner of given alarm shall be acknowledged, if so - fill in
 * the mapping corresponding to partner alarm
 * @param mAlarm Data for alarm whose partner shall be checked. The mapping contains:
 *                  - key = ID of alarm property (see ALARM_PROP_XXX constants)
 *                  - value = value of alarm property with this ID
 * @return mapping with data for partner alarm to be acknowledged, or
 *          empty mapping if there is no partner to acknowledge
 */
private mapping _AlarmScreenNg_partnerToAck(const mapping &mAlarm)
{
  mapping mPartner;  // empty result

  // Some checks can be done even without querying sever: TODO: may be some of these
  // checks could be done by C++ code of EWO?
  time tEmpty;
  if(mAlarm[ALARM_PROP_PARTNER_TIME] == tEmpty)
  {
    return mPartner;  // no partner time, but this should not happen
  }
  switch(mAlarm[ALARM_PROP_ACK_TYPE])
  {
  case DPATTR_ACK_DELETES:  // acknowledgement deletes
    if(mAlarm[ALARM_PROP_THIS_TO_ACK])
    {
      return mPartner;  // it is enough to acknowledge this alarm
    }
    break;
  case DPATTR_ACK_NONE:     // cannot be acknowledged
    return mPartner;  // Nothing to acknowledge
  case DPATTR_ACK_APP:     // CAME can be acknowledged
  case DPATTR_ACK_PAIR:    // alert pair must be acknowledged
    if(mAlarm[ALARM_PROP_THIS_TO_ACK])
    {
      return mPartner;  // just one of pair to be acknowledged
    }
    break;
  case DPATTR_ACK_APP_AND_DISAPP: // CAME and WENT must be acknowledged
    break;
  default:
    return mPartner;  // probably, ACKNOWLEDGEMENT_SUMALERT, which equivalent to DPATTR_ACK_NONE
  }

  // If we reached this point - then we have to check partner's data in system
  // If alarm will be found ackable, we'll have to set up the correct value for
  // ALARM_PROP_ACK_STATE_SUMMARY property of partner alarm, i.e. to repeat here
  // (partially) the logic of C++ code
  int iAckType;
  bool bAckable, bOldestAck;
  alertGet(mAlarm[ALARM_PROP_PARTNER_TIME], mAlarm[ALARM_PROP_PARTNER_TIME_IDX],
           AlarmScreenNg_appendDpeAttr(mAlarm[ALARM_PROP_FULL_ALARM_DPE], "_ack_type"), iAckType,
           mAlarm[ALARM_PROP_PARTNER_TIME], mAlarm[ALARM_PROP_PARTNER_TIME_IDX],
           AlarmScreenNg_appendDpeAttr(mAlarm[ALARM_PROP_FULL_ALARM_DPE], "_ackable"), bAckable,
           mAlarm[ALARM_PROP_PARTNER_TIME], mAlarm[ALARM_PROP_PARTNER_TIME_IDX],
           AlarmScreenNg_appendDpeAttr(mAlarm[ALARM_PROP_FULL_ALARM_DPE], "_oldest_ack"), bOldestAck);
  dyn_errClass deErrors = getLastError();
  if(dynlen(deErrors) > 0)
  {
    throwError(deErrors);
    return mPartner;
  }

  if(bAckable && (iAckType != DPATTR_ACK_NONE))  // Can be acked, copy almost all of source
  {
    int iStateSummary;
    for(int idx = mappinglen(mAlarm) ; idx > 0 ; idx--)
    {
      string sKey = mappingGetKey(mAlarm, idx);
      switch(sKey)
      {
      case ALARM_PROP_TIME:
        mPartner[ALARM_PROP_PARTNER_TIME] = mappingGetValue(mAlarm, idx);
        break;
      case ALARM_PROP_INDEX:
        mPartner[ALARM_PROP_PARTNER_TIME_IDX] = mappingGetValue(mAlarm, idx);
        break;
      case ALARM_PROP_PARTNER_TIME:
        mPartner[ALARM_PROP_TIME] = mappingGetValue(mAlarm, idx);
        break;
      case ALARM_PROP_PARTNER_TIME_IDX:
        mPartner[ALARM_PROP_INDEX] = mappingGetValue(mAlarm, idx);
        break;
      case ALARM_PROP_ACK_STATE_SUMMARY:
        if(bOldestAck) // _oldest_ack
        {
          iStateSummary = ALARM_ACK_STATE_SUMMARY_ACKABLE_OLDEST;
        }
        else
        {
          iStateSummary = ALARM_ACK_STATE_SUMMARY_ACKABLE;
        }
        mPartner[ALARM_PROP_ACK_STATE_SUMMARY] = iStateSummary;
        break;
      default:
        mPartner[sKey] = mappingGetValue(mAlarm, idx);
        break;
      }
    }
    DebugN(__FUNCTION__ + "(): original, then partner", mAlarm, mPartner);
  }
  return mPartner;
}
