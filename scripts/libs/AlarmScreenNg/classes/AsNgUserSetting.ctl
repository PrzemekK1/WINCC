// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  The class used when editing user setting for AS EWO
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions
#uses "AlarmScreenNg/classes/AsNgAlarmProperty.ctl"
#uses "AlarmScreenNg/classes/AsNgTableColumn.ctl"
#uses "AlarmScreenNg/classes/AsNgSortingTableColumn.ctl"
#uses "AlarmScreenNg/classes/AsNgGroupingColumn.ctl"

/// Where filter statistics view shall be shown in AS EWO area
enum AsNgFilterViewAppearance {
  None = 0, ///< No filter vew
  Left,     ///< Filter view is located on the left side of widget
  Right,    ///< Filter view is located on the right side of widget
  Top,      ///< Filter view is located on the top of widget
  Bottom    ///< Filter view is located on the bottom of widget
};

/** Possible values for widget visibility, see enum UserSettings::AsAreaVisibility in C++ code */
//@{
private const string WIDGET_VISIBILITY_EXPANDED = "Expanded";
private const string WIDGET_VISIBILITY_COLLAPSED = "Collapsed";
private const string WIDGET_VISIBILITY_HIDDEN = "Hidden";
//@}

/**
 * This class implements functionality required for editing user settings (stored in DP
 * of DP type _NgAsUserSetting).
 * The class provides methods for reading, parsing, modifying and writing
 * new/modified user settings.<br>
 * This class is built for editing user setting by user, but the class itself
 * has no UI-related functionality: only data is handled by this class, not
 * presentation to user.<br>
 * @warning The new content is able to read information from DP, but not to write.
 * The 'final result' of this class is JSON, which can be written by somebody else.
 */
class AsNgUserSetting {

  /**
   * The only constructor: instance is created for particular basic config and
   * set of alarm properties and columns, available in that basic config.
   * @param sConfigDp The name of basic configuration DP
   * @param sJsonString String with current user settings in JSON format, as returned by
   *              EWO's method getUserSettings()
   * @param dmAllProps Definition of all alarm properties available in model, returned
   *                    by EWO's method getAllProperties()
   * @param dmAllColumns Definition of all available columns in model, returned by EWO's
   *                      method getTableColumns()
   */
  public AsNgUserSetting(const string sConfigDp, const string &sJsonString, const dyn_mapping &dmAllProps, const dyn_mapping &dmAllColumns) {
    reset();
    m_configDp = sConfigDp;
    int iTotal = dynlen(dmAllProps);
    for(int n = 1 ; n <= iTotal ; n++) {
      if(!addAvailableProperty(dmAllProps[n])) {
        return;
      }
    }
    iTotal = dynlen(dmAllColumns);
    for(int n = 1 ; n <= iTotal ; n++) {
      if(!addAvailableColumn(dmAllColumns[n])) {
        return;
      }
    }
    if(!parseJson(sJsonString)) {
      reset();
      m_error = "error parsing user setting JSON, see WinCC OA log for details";
    }
    m_empty = false;
  }

  /**
   * Get possible values for widget visibility, see enum UserSettings::AsAreaVisibility
   * in C++ code
   */
  public static dyn_string getPossibleWidgetVisibilityValues() {
    return makeDynString(WIDGET_VISIBILITY_EXPANDED, WIDGET_VISIBILITY_COLLAPSED, WIDGET_VISIBILITY_HIDDEN);
  }

  /// Check if this instance is empty, i.e. it doesn't contain valid configuration
  public bool isEmpty() {
    return m_empty;
  }

  /// Get text description of last detected error
  public string getError() {
    return m_error;
  }

  /// Get the name of basic configuration (DP, but for this instance it is just a name)
  public string getConfigDp() {
    return m_configDp;
  }

  /// Get JSON string with current settings
  public string getJsonString() {
    prepareJson();
    return m_json;
  }

public int getVersion() {
  return m_version;
}

  /// Get appearance for filter widget (above the table)
  public string getFilterWidgetVisibility() {
    return m_filterWidgetVisibility;
  }

