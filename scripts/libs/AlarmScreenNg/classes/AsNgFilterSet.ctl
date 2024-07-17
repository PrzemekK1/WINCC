// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  The class used for editing filter statistics view definition for AS EWO.
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions

/**
 * The item (single filter widget) of filter set. This basically includes
 * the name of DP where filter definition can be found and position of this
 * item in the set (container).<br>
 * The container is supposed to use grid layout for placing items, and one
 * item to occupy exactly one cell of layout.
 */
struct AsNgFilterSetItem {

  /// Create empty instance
  public AsNgFilterSetItem() {
    m_row = 0;
    m_column = 0;
  }

  public string m_filterDp;  ///< The name of DP where filter definition can be read
  public int m_row;          ///< Row number of this item in container
  public int m_column;       ///< Column umber of this item in container
};

/**
 * This class implements functionality required for editing filter
 * statistics vew definition (stored in DPs of type _NgAsFilterSet).
 * The class provides methods for reading, parsing, modifying and writing
 * new definition of filter statistics view.<br>
 * This class is built for editing filter set by user, but the class itself
 * has no UI-related functionality: only data is handled by this class, not
 * presentation to user.
 */
class AsNgFilterSet {

  /// Get the list of possible values for frame and item shape
  public static dyn_string getShapeValues() {
    return m_shapeValues;
  }

  /// Get the list of possible values for frame and item shadows
  public static dyn_string getShadowValues() {
    return m_shadowValues;
  }

  /// Get the list of possible values for item color sources (both back and fore colors)
  public static dyn_string getColorSources() {
    return m_colorSources;
  }

  /// Get possible values for value parameters to be used in item text and tooltip
  public static dyn_string getValueParams() {
    return m_valueParams;
  }


  /// Create empty instance
  public AsNgFilterSet() {
    clear();
  }

  /// Get last detected error; every set/write operation clears previous error
  public string getError() {
    return m_error;
  }

  /// Check if content of this instance was modified and not saved to DP
  public bool isModified() {
    return m_modified;
  }

  /// Get DP name of this set
  public string getDpName() {
    return m_dpName;
  }

  /// Set the name of existing DP in this set, the content of set is read from this DP
  public void setDpName(const string sDpName) {
    clear();
    m_dpName = sDpName;
    readFromDp();
  }

  /// Get the name of this filter set
  public string getName() {
    return m_setName;
  }

  /// Set the name of this filter set
  public void setName(const string &sValue) {
    m_setName = sValue;
    m_modified = true;
  }

  /// Get current configuration of this filter set in JSON format
  public string getJson() {
    mapping mConfig = pack();
    return jsonEncode(mConfig, false);
  }

