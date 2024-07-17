// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  This file defines the names of actions used by AS EWO and by AS_related panels.
  The names are used for access control: in order to enable/disable execution of
  particular actions for currently logged user
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)

//--------------------------------------------------------------------------------
// variables and constants

/** Every action, related to AlarmScreen, is identified by unique name (string).
    The access rights are set for these actions. The following set of names identities
    possible actions, hidden 'inside' EWO. I.e. these names can be used in calls to
    EWO,s method setActionEnabled().<br>
    In principle, other names can also be used, but their effect on EWO will depend on
    the name: if name is known to EWO - then it will do something. Such 'extra' actions,
    in principle, can be buttons, added to EWO.,br>
    Note that these names are passed by EWO in arguments to events.
 */
//@{

/// EWO's notification that new basic config was applied, CTRL code can perform special
/// processing when processing such event of EWO, for example: load default user settings,
/// connect EWO to all (or some) of systems etc. This action can't be disabled, it is listed
/// here just to indicate that the name of action is already used internally
public const string AS_EWO_ACTION_BASIC_CONFIG_APPLIED = "basicConfigApplied";

/// This name is used in mouse event of AS EWO. This action can't be disabled, it is listed
/// here just to indicate that the name of action is already used internally.
public const string AS_EWO_ACTION_MOUSE_EVENT = "mouseEvent";

/// Request of EWO to decode password for connection to ORACLE archive.
/// EWO reads encoded password from DPE, but decoding password requires call of
/// fwDbDecryptPassword() function. This action can't be disabled, it is listed
/// here just to indicate that the name of action is already used internally
public const string AS_EWO_ACTION_ORACLE_PASS_REQUEST = "oraclePassRequest";

// The name related to the settings button
public const string AS_EWO_ACTION_SETTINGS = "settings";

/// The name related to the submenu in the settings menu allowing access to admin setting actions
public const string AS_EWO_ACTION_ADMIN_SETTINGS = "adminSettings";

/// The name of action used to open panel for editing access control
/// Note that opening panel doesn't mean the ability to modify settings,
/// this is controlled by another action: AS_ACTION_EDIT_ACCESS_CONTROL
public const string AS_EWO_ACTION_ADMIN_ACCESS_CONTROL = "adminAccessControl";

/// The name of action used to open panel for editing popup menu definition
/// Note that opening panel doesn't mean the ability to modify menu,
/// this is controlled by another action: AS_ACTION_EDIT_POPUP_MENU
public const string AS_EWO_ACTION_ADMIN_POPUP_MENU = "adminPopupMenu";

/// The name of action used to open panel for editing parameters for
/// querying alarms from ORACLE database.
/// Note that, in contrast to other admin actions, single action is used for
/// both opening the panel and for modifying credentials in that panel.
public const string AS_EWO_ACTION_ADMIN_ORACLE_RDB_SETTINGS = "adminOracleRdbSettings";

/// The name of action used to open panel for editing commands for opening hep files of different types
/// Note that opening panel doesn't mean the ability to modify menu,
/// this is controlled by another action: AS_ACTION_EDIT_HELP_FILE_TYPES
public const string AS_EWO_ACTION_ADMIN_HELP_FILE_TYPES = "adminHelpFileTypes";


/// The name of action controlling availability/visibility of alarm source part of EWO
public const string AS_EWO_ACTION_SRC_CONTROL = "sourceControl";

/// The name of action used to switch between online (live) and archived alarms
public const string AS_EWO_ACTION_SWITCH_SRC_MODE = "switchSourceMode";



/// The name of action used to save current content of filter in EWO
public const string AS_EWO_ACTION_SAVE_FILTER = "saveFilter";

/// The name of action to load previously saved filter to EWO
public const string AS_EWO_ACTION_LOAD_FILTER = "loadFilter";

/// The name of action to open panel for editing content/appearance of filter view
public const string AS_EWO_ACTION_EDIT_FILTER_SET = "editFilterSet";


/// The name related to the submenu in the settings menu allowing access to user setting actions
public const string AS_EWO_ACTION_USER_SETTINGS = "userSettings";

