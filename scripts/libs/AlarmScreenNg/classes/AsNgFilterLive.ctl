// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Auxiliary class for UI: provide live table with all available filters.
  The main reason for introducing this class is to make panel's code more
  readable and manageable.
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Common definitions
#uses "AlarmScreenNg/AlarmScreenNgConfigs.ctl"
#uses "AlarmScreenNg/AlarmScreenNgFilters.ctl"
#uses "AlarmScreenNg/classes/AsNgFilterLiveListener.ctl"  // the listener for 'events' of this class

/**
 * The class provides live content of Table, displaying list of available
 * filter definitions in the system.<br>
 * The instance of this class builds initial content of table and makes
 * corresponding connections in order to react on changes in the system,
 * and reflect these changes in the Table.<br>
 * In addition, this class may call given function ('callback') when changes
 * occur in the system.<br>
 * It is expected that Table contains at least two columns:
 *    - for storing and (optionally) displaying DP name of filter configuration
 *    - for storing and (most probably) displaying visible filter name
 */
class AsNgFilterLive {

  /// Create empty instance
  public AsNgFilterLive() {
  }

  /// Get last detected error message
  public string getError() {
    return m_error;
  }

  /// Set the listener to be notified in case of changes.
  public void setListener(shared_ptr<AsNgFilterLiveListener> listener) {
    m_listener = listener;
  }

  /**
   * Connect given Table control to live set of filters in the system, after this
   * call this will update the content of Table
   * @param sTableName The name of Table control where data shall be displayed
   * @param sDpColumn The name of column in this Table where DP name shall be written
   * @param sNameColumn The name of column in this table where visible filter name shall be written
   * @return <c>true</c> if connection was successful.
   */
  public bool connect(const string &sTableName, const string sDpColumn, const string &sNameColumn) {
    m_error = "";
    if(m_connected) {
      m_error = "Already connected to filter data";
      return false;
    }

    m_tableName = sTableName;
    m_dpColumn = sDpColumn;
    m_nameColumn = sNameColumn;
    setValue(m_tableName, "deleteAllLines");

    dyn_dyn_anytype ddaAllFilters = AlarmScreenNgFilters_loadNames("", false);

    if(dynlen(ddaAllFilters) >= NGAS_FILTER_INFO_USER) {  // Connect to existing
      // TODO: use pure DP name, without system name???
      dyn_string dsDpNames;
      int iTotal = dynlen(ddaAllFilters[NGAS_FILTER_INFO_DP]);
      for(int n = 1 ; n <= iTotal ; n++) {
        dpConnect(this, this.filterNameCb, false, ddaAllFilters[NGAS_FILTER_INFO_DP][n] + ".FilterName");
        dyn_errClass deErrors = getLastError();
        if(dynlen(deErrors) > 0) {
          m_error = "dpConnect() failed for " + ddaAllFilters[NGAS_FILTER_INFO_DP][n] + ": " + getErrorText(deErrors);
          throwError(deErrors);
          return false;
        }
        dynAppend(dsDpNames, dpSubStr(ddaAllFilters[NGAS_FILTER_INFO_DP][n], DPSUB_DP));
      }
      setValue(m_tableName, "appendLines", dynlen(dsDpNames),
               m_dpColumn, dsDpNames,
               m_nameColumn, ddaAllFilters[NGAS_FILTER_INFO_NAME]);
    }

    // In addition, panel shall follow creation/deletion of filter DPs
    sysConnect(this, this.filterCreateDeleteCb, "dpCreated");
    sysConnect(this, this.filterCreateDeleteCb, "dpDeleted");

    // TODO: what about DP renaming???
    return true;
  }

  /// Callback of dpConnect(), called when the value of ".FilterName" DPE has changed
  public void filterNameCb(string sDpeName, string sFilterName) {
    //DebugN(__FUNCTION__ + "()", sDpeName, sFilterName);
    string sDpName = dpSubStr(sDpeName, DPSUB_DP);
    setValue(m_tableName, "updateLine", 1, m_dpColumn, sDpName, m_nameColumn, sFilterName);
    if(!equalPtr(m_listener, nullptr)) {
      m_listener.filterChanged(AsNgFilterChangeReason::FilterName, sDpName, sFilterName);
    }
  }

  public void filterCreateDeleteCb(string sEvent, mapping mData) {
    //DebugN(__FUNCTION__ + "()", sEvent, mData);
    if(mData["dpType"] != AS_FILTER_CONFIG_DP_TYPE) {
      return;  // Another DP type
    }
    if(dpSubStr(mData["dp"], DPSUB_SYS) != getSystemName()) {
      return;  // DP in another system
    }
    if(sEvent == "dpCreated") {
      if(!equalPtr(m_listener, nullptr)) {
        string sDpName = dpSubStr(mData["dp"], DPSUB_DP);
        m_listener.filterChanged(AsNgFilterChangeReason::Created, sDpName, "");
      }
      dpConnect(this, this.filterNameCb, mData["dp"] + ".FilterName");
      dyn_errClass deErrors = getLastError();
      if(dynlen(deErrors) > 0) {
        m_error = "dpConnect() failed for " + mData["dp"] + ": " + getErrorText(deErrors);
        throwError(deErrors);
      }
    }
    else if(sEvent == "dpDeleted") {
      // dpSubStr() is not able to get pure DP name, may be because DP was already deleted?
      dyn_string dsParts = strsplit(mData["dp"], ":");
      string sDpName = dynlen(dsParts) == 2 ? dsParts[2] : mData["dp"];
      //DebugN(__FUNCTION__ + "(): deleted", sDpName, mData);
      // by some reason Table.deleteLine() doesn't work in this case
      int iLine = findTableLineByDp(sDpName);
      if(iLine > 0) {
        setValue(m_tableName, "deleteLineN", iLine); // No such available filter anymore
      }
      if(!equalPtr(m_listener, nullptr)) {
        m_listener.filterChanged(AsNgFilterChangeReason::Deleted, sDpName, "");
      }
    }
  }

  /// Find line number in table containing given DP name in column "dp"
  private int findTableLineByDp(string sDpName) {
    mapping mKey;
    mKey[m_dpColumn] = makeDynString(sDpName);
    dyn_int diLines;
    getValue(m_tableName, "lineNumbers", mKey, diLines);
    //DebugN(__FUNCTION__ + "(): diLines", mKey, diLines);
    if(dynlen(diLines) == 0) {
      return -1;
    }
    return diLines[1];
  }


  private string m_error;      ///< The description of last detected error

  private bool m_connected;    ///< Flag indicating if this instance is connected to DP data
  private string m_tableName;  ///< The name of Table control where list of filters shall be supported
  private string m_dpColumn;   ///< The name of table column where DP is displayed, must be non-empty
  private string m_nameColumn; ///< The name of table column where visible filter is displayed, must be non-empty

  private shared_ptr<AsNgFilterLiveListener> m_listener;  ///< Who shall be notified about events
};
