// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  The 'abstract' class that defines interface for subclasses who can be notified
  by AsNgFilterLive about important changes in AS filter configuration changes.
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

/// What has changed in filter definition DP, 'callback reason'
enum AsNgFilterChangeReason {
  None = 0,  ///< Nothing, just used as default for variables of such type
  FilterName,  ///< The name of filter (visible) has changed
  Created,     ///< New filter DP has been creates
  Deleted      ///< Previously existed filter DP has been deleted
};

/**
 * 'Abstract' class, used to build subclasses
 */
class AsNgFilterLiveListener {

  /// Default constructor
  public AsNgFilterLiveListener() {
  }

  /**
   * Method which is called when some changes occurred for one of DP with AS filter configuration.
   * This method shall be reimplemented in subclass, default implementation
   * just does nothing.
   * @param event The reason for call, see enum AsNgFilterChangeReason
   * @param sDpName The name of DP with filter configuration where change was detected
   * @param sFilterName The name of filter in this DP
   */
  public void filterChanged(AsNgFilterChangeReason event, const string &sDpName, const string &sFilterName) {
    DebugN(__FUNCTION__ + "(): this shall be overwritten by subclass!!!", event, sDpName, sFilterName);
  }
};
