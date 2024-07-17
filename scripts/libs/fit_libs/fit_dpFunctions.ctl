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

//set DPE function config for dpe with parameters and formula
public int setDPfunction(string dpe, dyn_string parameters, string formula, bool old_new_comparison = true){
  string postfix = "", par;
  if(!dpExists(dpe)){
    DebugN("DPE does not exists: " + dpe);
    return -1;
  }
  for(uint i = 1; i <= dynlen(parameters); ++i){
    par = parameters[i];
    if(!par.contains(":_original.._value")){
      par = par + ":_original.._value";
      parameters[i] = par;
    }
    if(!dpExists(par)){
       DebugN("DPE from parameters does not exists:" + par);
       return -1;
    }
  }
  return dpSetWait(dpe + ":_dp_fct.._type", DPCONFIG_DP_FUNCTION,
                   dpe + ":_dp_fct.._param", parameters,
                   dpe + ":_dp_fct.._fct", formula,
                   dpe + ":_dp_fct.._old_new_compare", old_new_comparison);
    }

//deletes all the _dp_fct configs for DPEs in the list
public delete_dp_fct_Configs(dyn_string &listOfDPEs){
  dyn_string exceptInfo;
  _fwConfigs_delete(listOfDPEs, "_dp_fct", exceptInfo);
  if(dynlen(exceptInfo)){
    DebugN(exceptInfo);
  }
}
//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
