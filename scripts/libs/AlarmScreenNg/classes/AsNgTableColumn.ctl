// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Defintion of table column available in model. Used for editing user settings
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions
#uses "AlarmScreenNg/AlarmScreenNgEwo.ctl"  // For AS_NG_EWO_MODE_xxx constants

/// Definition of single column in AS EWO table
class AsNgTableColumn {

  /// Get column title
  public string getTitle() {
    return m_title;
  }

  /// Get source of data for this column, see AS_TABLE_SOURCE_XXX constants
  public int getSource() {
    return m_source;
  }

  /// Get internal identified of value for this column, see ALARM_PROP_XXX constants
  public string getId() {
    return m_id;
  }

  /// Get width of column in table [pixels]
  public int getWidth() {
    return m_width;
  }

  /// Set width of column in table [pixels]; only positive values are accepted
  public void setWidth(int value) {
    if(value > 0) {
      m_width = value;
    }
  }

  /// Get visibility of this column in table
  public string getVisibility() {
    return m_visibility;
  }

  /// Set visibility of this column in table
  public void setVisibility(string value) {
    m_visibility = value;
  }

  /// Get flag indicating if this column can be hidden
  public bool isHideable() {
    return m_hideable;
  }

  /// Get flag indicating if this column contains old metadata value calculated from archived data
  public bool isOld() {
    return m_old;
  }

  /// Get flag indicating if column is missing for EWO in history (archive) mode
  public bool isMissingInHistory() {
    return m_missingInHistory;
  }

  /**
   * Convert content of mapping to definition of table column, put result to this instance
   * @param mColumn The mapping with column definition in format returned by EWO's
   *                method getAllColumns()
   * @return <c>true</c> if processing was successful
   */
  public bool fromMapping(const mapping &mColumn) {
    if(mappinglen(mColumn) != 9) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): 9 keys are expected for input, but mapping contains  " +
                           mappinglen(mColumn)));
    }
    for(int n = mappinglen(mColumn) ; n > 0 ; n--) {
      switch(mappingGetKey(mColumn, n)) {
        case AS_TABLE_COL_SOURCE:
          m_source = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_ID:
          m_id = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_TITLE:
          m_title = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_WIDTH:
          m_width = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_HIDEABLE:
          m_hideable = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_VISIBILITY:
          m_visibility = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_OLD:
          m_old = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_MISSING_IN_HISTORY:
          m_missingInHistory = mappingGetValue(mColumn, n);
          break;
        case AS_TABLE_COL_VISIBLE:  // Not used here
          break;
        default:
          throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                               __FUNCTION__ + "(): unexpected mapping key: " + mappingGetKey(mColumn, n)));
          return false;
      }
    }
    return true;
  }

  /// Convert content of this instance to mapping, in format suitable for user settings
  public mapping toMapping() {
    mapping mResult;
    mResult["columnTitle"] = m_title;
    mResult["width"] = m_width;
    mResult["visible"] = m_visibility;
    return mResult;
  }

  private string m_title;  ///< Column title
  private int m_source;    ///< The source of data for this column, see AS_TABLE_SOURCE_XXX constants
  private string m_id;     ///< Internal identified of value for this column, see ALARM_PROP_XXX constants
  private int m_width;     ///< The width of column in table [pixels]
  private string m_visibility = "never";  ///< Column's visibility: never, always, online, history, oldmeta
  private bool m_hideable; ///< <c>true</c> if column can be hidden
  private bool m_old;      ///< <c>true</c> if column contains old metadata value calculated from archived data
  private bool m_missingInHistory;  ///< <c>true</c> if column is missing for EWO in history (archive) mode
};
