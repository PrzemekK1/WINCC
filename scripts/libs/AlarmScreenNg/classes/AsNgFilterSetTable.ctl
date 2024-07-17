// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  The class used to display 'filter set definition' in Table control on panel
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/classes/AsNgFilterLiveListener.ctl"  // the listener interface
#uses "AlarmScreenNg/classes/AsNgFilterSet.ctl"  // the data to be displayed

/**
 * This class encapsulates functionality of displaying definition of filter set
 * (of type Grid) in Table control, located in panel.<br>
 * The table is expected to have columns with names "#0", "#1" etc., other column
 * names are not expected. The empty Table is expected to contain the single column
 * with name "#0", other columns (if needed) will be created by this class.
 */
class AsNgFilterSetTable : AsNgFilterLiveListener {

  /// Create empty instance
  public AsNgFilterSetTable() {
    m_freeColor = "{83,255,0,127}";  // semi-transparent green
    m_busyColor = "{255,255,0}";  // yellow
  }

  /**
   * Set parameters of Table control that can be used as source of data for conversion
   * of DP name (with filter config) to filter name.
   * @param sTableName Name of Table that contains columns for both DP name and filter name
   * @param sDpColumn Name of column in table where DP name is stored
   * @param sNameColumn Name of column in table where filter name is stored
   */
  public void setNamingTable(const string &sTableName, const string sDpColumn, const string sNameColumn) {
    m_namingTable = sTableName;
    m_namingDpColumn = sDpColumn;
    m_namingNameColumn = sNameColumn;
  }

  /// Set configuration to be displayed by this instance
  public void setConfig(shared_ptr<AsNgFilterSet> config) {
    m_config = config;
    displayConfig();
  }

  /// Set the name of Table control in panel where filter set configuration shall be shown
  public void setTableName(const string sTableName) {
    m_tableName = sTableName;
    displayConfig();
  }

  /// Display all of current configuration in current table, including adjusting number
  /// of rows and columns in table
  public void displayConfig() {
    if(!ready()) {
      return;  /// not all information is available
    }
    setValue(m_tableName, "deleteAllLines");
    dyn_anytype daAllFilters = m_config.getFilters();
    buildEmptyTable(daAllFilters);
    for(int n = dynlen(daAllFilters) ; n > 0 ; n--) {
      shared_ptr<AsNgFilterSetItem> filter = daAllFilters[n];
      setCellContent(filter.m_row, columnName(filter.m_column), getFilterName(filter.m_filterDp), false);
    }
  }

  /// Append filter information to given cell of table. Note that calling this method
  /// with empty sFilterName works as 'remove filter at given cell'
  public void appendFilter(int iRow, int iCol, const string &sFilterName) {
    if(!ready()) {
      return;  /// not all information is available
    }
    if(sFilterName.isEmpty()) {
      removeFilter(iRow, iCol);
    }
    else {
      setCellContent(iRow, columnName(iCol), sFilterName, false);
      adjustForCellOccupied(iRow, iCol);
    }
  }

  /// Remove filter information at given cell of table
  public void removeFilter(int iRow, int iCol) {
    if(!ready()) {
      return;  /// not all information is available
    }
    setCellContent(iRow, columnName(iCol), "", true);
    adjustForCellFree(iRow, iCol);
  }

  /// Move filter (or empty cell) from old cell to new one
  public void moveFilter(int iOldRow, int iOldColumn, int iNewRow, int iNewColumn) {
    if(!ready()) {
      return;  /// not all information is available
    }
    string sText, sColor;
    getMultiValue(m_tableName, "cellValueRC", iOldRow, columnName(iOldColumn), sText,
                  m_tableName, "cellBackColRC", iOldRow, columnName(iOldColumn), sColor);
    setCellContent(iNewRow, columnName(iNewColumn), sText, sColor == m_freeColor);
    setCellContent(iOldRow, columnName(iOldColumn), "", true);  // old cell became empty
    if(sColor != m_freeColor) {
      adjustForCellOccupied(iNewRow, iNewColumn);
    }
    else {
      adjustForCellFree(iNewRow, iNewColumn);
    }
    adjustForCellFree(iOldRow, iOldColumn);
  }

