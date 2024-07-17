// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author lkopylov
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "AlarmScreenNg/AlarmScreenNg.ctl"  // Access to admin settings DP
#uses "CtrlRDBAccess"  // encrypt/decrypt password


/**
 * @brief The class encapsulating functionality to work with admin-specific configuration
 *  for AS: access to archived alarms.
 *
 * The first implementation only keeps in mind ORACLE RDB. admin is responsible for
 * supplying information for connecting to appropriate ORACLE schema. The instance of this
 * class is used to store connection information in DPE and to retrieve that
 * information from DPE.<br>
 * Like many other configurations for AS, all connection information is stored in single
 * DPE as JSON string.
 */
class AsNgArchiveAccess {

  /**
   * Read the set of connection information from corresponding DPE, decode
   * the content of DPE for subsequent access.
   * @return <c>true</c> if load operation was successful. If <c>false</c>
   * was returned, then the description of error can be obtained using getError()
   * method of this class
   */
  public bool load() {

    m_error.clear();
    m_connect.clear();
    m_userName.clear();
    m_passWord.clear();
    m_maxAlarms = 50000;
    m_batchSize = 500;
    m_maxBatches = 20;

    string sDpeName = getDpeName();
    if(sDpeName.isEmpty()) {
      return false;
    }
    string sDpeValue;
    dpGet(sDpeName, sDpeValue);
    dyn_errClass dsErr = getLastError();
    if(!dsErr.isEmpty())
    {
      m_error = __FUNCTION__ + "(): dpGet() failed for DPE " + sDpeName + ": " + getErrorText(dsErr);
      return false;
    }

    if(sDpeValue.isEmpty()) {
      return true;  // Empty DPE value is not an error
    }

    mapping mSettings = jsonDecode(sDpeValue);
    dsErr = getLastError();
    if(!dsErr.isEmpty())
    {
      m_error = __FUNCTION__ + "(): JSON decode failed for value from DPE " + sDpeName + ": " + getErrorText(dsErr);
      return false;
    }

    if(mSettings.contains(ARCHIVE_ACCESS_KEY_CONNECT)) {
      m_connect = mSettings.value(ARCHIVE_ACCESS_KEY_CONNECT);
    }
    if(mSettings.contains(ARCHIVE_ACCESS_KEY_USER)) {
      m_userName = mSettings.value(ARCHIVE_ACCESS_KEY_USER);
    }
    if(mSettings.contains(ARCHIVE_ACCESS_KEY_PASS)) {
      m_passWord = mSettings.value(ARCHIVE_ACCESS_KEY_PASS);
      if(!m_passWord.isEmpty()) {
        m_passWord = decodePwd(m_passWord);
      }
    }
    if(mSettings.contains(ARCHIVE_ACCESS_MAX_ALARMS)) {
      uint value = mSettings.value(ARCHIVE_ACCESS_MAX_ALARMS);
      if(value > 0) {
        m_maxAlarms = value;
      }
    }
    if(mSettings.contains(ARCHIVE_ACCESS_BATCH_SIZE)) {
      uint value = mSettings.value(ARCHIVE_ACCESS_BATCH_SIZE);
      if(value > 0) {
        m_batchSize = value;
      }
    }
    if(mSettings.contains(ARCHIVE_ACCESS_MAX_BATCHES)) {
      uint value = mSettings.value(ARCHIVE_ACCESS_MAX_BATCHES);
      if(value > 0) {
        m_maxBatches = value;
      }
    }

    return true;
  }

  /**
   * Save the set of connection information to corresponding DPE, the data are
   * written in JSON format.
   * @return <c>true</c> if save operation was successful. If <c>false</c>
   * was returned, then the description of error can be obtained using getError()
   * method of this class
   */
  public bool save() {

    string sDpeName = getDpeName();
    if(sDpeName.isEmpty()) {
      return false;
    }

    mapping mSettings;
    mSettings.insert(ARCHIVE_ACCESS_KEY_CONNECT, m_connect);
    mSettings.insert(ARCHIVE_ACCESS_KEY_USER, m_userName);
    string sKey = m_useKey;
    mSettings.insert(ARCHIVE_ACCESS_KEY_PASS, fwDbEncryptPassword(m_passWord, sKey));
    mSettings.insert(ARCHIVE_ACCESS_MAX_ALARMS, m_maxAlarms);
    mSettings.insert(ARCHIVE_ACCESS_BATCH_SIZE, m_batchSize);
    mSettings.insert(ARCHIVE_ACCESS_MAX_BATCHES, m_maxBatches);

    string sDpeValue = jsonEncode(mSettings);
    dpSet(sDpeName, sDpeValue);
    dyn_errClass dsErr = getLastError();
    if(!dsErr.isEmpty())
    {
      m_error = __FUNCTION__ + "(): dpSet() failed for DPE " + sDpeName + ": " + getErrorText(dsErr);
      return false;
    }

    return true;
  }