  /// Write the content of this filter set into DP, return <c>true</c> if written successfully
  public bool write() {
    m_error = "";
    string sSetJson = getJson();
    dpSet(m_dpName + ".ConfigDp", m_configDp,
          m_dpName + ".SetName", m_setName,
          m_dpName + ".SetJSON", sSetJson);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      m_error = "dpSet() failed for " + m_dpName + ": " + getErrorText(deErrors);
      return false;
    }
    m_modified = false;
    return true;
  }


  /// Get current value of frame shape
  public string getFrameShape() {
    return m_frameShape;
  }

  /// Set new value of frame shape
  public bool setFrameShape(const string &value) {
    if(dynContains(m_shapeValues, value) > 0) {
      m_frameShape = value;
      m_modified = true;
    }
    else {
      m_error = "Unexpected frame shape value '" + value + "'";
      return false;
    }
    return true;
  }

  /// Get current value of frame shadow
  public string getFrameShadow() {
    return m_frameShadow;
  }

  /// Set new value of frame shadow
  public bool setFrameShadow(const string &value) {
    if(dynContains(m_shadowValues, value) > 0) {
      m_frameShadow = value;
      m_modified = true;
    }
    else {
      m_error = "Unexpected frame shadow value '" + value + "'";
      return false;
    }
    return true;
  }

  /// Get current value of frame background color
  public string getFrameBackColor() {
    return m_frameBackColor;
  }

  /// Set new value of frame background color
  public void setFrameBackColor(const string &value) {
    m_frameBackColor = value;
    m_modified = true;
  }

  /// Get current value of frame line width
  public int getFrameLineWidth() {
    return m_frameLineWidth;
  }

  /// Set new value of frame line width
  public void setFrameLineWidth(int value) {
    m_frameLineWidth = value;
    m_modified = true;
  }

  /// Get current value of frame mid-line width
  public int getFrameMidLineWidth() {
    return m_frameMidLineWidth;
  }

  /// Set new value of frame line width
  public void setFrameMidLineWidth(int value) {
    m_frameMidLineWidth = value;
    m_modified = true;
  }

  /// Get current value of space between widgets in frame
  public int getFrameSpacing() {
    return m_frameSpacing;
  }

  /// Set new value of space between widgets in frame
  public void setFrameSpacing(int value) {
    m_frameSpacing = value;
    m_modified = true;
  }

  /// Get current value of item shape
  public string getItemShape() {
    return m_itemShape;
  }

  /// Set new value of item shape
  public bool setItemShape(const string &value) {
    if(dynContains(m_shapeValues, value) > 0) {
      m_itemShape = value;
      m_modified = true;
    }
    else {
      m_error = "Unexpected item shape value '" + value + "'";
      return false;
    }
    return true;
  }

  /// Get current value of item shadow
  public string getItemShadow() {
    return m_itemShadow;
  }

  /// Set new value of item shadow
  public bool setItemShadow(const string &value) {
    if(dynContains(m_shadowValues, value) > 0) {
      m_itemShadow = value;
      m_modified = true;
    }
    else {
      m_error = "Unexpected item shadow value '" + value + "'";
      return false;
    }
    return true;
  }

  /// Get current value of item line width
  public int getItemLineWidth() {
    return m_itemLineWidth;
  }

  /// Set new value of item line width
  public void setItemLineWidth(int value) {
    m_itemLineWidth = value;
    m_modified = true;
  }

  /// Get current value of item mid-line width
  public int getItemMidLineWidth() {
    return m_itemMidLineWidth;
  }

  /// Set new value of item line width
  public void setItemMidLineWidth(int value) {
    m_itemMidLineWidth = value;
    m_modified = true;
  }

  /// Get current source of background color for items
  public string getItemBackColorSource() {
    return m_itemBackColorSource;
  }

  /// Set new source of background color for items
  public void setItemBackColorSource(const string &value) {
    m_itemBackColorSource = value;
    m_modified = true;
  }

  /// Get current source of foreground color for items
  public string getItemForeColorSource() {
    return m_itemForeColorSource;
  }

  /// Set new source of foreground color for items
  public void setItemForeColorSource(const string &value) {
    m_itemForeColorSource = value;
    m_modified = true;
  }

  /// Get current format of item visible text
  public string getItemTextFormat() {
    return m_itemTextFormat;
  }

  /// Set new format of item visible text
  public void setItemTextFormat(const string &value) {
    m_itemTextFormat = value;
    m_modified = true;
  }

  /// Get current format of item tooltip
  public string getItemToolTipTextFormat() {
    return m_itemToolTipTextFormat;
  }

  /// Set new format of item tooltip
  public void setItemToolTipTextFormat(const string &value) {
    m_itemToolTipTextFormat = value;
    m_modified = true;
  }

  /// Get list of individual items (filters) in this set, the type of every item is shared_ptr<AsNgFilterSetItem>
  public dyn_anytype getFilters() {
    return m_filters;
  }

  /// Set given DP name at given position, replace previously existing filter at that position.
  /// Calling this method with empty DP name is interpreted as 'remove filter'
  public void appendFilter(int iRow, int iColumn, const string &sDpName) {
    if(sDpName.isEmpty()) {
      removeFilter(iRow, iColumn);
      return;
    }
    int idx = findItemIndexAtPosition(iRow, iColumn);
    shared_ptr<AsNgFilterSetItem> item;
    if(idx > 0) {
      item = m_filters[idx];
    }
    else {
      item = new AsNgFilterSetItem();
      item.m_row = iRow;
      item.m_column = iColumn;
      dynAppend(m_filters, item);
    }
    item.m_filterDp = sDpName;
    m_modified = true;
  }

  /// Remove filter at given cell
  public void removeFilter(int iRow, int iColumn) {
    int idx = findItemIndexAtPosition(iRow, iColumn);
    if(idx <= 0) {
      return;  // no such cell used
    }
    dynRemove(m_filters, idx);
    m_modified = true;
  }

  /// Move filter (or empty cell) from old cell to new one
  public void moveFilter(int iOldRow, int iOldColumn, int iNewRow, int iNewColumn) {
    int iOldIdx = findItemIndexAtPosition(iOldRow, iOldColumn);
    int iNewIdx = findItemIndexAtPosition(iNewRow, iNewColumn);
    shared_ptr<AsNgFilterSetItem> oldFilter;
    if(iOldIdx > 0) {
      oldFilter = m_filters[iOldIdx];
      oldFilter.m_row = iNewRow;
      oldFilter.m_column = iNewColumn;
    }
    if(iNewIdx > 0) {
      dynRemove(m_filters, iNewIdx);
    }
    m_modified = true;
  }

  /// Find pointer to item at given row and column
  public shared_ptr<AsNgFilterSetItem> findItemAtPosition(int iRow, int iColumn) {
    for(int idx = dynlen(m_filters) ; idx > 0 ; idx--) {
      shared_ptr<AsNgFilterSetItem> filter = m_filters[idx];
      if((filter.m_row == iRow) && (filter.m_column == iColumn)) {
        return filter;
      }
    }
    shared_ptr<AsNgFilterSetItem> dummy;
    return dummy;
  }

  /// Find pointer to item widh given DP name
  public shared_ptr<AsNgFilterSetItem> findItemWithDpName(const string &sDpName) {
    for(int idx = dynlen(m_filters) ; idx > 0 ; idx--) {
      shared_ptr<AsNgFilterSetItem> filter = m_filters[idx];
      if(filter.m_filterDp == sDpName) {
        return filter;
      }
    }
    shared_ptr<AsNgFilterSetItem> dummy;
    return dummy;
  }

  /// Find index of item with given row and column in list m_filters
  public int findItemIndexAtPosition(int iRow, int iColumn) {
    for(int idx = dynlen(m_filters) ; idx > 0 ; idx--) {
      shared_ptr<AsNgFilterSetItem> filter = m_filters[idx];
      if((filter.m_row == iRow) && (filter.m_column == iColumn)) {
        return idx;
      }
    }
    return 0;  // not found
  }

  /// Pack definition of this set to single mapping which can be then encoded to JSON and saved to DPE
  private mapping pack() {
    mapping mGrid;
    mGrid["frameShape"] = m_frameShape;
    mGrid["frameShadow"] = m_frameShadow;
    mGrid["frameBackColor"] = (m_frameBackColor == "" ? "none" : m_frameBackColor);
    mGrid["frameLineWidth"] = m_frameLineWidth;
    mGrid["frameMidLineWidth"] = m_frameMidLineWidth;
    mGrid["frameSpacing"] = m_frameSpacing;

    mGrid["itemShape"] = m_itemShape;
    mGrid["itemShadow"] = m_itemShadow;
    mGrid["itemLineWidth"] = m_itemLineWidth;
    mGrid["itemMidLineWidth"] = m_itemMidLineWidth;
    mGrid["itemBackColorSource"] = m_itemBackColorSource;
    mGrid["itemForeColorSource"] = m_itemForeColorSource;
    mGrid["itemTextFormat"] = m_itemTextFormat;
    mGrid["itemToolTipTextFormat"] = m_itemToolTipTextFormat;

    dyn_anytype daFilters;
    //DebugN(__FUNCTION__ + "(): number of filters: " + dynlen(m_filters));
    int iTotal = dynlen(m_filters);
    for(int n = 1 ; n <= iTotal ; n++) {
      mapping mFilter;
      shared_ptr<AsNgFilterSetItem> filter = m_filters[n];
      // Skip items with negative row/column: they could only appear by mistake,
      // and EWO will not accept negative values anyway
      if((filter.m_row < 0) || (filter.m_column < 0)) {
        continue;
      }
      mFilter["filterDp"] = filter.m_filterDp;
      mFilter["row"] = filter.m_row;
      mFilter["column"] = filter.m_column;
      //DebugN(__FUNCTION__ + "(): filter # " + n + " is", mFilter);
      dynAppend(daFilters, mFilter);
    }
    mGrid["filters"] = daFilters;

    mapping mResult;
    mResult["grid"] = mGrid;
    mResult["Version"] = 1;
    return mResult;
  }

  /// Set all properties to defaule values
  private void clear() {
    m_error = "";
    m_modified = false;

    m_setName = "";
    m_configDp = "";

    m_frameShape = m_shapeValues[1];
    m_frameShadow = m_shadowValues[1];
    m_frameBackColor = "";
    m_frameLineWidth = 1;
    m_frameMidLineWidth = 1;
    m_frameSpacing = 1;

    m_itemShape = m_shapeValues[1];
    m_itemShadow = m_shadowValues[1];
    m_itemLineWidth = 1;
    m_itemMidLineWidth = 1;
    m_itemBackColorSource = m_colorSources[1];
    m_itemForeColorSource = m_colorSources[1];
    m_itemTextFormat = m_valueParams[1];
    m_itemToolTipTextFormat = m_valueParams[1];

    dynClear(m_filters);
  }

  /// Read content of filter set from DP with current name for this set
  private void readFromDp() {
    if(m_dpName == "") {
      m_error = "Empty DP name of filter set";
      return;
    }
    if(!dpExists(m_dpName)) {
      m_error = "DP does not exist " + m_dpName;
      return;
    }
    if(dpTypeName(m_dpName) != AS_FILTER_SET_CONFIG_DP_TYPE) {
      m_error = "Wrong DP type of DP " + m_dpName + ", expected " + AS_FILTER_SET_CONFIG_DP_TYPE;
      return;
    }
    string sSetJson;
    dpGet(m_dpName + ".ConfigDp", m_configDp,
          m_dpName + ".SetName", m_setName,
          m_dpName + ".SetJSON", sSetJson);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      m_error = "dpGet() failed for " + m_dpName + ": " + getErrorText(deErrors);
      return;
    }
    parseJson(sSetJson);
  }

  /// Parse JSON definition of filter set read from SetJSON DPE
  private void parseJson(const string &sSetJson) {
    if(sSetJson == "") {
      return;  // Nothing to parse
    }
    mapping mSet = jsonDecode(sSetJson);
    dyn_errClass deErrors = getLastError();
    if(dynlen(deErrors) > 0) {
      throwError(deErrors);
      addParsingError("Failed parsing JSON of filter set: " + getErrorText(deErrors));
      return;
    }
    if(!mappingHasKey(mSet, "grid")) {
      addParsingError("JSON doesn't contain 'grid' node at root level");
      return;
    }
    mapping mGrid = mSet["grid"];
    for(int n = mappinglen(mGrid) ; n > 0 ; n--) {
      if(mappingGetKey(mGrid, n) == "filters") {
        parseFilters(mappingGetValue(mGrid, n));
      }
      else {
        parseGridNode(mappingGetKey(mGrid, n), mappingGetValue(mGrid, n));
      }
    }
    //DebugN(__FUNCTION__ + "(): after parsing " + dynlen(m_filters));
  }

  /// Parse the node of filter set containing single value
  private void parseGridNode(const string &sKey, const anytype &aValue) {
    string sValue = aValue;  // Many values expect string
    switch(sKey) {
      //===================== Frame appearance =====================
      case "frameShape":
        if(dynContains(m_shapeValues, sValue) > 0) {
          m_frameShape = sValue;
        }
        else {
          addParsingError("Unexpected value for '" + sKey + "': " + aValue);
        }
        break;
      case "frameShadow":
        if(dynContains(m_shadowValues, sValue) > 0) {
          m_frameShadow = sValue;
        }
        else {
          addParsingError("Unexpected value for '" + sKey + "': " + aValue);
        }
        break;
      case "frameBackColor":
        if(sValue != "none") {
          m_frameBackColor = sValue;
        }
        break;
      case "frameLineWidth":
        m_frameLineWidth = aValue;
        break;
      case "frameMidLineWidth":
        m_frameMidLineWidth = aValue;
        break;
      case "frameSpacing":
        m_frameSpacing = aValue;
        break;
      //===================== Item appearance =====================
      case "itemShape":
        if(dynContains(m_shapeValues, sValue) > 0) {
          m_itemShape = sValue;
        }
        else {
          addParsingError("Unexpected value for '" + sKey + "': " + aValue);
        }
        break;
      case "itemShadow":
        if(dynContains(m_shadowValues, sValue) > 0) {
          m_itemShadow = sValue;
        }
        else {
          addParsingError("Unexpected value for '" + sKey + "': " + aValue);
        }
        break;
      case "itemLineWidth":
        m_itemLineWidth = aValue;
        break;
      case "itemMidLineWidth":
        m_itemMidLineWidth = aValue;
        break;
      case "itemBackColorSource":
        if(dynContains(m_colorSources, sValue) > 0) {
          m_itemBackColorSource = sValue;
        }
        else {
          addParsingError("Unexpected value for '" + sKey + "': " + aValue);
        }
        break;
      case "itemForeColorSource":
        if(dynContains(m_colorSources, sValue) > 0) {
          m_itemForeColorSource = sValue;
        }
        else {
          addParsingError("Unexpected value for '" + sKey + "': " + aValue);
        }
        break;
      case "itemTextFormat":
        m_itemTextFormat = sValue;
        break;
      case "itemToolTipTextFormat":
        m_itemToolTipTextFormat = sValue;
        break;
      default:
        addParsingError("unexpected key to parse '" + sKey + "'");
    }
  }

  /// Parse list of filters for this filter set
  void parseFilters(const dyn_anytype &daFilters) {
    int iTotal = dynlen(daFilters);
    //DebugN(__FUNCTION__ + "(): number of daFilters: " + iTotal);
    for(int n = 1 ; n <= iTotal ; n++) {
      parseFilter(daFilters[n]);
    }
  }

  /// Parse definition of single filter
  void parseFilter(const mapping &mFilter) {
    //DebugN(__FUNCTION__ + "(): mFilter:", mFilter);
    shared_ptr<AsNgFilterSetItem> filter = new AsNgFilterSetItem();
    for(int n = mappinglen(mFilter) ; n > 0 ; n--) {
      try {
        switch(mappingGetKey(mFilter, n)) {
          case "filterDp":
            filter.m_filterDp = mappingGetValue(mFilter, n);
            break;
          case "row":
            filter.m_row = mappingGetValue(mFilter, n);
            break;
          case "column":
            filter.m_column = mappingGetValue(mFilter, n);
            break;
          default:
            addParsingError("unexpected key '" + mappingGetKey(mFilter, n) + "' for filter # " + n);
            return;
        }
      }
      catch {
        return;
      }
    }
    if(filter.m_filterDp != "") {
      dynAppend(m_filters, filter);
    }
  }

  /// Add error message, detected during parsing, to 'overall error; of this set
  private void addParsingError(const string &sError) {
    if(m_error != "") {
      m_error += " | ";
    }
    m_error += sError;
  }

  private string m_error;     ///< Description of last detected error

  private bool m_modified;    ///< <c>true</c> if content was modified after reading from DP

  private string m_dpName;    ///< The name of DP where this filter set is stored
  private string m_setName;   ///< The name of this filter set (the value is stored in SetName DPE)
  private string m_configDp;  ///< The name of basic configuration DP for which this set was built
                              ///< (the value is stored in ConfigDp DPE)

  private string m_frameShape;  ///< The shape of frame, containing filter widgets
  private string m_frameShadow;  ///< The shadow of frame, containing filter widgets
  private string m_frameBackColor;  ///< Background color of frame, containing filter widgets
  private int m_frameLineWidth;     ///< The line width around frame, containing filter widgets
  private int m_frameMidLineWidth;  ///< The width of midline around frame, containing filter widgets
  private int m_frameSpacing;       ///< Spacing between widgets in frame, containing filter widgets

  private string m_itemShape;    ///< The shape of items (filter widgets)
  private string m_itemShadow;   ///< The shadow of items (filter widgets)
  private int m_itemLineWidth;   ///< The line width around item (filter widget)
  private int m_itemMidLineWidth; ///< The width of midline around item (filter widget)
  private string m_itemBackColorSource;  ///< The source for background color of item (filter widget)
  private string m_itemForeColorSource;  ///< The source for foreground color of item (filter widget)
  private string m_itemTextFormat;       ///< The format for text (label) of item (filter widget)
  private string m_itemToolTipTextFormat;  ///< The format for tooltip of item (filter widget)

  private dyn_anytype  m_filters;  ///< Items for this set, the type of every item is shared_ptr<AsNgFilterSetItem>

  /// Possible values for m_xxxShape, these correspond to values of QFrame::Shape enum
  private static const dyn_string m_shapeValues = makeDynString("NoFrame", "Box", "Panel",
                                                                "StyledPanel", "HLine", "VLine",
                                                                "WinPanel");

  /// Possible values for m_xxxxShadow, these correspond to values of QFrame::Shadow enum
  private static const dyn_string m_shadowValues = makeDynString("Plain", "Raised", "Sunken");

  /// Possible values for color sources of items (filter widgets), used for both back and fore colors
  private static const dyn_string m_colorSources = makeDynString("none",
                                                                 "totalBg", "totalFg",
                                                                 "cameBg", "cameFg",
                                                                 "wentBg", "wentFg",
                                                                 "notAckedBg", "notAckedFg",
                                                                 "newBg", "newFg");

  /// Possible values for value parameters to be used in item text and tooltip
  private static const dyn_string m_valueParams = makeDynString("%{name}",
                                                                "%{total}", "%{totalBg}", "%{totalFg}", "%{totalTime}",
                                                                "%{came}", "%{cameBg}", "%{cameFg}", "%{cameTime}",
                                                                "%{went}", "%{wentBg}", "%{wentFg}", "%{wentTime}",
                                                                "%{notAck}", "%{notAckBg}", "%{notAckFg}", "%{notAckTime}",
                                                                "%{new}", "%{newBg}", "%{newFg}", "%{newTime}");
};