  /// Set appearance for filter widget (above the table)
  public void setFilterWidgetVisibility(const string &sValue) {
    dyn_string dsAllowed = getPossibleWidgetVisibilityValues();
    if(!dsAllowed.contains(sValue)) {
      DebugTN(__FUNCTION__ + "(): unexpected value: " + sValue);
      return;
    }
    m_filterWidgetVisibility = sValue;
  }

  /// Get appearance for footer widget (beneath the table)
  public string getFoolterWidgetVisibility() {
    return m_footerWidgetVisibility;
  }

  /// Set appearance for footer widget (beneath the table)
  public void setFooterWidgetVisibility(const string &sValue) {
    dyn_string dsAllowed = getPossibleWidgetVisibilityValues();
    if(!dsAllowed.contains(sValue)) {
      DebugTN(__FUNCTION__ + "(): unexpected value: " + sValue);
      return;
    }
    m_footerWidgetVisibility = sValue;
  }

  /// Get flag indicating if by default 1 row shall be displayed per alarms pair
  public bool isSingleRowPerPair() {
    return m_singleRowPerPair;
  }

  /// Set flag indicating if by default 1 row shall be displayed per alarms pair
  public void setSingleRowPerPair(bool bValue) {
    m_singleRowPerPair = bValue;
  }

  /// Get flag indicating if connection map widget shall be shown
  public bool isShowConnectMap() {
    return m_showConnectMap;
  }

  /// Set flag indicating if connection map widget shall be shown
  public void setShowConnectMap(bool bValue) {
    m_showConnectMap = bValue;
  }

  /// Get flag indicating if special dialog shall be used for connecting/disconnecting by user
  public bool isUseSystemConnectionDialog() {
    return m_useSystemConnectionDialog;
  }

  /// Set flag indicating if special dialog shall be used for connecting/disconnecting by user
  public void setUseSystemConnectionDialog(bool bValue) {
    m_useSystemConnectionDialog = bValue;
  }

  /// Get the string presentation of font used for main table of AS
  public string getTableFont() {
    return m_tableFont;
  }

  /// Set the string presentation of font used for main table of AS
  public void setTableFont(const string &sValue) {
    m_tableFont = sValue;
  }

  /// Get the name of DP where filter statistics view config is taken
  public string getFilterSetDp() {
    return m_filterSetDp;
  }

  /// Get the name of DP where filter statistics view config is taken
  public void setFilterSetDp(const string &sDpName) {
    m_filterSetDp = sDpName;
    if(m_filterSetDp.isEmpty()) {
      m_showFilterView = AsNgFilterViewAppearance::None;
    }
  }

  /// Get required position of filter statistics view
  public AsNgFilterViewAppearance getShowFilterView() {
    return m_showFilterView;
  }

  public void setShowFilterView(AsNgFilterViewAppearance ePosition) {
    m_showFilterView = ePosition;
  }

  /// Get all columns and their settings
  public vector<shared_ptr<AsNgTableColumn> > getColumns() {
    return m_columns;
  }