/// The name of action to open the panel for editing user settings
public const string AS_EWO_ACTION_EDIT_USER_SETTINGS = "editUserSettings";

/// The name of action for loading previously saved user settings
public const string AS_EWO_ACTION_LOAD_USER_SETTINGS = "loadUserSettings";

/// The name of action for saving current set of user settings
public const string AS_EWO_ACTION_SAVE_USER_SETTINGS = "saveUserSettings";

/// The name of action to open the panel for viewing/modifying default user settings
public const string AS_EWO_ACTION_SET_DEFAULT_SETTINGS = "defaultUserSettings";


/// The name related to button, allowing to perform a number of actions for
/// user settings (see below). There is no 'real' action with this name, the name
/// can be used to disable for current user all actions, related to operations with
/// user settings
public const string AS_EWO_ACTION_ACK_MULTIPLE = "ackMultiple";

/// The name of action to initiate acknowledgement of all alarms, selected in AS EWO
public const string AS_EWO_ACTION_ACK_SELECTED = "ackSelected";

/// The name of action to initiate acknowledgement of all gone alarms, shown in AS EWO
public const string AS_EWO_ACTION_ACK_GONE = "ackGone";

/// The name of action to initiate acknowledgement of all alarms, shown in AS EWO
public const string AS_EWO_ACTION_ACK_ALL = "ackAll";


/// The name of action to expand all nodes in alarm tree
public const string AS_EWO_ACTION_EXPAND_ALL_NODES = "expandAllNodes";

/// The name of action to collapse all nodes in alarm tree
public const string AS_EWO_ACTION_COLLAPSE_ALL_NODES = "collapseAllNodes";

//@}

/** The following actions are not 'inside' AS EWO, these names are rather used to control
  availability of different action in AS-related panels */
//@{

/// The name of action to control the ability of current user to edit access control rules
public const string AS_ACTION_EDIT_ACCESS_CONTROL = "editAccessControl";

/// The name of action to control the ability of current user to edit popup menu definition
public const string AS_ACTION_EDIT_POPUP_MENU = "editPopupMenu";

/// The name of action to control the ability of current user to edit commands for help file types
public const string AS_ACTION_EDIT_HELP_FILE_TYPES = "editHelpFileTypes";


/// The name of action to control the ability of current user to delete filter, written by another user.
/// Note that ability of deleting own filters is not restricted
public const string AS_ACTION_DELETE_FILTER = "deleteFilter";

/// The name of action to control the ability of current user to create new filter set (filter view)
public const string AS_ACTION_CREATE_FILTER_SET = "createFilterSet";

/// The name of action to control the ability of current user to delete existing filter set (filter view)
public const string AS_ACTION_DELETE_FILTER_SET = "deleteFilterSet";

/// The name of action to control the ability of current user to delete user settings, written by another user.
/// Note that ability of deleting own user settings is not restricted
public const string AS_ACTION_DELETE_USER_SETTING = "deleteUserSetting";

/// The name of action to control the ability of current user to set default user settings for this user
public const string AS_ACTION_SET_USER_SETTINGS_DEFAULT = "setDefaultUserSettings";

/// The name of action to control the ability of current user to set default user settings for all users
public const string AS_ACTION_SET_USER_SETTINGS_DEFAULT_ALL = "setDefaultUserSettingsAll";

/// The name of action to control the ability of current user to acknowledge single alarm
/// Note that disabling this action will disable all other acknowledgement-related actions
/// (acknowledge selected/acknowledge gone/acknowledge all)
public const string AS_ACTION_ACK_SINGLE = "ackSingle";


/// The name of action to control the ability of current user to open FSM panel from alarm screen
public const string AS_ACTION_VIEW_FSM_PANEL = "viewFSMPanel";

/// The name of action to control the ability of current user to open panel with alarm details from alarm screen
public const string AS_ACTION_VIEW_ALARM_DETAILS = "viewAlarmDetails";

/// The name of action to control the ability of current user to open panel with trend for alarm DPE from alarm screen
public const string AS_ACTION_VIEW_ALARM_TREND = "viewAlarmTrend";

