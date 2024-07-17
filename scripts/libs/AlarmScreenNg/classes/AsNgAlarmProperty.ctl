// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  The definition of one alarm's property; used for user settings editing and some more.
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions

/// Definition of alarm property available in EWO's model
struct AsNgAlarmProperty {

  /**
   * Convert content of mapping to definition of alarm property, put results to this instance
   * @param mProp The mapping with alarm property definition in format returned by EWO's
   *                method getAllProperties()
   * @return <c>true</c> if mapping has correct content and parsing was successful
   */
  public bool fromMapping(const mapping &mProp) {
    if(mappinglen(mProp) != 4) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): 3 keys are expected for input, but mapping contains  " +
                           mappinglen(mProp)));
    }
    for(int n = mappinglen(mProp) ; n > 0 ; n--) {
      switch(mappingGetKey(mProp, n)) {
        case "id":
          m_id = mappingGetValue(mProp, n);
          break;
        case "alarmAttr":
          m_attr = mappingGetValue(mProp, n);
          break;
        case "isAtime":
          m_isAtime = mappingGetValue(mProp, n);
          break;
        case "missingInHistory":
          m_missingIsHistory = mappingGetValue(mProp, n);
          break;
        default:
          throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                               __FUNCTION__ + "(): unexpected mapping key: " + mappingGetKey(mProp, n)));
          return false;
      }
    }
    return true;
  }

  public string m_id;  ///< Internal identified of value for this column, see ALARM_PROP_XXX constants
  public string m_attr;  ///< Attribute of _alert_hdl config, can be empty
  public bool m_isAtime;  ///< <c>true</c> if property was extracted from atime of alarm
  public bool m_missingIsHistory;  ///< <c>true</c> if value for this property is missing in history mode of EWO
};