  /**
   * Move table column up or down.
   * @param iColumnIdx Index of column to be moved
   * @param bMoveUp Direction of movements:
   *   - <c>true</c> = up (towards beginning of column list)
   *   - <c>false</c> = down (towards end of column list)
   * @return New index for table column that was moved, or
   *      -1 if operation failed
   */
  public int moveColumn(int iColumnIdx, bool bMoveUp) {
    int iNewIdx = -1;
    if((iColumnIdx < 0) || (iColumnIdx >= m_columns.count())) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): invalid column index " + iColumnIdx +
                           ", list contains " + m_columns.count() + " column(s)"));
      return iNewIdx;
    }
    iNewIdx = newIndexForMove(iColumnIdx, m_columns.count(), bMoveUp);
    shared_ptr<AsNgTableColumn> column = m_columns.takeAt(iColumnIdx);
    m_columns.insertAt(iNewIdx, column);
    return iNewIdx;
  }

  ///< Get the list of all alarm properties available in proxy model
  public vector<shared_ptr<AsNgAlarmProperty> > getAllProperties() {
    return m_allProps;
  }

  /// Get grouping rules
  public vector<shared_ptr<AsNgGroupingColumn> > getGroupRules() {
    return m_groupRules;
  }

  /// Get the header of grouping column
  public string getGroupHead() {
    return m_groupHeader;
  }

  /// Get the header of grouping column
  public void setGroupHead(const string &sHead) {
    m_groupHeader = sHead;
  }

  /// Get the width of grouping column in table
  public int getGroupWidth() {
    return m_groupWidth;
  }

  /// Set the width of grouping column in table
  public void setGroupWidth(int iWidth) {
    if(iWidth > 0) {
      m_groupWidth = iWidth;
    }
  }

  // Add empty grouping rule, return new number of rules
  public int addGroupRule() {
    shared_ptr<AsNgGroupingColumn> rule = new AsNgGroupingColumn();
    m_groupRules.append(rule);
    return m_groupRules.count();
  }

  /**
   * Move grouping rule up or down.
   * @param iRuleIdx Index of rule to be moved
   * @param bMoveUp Direction of movements:
   *   - <c>true</c> = up (towards beginning of rules list)
   *   - <c>false</c> = down (towards end of rules list)
   * @return New index for rule that was moved, or
   *      -1 if operation failed
   */
  public bool moveGroupRule(int iRuleIdx, bool bMoveUp) {
    int iNewIdx = -1;
    if((iRuleIdx < 0) || (iRuleIdx >= m_groupRules.count())) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): invalid rule index " + iRuleIdx +
                           ", list contains " + m_groupRules.count() + " rule(s)"));
      return iNewIdx;
    }
    iNewIdx = newIndexForMove(iRuleIdx, m_groupRules.count(), bMoveUp);
    shared_ptr<AsNgGroupingColumn> rule = m_groupRules.takeAt(iRuleIdx);
    m_groupRules.insertAt(iNewIdx, rule);
    return iNewIdx;
  }

  /**
   * Remove single rule from grouping rules
   * @param iRuleIdx Index of rules to be removed
   * @return <c>true</c> if rule was removed
   */
  public bool removeGroupRule(int iRuleIdx) {
    if((iRuleIdx < 0) || (iRuleIdx >= m_groupRules.count())) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): invalid rule index " + iRuleIdx +
                           ", list contains " + m_groupRules.count() + " rule(s)"));
      return false;
    }
    m_groupRules.removeAt(iRuleIdx);
    return true;
  }

  /// Get sort order of this user setting
  public vector<shared_ptr<AsNgSortingTableColumn> > getSortRules() {
    return m_sort;
  }

  // Add empty sort rule, return new number of sort rules
  public int addSortRule() {
    shared_ptr<AsNgSortingTableColumn> rule = new AsNgSortingTableColumn();
    m_sort.append(rule);
    return m_sort.count();
  }

  /**
   * Move sort rule up or down.
   * @param iRuleIdx Index of rule to be moved
   * @param bMoveUp Direction of movements:
   *   - <c>true</c> = up (towards beginning of rules list)
   *   - <c>false</c> = down (towards end of rules list)
   * @return New index for rule that was moved, or
   *      -1 if operation failed
   */
  public bool moveSortRule(int iRuleIdx, bool bMoveUp) {
    int iNewIdx = -1;
    if((iRuleIdx < 0) || (iRuleIdx >= m_sort.count())) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): invalid rule index " + iRuleIdx +
                           ", list contains " + m_sort.count() + " rule(s)"));
      return iNewIdx;
    }
    iNewIdx = newIndexForMove(iRuleIdx, m_sort.count(), bMoveUp);
    shared_ptr<AsNgSortingTableColumn> rule = m_sort.takeAt(iRuleIdx);
    m_sort.insertAt(iNewIdx, rule);
    return iNewIdx;
  }


  /**
   * Remove single rule from sorting rules
   * @param iRuleIdx Index of rules to be removed
   * @return <c>true</c> if rule was removed
   */
  public bool removeSortRule(int iRuleIdx) {
    if((iRuleIdx < 0) || (iRuleIdx >= m_sort.count())) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): invalid rule index " + iRuleIdx +
                           ", list contains " + m_sort.count() + " rule(s)"));
      return false;
    }
    m_sort.removeAt(iRuleIdx);
    return true;
  }

  /// Get flag indicating if filter for system auto connect from user settings shall be used
  public bool isOverrideAutoConnectRules() {
    return m_overrideAutoConnectRules;
  }

  /// Set flag indicating if filter for system auto connect from user settings shall be used
  public void setOverrideAutoConnectRules(bool flag) {
    m_overrideAutoConnectRules = flag;
  }

  /// Get list of systems names (with wildcards) which shall be automatically connected
  public dyn_string getAutoConnectIncludes() {
    return m_autoConnectIncludes;
  }

  /// Set list of systems names (with wildcards) which shall be automatically connected
  public void setAutoConnectIncludes(const dyn_string &dsNames) {
    m_autoConnectIncludes = dsNames;
  }

  /// Get list of systems names (with wildcards) which shall NOT be automatically connected
  public dyn_string getAutoConnectExcludes() {
    return m_autoConnectExcludes;
  }

  /// Set list of systems names (with wildcards) which shall NOT be automatically connected
  public void setAutoConnectExcludes(const dyn_string &dsNames) {
    m_autoConnectExcludes = dsNames;
  }

  /// Get flag indicating if dedicated spoiler shall be used to control online visibility of filters
  public bool isUseSpoilerForFilter() {
    return m_useSpoilerForFilter;
  }

  /// Set flag indicating if dedicated spoiler shall be used to control online visibility of filters
  public void setUseSpoilerForFilter(bool flag) {
    m_useSpoilerForFilter = flag;
  }

  /// Get flag indicating if dedicated spoiler shall be used to control online visibility of status bar
  public bool isUseSpoilerForStatusBar() {
    return m_useSpoilerForStatusBar;
  }

  /// Set flag indicating if dedicated spoiler shall be used to control online visibility of status bar
  public void setUseSpoilerForStatusBar(bool flag) {
    m_useSpoilerForStatusBar = flag;
  }

  /// Get flag indicating if dedicated spoiler shall be used to control online visibility of filter view
  public bool isUseSpoilerForFilterView() {
    return m_useSpoilerForFilterView;
  }

  /// Set flag indicating if dedicated spoiler shall be used to control online visibility of filter view
  public void setUseSpoilerForFilterView(bool flag) {
    m_useSpoilerForFilterView = flag;
  }

  /**
   * Parse string in JSON format (as returned by EWO's method getUserSettings()) and
   * store result in this instance for further editing.
   * @param sJsonString The string to be parsed
   * @return <c>true</c> if parsing was successful
   */
  private bool parseJson(const string &sJsonString) {
    mapping mSetting = jsonDecode(sJsonString);
    //DebugN("parsed:", mSetting);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors)) {
      m_error = __FUNCTION__ + "(): error parsing JSON: " + getErrorText(deErrors);
      throwError(deErrors);
      return false;
    }
    for(int n = mappinglen(mSetting) ; n > 0 ; n--) {
      switch(mappingGetKey(mSetting, n)) {
        case "Version":
          m_version = mappingGetValue(mSetting, n);
        case "showFilterWidget":
          if(getType(mappingGetValue(mSetting, n)) == BOOL_VAR) {  // backward compatibility
            m_filterWidgetVisibility = mappingGetValue(mSetting, n) ? WIDGET_VISIBILITY_EXPANDED : WIDGET_VISIBILITY_HIDDEN;
          }
          else {
            m_filterWidgetVisibility = mappingGetValue(mSetting, n);
          }
          break;
        case "showFooterWidget":
          if(getType(mappingGetValue(mSetting, n)) == BOOL_VAR) {  // backward compatibility
            m_footerWidgetVisibility = mappingGetValue(mSetting, n) ? WIDGET_VISIBILITY_EXPANDED : WIDGET_VISIBILITY_HIDDEN;
          }
          else {
            m_footerWidgetVisibility = mappingGetValue(mSetting, n);
          }
          break;
        case "showFilterView":
          switch(mappingGetValue(mSetting, n)) {
            case "none":
              m_showFilterView = AsNgFilterViewAppearance::None;
              break;
            case "left":
              m_showFilterView = AsNgFilterViewAppearance::Left;
              break;
            case "right":
              m_showFilterView = AsNgFilterViewAppearance::Right;
              break;
            case "top":
              m_showFilterView = AsNgFilterViewAppearance::Top;
              break;
            case "bottom":
              m_showFilterView = AsNgFilterViewAppearance::Bottom;
              break;
            default:
              throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                                   __FUNCTION__ + "(): unexpected mapping value '" + mappingGetValue(mSetting, n) +
                                   "' for key: " + mappingGetKey(mSetting, n)));
              return false;
            }
          break;
        case "filterSetDp":
          m_filterSetDp = mappingGetValue(mSetting, n);
          break;
        case "visibleColumns":
          if(!parseVisibleColumns(mappingGetValue(mSetting, n))) {
            return false;
          }
          break;
        case "sortingOrder":
          if(!parseSortingOrder(mappingGetValue(mSetting, n))) {
            return false;
          }
          break;
        case "GroupingConfiguration":
          if(!parseGroupingConfig(mappingGetValue(mSetting, n))) {
            return false;
          }
          break;
        case "singleRowPerPair":
          m_singleRowPerPair = mappingGetValue(mSetting, n);
          break;
        case "allowSwitchPairMode":
          // TODO: planning to remove
          break;
        case "showConnectMap":
          m_showConnectMap = mappingGetValue(mSetting, n);
          break;
        case "useSystemConnectDialog":
          m_useSystemConnectionDialog = mappingGetValue(mSetting, n);
          break;
        case "tableFont":
          m_tableFont = mappingGetValue(mSetting, n);
          break;
        case "defaultFilter":
          m_defaultFilter = mappingGetValue(mSetting, n);
          break;
        case "overrideDefaultAutoConnectRules":
          m_overrideAutoConnectRules = mappingGetValue(mSetting, n);
          break;
        case "autoConnectIncludes":
          m_autoConnectIncludes = mappingGetValue(mSetting, n);
          break;
        case "autoConnectExcludes":
          m_autoConnectExcludes = mappingGetValue(mSetting, n);
          break;
        case "useSpoilerForFilter":
          m_useSpoilerForFilter = mappingGetValue(mSetting, n);
          break;
        case "useSpoilerForStatusBar":
          m_useSpoilerForStatusBar = mappingGetValue(mSetting, n);
          break;
        case "useSpoilerForFilterView":
          m_useSpoilerForFilterView = mappingGetValue(mSetting, n);
          break;
        default:
          throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                               __FUNCTION__ + "(): unexpected mapping key: " + mappingGetKey(mSetting, n)));
          return false;
      }
    }
    return true;
  }

  /// Reset content of this instance to 'empty' default suitable for new settings
  private void reset() {
    m_error = "";
    m_json = "";
    m_version = 1;
    m_filterSetDp = "";
    m_showFilterView = AsNgFilterViewAppearance::None;
    m_filterWidgetVisibility = WIDGET_VISIBILITY_EXPANDED;
    m_footerWidgetVisibility = WIDGET_VISIBILITY_EXPANDED;
    m_singleRowPerPair = false;
    m_showConnectMap = false;
    m_useSystemConnectionDialog = false;
    m_tableFont.clear();
    m_groupHeader = "";
    m_groupWidth = 100;
    m_groupRules.clear();
    m_columns.clear();
    m_sort.clear();
    m_defaultFilter.clear();
    m_overrideAutoConnectRules = false;
    m_autoConnectIncludes.clear();
    m_autoConnectExcludes.clear();
    m_useSpoilerForFilter = false;
    m_useSpoilerForStatusBar = false;
    m_useSpoilerForFilterView = false;
    m_empty = true;
  }

  /**
   * Convert content of mapping to definition of alarm property, add resulting
   * property to list of available properties in this instance.
   * @param mProp The mapping with alarm property definition in format returned by EWO's
   *                method getAllProperties()
   * @return <c>true</c> if mapping has correct content and property was added successfully
   */
  private bool addAvailableProperty(const mapping &mProp) {
    shared_ptr<AsNgAlarmProperty> prop = new AsNgAlarmProperty();
    if(!prop.fromMapping(mProp)) {
      m_error = "failed to process available property, see WinCC OA log for details";
      return false;
    }
    m_allProps.append(prop);
    return true;
  }

  /**
   * Convert content of mapping to definition of table column, add resulting
   * column to list of available columns in this instance.
   * @param mColumn The mapping with table column definition in format returned by EWO's
   *                method getTableColumns()
   * @return <c>true</c> if mapping has correct content and column was added successfully
   */
  private bool addAvailableColumn(const mapping &mColumn) {
    shared_ptr<AsNgTableColumn> column = new AsNgTableColumn();
    if(!column.fromMapping(mColumn)) {
      m_error = "failed to process available column, see WinCC OA log for details";
      return false;
    }
    m_columns.append(column);
    return true;
  }

  /**
   * Process list of visible columns from user settings, this will modify columns previously
   * added to m_columns (all available columns)
   * @param dmColumns The list of mappings with column definition in format found in user settings JSON
   * @return <c>true</c> if mapping has correct content and processing was successful
   */
  private bool parseVisibleColumns(const dyn_mapping &dmColumns) {
    // First set to not visible all available columns which are hidable
    for(int n = m_columns.count() - 1 ; n >= 0 ; n--) {
      shared_ptr<AsNgTableColumn> column = m_columns.at(n);
      if(column.isHideable()) {
        column.setVisibility("never");  // TODO: magic string constant
      }
    }

    // Then apply visibility and width from user settings
    int iTotal = dynlen(dmColumns);
    for(int n = 1 ; n <= iTotal ; n++) {
      if(!parseVisibleColumn(dmColumns[n])) {
        return false;
      }
    }
    return true;
  }

  /**
   * Process definition of single visible column from user settings.
   * @param mColumn Mapping containing visible column definition
   * @return <c>true</c> if processing was successful
   */
  private bool parseVisibleColumn(const mapping &mColumn) {
    if(!mappingHasKey(mColumn, "columnTitle")) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): mapping doesn't contain key: columnTitle"));
      return false;
    }
    shared_ptr<AsNgTableColumn> column = findColumnWithTitle(mColumn["columnTitle"]);
    if(equalPtr(column, nullptr)) {
      return false;
    }
    if(column.isHideable() && mappingHasKey(mColumn, "visible")) {
      column.setVisibility(mColumn["visible"]);
    }
    if(mappingHasKey(mColumn, "width")) {
      column.setWidth(mColumn["width"]);
    }
    return true;
  }

  /**
   * Process sorting order of user settings
   * @param dmOrder list of ordering column parameters
   * @return <c>true</c> if parsing was successful
   */
  private bool parseSortingOrder(const dyn_mapping &dmOrder) {
    int iTotal = dynlen(dmOrder);
    for(int n = 1 ; n <= iTotal ; n++) {
      shared_ptr<AsNgSortingTableColumn> sort = new AsNgSortingTableColumn();
      if(!sort.fromMapping(dmOrder[n])) {
        return false;
      }
      m_sort.append(sort);
    }
    return true;
  }

  /**
   * Parse grouping configuration of user setting, store result in this instance
   * @param mConfig mapping with grouping configuration from user setting JSON
   * @return <c>true</c> if parsing was successful
   */
  private bool parseGroupingConfig(const mapping &mConfig) {
    for(int n = mappinglen(mConfig) ; n > 0 ; n--) {
      switch(mappingGetKey(mConfig, n)) {
        case "groupHeader":
          m_groupHeader = mappingGetValue(mConfig, n);
          break;
        case "columnWidth":
          m_groupWidth = mappingGetValue(mConfig, n);
          break;
        case "groupingRules":
          if(!parseGroupingRules(mappingGetValue(mConfig, n))) {
            return false;
          }
          break;
        default:
          throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                               __FUNCTION__ + "(): unexpected mapping key: " + mappingGetKey(mConfig, n)));
          return false;
      }
    }
    return true;
  }

  /**
   * Parse grouping rules: the set of alarm properties by which model content
   * shall be grouped. The result is stored in this instance.
   * @param dmRules List of rules, in format from user setting JSON
   * @return <c>true</c> if processing was successful.
   */
  private bool parseGroupingRules(const dyn_mapping &dmRules) {
    int iTotal = dynlen(dmRules);
    for(int n = 1 ; n <= iTotal ; n++) {
      shared_ptr<AsNgGroupingColumn> rule = new AsNgGroupingColumn();
      if(!rule.fromMapping(dmRules[n])) {
        return false;
      }
      m_groupRules.append(rule);
    }
    return true;
  }

  /**
   * Find column definition with given title
   * @param sTitle The title to find
   * @return Pointer to column with required title; or <c>nullptr</c> if not found
   */
  private shared_ptr<AsNgTableColumn> findColumnWithTitle(const string &sTitle) {
    vector<int> indices = m_columns.indexListOf("m_title", sTitle);
    if(indices.count() == 0) {
      throwError(makeError("", PRIO_SEVERE, ERR_IMPL, 76,  // 00076,Invalid argument in function
                           __FUNCTION__ + "(): not found column with title: " + sTitle +
                           ", total columns " + m_columns.count()));
      shared_ptr<AsNgTableColumn> dummy;
      return dummy;
    }
    return m_columns.at(indices.at(0));
  }

  /// Generate JSON string with current state of this instance, the result is set to m_json member
  /// In fact, this is operation reverse to parseJson(), and the result of this method must be
  /// successfully processable by parseJson()
  private void prepareJson() {
    mapping mSetting;
    mSetting["Version"] = m_version;
    mSetting["showFilterWidget"] = m_filterWidgetVisibility;
    mSetting["showFooterWidget"] = m_footerWidgetVisibility;
    mSetting["showFilterView"] = showFilterViewToString();
    mSetting["filterSetDp"] = m_filterSetDp;
    dyn_mapping dmVisbleColumns;
    for(int n = 0 ; n < m_columns.count() ; n++) {
      shared_ptr<AsNgTableColumn> column = m_columns.at(n);
      dynAppend(dmVisbleColumns, column.toMapping());
    }
    mSetting["visibleColumns"] = dmVisbleColumns;
    dyn_mapping dmSortOrder;
    for(int n = 0 ; n < m_sort.count() ; n++) {
      shared_ptr<AsNgSortingTableColumn> column = m_sort.at(n);
      dynAppend(dmSortOrder, column.toMapping());
    }
    mSetting["sortingOrder"] = dmSortOrder;
    mSetting["GroupingConfiguration"] = prepareGroupingConfig();
    mSetting["singleRowPerPair"] = m_singleRowPerPair;
    mSetting["showConnectMap"] = m_showConnectMap;
    mSetting["useSystemConnectDialog"] = m_useSystemConnectionDialog;
    mSetting["tableFont"] = m_tableFont;
    mSetting["defaultFilter"] = m_defaultFilter;
    mSetting["overrideDefaultAutoConnectRules"] = m_overrideAutoConnectRules;
    mSetting["autoConnectIncludes"] = m_autoConnectIncludes;
    mSetting["autoConnectExcludes"] = m_autoConnectExcludes;
    mSetting["useSpoilerForFilter"] = m_useSpoilerForFilter;
    mSetting["useSpoilerForStatusBar"] = m_useSpoilerForStatusBar;
    mSetting["useSpoilerForFilterView"] = m_useSpoilerForFilterView;
    m_json = jsonEncode(mSetting, true);
  }

  /// String presentation of AsNgFilterViewAppearance for JSON
  private string showFilterViewToString() {
    string sResult;
    switch(m_showFilterView) {
      case AsNgFilterViewAppearance::None:
        sResult = "none";
        break;
      case AsNgFilterViewAppearance::Left:
        sResult = "left";
        break;
      case AsNgFilterViewAppearance::Right:
        sResult = "right";
        break;
      case AsNgFilterViewAppearance::Top:
        sResult = "top";
        break;
      case AsNgFilterViewAppearance::Bottom:
        sResult = "bottom";
        break;
      }
    return sResult;
  }

  /// Prepare grouping configuration to be inserted to user settings. Operation of this method
  /// is reverse to parseGroupingConfig(): the result of this method must be successfully
  /// processed by parseGroupingConfig()
  private mapping prepareGroupingConfig() {
    mapping mConfig;
    mConfig["groupHeader"] = m_groupHeader;
    mConfig["columnWidth"] = m_groupWidth;
    dyn_mapping dmRules;
    for(int n = 0 ; n < m_groupRules.count() ; n++) {
      shared_ptr<AsNgGroupingColumn> rule = m_groupRules.at(n);
      dynAppend(dmRules, rule.toMapping());
    }
    mConfig["groupingRules"] = dmRules;
    return mConfig;
  }

  /**
   * Calculate new index for list item after moving this item in the list.
   * @param iOldIdx Original index of item in the list
   * @param iListSize The size of list
   * @param bMoveUp <c>true</c> if item shall be moved up (towards beginning of list).
   */
  private int newIndexForMove(int iOldIdx, int iListSize, bool bMoveUp) {
    int iResult = iOldIdx;
    if(bMoveUp) {
      iResult--;
      if(iResult < 0) {
        iResult = iListSize - 1;
      }
    }
    else {
      iResult++;
      if(iResult >= iListSize) {
        iResult = 0;
      }
    }
    return iResult;
  }

  private string m_error;     ///< Description of last detected error

  private string m_json;      ///< User settings in JSON format
  private int m_version;       ///< User settings JSON version
  private string m_name;      ///< The name of this user setting (the value is stored in SettingName DPE)
  private string m_configDp;  ///< The name of basic configuration DP for which this setting was built
                              ///< (the value is stored in ConfigDp DPE)
  private bool m_empty;       ///< <c>true</c> if this instance is empty, i.e. doesn't contain result of parsing valid JSON

  private string m_filterSetDp;  ///< The name of DP where filter statistics view config is taken
  private AsNgFilterViewAppearance m_showFilterView;  ///< Where filter statistics view shall appear
  private string m_filterWidgetVisibility;  ///< One of strings returned by getPossibleWidgetVisibilityValues()
  private string m_footerWidgetVisibility;  ///< One of strings returned by getPossibleWidgetVisibilityValues()
  private bool m_singleRowPerPair;  ///< <c>true</c> if by default model shall display one row per pair of alarms (CAM + WENT)
  private bool m_showConnectMap;  //</ <c>true</c> if 'connection map' widget shall be shown in footer widget

  /// <c>true</c> if dedicated dialog with table of all systems shall be shown when
  /// user wants to connect/disconnect system; <c>false</c> if popup menu with system
  /// names shall be used in such case
  private bool m_useSystemConnectionDialog;

  private string m_tableFont;    ///< String presentation of font used for main AS table

  private string m_groupHeader;  ///< The header for grouping column
  private int m_groupWidth;      ///< The width of grouping column in table
  private vector<shared_ptr<AsNgGroupingColumn> > m_groupRules;  ///< The rules for grouping

  private vector<shared_ptr<AsNgTableColumn> > m_columns;  ///< The list of table columns

  private vector<shared_ptr<AsNgSortingTableColumn> > m_sort;  ///< Default sort order


  private vector<shared_ptr<AsNgAlarmProperty> > m_allProps;  ///< The list of all alarm properties available in proxy model

  private mapping m_defaultFilter;  ///< The filter included in user settings, the content is not interpreted here

  /// <c>true</c> if rules for auto-connection in this instance (m_autoConnectFilter)
  /// shall be used instead of similar rules given in basic configuration.
  /// Note that setting this member to <c>true</c> will completely hide settings from basic
  /// configuration.
  private bool m_overrideAutoConnectRules;

  /// List of systems names (with wildcards) which shall be automatically connected
  private dyn_string m_autoConnectIncludes;

  /// List of systems names (with wildcards) which shall NOT be automatically connected
  private dyn_string m_autoConnectExcludes;

  /// <c>true</c> if online visibility of filters area shall be controlled by dedicated spoiler;
  /// <c>false</c> if visibility shall be controlled by splitter of AS EWO widget
  private bool m_useSpoilerForFilter;

  /// <c>true</c> if online visibility of status bar (below table) shall be controlled by dedicated spoiler;
  /// <c>false</c> if visibility shall be controlled by splitter of AS EWO widget
  private bool m_useSpoilerForStatusBar;

  /// <c>true</c> if online visibility of filter statistics view shall be controlled by dedicated spoiler;
  /// <c>false</c> if filter statistics view can't be hidden
  bool m_useSpoilerForFilterView;
};
