// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "fit_libs/fit_constants.ctl"
//--------------------------------------------------------------------------------
// Variables and Constants


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

/**
  Function sends the file with standart means of Windows curl. Use it for sending files to FPS (File Push Service)

  @param IPaddress - Address of the server
  @param port - Port of the server
  @param fName - path to the file

 */

public winCURL(string IPaddress, uint port, string fName){
  string formatCommand = "start cmd /c curl --header \"Content-type:application/octet-stream\" -verbose --header \"filename:%s\" --data-binary @%s http://%s:%u", command, out;
  dyn_string dsTmp = fName.contains("/") ?  strsplit(fName, "/") : makeDynString(fName);
  sprintf(command, formatCommand, dsTmp.last(), PROJ_PATH + fName, getHostByName(IPaddress), port);
//   DebugN(command);
  if(system(command, out) == -1){
    DebugN("--> winCURL " + fName + " can not send to " + getHostByName(IPaddress) + ":" + (string)port);
  }
  if(out) DebugN("winCURL output:" + out);
}

//------------------------------------------------------------------------------
/**
  Function prepares CSV file with settings of all the channels for CCDB

  @param fileName - Name of the csv file. This file should exist on the moment of calling this function
  @param lut - Channels table (lookup table), for this detector.
  @return errCode of csvFileWrite() function

 */

public int preparePMchannelCSV(const string fileName, const fitLookUpTable &lut){
  dyn_string data = getAllSettings_DIM(FIT_CCDB_PM_CH_ACT_DYNELEM, lut);
  dyn_dyn_string result;
  result[1] = FIT_CCDB_PM_CH_ACT_HEADERS;
  fitLookUpTableEntry luteDIM = fitLookUpTableEntry("DIM position", lut);

  for(uint i = 2; i <= dynlen(luteDIM.getData()) + 1; ++i){
    for(uint k = luteDIM.getData()[i - 1]; k <= dynlen(data); k+= 240)
      dynAppend(result[i], data[k]);
  }
  return csvFileWrite(fileName, result);
}


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
private dyn_string getAllSettings_DIM(const dyn_string &dynDIMsettings, const fitLookUpTable &table){
  dyn_string result;
  dyn_int values;

  for(uint i = 1; i <= dynlen(dynDIMsettings); ++i){
    dpGet(dynDIMsettings[i], values);
    if(dynlen(values) == 20){
      dynAppend(result, bit32DynDIMhandler((dyn_bit32)values, table));
    }else{
      dynAppend(result, (dyn_string)values);
    }
  }
  return result;
}

private dyn_string bit32DynDIMhandler(dyn_bit32 values){
  dyn_string result;
  for(uint i = 1; i <= 240; ++i)
    result.append((string)getBit(values[(i - 1) % 20 + 1], (i - 1)/20));
  return result;
}
