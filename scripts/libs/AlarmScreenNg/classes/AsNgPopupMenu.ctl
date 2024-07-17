// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  Loading/parsing/editing/saving definition of popup menu in JSON format.
  Plus using prepared definition for displaying menu.
  This file defines two classes which always come together:
    - the definition of popup menu
    - the definition of single item in popup menu
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// used libraries (#uses)
#uses "fwGeneral/fwGeneral"
#uses "fwGeneral/fwException"
#uses "AlarmScreenNg/AlarmScreenNg"  // Basic definitions, mainly - admin config DP
#uses "AlarmScreenNg/classes/AsNgAccessControl"  // access control for AS NG

//--------------------------------------------------------------------------------
// variables and constants

/**
 * The definition of single item of popup menu. Every item is contains (the
 * names correspond to keys of item description in JSON):
 *  - <b>label</b>: the string that will appear in menu
 *  - <b>ctrlLib</b>: (optional) the name of CTRL library which shall be used for processing of this item selection
 *  - <b>ctrlFunc</b>: the name of CTRL function in that library which shall be called when this item is selected in menu
 *  - <b>action</b>: (optional) the named action associated with this menu item, this can be used
 *      to setup access control (for example, if action is only allowed for certain privileges,
 *      and I want this item to appear disabled for all other users).
 *  - <b>appearanceLib</b>: (optional) the CTRL library with function to be called when
 *      menu is being built. The function can decide if menu item shall appear/shall be disabled...
 *      for example, certain menu items do not make sense for summary alarms.
 *  - <b>appearanceFunc</b>: (optional) the CTRL function in <b>appearanceLib</b> that shall be called
 *      when menu is built.
 *
 * Note that in two pairs 'lib + func' the 'lib' is always optional: it can be omitted if no specific
 * CTRL library shall be loaded. This can happen, for example, if CTRL library is loaded because of
 * corresponding entry in project config file.
 */
class AsNgPopupMenuItem {

  /// Public constructor
  public AsNgPopupMenuItem() {}

  /** Trivial getters/setters for private members */
  //@{
  public string getError() { return m_error; }

  public string getLabel() { return m_label; }

  public void setLabel(const string &value) { m_label = value; }

  public string getCtrlLib() { return m_ctrlLib; }

  public void setCtrlLib(const string &value) {  m_ctrlLib = value; }

  public string getCtrlFunc() { return m_ctrlFunc; }

  public void setCtrlFunc(const string &value) { m_ctrlFunc = value; }

  public string getAction() { return m_action; }

  public void setAction(const string &value) { m_action = value; }

  public string getAppearanceLib() { return m_appearanceLib; }

  public void setAppearanceLib(const string &value) { m_appearanceLib = value; }

  public string getAppearanceFunc() { return m_appearanceFunc; }

  public void setAppearanceFunc(const string &value) { m_appearanceFunc = value; }
  //@}

  /**
   * Fill this instance from content of mapping; the mapping shall contain
   * all mandatory values, and nothing else.
   * @param mItem Mapping with information for this item
   * @return <c>true</c> if this item was successfully parsed from mapping. In
   * case of problem, the description of error can be obtained with method getError()
   */
  public bool fill(const mapping &mItem) {
    clear();
    for(int n = mappinglen(mItem) ; n > 0 ; n--) {
      switch(mappingGetKey(mItem, n)) {
        case KEY_LABEL:
          m_label = mappingGetValue(mItem, n);
          break;
        case KEY_CTRL_LIB:
          m_ctrlLib = mappingGetValue(mItem, n);
          break;
        case KEY_CTRL_FUNS:
          m_ctrlFunc = mappingGetValue(mItem, n);
          break;
        case KEY_ACTION:
          m_action = mappingGetValue(mItem, n);
          break;
        case KEY_APPEARANCE_LIB:
          m_appearanceLib = mappingGetValue(mItem, n);
          break;
        case KEY_APPEARANCE_FUNC:
          m_appearanceFunc = mappingGetValue(mItem, n);
          break;
        default:
          m_error = "unexpected key '" + mappingGetKey(mItem, n) + "'";
          return false;  // stop on first error
      }
    }
    return validate();
  }