  /**
   * Try connecting to database with currently known parameters
   * @return <c>true</c> if connection was successful; if <c>false</c> was returned
   *        then error description can be obtained using getError() method
   */
  public bool tryDbConnect() {
    dbConnection connection;
    string sConnectString = "Driver=QOCI8;Database=" + getConnect() +
                            ";User=" + getUserName() +
                            ";Password=" + getPassWord();
    fwDbOpenConnection(sConnectString, connection);
    bool bSuccess = (fwDbCheckError(m_error, connection) == 0);
    if(!bSuccess) {
      DebugN(__FUNCTION__ + "(): error is", m_error);
    }

    fwDbCloseConnection(connection);
    fwDbDeleteConnection(connection);
    return bSuccess;
  }

  /**
   * Decode previously encoded password
   * @param sEncodedPwd Encoded password
   * @return Result of decoding
   */
  public string decodePwd(const string &sEncodedPwd) {
    string sKey = m_useKey,
           sPwd = sEncodedPwd;
    return fwDbDecryptPassword(sPwd, sKey);
  }

  /// Get the connect string for connection to ORACLE DB
  public string getConnect() {
    return m_connect;
  }

  /// Set the connect string for connection to ORACLE DB
  public void setConnect(const string &sValue) {
    m_connect = sValue;
  }

  /// Get the user name for connection to ORACLE DB
  public string getUserName() {
    return m_userName;
  }

  /// Set the user name for connection to ORACLE DB
  public void setUserName(const string &sValue) {
    m_userName = sValue;
  }

  /// Get the password for connection to ORACLE DB
  public string getPassWord() {
    return m_passWord;
  }

  /// Set the password for connection to ORACLE DB
  public void setPassWord(const string &sValue) {
    m_passWord = sValue;
  }

  /// Get maximum number of alarms which can be loaded to EWO from archive
  public uint getMaxAlarms() {
    return m_maxAlarms;
  }

  /// Set maximum number of alarms which can be loaded to EWO from archive
  public void setMaxAlarms(uint value) {
    if(value > 0) {
      m_maxAlarms = value;
    }
  }

  /// Get number of alarms from archive for one batch of processing by main thread
  public uint getBatchSize() {
    return m_batchSize;
  }

  /// Set number of alarms from archive for one batch of processing by main thread
  public void setBatchSize(uint value) {
    if(value > 0) {
      m_batchSize = value;
    }
  }

  /// Get maximum number of batches pending in processing queue
  public uint getMaxBatches() {
    return m_maxBatches;
  }

  /// Set maximum number of batches pending in processing queue
  public void setMaxBatches(uint value) {
    if(value > 0) {
      m_maxBatches = value;
    }
  }

  /// Get the description of last detected error
  public string getError() {
    return m_error;
  }

  /**
   * Get the name of DPE where archive access information is stored; the method
   * also checks if DPE exists.
   * @return The name of existing DPE; empty string is something went wrong
   */
  private string getDpeName() {
    dyn_string dsExceptionInfo;
    string sDpName = AlarmScreenNg_getAdminDP(dsExceptionInfo);
    if(sDpName.isEmpty())
    {
      m_error = __FUNCTION__ + "(): failed to get the name of admin settings DP for AS";
      return "";
    }

    string sDpeName = sDpName + "." + ARCHIVE_ACCESS_DPE;
    if(!dpExists(sDpeName))
    {
      m_error = __FUNCTION__ + "(): DPE doesn't exist " + sDpeName;
      return "";
    }

    return sDpeName;
  }

  private string m_connect;  ///< Connect string for connection to ORACLE DB
  private string m_userName; ///< User name for connection to ORACLE DB
  private string m_passWord; ///< Password for connection to ORACLE DB

  private uint m_maxAlarms = 50000;  ///< Maximum number of alarms which can be loaded to EWO from archive
  private uint m_batchSize = 500;    ///< Number of alarms from archive for one batch of processing by main thread
  private uint m_maxBatches = 20;    ///< Maximum number of batches pending in processing queue

  private string m_error;  ///< The description of last detected error

  private static const string m_useKey = "AsNgOracleRdbAccess";

  /// The name of DPE in admin-configuration DP where archive access information is stored
  /// as JSON string
  private static const string ARCHIVE_ACCESS_DPE = "ArchiveAccess";

  /// The key in JSON where the value is connection string to ORACLE DB
  private static const string ARCHIVE_ACCESS_KEY_CONNECT = "connect";

  /// The key in JSON where the value is user name for connection to ORACLE DB
  private static const string ARCHIVE_ACCESS_KEY_USER = "user";

  /// The key in JSON where the value is password for connection to ORACLE DB.
  /// @note The password is stored in encrypted form
  private static const string ARCHIVE_ACCESS_KEY_PASS = "pass";

  /// The key in JSON where the value is maximum number of alarms which can be loaded to EWO from archive
  private static const string ARCHIVE_ACCESS_MAX_ALARMS = "maxAlarms";

  /// The key in JSON where the value is number of alarms from archive for one batch of processing by main thread
  private static const string ARCHIVE_ACCESS_BATCH_SIZE = "batchSize";

  /// The key in JSON where the value is maximum number of batches pending in processing queue
  private static const string ARCHIVE_ACCESS_MAX_BATCHES = "maxBatches";
};
