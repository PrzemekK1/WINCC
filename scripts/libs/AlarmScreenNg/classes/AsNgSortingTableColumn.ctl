// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions

/// Definition of sorting column settings
struct AsNgSortingTableColumn {

  /**
   * Convert content of mapping to definition of sorting table column, put result to this instance
   * @param mColumn The mapping with sorting column definition in format from user settings JSON
   * @return <c>true</c> if processing was successful
   */
  public bool fromMapping(const mapping &mColumn) {
    if(mappinglen(mColumn) != 2) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): 2 keys are expected for input, but mapping contains  " +
                           mappinglen(mColumn)));
    }
    for(int n = mappinglen(mColumn) ; n > 0 ; n--) {
      switch(mappingGetKey(mColumn, n)) {
        case "columnTitle":
          m_title = mappingGetValue(mColumn, n);
          break;
        case "sortAscending":
          m_sortAscending = mappingGetValue(mColumn, n);
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
    mResult["sortAscending"] = m_sortAscending;
    return mResult;
  }

  public string m_title;  ///< Column title
  public bool m_sortAscending;  ///< <c>true</c> if sorting shall be done in ascending order
};