  /**
   * Method which is called when some changes occurred for one of DP with AS filter configuration.
   * This overrides method of basic class
   * @param event The reason for call, see enum AsNgFilterChangeReason
   * @param sDpName The name of DP with filter configuration where change was detected
   * @param sFilterName The name of filter in this DP
   */
  public void filterChanged(AsNgFilterChangeReason event, const string &sDpName, const string &sFilterName) {
    //DebugN(__FUNCTION__ + "()", event, sDpName, sFilterName);
    shared_ptr<AsNgFilterSetItem> filter = m_config.findItemWithDpName(sDpName);
    if(equalPtr(filter, nullptr)) {
      return;
    }
    switch(event) {
      case AsNgFilterChangeReason::FilterName:
        setCellContent(filter.m_row, columnName(filter.m_column), sFilterName, false);
        break;
      case AsNgFilterChangeReason::Created:  // though... difficult to imagine how could this happen
        setCellContent(filter.m_row, columnName(filter.m_column), sFilterName, false);
        break;
      case AsNgFilterChangeReason::Deleted:  // DP is deleted, but still in filter set
        setCellContent(filter.m_row, columnName(filter.m_column), "", false);
        break;
    }
  }

  /**
   * Configure Table control such that table contains enough rows and columns for
   * displaying 'positions' for all filters. The number of both rows and columns is one
   * more than required for display - in order to be able to add new filters. Then set
   * background color of all cells to 'empty' color.
   * @param daAllFilters Details of all filters to be shown in table, every item in list is
   *                      shared_ptr<AsNgFilterSetItem>
   */
  private void buildEmptyTable(const dyn_anytype &daAllFilters) {
    // calculate required table size
    int iMaxRow = 0, iMaxCol = 0;
    for(int n = dynlen(daAllFilters) ; n > 0 ; n--) {
      shared_ptr<AsNgFilterSetItem> filter = daAllFilters[n];
      if(filter.m_row >= iMaxRow) {
        iMaxRow = filter.m_row + 1;
      }
      if(filter.m_column >= iMaxCol) {
        iMaxCol = filter.m_column + 1;
      }
    }
    //DebugN(__FUNCTION__ + "(): limits found", iMaxRow, iMaxCol);

    // resize, plus one row/column for adding new items
    setColumnCount(iMaxCol + 1);
    setValue(m_tableName, "appendLines", iMaxRow + 1);

    //clear
    string sEmpty;
    for(int iCol = 0 ; iCol <= iMaxCol ; iCol++) {
      string sColumnName = columnName(iCol);
      for(int iRow = 0 ; iRow <= iMaxRow ; iRow++) {
        setCellContent(iRow, sColumnName, sEmpty, true);
      }
    }
  }

  /// Make sure the number of columns in table is exactly as requested, remove/append columns if needed
  private void setColumnCount(int iMaxCol) {
    int iColumnCount = 0;
    getValue(m_tableName, "columnCount", iColumnCount);
    //DebugN(__FUNCTION__ + "(): columns", m_tableName, iColumnCount, iMaxCol);
    if(iMaxCol < iColumnCount) {
      while(iColumnCount > iMaxCol) {
        setValue(m_tableName, "deleteColumn", --iColumnCount);
      }
    }
    else {
      for(int n = iColumnCount ; n < iMaxCol ; n++) {
        //DebugN(__FUNCTION__ + "(): insertColumn", n, columnName(n));
        setValue(m_tableName, "insertColumn", n);
        setMultiValue(m_tableName, "columnName", n, columnName(n),
                      m_tableName, "columnWidth", n, 80);
      }
    }
  }