/// The name of action to control the ability of current user to open help for alarm from alarm screen
public const string AS_ACTION_VIEW_ALARM_HELP = "viewAlarmHelp";

/// The name of action to control the ability of current user to open comment for alarm from alarm screen
public const string AS_ACTION_VIEW_ALARM_COMMENT = "viewAlarmComment";

/// The name of action to control the ability of current user to toggle _force_filtered bit for alarm masking
public const string AS_ACTION_TOGGLE_MASKED = "toggleAlarmMasked";


//@}

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
 * Get the list of action name which are fixed; in fact - get all names
 * for constants, defined above.<br>
 * These names are 'fixed' in a sense that they were defined, used in the code
 * and can not be changed in easy way. For example, the particular button in AS EWO
 * is 'linked to' given action name in C++ code, and this can not be changed without
 * modifying C++ code.<br>
 * Custom extensions (for example, extra buttons added to EWO, or other extension)
 * may also want to use access control mechanism, based on action names. But this
 * mechanism requires that actions have been assigned unique names. Thus, the main
 * purpose of this function is: give list of names which are already 'busy'.
 * @return List of al known fixed names for actions
 */
dyn_string AlarmScreenNgActions_getAllFixed()
{
  return makeDynString(
      AS_EWO_ACTION_BASIC_CONFIG_APPLIED,
      AS_EWO_ACTION_MOUSE_EVENT,
      AS_EWO_ACTION_ORACLE_PASS_REQUEST,

      AS_EWO_ACTION_SETTINGS,

      AS_EWO_ACTION_ADMIN_SETTINGS,
      AS_EWO_ACTION_ADMIN_ACCESS_CONTROL,
      AS_EWO_ACTION_ADMIN_POPUP_MENU,
      AS_EWO_ACTION_ADMIN_ORACLE_RDB_SETTINGS,
      AS_EWO_ACTION_ADMIN_HELP_FILE_TYPES,

      AS_EWO_ACTION_SRC_CONTROL,
      AS_EWO_ACTION_SWITCH_SRC_MODE,

      AS_EWO_ACTION_SAVE_FILTER,
      AS_EWO_ACTION_LOAD_FILTER,
      AS_EWO_ACTION_EDIT_FILTER_SET,

      AS_EWO_ACTION_USER_SETTINGS,
      AS_EWO_ACTION_EDIT_USER_SETTINGS,
      AS_EWO_ACTION_LOAD_USER_SETTINGS,
      AS_EWO_ACTION_SAVE_USER_SETTINGS,
      AS_EWO_ACTION_SET_DEFAULT_SETTINGS,

      AS_EWO_ACTION_ACK_MULTIPLE,
      AS_EWO_ACTION_ACK_SELECTED,
      AS_EWO_ACTION_ACK_GONE,
      AS_EWO_ACTION_ACK_ALL,

      AS_EWO_ACTION_EXPAND_ALL_NODES,
      AS_EWO_ACTION_COLLAPSE_ALL_NODES,

      AS_ACTION_EDIT_ACCESS_CONTROL,
      AS_ACTION_EDIT_POPUP_MENU,
      AS_ACTION_EDIT_HELP_FILE_TYPES,

      AS_ACTION_DELETE_FILTER,
      AS_ACTION_CREATE_FILTER_SET,
      AS_ACTION_DELETE_FILTER_SET,

      AS_ACTION_DELETE_USER_SETTING,
      AS_ACTION_SET_USER_SETTINGS_DEFAULT,
      AS_ACTION_SET_USER_SETTINGS_DEFAULT_ALL,

      AS_ACTION_ACK_SINGLE,

      AS_ACTION_VIEW_FSM_PANEL,
      AS_ACTION_VIEW_ALARM_DETAILS,
      AS_ACTION_VIEW_ALARM_TREND,
      AS_ACTION_VIEW_ALARM_HELP,
      AS_ACTION_VIEW_ALARM_COMMENT,
      AS_ACTION_TOGGLE_MASKED
      );
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
