// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

#uses "fit_libs/fit_functions.ctl"

//--------------------------------------------------------------------------------
// Variables and Constants

private const string CONTROL_SERVER_LNK_PATH = "C:\\Users\\Public\\Desktop\\ControlServer.lnk";
private const string CS_CONST_PREF = "ControlServer";
private const string CS_START_BAT_FILE_NAME = "startCS.bat";
private const string CS_START_BAT_FILE_PATH = "scripts\\libs\\fit_libs\\" + CS_START_BAT_FILE_NAME;
private const string CS_START_BAT_FILE_CONT = "start explorer " + CONTROL_SERVER_LNK_PATH;
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

public bool startCS(){
  if(!isBatFileExists()) createBatFile();
  if(isInTaskList(CS_CONST_PREF)){ DebugTN("Start Control Server: " + CS_CONST_PREF + " already started."); return false;}
  return system("start cmd /c " +PROJ_PATH +  CS_START_BAT_FILE_PATH) != -1;
}

public bool stopCS(string dpControlServer = "", bool force = false){
  dpControlServer = dpSubStr(dpControlServer, DPSUB_SYS_DP);
  if(force){
    system("taskkill /im" + CS_CONST_PREF + "*");
    if(dpExists(dpControlServer))dpSetWait(dpControlServer + ".status.description", "offline");
    return !isInTaskList(CS_CONST_PREF);
  }
  if(!dpExists(dpControlServer)) return false;
  if(dpSetWait(dpControlServer + ".commands.stopServer", true) == -1) return false;
  uint timeout = 10;
  string description;
  while(timeout > 0){
    dpGet(dpControlServer + ".status.description", description);
    if(description == "offline") return true;
    delay(0, 100);
    timeout--;
  }
  return false;
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

private bool isBatFileExists(){
  string res;
  if(isfile(CS_START_BAT_FILE_PATH)){
    file f = fopen(CS_START_BAT_FILE_PATH, "r");
    fgets(res, 100, f);
  }
  return res == CS_START_BAT_FILE_CONT;
}

private void createBatFile(){
  file f = fopen(CS_START_BAT_FILE_PATH, "w");
  int err = ferror(f);
  DebugN(err);
  fputs(CS_START_BAT_FILE_CONT, f);
  fclose(f);
}
