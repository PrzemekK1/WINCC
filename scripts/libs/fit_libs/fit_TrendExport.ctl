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


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
public string dpNameArc(string dpeName){
  dpeName = dpSubStr(dpeName, DPSUB_DP_EL);
  strreplace(dpeName, ".", "_");
  return "_arc_" + dpeName;
}

public string arcToName(string arcName){
  arcName = dpSubStr(arcName, DPSUB_DP);
  strreplace(arcName, "_", ".");
  return arcName.right(strlen(arcName) - 5);
}

public getArchiveElements(string dpe, string type, dyn_dyn_int &cAD){
  bool arc; uint dId; int eId;
  //search of the elemts of the datapoints
  dyn_string allDpes = dpNames(dpe + "*.*", type);
//   DebugN(allDpes);
  //search of the datapoints with archive settings
  for(uint i = 1; i <= dynlen(allDpes); ++i){
    dpGet(allDpes[i] + ":_archive.._archive", arc);
    //arc is TRUE if the archiving for the given element enabled
    if(arc){
      //Create the datapoint of the special type if not exists to flag if it will be in export list
      if(!dpExists(dpNameArc(dpe))) dpCreate(dpNameArc(allDpes[i]), "_fitTrendListToExport");
      //Obtaining identificator of datapoints to make the shapes name different later
      dpGetId(dpNameArc(allDpes[i]), dId, eId);
      cAD.append(makeDynInt(dId, eId));
      dpSet(dpNameArc(allDpes[i]) + ".name", allDpes[i]);
    }
  }
}

public setIncludedTo(bool included, dyn_string &subGroup){
  for(uint i = 1; i <= dynlen(subGroup); ++i){
    dpSetWait(subGroup[i] + ".included", included);
  }
}

public selectGroup(dyn_dyn_string &gr, uint idx, bool included){
  dyn_string subDynStr;
  for(uint i = 1; i <= (idx ? 1 : dynlen(gr)); ++i){
    subDynStr = idx ? gr[idx] : gr[i];
    setIncludedTo(included, subDynStr);
  }
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