  /**
   * Pack the content of this instance to mapping for writing the whole
   * menu definition to JSON string.
   * @return packed content of this instance. Empty mapping is returned if this
   *        instance is not valid, in such case error description can be obtained
   *        using getError() method
   */
  public mapping pack() {
    mapping mResult;
    if(validate()) {
      mResult[KEY_LABEL] = m_label;
      mResult[KEY_CTRL_FUNS] = m_ctrlFunc;
      if(!m_ctrlLib.isEmpty()) {
        mResult[KEY_CTRL_LIB] = m_ctrlLib;
      }
      if(!m_action.isEmpty()) {
        mResult[KEY_ACTION] = m_action;
      }
      if(!m_appearanceLib.isEmpty()) {
        mResult[KEY_APPEARANCE_LIB] = m_appearanceLib;
      }
      if(!m_appearanceFunc.isEmpty()) {
        mResult[KEY_APPEARANCE_FUNC] = m_appearanceFunc;
      }
    }
    return mResult;
  }

  /**
   * Build description of menu item for popupMenuXY() from content of this item
   * @param idx Index of this item in menu, starting from 0
   * @param iAccessLevel The access level of user to functionality behind this menu item,
   *                    one of constants ALARM_SCREEN_ACCESS_ACTION_xxx
   * @return String content of menu item
   */
  public string makeMenuItem(int idx, int iAccessLevel) {
    string sMenuItem;
    bool bEnabled = (iAccessLevel == ALARM_SCREEN_ACCESS_ACTION_ENABLE);
    sMenuItem = "PUSH_BUTTON," + m_useLabel + "," + (idx + 1) + "," +
                (bEnabled ? "1" : "0");
    return sMenuItem;
  }