  /// Process event of occupying given cell in table: add (if necessary)
  /// row and/or column to table in order to have free space next to new cell
  private void adjustForCellOccupied(int iRow, int iCol) {
    int iColumnCount, iRowCount;
    getMultiValue(m_tableName, "columnCount", iColumnCount,
                  m_tableName, "lineCount", iRowCount);
    if((iCol + 1) == iColumnCount) {  // cell is at last column, add one more column
      setValue(m_tableName, "insertColumn", iColumnCount);
      string sColumnName = columnName(iColumnCount);
      setMultiValue(m_tableName, "columnName", iColumnCount, sColumnName,
                    m_tableName, "columnWidth", iColumnCount, 80);
      string sEmpty;
      for(int n = 0 ; n < iRowCount ; n++) {
        setCellContent(n, sColumnName, sEmpty, true);
      }
      iColumnCount++;  // !!!
    }
    if((iRow + 1) == iRowCount) {  // cell is at last row, add one more row
      int iDummy;
      setValue(m_tableName, "appendLine", iDummy);
      string sEmpty;
      for(int n = 0 ; n < iColumnCount ; n++) {
        setCellContent(iRowCount, columnName(n), sEmpty, true);
      }
    }
  }

  /// Process event of freeing given cell in table: remove (if necessary)
  /// row and/or column from table in order not to have 'too much' free rows/columns
  private void adjustForCellFree(int iRow, int iCol) {
    // calculate required table size
    int iMaxRow = 0, iMaxCol = 0;
    dyn_anytype daAllFilters = m_config.getFilters();
    for(int n = dynlen(daAllFilters) ; n > 0 ; n--) {
      shared_ptr<AsNgFilterSetItem> filter = daAllFilters[n];
      if(filter.m_row >= iMaxRow) {
        iMaxRow = filter.m_row + 1;
      }
      if(filter.m_column >= iMaxCol) {
        iMaxCol = filter.m_column + 1;
      }
    }

    // Get current sizes
    int iLineCount, iColumnCount;
    getMultiValue(m_tableName, "lineCount", iLineCount,
                  m_tableName, "columnCount", iColumnCount);

    // Adjust table space, taking into account one more free row and column are needed
    iMaxRow++;
    iMaxCol++;
    while(iLineCount > iMaxRow) {
      setValue(m_tableName, "deleteLineN", --iLineCount);
    }
    while(iColumnCount > iMaxCol) {
      setValue(m_tableName, "deleteColumn", --iColumnCount);
    }
  }

  /// Set content of given cell in table to given text and color, corresponding to free/busy cell state
  private void setCellContent(int iRow, const string &sColumnName, const string &sText, bool bFree) {
    setMultiValue(m_tableName, "cellValueRC", iRow, sColumnName, sText,
                  m_tableName, "cellBackColRC", iRow, sColumnName, bFree ? m_freeColor : m_busyColor);
  }

  /// Build the name for column with given index
  private string columnName(int iColIdx) {
    return "#" + iColIdx;
  }

  /// Check if this instance is ready to display, i.e. it know what and where to display
  private bool ready() {
    if(!equalPtr(m_config, nullptr)) {
      return (m_tableName != "");
    }
    return false;
  }

  /// Find the name of filter stored in DP with given name. In principle, dpGet() can be
  /// used to find filter name, but let's hope that search in another Table is faster
  private string getFilterName(const string sDpName) {
    string sResult;
    if(m_namingTable != "") {
      mapping mKey;
      mKey[m_namingDpColumn] = makeDynString(sDpName);
      dyn_int diLines;
      getValue(m_namingTable, "lineNumbers", mKey, diLines);
      //DebugN(__FUNCTION__ + "(): diLines", mKey, diLines);
      if(dynlen(diLines) > 0) {
        if(diLines[1] >= 0) {
          getValue(m_namingTable, "cellValueRC", diLines[1], m_namingNameColumn, sResult);
        }
      }
    }
    return sResult;
  }

  private shared_ptr<AsNgFilterSet> m_config;  ///< Filter set configuration to be displayed
  private string m_tableName;  ///< The name of Table control where this instance shall display data

  private string m_freeColor;  ///< Color string for background of free cell
  private string m_busyColor;  ///< Color string for background of busy cell

  private string m_namingTable;  ///< The name of another table control where filter name can be found for DP name
  private string m_namingDpColumn;  ///< The name of column with DP in m_namingTable
  private string m_namingNameColumn;  ///< The name of column with filter name in m_namingTable
};
