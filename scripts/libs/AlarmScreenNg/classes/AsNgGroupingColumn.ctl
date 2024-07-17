// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Settings for alarm property to use used for grouping. Used for user settings.
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions

/// Possible data riles  of alarm property which can be used for grouping
enum AsNgDataRole {
  Display = 0,  ///< Corresponds to Qt::DisplayRole
  Edit = 1      ///< Corresponds to Qt::EditRole
};

/// Definition of grouping column for AS EWO - if grouping is used
class AsNgGroupingColumn {

  /// Get identifier of alarm property used for grouping, see ALARM_PROP_XXX constants
  public string getId() {
    return m_id;
  }

  /// Set identifier of alarm property used for grouping, see ALARM_PROP_XXX constants
  public void setId(const string sValue) {
    m_id = sValue;
  }

  /// Get data role of of alarm property used for grouping
  public AsNgDataRole getRole() {
    return m_role;
  }

  /// Set data role of of alarm property used for grouping
  public void setRole(AsNgDataRole role) {
    m_role = role;
  }

  /// Get the name of role used for grouping
  public string getRoleName() {
    return (m_role == AsNgDataRole::Edit ? "edit" : "display");
  }

  /// Get flag indicating if this value in group column shall be ordered in ascending order
  public bool isSortAsc() {
    return m_sortAsc;
  }

  /// Set flag indicating if this value in group column shall be ordered in ascending order
  public void setSortAsc(bool bSortAsc) {
    m_sortAsc = bSortAsc;
  }

  /**
   * Convert content of mapping to definition of grouping rule, put result to this instance
   * @param mColumn The mapping with grouping column definition in format from user settings JSON
   * @return <c>true</c> if processing was successful
   */
  public bool fromMapping(const mapping &mRule) {
    if(mappinglen(mRule) != 4) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): 4 keys are expected for input, but mapping contains  " +
                           mappinglen(mRule)));
    }
    for(int n = mappinglen(mRule) ; n > 0 ; n--) {
      switch(mappingGetKey(mRule, n)) {
        case "alarmPropId":
          m_id = mappingGetValue(mRule, n);
          break;
        case "groupingRole":
          switch(mappingGetValue(mRule, n)) {
            case "display":
              m_role = AsNgDataRole::Display;
              break;
            case "edit":
              m_role = AsNgDataRole::Edit;
              break;
            default:
              throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                                   __FUNCTION__ + "(): unexpected value for key " +
                                   "groupingRole" + ": " + mappingGetValue(mRule, n)));
              return false;
          }
          break;
        case "textFormat":
          // Not used yet
          break;
        case "sortAscending":
          m_sortAsc = mappingGetValue(mRule, n);
          break;
        default:
          throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                               __FUNCTION__ + "(): unexpected mapping key: " + mappingGetKey(mRule, n)));
          return false;
      }
    }
    return true;
  }

  /// Convert content of this instance to mapping, in format suitable for user settings
  public mapping toMapping() {
    mapping mResult;
    mResult["alarmPropId"] = m_id;
    mResult["groupingRole"] = getRoleName();
    mResult["sortAscending"] = m_sortAsc;
    return mResult;
  }

  private string m_id;         ///< Internal identified of value for this column, see ALARM_PROP_XXX constants
  private AsNgDataRole m_role; ///< Data role of of alarm property used for grouping
  private bool m_sortAsc;      ///< <c>true</c> if this column in header is sorted in ascending order
};