  /**
   * Check if appearance of this item is controlled by dedicated function, if yes - call that function
   * @param mArgs The arguments from AS EWO, all keys are strings:
   *          - "mSource": the value is mapping with information on mouse event:
   *               row/column in table, (X,Y) coordinates of mouse cursor etc.
   *          - "mAlarm": the value is mapping with properties of alarm in row where
   *               mouse was clicked
   *          - "asEwo": the value is shape - AS EWO itself, in case the function will need
   *              more information from EWO (for example, get list of all selected alarms)
   * @param dsExceptions The variable where exception details will be added in case of error
   * @return Access level for this menu item
   */
  public int checkAppearance(const mapping &mArgs, dyn_string &dsExceptions) {
    string iResult = ALARM_SCREEN_ACCESS_ACTION_ENABLE;
    m_useLabel = m_label;  // by default use label from configuration
    if(!m_appearanceFunc.isEmpty()) {

      // prepare arguments for call
      mapping mCallArgs = mArgs;
      mCallArgs.insert("action", m_action);

      mapping mItemAppearance;
      mItemAppearance[AS_MENU_ITEM_KEY_ACCESS] = iResult;
      mItemAppearance[AS_MENU_ITEM_KEY_LABEL] = m_label;

      // perform function call if possible
      mapping mCallResult;
      if(isFunctionDefined(m_appearanceFunc)) {
        mCallResult = callFunction(m_appearanceFunc, mCallArgs, mItemAppearance, dsExceptions);
      }
      else if(!m_appearanceLib.isEmpty()) {
        if(!fwGeneral_loadCtrlLib(m_appearanceLib, false, true)) {
          fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                            "(): failed to load library '" + m_appearanceLib +
                            "' for processing menu item " + m_label, "");
        }
        else if(!isFunctionDefined(m_appearanceFunc)) {
          fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                            "(): unknown function '" + m_appearanceFunc + "'for processing menu item "
                            + m_label + ", even after loading library '" + m_appearanceLib + "'", "");
        }
        else {
          mCallResult = callFunction(m_appearanceFunc, mCallArgs, mItemAppearance, dsExceptions);
        }
      }
      else {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): unknown function '" + m_appearanceFunc + "'for processing menu item " + m_label, "");
      }

      // Interpret call results
      if(mappingHasKey(mCallResult, AS_MENU_ITEM_KEY_ACCESS)) {
        iResult = mCallResult[AS_MENU_ITEM_KEY_ACCESS];
      }
      if(mappingHasKey(mCallResult, AS_MENU_ITEM_KEY_LABEL)) {
        m_useLabel = mCallResult[AS_MENU_ITEM_KEY_LABEL];
      }
    }
    return iResult;
  }

  /**
   * Process selection of this item from popup menu
   * @param mArgs The arguments from AS EWO, all keys are strings:
   *          - "mSource": the value is mapping with information on mouse event:
   *               row/column in table, (X,Y) coordinates of mouse cursor etc.
   *          - "mAlarm": the value is mapping with properties of alarm in row where
   *               mouse was clicked
   *          - "asEwo": the value is shape - AS EWO itself, in case the function will need
   *              more information from EWO (for example, get list of all selected alarms)
   * @param dsExceptions The variable where exception details will be added in case of error
   */
  public void process(const mapping &mArgs, dyn_string &dsExceptions) {
    if(m_ctrlFunc.isEmpty()) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): missing function for processing menu item " + m_label, "");
      return;
    }
    mapping mCallArgs = mArgs;
    mCallArgs.insert("action", m_action);
    if(isFunctionDefined(m_ctrlFunc)) {
      callFunction(m_ctrlFunc, mCallArgs, dsExceptions);
    }
    else if(!m_ctrlLib.isEmpty()) {
      if(!fwGeneral_loadCtrlLib(m_ctrlLib, false, true)) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                          "(): failed to load library '" + m_ctrlLib +
                          "' for processing menu item " + m_label, "");
      }
      else if(!isFunctionDefined(m_ctrlFunc)) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                          "(): unknown function '" + m_ctrlFunc + "'for processing menu item "
                          + m_label + ", even after loading library '" + m_ctrlLib + "'", "");
      }
      else {
        callFunction(m_ctrlFunc, mCallArgs, dsExceptions);
      }
    }
    else {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): unknown function '" + m_ctrlFunc + "'for processing menu item " + m_label, "");
    }
  }

  /**
   * Validate content of this instance: all mandatory fields must be filled
   * @return <c>true</c> if this instance is valid. In case of problem the description
   *        of error is written to <c>m_error</c> member and can be read using getError()
   *        method
   */
  private bool validate() {
    m_error.clear();  // start validation from scratch
    if(m_label.isEmpty()) {
      m_error = "empty menu label";
      return false;
    }
    if(m_ctrlFunc.isEmpty()) {
      m_error = "empty name of function for processing selection of this item";
      return false;
    }
    // TODO: in principle, we can also validate that CTRL lib(s) can be loaded, and
    // that CTRL functions are defined (or will become defined after loading CTRL lib(s))
    return true;
  }

  /// Clear content of this instance
  private void clear() {
    m_error.clear();
    m_label.clear();
    m_ctrlLib.clear();
    m_ctrlFunc.clear();
    m_action.clear();
    m_appearanceLib.clear();
    m_appearanceFunc.clear();
  }

  private string m_error;  ///< The description of last detected error

  private string m_label;  ///< The is label of menu item, read from menu configuration
  private string m_useLabel;  ///< The label of menu ite, used for menu. By default this is equal to m_label, but
                              ///< can be overwritten by function, calculating menu item appearance
  private string m_ctrlLib;  ///< The name of CTRL library with function for processing of item selection
  private string m_ctrlFunc;    ///< The value is name of CTRL function for processing of item selection
  private string m_action;  ///< The name of action, associated with menu item (for access control)
  private string m_appearanceLib;  ///< The name of CTRL library with function for decision of item appearance
  private string m_appearanceFunc;  ///< The name of CTRL function for decision of item appearance

  /** The names of keys in JSON string with menu item description */
  //@{
  private static const string KEY_LABEL = "label";  ///< The value is label of menu item
  private static const string KEY_CTRL_LIB = "ctrlLib";  ///< The value is name of CTRL library with function for processing of item selection
  private static const string KEY_CTRL_FUNS = "ctrlFunc";  ///< The value is name of CTRL function for processing of item selection
  private static const string KEY_ACTION = "action";  ///< The value is name of action, associated with menu item (for access control)
  private static const string KEY_APPEARANCE_LIB = "appearanceLib";  ///< The value is name of CTRL library with function for decision of item appearance
  private static const string KEY_APPEARANCE_FUNC = "appearanceFunc";  ///< The value is name of CTRL function for decision of item appearance
  //@}
};


