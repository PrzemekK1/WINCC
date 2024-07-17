// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants
const bool LOG_WRITE = true;
const bool LOG_NO_WRITE = false;
const bool LOG_SHOW = true;
const bool LOG_NO_SHOW = false;

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
class fitLog{
  public fitLog(string fileName = "log\fit_dcs.log"){
      name = fileName;
  }
  public void addLogEntry(string text, bool writeFlag = LOG_WRITE, bool showFlag = LOG_SHOW, string source = "", string func = ""){
    string toAdd = (source == "" ? "" : ("(" + source + ") ")) +
                   (func == "" ? "" : (func + ": ")) +
                   text;
    if(showFlag) DebugTN(toAdd);
    if(writeFlag){
      file f = fopen(name, "a+");
      fputs(formatTime("[%Y-%m-%d %H:%M:%S", getCurrentTime(), ".%03d]") + toAdd + "\n", f);
      fclose(f);
    }
}
  private string name;

};

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