/**
 * The definition of popup menu for NG AlarmScreen. Basically, this is a collection
 * of AsNgPopupMenuItem, plus a set of methods for reading from DP, saving to DP,
 * displaying and processing selection of popup menu
 */
class AsNgPopupMenu {

  /// default constructor
  public AsNgPopupMenu() {}

  /// Get modification flag of this menu definition
  public bool isModified() { return m_modified; }

  /// Get the description of last detected error
  public string getError() { return m_error; }

  /// Get all items of menu definition
  public vector<shared_ptr<AsNgPopupMenuItem> > getItems() { return m_items; }

  /// Get item with given index
  public shared_ptr<AsNgPopupMenuItem> getItem(int idx) {
    shared_ptr<AsNgPopupMenuItem> item;
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
    }
    else {
      item = m_items.at(idx);
    }
    return item;
  }

  /// Add new item with given label
  public shared_ptr<AsNgPopupMenuItem> addItem(const string &sLabel) {
    shared_ptr<AsNgPopupMenuItem> item = new AsNgPopupMenuItem();
    item.setLabel(sLabel);
    m_items.append(item);
    m_modified = true;
    return item;
  }

  /// Set new label for item with given index
  public void setItemLabel(int idx, const string &sLabel) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    if(item.getLabel() != sLabel) {
      item.setLabel(sLabel);
      m_modified = true;
    }
  }

  /// Set action name for item with given index
  public void setAction(int idx, const string &sAction) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    if(item.getAction() != sAction) {
      item.setAction(sAction);
      m_modified = true;
    }
  }

  /// Set item processing CTRL library name for item with given index
  public void setCtrlLib(int idx, const string &sLib) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    if(item.getCtrlLib() != sLib) {
      item.setCtrlLib(sLib);
      m_modified = true;
    }
  }

  /// Set item processing CTRL function name for item with given index
  public void setCtrlFunc(int idx, const string &sFunc) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    if(item.getCtrlFunc() != sFunc) {
      item.setCtrlFunc(sFunc);
      m_modified = true;
    }
  }

  /// Set item appearance CTRL library name for item with given index
  public void setAppearanceLib(int idx, const string &sLib) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    if(item.getAppearanceLib() != sLib) {
      item.setAppearanceLib(sLib);
      m_modified = true;
    }
  }

  /// Set item appearance CTRL function name for item with given index
  public void setAppearanceFunc(int idx, const string &sFunc) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    if(item.getAppearanceFunc() != sFunc) {
      item.setAppearanceFunc(sFunc);
      m_modified = true;
    }
  }

  /**
   * Move selected item up or down.
   * @param idx Index of item to be moved
   * @param iDir Direction for movement: <0 == up, >0 == down
   * @return New index for this item, or -1 in case of error
   */
  public int moveItem(int idx, int iDir) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return -1;
    }
    if(m_items.count() == 1) {
      return idx;  // just one item, no reasons for moving up/down
    }
    int iNewIdx = idx + (iDir < 0 ? -1 : 1);
    if(iNewIdx < 0) {
      iNewIdx = m_items.count() - 1;
    }
    else if(iNewIdx >= m_items.count()) {
      iNewIdx = 0;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.takeAt(idx);
    m_items.insertAt(iNewIdx, item);
    m_modified = true;
    return iNewIdx;
  }

  /**
   * Delete definition of menu item with selected index
   * @param idx The index of item to be deleted
   * @return <c>true</c> if item was deleted successfully
   */
  public bool deleteItem(int idx) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return false;
    }
    m_items.removeAt(idx);
    m_modified = true;
    return true;
  }

  /**
   * Load and parse definition of popup menu from DP.
   * @param dsExceptions The variable where information on detected error(s) will be written
   * @return <c>true</c> if operation was successful.
   */
  public bool load(dyn_string &dsExceptions) {
    clear();

    string sDpName = AlarmScreenNg_getAdminDP(dsExceptions);
    if(sDpName == "") {
      DebugN(__FUNCTION__ + "(): error", dsExceptions);
      return false;
    }

    string sJson;
    dpGet(sDpName + "." + STORAGE_DPE_NAME, sJson);
    dyn_errClass deErrors = getLastError();
    if(deErrors.count() > 0) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): failed to read JSON string from DPE: " + getErrorText(deErrors), "");
      throwError(deErrors);
      return false;
    }

    if(sJson.isEmpty()) {
      return true;  // empty string is empty, but still valid, configuration
    }
    dyn_mapping dmItems = jsonDecode(sJson);
    deErrors = getLastError();
    if(deErrors.count() > 0) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): failed to parse JSON string from DPE: " + getErrorText(deErrors), "");
      throwError(deErrors);
      return false;
    }

    for(int n = 0 ; n < dmItems.count() ; n++) {
      shared_ptr<AsNgPopupMenuItem> item = new AsNgPopupMenuItem();
      if(!item.fill(dmItems.at(n))) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): parsing menu item " + (n + 1) + " of " +
                        dmItems.count() + ": " + item.getError(), "");
        DebugN(__FUNCTION__ + "(): ", dsExceptions);
        return false;  // Stop on first error, but keep successfully filled items
      }
      m_items.append(item);
    }
    return true;
  }

  /**
   * Save the current content of menu definition to DP as string in JSON format.
   * All menu items are validated before the whole menu definition is written.
   * @param dsExceptions The variable where information on detected error(s) will be written
   * @return <c>true</c> if menu definition was saved successfully
   */
  public bool save(dyn_string &dsExceptions) {
    dyn_mapping dmItems;
    for(int n = 0 ; n < m_items.count() ; n++) {
      shared_ptr<AsNgPopupMenuItem> item = m_items.at(n);
      mapping mItem = item.pack();
      if(mItem.isEmpty()) {
        fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                          "(): error packing menu item #" + (n + 1) + " of " +
                          m_items.count() + " for saving: " + item.getError(), "");
        return false;
      }
      dmItems.append(mItem);
    }

    string sJson;
    if(!dmItems.isEmpty()) {
      sJson = jsonEncode(dmItems);
    }
    string sDpName = AlarmScreenNg_getAdminDP(dsExceptions);
    if(sDpName == "") {
      DebugN(__FUNCTION__ + "(): error", dsExceptions);
      return false;
    }

    dpSet(sDpName + "." + STORAGE_DPE_NAME, sJson);
    dyn_errClass deErrors = getLastError();
    if(deErrors.count() > 0) {
      fwException_raise(dsExceptions, "ERROR", __FUNCTION__ +
                        "(): failed to save JSON string to DPE: " + getErrorText(deErrors), "");
      throwError(deErrors);
      return false;
    }
    m_modified = false;
    return true;
  }

  /**
   * Display menu, process user selection from menu.
   * @param mArgs The arguments from AS EWO, all keys are strings:
   *          - "mSource": the value is mapping with information on mouse event:
   *               row/column in table, (X,Y) coordinates of mouse cursor etc.
   *          - "mAlarm": the value is mapping with properties of alarm in row where
   *               mouse was clicked
   *          - "asEwo": the value is shape - AS EWO itself, in case the function will need
   *              more information from EWO (for example, get list of all selected alarms)
   * @param dsExceptions The variable where exception details will be added in case of error
   */
  public void display(const mapping &mArgs, dyn_string &dsExceptions) {
    dyn_string dsMenu = buildMenu(mArgs, dsExceptions);
    if(dynlen(dsExceptions) > 0) {
      return;
    }
    mapping mSource = mArgs["mSource"];
    int iAnswer;
    popupMenuXY(dsMenu, mSource["screenX"], mSource["screenY"], iAnswer);
    if(iAnswer > 0) {
      int idx = iAnswer - 1;
      if((idx < 0) || (idx >= m_items.count())) {
        DebugN(__FUNCTION__ + "(): invalid index of answer " + idx + ", total items " + m_items.count());
        return;
      }
      shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
      item.process(mArgs, dsExceptions);
    }
  }

  /// Clear content of this instance
  private void clear() {
    m_modified = false;
    m_error.clear();
    m_items.clear();
  }

  /// Print item with given index - for debugging
  private void printItem(int idx) {
    if((idx < 0) || (idx >= m_items.count())) {
      DebugN(__FUNCTION__ + "(): invalid index " + idx + ", total items " + m_items.count());
      return;
    }
    shared_ptr<AsNgPopupMenuItem> item = m_items.at(idx);
    DebugN(__FUNCTION__ + "(): menu item # " + idx);
    DebugN("    label:", item.getLabel());
    DebugN("   action:", item.getAction());
  }

  /**
   * Load menu definition and build menu description, suitable for popupMenuXY()
   * @param mArgs The arguments from AS EWO, all keys are strings:
   *          - "mSource": the value is mapping with information on mouse event:
   *               row/column in table, (X,Y) coordinates of mouse cursor etc.
   *          - "sourceMode": the value is int, corresponding to one of constants AS_NG_EWO_MODE_xxx
   *          - "mAlarm": the value is mapping with properties of alarm in row where
   *               mouse was clicked
   *          - "asEwo": the value is shape - AS EWO itself, in case the function will need
   *              more information from EWO (for example, get list of all selected alarms)
   * @param dsExceptions The variable where exception details will be added in case of error
   */
  private dyn_string buildMenu(const mapping &mArgs, dyn_string &dsExceptions) {
    dyn_string dsMenu;
    AsNgAccessControl accessControl;  // to check availability of individual menu items for user
    if(load(dsExceptions)) {
      for(int n = 0 ; n < m_items.count() ; n++) {
        shared_ptr<AsNgPopupMenuItem> item = m_items.at(n);
        int iAccessLevel = ALARM_SCREEN_ACCESS_ACTION_ENABLE;
        string sAction = item.getAction();
        if(!sAction.isEmpty()) {
          iAccessLevel = accessControl.getAccessLevel(item.getAction());
          if(iAccessLevel == ALARM_SCREEN_ACCESS_ACTION_HIDE) {
            continue;  // Do not add item to menu - limitation because of access rights
          }
        }
        if(iAccessLevel == ALARM_SCREEN_ACCESS_ACTION_ENABLE) {
          iAccessLevel = item.checkAppearance(mArgs, dsExceptions);
          if(dynlen(dsExceptions) > 0) {
            return dsMenu;  // Stop in 1st error
          }
          if(iAccessLevel == ALARM_SCREEN_ACCESS_ACTION_HIDE) {
            continue;  // Do not add item to menu - limitation because of specific conditions for this item
          }
        }
        string sMenuItem = item.makeMenuItem(n, iAccessLevel);
        dsMenu.append(sMenuItem);
      }
    }
    return dsMenu;
  }

  private string m_error;  ///< The description of last detected error

  private bool m_modified;  ///< Flag indicating that menu definition was modified and not saved yet

  private vector<shared_ptr<AsNgPopupMenuItem> > m_items;  ///< Definition of menu items

  private const string STORAGE_DPE_NAME = "PopupMenu";  /// The name of DPE where popup menu definition is stored as string in JSON format

};
