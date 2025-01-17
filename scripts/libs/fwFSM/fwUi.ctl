#uses "fwFSM/fwFsmBasics.ctl"
#uses "fwFSM/fwFsmUtil.ctl"
#uses "fwFSM/fwFsm.ctl" // notably to have fwFsm_separator

// Load the fwFSMUser.ctl library dynamically if it exists (mind the false param)
private const bool fwUi_fwFsmUserLibLoaded = fwGeneral_loadCtrlLib("fwFSM/fwFsmUser.ctl",false);

int RememberLockedOutPerm = 1;

int isCMS()
{
  if(isFunctionDefined("fwCMS"))
    return 1;
  return 0;
}

int isATLAS()
{
  if(isFunctionDefined("fwAtlas"))
    return 1;
  return 0;
}

int isLHCb()
{
  if(isFunctionDefined("fwLHCb"))
    return 1;
  return 0;
}

int isALICE()
{
  if(isFunctionDefined("fwALICE"))
    return 1;
  return 0;
}

// In fwFsmBasics
/*
const int FwFreeBit = 0;
const int FwOwnerBit = 1;
const int FwExclusiveBit = 2;
const int FwIncompleteBit = 3;
const int FwIncompleteDevBit = 4;
const int FwUseStatesBit = 5;
const int FwSendCommandsBit = 6;
const int FwCUNotOwnerBit = 7;
const int FwCUFreeBit = 8;
const int FwIncompleteDeadBit = 9;
*/

int FwUi_ActOnMultiple = 0;
dyn_string FwUi_MultiDPList;
dyn_anytype FwUi_MultiDPValues;

global mapping FwUi_GblDomainSyss;

string fwUi_getGlobalUiId()
{
	string id;

	if(globalExists("FwFSMUi_CurrentOwner"))
		id = FwFSMUi_CurrentOwner;
	else
		id = fwUi_getUiId();
	return id;
}

fwUi_changeIdentity(string id)
{
	addGlobal("FwFSMUi_CurrentOwner",STRING_VAR);
	FwFSMUi_CurrentOwner = id;
}

fwUi_getDpDomain(string dp, string & domain)
{
int pos;

	dp = fwFsm_extractSystem(dp);
	pos = strpos(dp,fwFsm_separator);
	domain = substr(dp, 0, pos);
}

fwUi_findDomainSys(string domain, string &sys)
{
dyn_string dps, syslist, refs, syss;
string local_sys, ref;
int index;

	local_sys = fwFsm_getSystemName();
	dps = fwFsm_getDpsSys("*:fwCU_"+domain,"_FwCtrlUnit", syslist);
	if(dynlen(syslist))
	{
		if(index = dynContains(syslist, local_sys))
			sys = syslist[index];
		else
			sys = syslist[1];
	}
	else
	{
		ref = "";
		fwFsm_getObjectReferences(domain, refs, syss);
		if(index = dynContains(syss, local_sys))
			ref = refs[index];
		if(ref != "")
			fwFsm_getObjectReferenceSystem(ref, sys);
	}
}
/*
fwUi_getDomainSys(string domain, string &dp)
{
	string top;
	int index;

	if(!globalExists("GBL_DOMAINS_SYSS"))
	{
		addGlobal("GBL_DOMAINS_SYSS",DYN_STRING_VAR);
	}
	if(!(index = dynContains(GBL_DOMAINS_SYSS, domain)))
	{
		dp = "";
		fwUi_findDomainSys(domain, dp);

		if(dp != "")
		{
			dp += ":";
			dynAppend(GBL_DOMAINS_SYSS, domain);
			dynAppend(GBL_DOMAINS_SYSS,dp);
		}
	}
	else
	{
		dp = GBL_DOMAINS_SYSS[index +1];
	}
}
*/

fwUi_getDomainSys(string domain, string &dp)
{
	string top;
	int index;

	if(!mappingHasKey(FwUi_GblDomainSyss, domain))
	{
		dp = "";
		fwUi_findDomainSys(domain, dp);

		if(dp != "")
		{
			dp += ":";
			FwUi_GblDomainSyss[domain] = dp;
		}
	}
	else
	{
		dp = FwUi_GblDomainSyss[domain];
	}
}

fwUi_getDomainPrefix(string domain, string &dp)
{
	fwUi_getDomainSys(domain, dp);
	if(dp != "")
		dp += "fwCU_"+domain;
}

fwUi_getSysPrefix(string domain, string &dp)
{
	fwUi_getDomainSys(domain, dp);
	if(dp != "")
		dp += domain;
	else
		dp = domain;
}

fwUi_getPanel(string domain, string obj, string & panel)
{
	string dp;
	dyn_string panels;
	panel = "";

	fwUi_getSysPrefix(domain, dp);
	if(fwFsm_isAssociated(obj))
	{
		dp += fwFsm_separator+fwFsm_convertAssociated(obj);
	}
	else
	{
		dp += fwFsm_separator+obj;
	}
	if(dpExists(dp))
	{
		dpGet(dp+".ui.panels:_online.._value",panels);
		if(dynlen(panels))
			panel = panels[1];
	}
	if(panel == "")
	{
		panel = fwFsm_getDefaultMainPanel();
	}
}

fwUi_getUserPanel(string domain, string obj, string & panel)
{
	string dp, type, sys;
	dyn_string panels;
	panel = "";

	fwUi_getSysPrefix(domain, dp);
	sys = fwFsm_getSystem(dp);
	if(fwFsm_isAssociated(obj))
	{
		dp += fwFsm_separator+fwFsm_convertAssociated(obj);
	}
	else
	{
		dp += fwFsm_separator+obj;
	}
	if(dpExists(dp))
	{
		dpGet(dp+".ui.panels:_online.._value",panels);
		if(dynlen(panels) > 1)
			panel = panels[2];
		else
		{
			dpGet(dp+".type:_online.._value",type);
			fwUi_getTypePanel(sys+":"+type, panel);
		}
	}
}

fwUi_getTypeFullPanel(string type, string &panel)
{
	string type1;

	type1 = fwFsm_formType(type);
	panel = "";

	if(dpExists(type1))
	{
		dpGet(type1+".panel:_online.._value",panel);
	}
}

fwUi_setTypeFullPanel(string type, string panel)
{
	string type1;

	type1 = fwFsm_formType(type);

	if(dpExists(type1))
	{
		dpSet(type1+".panel:_original.._value",panel);
	}
}

fwUi_getTypePanel(string type, string & panel)
{
	string type1;
	dyn_string items;

	type1 = fwFsm_formType(type);
	panel = "";

	if(dpExists(type1))
	{
		dpGet(type1+".panel:_online.._value",panel);
		if(strpos(panel,"|") >= 0)
		{
			items = strsplit(panel,"|");
			if(dynlen(items) > 1)
			{
				if(items[2] != "")
					panel = items[2];
			}
			else
				panel = "";
		}
	}
}

fwUi_setTypePanel(string type, string panel)
{
	string type1, old_panel;
	dyn_string items;

	type1 = fwFsm_formType(type);

	if(dpExists(type1))
	{
		dpGet(type1+".panel:_online.._value",old_panel);
		if(strpos(old_panel,"|") >= 0)
		{
			items = strsplit(old_panel,"|");
			if(dynlen(items) > 1)
			{
				strreplace(old_panel,"|"+items[2],"|"+panel);
				panel = old_panel;
			}
			else
				panel = old_panel + panel;
		}
	}
	dpSetWait(type1+".panel:_original.._value",panel);
}

fwUi_setTypePanelBaseType(string type, string baseType)
{
	string type1, old_panel, panel;
	dyn_string items;

	type1 = fwFsm_formType(type);

	if(dpExists(type1))
	{
		dpGet(type1+".panel:_online.._value",old_panel);
		items = strsplit(old_panel,"|");
		if(dynlen(items) > 1)
		{
			strreplace(old_panel,items[1]+"|",baseType+"|");
			panel = old_panel;
		}
		else
			panel = baseType+"|"+old_panel;
	}
	dpSetWait(type1+".panel:_original.._value",panel);
}

fwUi_getTypePanelBaseType(string type, string &baseType)
{
	string type1, old_panel;
	dyn_string items;

	type1 = fwFsm_formType(type);

	baseType = "";
	if(dpExists(type1))
	{
		dpGet(type1+".panel:_online.._value",old_panel);
		if(strpos(old_panel,"|") >= 0)
		{
			items = strsplit(old_panel,"|");
			baseType = items[1];
		}
/*
		else if(strpos(old_panel,"/") >= 0)
		{
			items = strsplit(old_panel,"/");
			if(strpos(type, items[1]) == 0)
				baseType = items[1];
		}
*/
	}
}

fwUi_getLabel(string domain, string obj, string & label)
{
	string dp;

	label = "";
	fwUi_getSysPrefix(domain, dp);
	if(fwFsm_isAssociated(obj))
	{
		dp += fwFsm_separator+fwFsm_convertAssociated(obj);
	}
	else
	{
		dp += fwFsm_separator+obj;
	}
	if(dpExists(dp))
	{
		dpGet(dp+".ui.label:_online.._value",label);
	}
}

fwUi_getChildren(string domain, dyn_string & children)
{
int i;
dyn_string nodes, exInfo;
int cu;
string sys, node;

	dynClear(children);
	fwUi_getSysPrefix(domain, sys);
	fwTree_getChildren(sys, nodes, exInfo);
	sys = fwFsm_getSystem(sys);
	if(sys != "")
		sys += ":";
	for(i = 1; i <= dynlen(nodes); i++)
	{
		node = sys+nodes[i];
		fwTree_getNodeCU(node, cu, exInfo);
		if(cu)
		{
			nodes[i] = fwTree_getNodeDisplayName(nodes[i], exInfo);
//			if(fwFsm_isObjectReference(nodes[i]))
//				nodes[i] = fwFsm_getReferencedObject(nodes[i]);
			dynAppend(children,nodes[i]);
		}
	}
}

fwUi_getEnabled(string domain, string obj, int &enabled)
{
	string dp;

	enabled = -1;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".mode.enabled";
	if(dpExists(dp))
	{
		dpGet(dp+":_online.._value",enabled);
	}
}

fwUi_getEnabledType(string domain, string obj, int &enabled, string &type)
{
	string dp;

	enabled = -1;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj;
	if(dpExists(dp))
	{
		dpGet(dp+".mode.enabled:_online.._value",enabled,
                    dp+".type:_online.._value", type);
	}
}

int fwUi_dpSetWait(string dp, anytype value)
{
	if(FwUi_ActOnMultiple > 0)
	{
		dynAppend(FwUi_MultiDPList, dp);
		dynAppend(FwUi_MultiDPValues, value);
	}
	else
		dpSet(dp, value);
//		dpSetWait(dp, value);
}

string fwUi_setEnabled(string domain, string obj, int enabled, int fast = 0)
{
	string dp;
	dyn_string exInfo;
	string tnode, parent;
 dyn_string items;
 int i;

	parent = "";
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj;
//DebugTN("en/disabling dp",domain, obj, dp, enabled);
	if(dpExists(dp))
	{
		/*fwUi_*/dpSetWait(dp+".mode.enabled",enabled);

   if(!fast)
   {
		  dpGet(dp+".part",parent);
		  if(parent == domain)
			   parent = "";
     items = strsplit(parent,",");
     for(i = 1; i <= dynlen(items); i++)
     {
		    fwFsm_actOnSummaryAlarm(enabled, obj, domain, items[i]);
     }
   }
	}
	return parent;
}

fwUi_setLockedOut(string domain, string obj, int lockedOut)
{
	string dp;
	int enabled;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
//	dp += fwFsm_separator+obj+"_FWM";
	dp += fwFsm_separator+obj;
//DebugN("LockedOut: en/disabling",domain, obj, dp, lockedOut);
	if(dpExists(dp))
	{
    if(lockedOut == 0)
      enabled = 1;
    if(lockedOut == -1)
      enabled = 2;
    else if(lockedOut == 1)
      enabled = 0;
    else if(lockedOut == 2)
    {
      if(!RememberLockedOutPerm)
        enabled = 0;
      else
        enabled = -1;
    }
//		enabled = !lockedOut;
		/*fwUi_*/dpSetWait(dp+".mode.enabled",enabled);
	}
}

fwUi_getLockedOut(string domain, string obj, int &lockedOut)
{
	string dp;
	dyn_string exInfo;
	int enabled;

	lockedOut = 0;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
//	dp += fwFsm_separator+obj+"_FWM";
	dp += fwFsm_separator+obj;
//DebugN("LockedOut: getting ",domain, obj, dp);
	if(dpExists(dp))
	{
		dpGet(dp+".mode.enabled",enabled);
    if(enabled == 1)
      lockedOut = 0;
    else if(enabled == 0)
      lockedOut = 1;
    else if(enabled == -1)
      lockedOut = 2;
//		lockedOut = !enabled;
	}
}

int fwUi_connectEnabled(string rout, string domain, string obj, bool first = TRUE)
{
	string dp;
	int pos;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".mode.enabled";
//	if(dpExists(dp))
//	{
//		dpConnect(rout, dp+":_online.._value");
//		return 1;
//	}
//	return 0;
	while(!dpExists(dp))
		delay(5);
	dpConnect(rout, first, dp+":_online.._value");
	return 1;
}

int fwUi_disconnectEnabled(string rout, string domain, string obj)
{
	string dp;
	int pos;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".mode.enabled";
//	if(dpExists(dp))
//	{
//		dpConnect(rout, dp+":_online.._value");
//		return 1;
//	}
//	return 0;
	if(!dpExists(dp))
		return 0;
	dpDisconnect(rout, dp+":_online.._value");
	return 1;
}

fwUi_getVisibility(string domain, string obj, int & flag)
{
	string dp;

	flag = 0;
	fwUi_getSysPrefix(domain, dp);
	if(fwFsm_isAssociated(obj))
	{
		dp += fwFsm_separator+fwFsm_convertAssociated(obj);
	}
	else
	{
		dp += fwFsm_separator+obj;
	}
	if(dpExists(dp))
	{
		dpGet(dp+".ui.visible:_online.._value",flag);
	}
}

fwUi_getOperation(string domain, string obj, int & flag)
{
	string dp;

	flag = 0;
	fwUi_getSysPrefix(domain, dp);
	if(fwFsm_isAssociated(obj))
	{
		dp += fwFsm_separator+fwFsm_convertAssociated(obj);
	}
	else
	{
		dp += fwFsm_separator+obj;
	}
	if(dpExists(dp))
	{
		dpGet(dp+".ui.operatorControl:_online.._value",flag);
	}
}

fwUi_setOperation(string domain, string obj, int flag)
{
	string dp;

	fwUi_getSysPrefix(domain, dp);
	if(fwFsm_isAssociated(obj))
	{
		dp += fwFsm_separator+fwFsm_convertAssociated(obj);
	}
	else
	{
		dp += fwFsm_separator+obj;
	}
	if(dpExists(dp))
	{
		/*fwUi_*/dpSetWait(dp+".ui.operatorControl:_original.._value",flag);
	}
}

fwUi_getDomainOperation(string domain, int & flag)
{
	string dp;

	flag = 0;
	fwUi_getDomainPrefix(domain, dp);
	if(dpExists(dp))
	{
		dpGet(dp+".mode.childrenOperatorControl:_online.._value",flag);
	}
}

fwUi_setDomainOperation(string domain, int flag)
{
	string dp;

	fwUi_getDomainPrefix(domain, dp);
	if(dpExists(dp))
	{
		dpSetWait(dp+".mode.childrenOperatorControl:_original.._value",flag);
	}
}

fwUi_getCurrentState(string domain, string obj, string & state)
{
	string dp;

  state = "";
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	if(dpExists(dp))
		dpGet(dp+".currentState:_online.._value",state);
}


string fwUi_convertCurrentState(string domain, string obj, string state)
{
	string full_obj, type, capstate;
	dyn_string states;
	int i;

	full_obj = domain+"::"+obj;
	if (state != "")
	{
		fwFsm_getObjectType(full_obj, type);
		fwFsm_getObjectStates(type, states);
		for(i = 1; i <= dynlen(states); i++)
		{
			capstate = fwFsm_capitalize(states[i]);
			if(capstate == state)
				return states[i];
		}
	}
	return "";
}

/*
string fwUi_convertCurrentState(string domain, string obj, string state)
{
	int index;
	dyn_string states;
	int i;
	string capstate;

	if (state != "")
	{
		if(index = dynContains(FsmDisplayObjs, domain+"::"+obj))
		{
			index = FsmDisplayObjsType[index];
			states = FsmDisplayObjStates[index];
			for(i = 1; i <= dynlen(states); i++)
			{
				capstate = fwFsm_capitalize(states[i]);
				if(capstate == state)
					return states[i];
			}
		}
	}
	return state;
}
*/

fwUi_getDisplayInfo(dyn_string nodes)
{
  string domain, obj, type;
  dyn_string types;
  int i, reloadTypes = 1;

  if(!globalExists("FsmDisplayObjTypes"))
  {
    addGlobal("FsmDisplayObjTypes", MAPPING_VAR); // key: obj name, value: obj type
    addGlobal("FsmDisplayTypeStates", MAPPING_VAR); // key: obj type
    addGlobal("FsmDisplayTypeColors", MAPPING_VAR); // key: obj type
    addGlobal("FsmDisplayTypeActions", MAPPING_VAR); // key: obj type
    addGlobal("FsmDisplayTypeActionsVisi", MAPPING_VAR); // key: obj type
  }
  domain = nodes[1];
  for(i = 2; i <= dynlen(nodes); i++)
  {
    obj = nodes[i];
    if (isATLAS() && strpos(obj, "STATUS_")>-1)
      continue;
//DebugTN("Calling fwUi_addLocalObj from fwUi_getDisplayInfo");
    type = fwUi_addLocalObj(domain, obj, 1, 0);
    if(!dynContains(types, type))
      dynAppend(types, type);
  }
  if(isATLAS())
    reloadTypes = 0;
  for(i = 1; i <= dynlen(types); i++)
  {
    fwUi_addLocalType(types[i], reloadTypes);
  }
}
/*
fwUi_getDisplayInfo_old(dyn_string nodes)
{
	string domain, sub_domain, obj;
	string type, sys;
	string full_obj;
	dyn_string syss;
	dyn_uint ids;
	int i, index, index1;
	dyn_string local_types;
	dyn_int local_indexes;

	if(!globalExists("FsmDisplayObjs"))
	{
		addGlobal("FsmDisplayObjs", DYN_STRING_VAR);
		addGlobal("FsmDisplayObjsType", DYN_INT_VAR);
		addGlobal("FsmDisplayObjTypes", DYN_STRING_VAR);
		addGlobal("FsmDisplayObjStates", DYN_DYN_STRING_VAR);
		addGlobal("FsmDisplayObjColors", DYN_DYN_STRING_VAR);
		addGlobal("FsmDisplayObjActions", DYN_DYN_STRING_VAR);
		addGlobal("FsmDisplayObjActionsVisi", DYN_DYN_INT_VAR);
	}
	domain = nodes[1];
	for(i = 2; i <= dynlen(nodes); i++)
	{
		obj = nodes[i];
		full_obj = domain+"::"+obj;
		fwFsm_getObjectType(full_obj, type);
//DebugN(domain, nodes[i], type);
//		if(fwFsm_isAssociated(obj))
//			sub_domain = fwFsm_getAssociatedDomain(obj);
//		fwUi_getDomainSys(sub_domain, sys);
		fwUi_getDomainSys(domain, sys);
		if(!(index = dynContains(FsmDisplayObjTypes, sys+type)))
		{
			index = dynAppend(FsmDisplayObjTypes, sys+type);
			FsmDisplayObjStates[index] = makeDynString();
			FsmDisplayObjColors[index] = makeDynString();
		}
		if(!dynContains(local_types, sys+type))
		{
			dynAppend(local_types, sys+type);
			dynAppend(local_indexes, index);
		}
		if(!(index1 = dynContains(FsmDisplayObjs, domain+"::"+obj)))
		{
			dynAppend(FsmDisplayObjs, domain+"::"+obj);
			dynAppend(FsmDisplayObjsType, index);
		}
		else
			FsmDisplayObjsType[index1] = index;
	}
//DebugN(FsmDisplayObjTypes);

	for(i = 1; i <= dynlen(local_types); i++)
	{
		dyn_string states, colors, actions, full_actions;
		dyn_int visis, full_visis;
		int j, k;

		fwFsm_getObjectStatesColors(local_types[i],
			states, colors);

		for(j = 1; j <= dynlen(states); j++)
		{
			fwFsm_getObjectStateFullActionsV(local_types[i],
				states[j], actions, visis);
			dynAppend(full_actions, actions);
			dynAppend(full_visis, visis);
		}
		if(!dynlen(FsmDisplayObjStates[local_indexes[i]]))
		{
			FsmDisplayObjStates[local_indexes[i]] = states;
			FsmDisplayObjColors[local_indexes[i]] = colors;
			FsmDisplayObjActions[local_indexes[i]] = full_actions;
			FsmDisplayObjActionsVisi[local_indexes[i]] = full_visis;
		}
		else
		{
			if( states != FsmDisplayObjStates[local_indexes[i]])
				FsmDisplayObjStates[local_indexes[i]] = states;
			if( colors != FsmDisplayObjColors[local_indexes[i]])
				FsmDisplayObjColors[local_indexes[i]] = colors;
			if( full_actions != FsmDisplayObjActions[local_indexes[i]])
				FsmDisplayObjActions[local_indexes[i]] = full_actions;
			if( visis != FsmDisplayObjActionsVisi[local_indexes[i]])
				FsmDisplayObjActionsVisi[local_indexes[i]] = full_visis;
		}
	}
//	DebugN("types",FsmDisplayObjTypes,
//		FsmDisplayObjStates, FsmDisplayObjColors, FsmDisplayObjActions);

}
*/
fwUi_getCurrentStateTime(string domain, string obj, time &stime)
{
	string dp;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	dpGet(dp+".currentState:_online.._stime",stime);
}

fwUi_getCurrentParameter(string domain, string obj, string param, string &value)
{
	int i, j, pos;
	string dp;
	dyn_string pars, items;

	value = "";
	param = fwFsm_capitalize(param);
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	dpGet(dp+".currentParameters:_online.._value",pars);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i]," ");
  if(dynlen(items) < 2)
    continue;
		items[2] = fwFsm_capitalize(items[2]);
		if(items[2] == param)
		{
			 if(dynlen(items) == 4)
				  value = items[4];
			 else
				  value = "";
			 if((pos = strpos(value,"\"")) == 0)
			 {
				  value = substr(value,1,strlen(value)-2);
			 }
    for(j = i+1; j <= dynlen(pars); j++)
    {
		    items = strsplit(pars[j]," ");
      if(dynlen(items) == 1)
      {
        value += "|"+items[1];
        i++;
      }
      else
      {
        break;
      }
    }
		}
	}
}

fwUi_setCurrentParameter(string domain, string obj, string param, string value)
{
	string dp;
	dyn_string pars, item;
	int i;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	dpGet(dp+".currentParameters:_online.._value",pars);
	for(i = 1; i <= dynlen(pars); i++)
	{
		item = strsplit(pars[i]," ");
		if(item[2] == param)
		{
			pars[i] = item[1]+" "+item[2]+" = "+value;
		}
	}
	dpSetWait(dp+".currentParameters:_original.._value",pars);
}

fwUi_getExecutingAction(string domain, string obj, string & action)
{
	string dp;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	dpGet(dp+".executingAction:_online.._value",action);
}

fwUi_getExecutingActionTime(string domain, string obj, time &stime)
{
	string dp;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	dpGet(dp+".executingAction:_online.._stime",stime);
}

int fwUi_parseExecutingActionParameter(string command, string param, string &value, int unescape = 1)
{
	dyn_string pars, items;
	int i, s_flag = 1;

	value = "";
	param = fwFsm_capitalize(param);
 	pars = strsplit(command,"/");
	if(!dynlen(pars))
		return -1;
	dynRemove(pars,1);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i],"()=");
		items[1] = fwFsm_capitalize(items[1]);
		if(items[1] == param)
		{
			if( (items[2] != "S")&&(items[2] != "I")&&(items[2] != "F") )
			{
				if(dynlen(items) >= 2)
					value = items[2];
			}
			else
			{
				if((items[2] == "I") || (items[2] == "F"))
					s_flag = 0;
				if(dynlen(items) >= 4)
					value = items[4];
			}
			break;
		}
	}
	if(value != "")
	{
		if((s_flag) && (unescape))
		{
			value = _fwUi_unescape(value);
		}
		return 1;
	}
  return 0;
}

int fwUi_getExecutingActionParameter(string domain, string obj, string param, string &value, int unescape = 1)
{
	string command;

  fwUi_getExecutingAction(domain, obj, command);
  return fwUi_parseExecutingActionParameter(command, param, value, unescape);
}

string _fwUi_unescape(string value)
{
	string ret, ptr, item;
	int pos, casc;
	char c;

//DebugN("unescape",value);
	ptr = value;
	while(1)
	{
		pos = strpos(ptr,"\\");
		if(pos >= 0)
		{
			ret += substr(ptr, 0, pos);
			item = substr(ptr, pos+1);
			sscanf(item,"%03o",casc);
			c = casc;
//DebugN("found esc", pos, ptr, item,casc, c, ret);
			ret += c;
			ptr = substr(ptr,pos+4);
		}
		else
		{
			ret += ptr;
			break;
		}
	}
	if((pos = strpos(ret,"\"")) == 0)
	{
		ret = substr(ret,1,strlen(ret)-2);
	}
//DebugN("ret", ret);
	return ret;
}

string _fwUi_escape(string value)
{
	string ret, ptr, item;
	int pos, casc;
	char c;

//DebugN("escape",value);

	ptr = value;
	if((pos = strpos(ptr,"\"")) == 0)
	{
		ptr = substr(ptr,1,strlen(ptr)-2);
	}
	while(1)
	{
		pos = strtok(ptr, "\"/|\\()");
		if(pos >= 0)
		{
			ret += substr(ptr, 0, pos);
			item = substr(ptr, pos+1);
			c = ptr[pos];
			casc = c;
			sprintf(item,"%03o",casc);
//DebugN("found esc", pos, ptr, c, casc, item, ret);
			ret += "\\"+item;
			ptr = substr(ptr,pos+1);
		}
		else
		{
			ret += ptr;
			break;
		}
	}
//DebugN("ret", ret);
	return ret;
}

int fwUi_parseExecutingActionDefaultParameter(string command, string domain, string obj, string param, string &value)
{
string state, action, type, par;
dyn_string pars, items;
int i, pos;

	fwUi_getCurrentState(domain, obj, state);
	fwFsm_getObjectType(domain+"::"+obj,type);
	items = strsplit(command,"/");
	if(!dynlen(items))
		return 0;
  action = items[1];
	fwFsm_readObjectActionParameters(type, state, action, pars);
//DebugTN("readObjectActionParameters",command, action, type, state, action, pars);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i]," ");
		par = items[2];
		if(par == param)
		{
			value = "";
			if(dynlen(items) > 2)
			{
				value = items[4];
				if((pos = strpos(value,"\"")) == 0)
				{
					value = substr(value,1,strlen(value)-2);
				}
			}
			break;
		}
	}
  return 1;
}

fwUi_getExecutingActionDefaultParameter(string domain, string obj, string param, string &value)
{
string state, command, action, type, par;
dyn_string items;
int i, pos;

	fwUi_getExecutingAction(domain, obj, command);
  fwUi_parseExecutingActionDefaultParameter(command, domain, obj, param, value);
}

int fwUi_sendCommand(string domain, string obj, string command)
{
	string dp;
	string action;
	dyn_string pars;

	fwUi_getSysPrefix(domain, dp);
	action = command;
	if(fwFsm_isAssociated(obj))
	{
		obj = fwFsm_convertAssociated(obj);
		obj = fwFsm_convertAssociated(obj);
		dp += fwFsm_separator+obj+".fsm";
	}
	else
	{
		dp += fwFsm_separator+obj+".fsm";
//		if(fwFsm_isProxy(obj))
//DebugTN("fwUi_sendCommand",domain, obj, command, dp);
		if(fwFsm_isProxyDp(dp))
		{
			pars = strsplit(command,"/");
			if(dynlen(pars))
				action = pars[1];
			if(dpExists(dp))
				/*fwUi_*/dpSetWait(dp+".executingAction:_original.._value",command);
		}
	}
	if(dpExists(dp))
	{
		/*fwUi_*/dpSetWait(dp+".sendCommand:_original.._value",action);
		return 1;
	}
	return 0;
}

int fwUi_connectCurrentState(string rout, string domain, string obj, int imm_flag = 1)
{
	string dp;
	int pos;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
//DebugN("dpConnect",dp+".currentState:_online.._value", rout);
	if(dpExists(dp))
	{
		dpConnect(rout, imm_flag, dp+".currentState:_online.._value");
		return 1;
	}
	return 0;
}

int fwUi_disconnectCurrentState(string rout, string domain, string obj)
{
	string dp;
	int pos, ret;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	if(dpExists(dp))
	{
		ret = dpDisconnect(rout, dp+".currentState:_online.._value");
		return 1;
	}
	return 0;
}

fwUi_connectCurrentParameters(string rout, string domain, string obj)
{
	string dp;
	int pos;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	if(dpExists(dp))
		dpConnect(rout, dp+".currentParameters:_online.._value");
}

fwUi_connectExecutingAction(string rout, string domain, string obj, int immediate = 1)
{
	string dp;
	int ret;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	if(dpExists(dp))
	{
		ret = dpConnect(rout, immediate, dp+".executingAction:_online.._value");
	}
}

fwUi_disconnectExecutingAction(string rout, string domain, string obj)
{
	string dp;
	int ret;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".fsm";
	if(dpExists(dp))
	{
		ret = dpDisconnect(rout, dp+".executingAction:_online.._value");
	}
}

fwUi_getObjStates(string domain, string obj, dyn_string & states)
{
	string type, sys;
	string full_obj;
	dyn_string syss;
	dyn_uint ids;

	full_obj = domain+"::"+obj;
	fwFsm_getObjectType(full_obj, type);
	if(fwFsm_isAssociated(obj))
		domain = fwFsm_getAssociatedDomain(obj);
	fwUi_getDomainSys(domain, sys);
	sys = strrtrim(sys,":");
	getSystemNames(syss, ids);
	if(!dynContains(syss, sys))
		return;
	fwFsm_getObjectStates(sys+":"+type, states);
}

fwUi_getObjStateColor(string domain, string obj, string state, string & color)
{
	string type, sys, typedp;
	string full_obj;
	dyn_string syss;
	dyn_uint ids;

	full_obj = domain+"::"+obj;
	color = "_3DFace";
	if (state != "")
	{
		fwFsm_getObjectType(full_obj, type);
		if(fwFsm_isAssociated(obj))
			domain = fwFsm_getAssociatedDomain(obj);
		fwUi_getDomainSys(domain, sys);
		sys = strrtrim(sys,":");
		getSystemNames(syss, ids);
		if(!dynContains(syss, sys))
			return;

		typedp = fwFsm_formType(type);
		if(dpExists(typedp))
			fwFsm_getObjectStateColor(type, state, color);
		else
			fwFsm_getObjectStateColor(sys+":"+type, state, color);
	}
}

fwUi_getObjStateAllActions(string domain, string obj, string state, dyn_string & actions)
{
int i, pos;
bool nv;
string action, type, sys;
dyn_string list;
string full_obj;
dyn_string syss;
dyn_uint ids;

	full_obj = domain+"::"+obj;
	dynClear(actions);
	fwFsm_getObjectType(full_obj, type);
	if(fwFsm_isAssociated(obj))
		domain = fwFsm_getAssociatedDomain(obj);
	fwUi_getDomainSys(domain, sys);
	sys = strrtrim(sys,":");
	getSystemNames(syss, ids);
	if(!dynContains(syss, sys))
		return;
//DebugN("getObjStateSctions",domain, obj, state, type);
	fwFsm_getObjectStateActions(sys+":"+type, state, actions);
}

fwUi_getObjStateActions(string domain, string obj, string state, dyn_string & actions)
{
int i, pos;
bool nv;
string action, type, sys;
dyn_string list;
string full_obj;
dyn_string syss;
dyn_uint ids;

	full_obj = domain+"::"+obj;
	dynClear(actions);
	fwFsm_getObjectType(full_obj, type);
	if(fwFsm_isAssociated(obj))
		domain = fwFsm_getAssociatedDomain(obj);
	fwUi_getDomainSys(domain, sys);
	sys = strrtrim(sys,":");
	getSystemNames(syss, ids);
//DebugN(syss, sys);
	if(!dynContains(syss, sys))
		return;
	fwFsm_getObjectStateVActions(sys+":"+type, state, actions);
//DebugN("getObjStateSctions",domain, obj, state, type, actions);
}

fwUi_getObjStateActionsV(string domain, string obj, string state, dyn_string & actions, dyn_int &visi)
{
int i, pos;
bool nv;
string action, type, sys;
dyn_string list;
string full_obj;
dyn_string syss;
dyn_uint ids;

	full_obj = domain+"::"+obj;
	dynClear(actions);
	fwFsm_getObjectType(full_obj, type);
	if(fwFsm_isAssociated(obj))
		domain = fwFsm_getAssociatedDomain(obj);
	fwUi_getDomainSys(domain, sys);
	sys = strrtrim(sys,":");
	getSystemNames(syss, ids);
	if(!dynContains(syss, sys))
		return;
	fwFsm_getObjectStateVActionsV(sys+":"+type, state, actions, visi);
//DebugN("ActionsV", domain, obj, state, actions, visi);
}

string fwUi_convertLocalCurrentState(string domain, string obj, string state)
{
  int index;
  dyn_string states;
  int i;
  string type, capstate;

//DebugTN("fwUi_convertLocalCurrentState",domain, obj, state);
  if (state != "")
  {
    type = fwUi_addLocalObj(domain, obj, 0);
//DebugTN("type", domain, obj, type, FsmDisplayTypeStates);
    if (type != "")
    {
      states = FsmDisplayTypeStates[type];
      for(i = 1; i <= dynlen(states); i++)
      {
        capstate = fwFsm_capitalize(states[i]);
        if(capstate == state)
          return states[i];
      }
    }
    else
      fwUi_convertCurrentState(domain, obj, state);
  }
  return state;
}


fwUi_getLocalObjStateColor(string domain, string obj, string state, string & color)
{
int index, state_index;
dyn_string states;
string type;

  color = "_3DFace";
//DebugN(FsmDisplayObjs, FsmDisplayObjsType, domain, obj, state);
  type = fwUi_addLocalObj(domain, obj, 0);
  if(type != "")
  {
    if(state_index = dynContains(FsmDisplayTypeStates[type], state))
    {
      color = FsmDisplayTypeColors[type][state_index];
    }
    else if (state!="DEAD")
    {
      DebugTN("fwUi_getLocalObjStateColor: Error, no state color defined for "+domain+"::"+obj+", type "+type+", state "+state+"!!");
    }
  }
  else
    fwUi_getObjStateColor(domain, obj, state, color);
}
/*
_fwUi_fillLocalObj(string type, int index)
{
  dyn_string states, colors, actions, full_actions;
  dyn_int visis, full_visis;
  int j, k;

  fwFsm_getObjectStatesColors(type, states, colors);

  for(j = 1; j <= dynlen(states); j++)
  {
    fwFsm_getObjectStateFullActionsV(type, states[j], actions, visis);
    dynAppend(full_actions, actions);
    dynAppend(full_visis, visis);
  }
  if(!dynlen(FsmDisplayObjStates[index]))
  {
    FsmDisplayObjStates[index] = states;
    FsmDisplayObjColors[index] = colors;
    FsmDisplayObjActions[index] = full_actions;
    FsmDisplayObjActionsVisi[index] = full_visis;
  }
  else
  {
    if( states != FsmDisplayObjStates[index])
      FsmDisplayObjStates[index] = states;
    if( colors != FsmDisplayObjColors[index])
      FsmDisplayObjColors[index] = colors;
    if( full_actions != FsmDisplayObjActions[index])
      FsmDisplayObjActions[index] = full_actions;
    if( visis != FsmDisplayObjActionsVisi[index])
				FsmDisplayObjActionsVisi[index] = full_visis;
  }
}
*/
int fwUi_addLocalType(string type, int reload = 0)
{
  dyn_string states, colors, actions, full_actions;
  dyn_int visis, full_visis;
  int j, k;

//DebugTN("fwUi_addLocalType", type, reload);
  if ((mappingHasKey(FsmDisplayTypeStates, type)) && (!reload))
    return 1; // type already cached

  // fill states, colors, actions and visibility
  //

//DebugTN("fwUi_addLocalType - added", type);
  fwFsm_getObjectStatesColors(type, states, colors);

  for(j = 1; j <= dynlen(states); j++)
  {
    fwFsm_getObjectStateFullActionsV(type, states[j], actions, visis);
    dynAppend(full_actions, actions);
    dynAppend(full_visis, visis);
  }
  if (dynlen(states))
    FsmDisplayTypeStates[type] = states;
  else
    return 0; // type states must be defined
  FsmDisplayTypeColors[type] = colors;
  FsmDisplayTypeActions[type] = full_actions;
  FsmDisplayTypeActionsVisi[type] = full_visis;
  return 1;
}

fwUi_getLocalTypeActions(string type, dyn_string &actions, dyn_int &visis)
{
  actions = FsmDisplayTypeActions[type];
  visis = FsmDisplayTypeActionsVisi[type];
}

fwUi_setLocalTypeActions(string type, dyn_string actions, dyn_int visis)
{
  FsmDisplayTypeActions[type] = actions;
  FsmDisplayTypeActionsVisi[type] = visis;
}

synchronized string fwUi_addLocalObj(string domain, string obj, int create = 1, int addType = 1)
{
  string str, type, sys;

//  if(create)
//    DebugTN("fwUi_addLocalObj", domain, obj, create, addType);
  if (!globalExists("FsmDisplayObjTypes"))
    return "";

  str = domain+"::"+obj;
  if (mappingHasKey(FsmDisplayObjTypes, str))
    return FsmDisplayObjTypes[str]; // object already cached

  if(!create)
    return "";
  fwFsm_getObjectType(str, type);
  if(type == "")
    return "";
//DebugTN("fwUi_addLocalObj - added", domain, obj, type);
  fwUi_getDomainSys(domain, sys);
  FsmDisplayObjTypes[str] = sys+type;
  if(addType)
  {
    fwUi_addLocalType(sys+type);
  }
  return sys+type;
}
/*
fwUi_addLocalObj(string domain, string obj)
{
  int index, index1;
  string type, sys;

DebugTN("Adding Local Object", domain, obj);
  fwFsm_getObjectType(domain+"::"+obj, type);
  fwUi_getDomainSys(domain, sys);
  if(!(index = dynContains(FsmDisplayObjTypes, sys+type)))
  {
    index = dynAppend(FsmDisplayObjTypes, sys+type);
    FsmDisplayObjStates[index] = makeDynString();
    FsmDisplayObjColors[index] = makeDynString();
  }
  if(!(index1 = dynContains(FsmDisplayObjs, domain+"::"+obj)))
  {
    dynAppend(FsmDisplayObjs, domain+"::"+obj);
    dynAppend(FsmDisplayObjsType, index);
  }
  else
    FsmDisplayObjsType[index1] = index;
  _fwUi_fillLocalObj(FsmDisplayObjTypes[index], index);
}
*/
fwUi_getLocalObjStateActions(string domain, string obj, string state, dyn_string &actions, dyn_int &visis,
                             dyn_string filter = makeDynString())
{
int index;
dyn_string full_actions, tmp_actions;
dyn_int full_visis, tmp_visis;
int i;
string type;

  dynClear(actions);
  type = fwUi_addLocalObj(domain, obj, 0);
  if (type != "")
  {
    full_actions = FsmDisplayTypeActions[type];
    full_visis = FsmDisplayTypeActionsVisi[type];
//DebugTN("getLocalObjStatesActions", domain, obj, full_actions, full_visis, filter);
    for(i = 1; i <= dynlen(full_actions); i++)
    {
				if(strpos(full_actions[i],state+"/") == 0)
				{
					if(strreplace(full_actions[i],state+"/",""))
					{
				   dynAppend(tmp_actions, full_actions[i]);
						dynAppend(tmp_visis, full_visis[i]);
        }
      }
    }
    for(i = 1; i <= dynlen(tmp_actions); i++)
    {
      if(dynlen(filter))
      {
        if(dynContains(filter, tmp_actions[i]))
        {
          dynAppend(actions, tmp_actions[i]);
          dynAppend(visis, tmp_visis[i]);
        }
      }
      else
      {
        if(tmp_visis[i])
        {
          dynAppend(actions, tmp_actions[i]);
          dynAppend(visis, tmp_visis[i]);
        }
      }
    }
  }
  else
  {
    fwUi_getObjStateActionsV(domain, obj, state, actions, visis);
  }
}

/*
string fwUi_getUiId()
{
	dyn_string in, out;
	int ret;

	in = makeDynString("");
	out = makeDynString("");
	ret = userDefFunc("FwUi","fwUiGetId",in,out);
	return out[1];
}
*/

// In fwFsmBasics
/*
string fwUi_getUiId()
{
	string id;

	id = getSystemName()+"Manager"+myManNum();
	return id;
}
*/

string fwUi_green()
{
	return "[0,80,60]";
}

string fwUi_blue()
{
	return "[0,60,100]";
}

string fwUi_yellow()
{
	return "[100,100,40]";
}

string fwUi_orange()
{
	return "[100,60,0]";
}

string fwUi_red()
{
	return "[100,0,0]";
}

fwUi_setDomainObjectsOperation(string domain, int operatable)
{
dyn_string objs;
int i;

	objs = fwFsm_getDomainDevices(domain);
	for(i = 1; i <= dynlen(objs); i++)
	{
		fwUi_setOperation(domain, objs[i], operatable);
	}
	objs = fwFsm_getDomainLogicalObjects(domain);
	for(i = 1; i <= dynlen(objs); i++)
	{
		fwUi_setOperation(domain, objs[i], operatable);
	}
}

fwUi_setDomainObjectsEnabled(string domain)
{
dyn_string objs, logobjs, children;
int i, enabled;
dyn_int enableds;

	objs = fwFsm_getDomainDevices(domain);
	logobjs = fwFsm_getDomainLogicalObjects(domain);
	dynAppend(objs, logobjs);
//	fwUi_startEnDisableDevices();
	for(i = 1; i <= dynlen(objs); i++)
	{
		fwUi_getEnabled(domain, objs[i], enabled);
		if(enabled <= 0)
		{
			dynAppend(children, objs[i]);
			dynAppend(enableds, enabled);
//			fwUi_disableDevice(domain, objs[i], enabled);
		}
	}
	fwUi_disableDevices(domain, children, enableds);
//	fwUi_stopEnDisableDevices();
}

/*
fwUi_setDomainsLockedOut(string domain, string id)
{
int i, enabled;
dyn_string cus;
int lockedOut;

	cus = fwFsm_getLogicalUnitCUs(domain);
	for(i = 1; i <= dynlen(cus); i++)
	{
		fwUi_getLockedOut(domain, cus[i], lockedOut);
		if(lockedOut)
		{
DebugN("Should LockOut", domain, cus[i]);
			fwUi_excludeTree(domain, cus[i], id);
			fwUi_lockOutTree(domain, cus[i], id);
		}
	}
}
*/

dyn_int FwUI_CurrentUIs;

fwUi_connectManagerIds()
{
  if(isLHCb())
    dpConnect("fwUi_checkManagerIdGone","_Connections.Ui.ManNums");
}

fwUi_checkManagerIdGone(string dp, dyn_int nums)
{
  int i;

  if(dynlen(FwUI_CurrentUIs))
  {
    for(i = 1; i <= dynlen(FwUI_CurrentUIs); i++)
    {
      if(!dynContains(nums, FwUI_CurrentUIs[i]))
        fwUi_cleanManagerId(FwUI_CurrentUIs[i]);
    }
  }
  FwUI_CurrentUIs = nums;
}

fwUi_cleanManagerId(int num)
{
  string sys, dp, owner, user;
  dyn_string nodes;
  int i;

  dp = "_fwFsm_Manager"+num;
	if(dpExists(dp+".taken"))
	{
    dpGet(dp+".taken", nodes);
    if(!dynlen(nodes))
      return;
    sys = getSystemName();
    owner = sys+"Manager"+num;
    dpGet(dp+".info", user);
DebugTN("*** User Interface killed - was owned by "+owner+" ("+user+") *** Releasing ", nodes);
    for(i = 1; i <= dynlen(nodes); i++)
      fwUi_releaseTree(nodes[i], nodes[i], owner);
    dpSet(dp+".taken", makeDynString());
  }
}

fwUi_addManagerIdNodeTaken(string owner, string node)
{
string dp, sys, man;
dyn_string items, nodes;

	items = strsplit(owner,":");
	sys = items[1];
	if(dynlen(items) >= 2)
		man = items[2];
	sys += ":";
	dp = "_fwFsm_"+man;
	if(dpExists(sys+dp+".taken"))
	{
    dpGet(sys+dp+".taken", nodes);
    if(!dynContains(nodes, node))
    {
      dynAppend(nodes, node);
      dpSet(sys+dp+".taken", nodes);
    }
  }
}

fwUi_removeManagerIdNodeTaken(string owner, string node)
{
string dp, sys, man;
dyn_string items, nodes;
int index;

	items = strsplit(owner,":");
	sys = items[1];
	if(dynlen(items) >= 2)
		man = items[2];
	sys += ":";
	dp = "_fwFsm_"+man;
	if(dpExists(sys+dp+".taken"))
	{
    dpGet(sys+dp+".taken", nodes);
    if((index = dynContains(nodes, node)))
    {
      dynRemove(nodes, index);
      dpSet(sys+dp+".taken", nodes);
    }
  }
}

synchronized fwUi_setManagerIdInfo(string owner)
{
string dp, sys, man;
dyn_string items;
string user, full, desc, host;
dyn_string groups;
int sysid;
file f;
int ownerid;

	items = strsplit(owner,":");
	sys = items[1];
	if(dynlen(items) >= 2)
		man = items[2];
	sys += ":";
	dp = "_fwFsm_"+man;
	if(!dpExists(sys+dp))
	{
//		if(sys != getSystemName())
//			sysid =
		dpCreate(dp, "_FwFsmUiManager");
	}
  if (!isATLAS())
  {
/*
	  if(_UNIX)
	  {
	  	system("mv "+PROJ_PATH+"config/user.txt "+PROJ_PATH+"config/user_old.txt");
	  	system("whoami > "+PROJ_PATH+"config/user.txt");
	  	system("chmod 777 "+PROJ_PATH+"config/user.txt");
	  	f= fopen(PROJ_PATH+"config/user.txt", "r");
	  	fscanf(f,"%s",user);
	  	fclose(f);
	  }
	  else
	  {
*/
    		getCurrentOSUser(user, full, desc, groups, "");
/*
	  }
*/
  }
  else
  {
	  fwAccessControl_getUserName(user);
  }
  strreplace(man,"Manager","");
  strreplace(man,"Ctrl","");
  ownerid = (int)man;
  if(ownerid != (int)myManNum())
  {
DebugTN("fwUi_setManagerIdInfo aborted", sys+dp+".info",user+"@"+host, owner, getSystemName(), myManNum());
    return;
  }
  host = getHostname();
  if (dpExists(sys+dp+".info"))
    dpSet(sys+dp+".info",user+"@"+host);
//DebugTN("fwUi_setManagerIdInfo", sys+dp+".info",user+"@"+host, owner, getSystemName(), myManNum());
}

string fwUi_getManagerIdInfo(string owner)
{
string dp, sys, man;
dyn_string items;
string user;

	items = strsplit(owner,":");
	sys = items[1];
	if(dynlen(items) >= 2)
		man = items[2];
	sys += ":";
	dp = "_fwFsm_"+man;
	if(dpExists(sys+dp))
	{
		dpGet(sys+dp+".info",user);
	}
	return user;
}

int fwUi_actOnObject(string action, string parent, string child, string id, int exclusive = -1)
{
	int owned;
	string owner;
	string itsid;
	string currDomain, currObj;
	int operatable;
	dyn_string objs, syss, children;
	string dp, sys;
	int disc = 0, running = 0;
	dyn_uint sys_ids;
	int i, ret = 1;
	string state, new_owner;

//DebugTN("*********** actOnObject", action, parent, child);
	currObj = fwFsm_getAssociatedObj(child);
	currDomain = fwFsm_getAssociatedDomain(child);
	if(currDomain == "")
		currDomain = parent;

	fwUi_getDomainOperation(parent, operatable);

	fwUi_getDomainPrefix(currObj, dp);
	fwUi_checkOwnership(currObj, owned, owner, id);

//DebugTN("*** actOnObject",action, currDomain, currObj, dp, owner, id);
	if(!dpExists(dp))
		disc = 1;
	else
		dpGet(dp+".running", running);
	if((owned) && (running) && (!disc))
	{
		if(id != "")
			itsid = id;
		else
			itsid = fwUi_getUiId();
		switch(action)
		{
		case "Share":
			/*fwUi_*/dpSetWait(dp+".mode.exclusivity:_original.._value",0);
			break;
		case "Exclusive":
			/*fwUi_*/dpSetWait(dp+".mode.exclusivity:_original.._value",1);
			break;
		case "Include":
			fwUi_setOperation(currDomain, currObj+"::"+currObj, operatable);
			fwUi_setOperation(currObj, currObj, operatable);
//			fwUi_setDomainObjectsOperation(currObj,operatable);
//DebugN("SetObjectsEnabled", currObj);
//			fwUi_setDomainObjectsEnabled(currObj);
			if(parent == currObj)
				/*fwUi_*/dpSetWait(dp+".mode.owner:_original.._value",itsid);
//			fwUi_setDomainsLockedOut(currObj, itsid);
			fwFsm_actOnSummaryAlarm(1, currObj+"::"+currObj, currDomain);
			if(exclusive != -1)
			{
				/*fwUi_*/dpSetWait(dp+".mode.exclusivity:_original.._value", exclusive);
			}
			break;
		case "Take":
			if(currObj != parent)
			{
				fwUi_setOperation(currDomain, currObj+"::"+currObj, operatable);
				fwUi_setOperation(currObj, currObj, operatable);
			}
			else
			{
				fwUi_setOperation(currObj, currObj, 1);
			}
//			fwUi_setDomainObjectsOperation(currObj,operatable);
//DebugN("SetObjectsEnabled1", currObj);
//			fwUi_setDomainObjectsEnabled(currObj);
			if(parent == currObj)
				/*fwUi_*/dpSetWait(dp+".mode.owner:_original.._value",itsid);
//			fwUi_setDomainsLockedOut(currObj, itsid);
			fwFsm_actOnSummaryAlarm(1, currObj+"::"+currObj, currDomain);
			if(exclusive != -1)
			{
				/*fwUi_*/dpSetWait(dp+".mode.exclusivity:_original.._value", exclusive);
			}
			break;
		case "Release":
		case "Delegate":
			if(parent == currObj)
				/*fwUi_*/dpSetWait(dp+".mode.owner:_original.._value","");
			fwFsm_actOnSummaryAlarm(0, currObj+"::"+currObj, currDomain);
			break;
		case "Ignore":
			if(parent == currObj)
				/*fwUi_*/dpSetWait(dp+".mode.owner:_original.._value",itsid);
			break;
		}
	}
	else
		ret = 0;
	return ret;
}

int fwUi_waitExcluded(string domain, dyn_string children, int timeout = 5000)
{
  dyn_string included_nodes;
  int elapsed = 0;
  int delayTime = 20;
  int foundChild, i;
//  DebugTN("Wait excluded for " + dynlen(children) + " children");

  if(dynlen(children) == 0)
    return 1;
  do
  {
    delay(0,delayTime);
    elapsed += delayTime;
    dynClear(included_nodes);
    fwUi_getIncludedChildren(domain, domain, included_nodes);
// DebugTN("Get Included Children ", included_nodes, elapsed + "/" + timeout);
    foundChild = 0;
    for(i = 1; i <= dynlen(children); i++)
    {
      if(dynContains(included_nodes, children[i]))
      {
        foundChild = 1;
        break;
      }
    }
  } while(foundChild && (elapsed <= timeout));
  if(!foundChild)
    return 1;
  return 0;
}

int fwUi_waitModeChanged(dyn_string nodes, string previousMode, int timeout = 5000)
{
  int elapsed = 0;
  int delayTime = 100;
  string currDomain, currObj;
  int foundChild;
  string childMode;
  int i;
  dyn_string items;

//  DebugTN("Wait mode != " + previousMode + " for " + dynlen(nodes) + " nodes");
  if (dynlen(nodes) == 0)
    return true;

  do
  {
    delay(0,delayTime);
    elapsed += delayTime;
    foundChild = 0;
    for (i = 1; i <= dynlen(nodes); i++)
    {
      items = strsplit(nodes[i], "|");
      currDomain = items[1];
      currObj = items[2];
      childMode = fwUi_getCUMode(currDomain, currObj);
//    DebugTN("Mode for " + currObj + ": " + childMode, elapsed + "/" + timeout);
      if (childMode == previousMode) // previousMode is the mode that we do not want!
      {
        foundChild = 1;
        break;
      }
    }

  } while (foundChild && (elapsed <= timeout));

  if(!foundChild)
    return 1;
  return 0;
}


int fwUi_actOnObjectChildren(string action, string parent, string child, string id, int exclusive = -1, dyn_string dontreport = makeDynString(),int waitExcluded = 0)
{
	dyn_string lockedNodes, notTakenNodes, items, excludedNodes;
	string report;
	int ret, i;

	ret = fwUi_actOnObjectChildrenRec(action, parent, child, id, lockedNodes, notTakenNodes, excludedNodes, dontreport);

  if (waitExcluded)
  {
    fwUi_waitModeChanged(excludedNodes,"Included");
  }
//DebugN(action, parent, child, id, lockedNodes, notTakenNodes, isFunctionDefined("setValue"), shapeExists("LockedOut"));
	if( (isFunctionDefined("setValue")) && (shapeExists("LockedOut")) )
	{
		getValue("LockedOut", "items", items);
		dynAppend(items, lockedNodes);
		setValue("LockedOut", "items", items);
	}
	return ret;
}

int fwUi_actOnObjectChildrenRec(string action, string parent, string child, string id,
	dyn_string &lockedNodes, dyn_string &notTakenNodes, dyn_string &excludedNodes, dyn_string dontreport = makeDynString())
{
	int owned;
	string owner;
	string itsid;
	string currDomain, currObj;
	int operatable;
	dyn_string objs, syss, children;
	string dp, sys;
	int disc = 0, running = 0;
	dyn_uint sys_ids;
	int i, ret = 1;
	string state, childState, user;

//DebugTN("*********** actOnObjectChildrenRec", action, parent, child, id, dontreport);
	currObj = fwFsm_getAssociatedObj(child);
	currDomain = fwFsm_getAssociatedDomain(child);
	if(currDomain == "")
		currDomain = parent;

	fwUi_getChildren(currObj, children);
//DebugTN("children", currObj, children);
	currDomain = currObj;
	for(i = 1; i <= dynlen(children); i++)
	{
		currObj = children[i];
//DebugTN("checking child", i, currDomain, currObj);
		ret = 1;
		state = fwUi_getCUMode(currDomain, currObj);
		if((state != "LockedOut") && (state != "LockedOutPerm"))
		{
			fwUi_getDomainPrefix(currObj, dp);
			fwUi_checkOwnership(currObj, owned, owner, id);

			if(!dpExists(dp))
				disc = 1;
			else
				dpGet(dp+".running", running);
//DebugTN("actOnObjectChildren",action, currDomain, currObj, dp, owned, owner, id);
			if(!owned)
			{
//DebugTN("Would have reported", currObj);
				if(state == "ExcludedPerm")
				{
//DebugN("SendingCommand",currDomain, currObj+"_FWM","Exclude");
					fwUi_sendCommand(currDomain, currObj+"_FWM","ExcludePerm");
          dynAppend(excludedNodes, currDomain+"|"+currObj);
				}
				if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
				{
				  user = fwUi_getManagerIdInfo(owner);
//				  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is owned by "+owner+" ("+user+") ***", parent, 3);
				  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is owned by "+owner+" ("+user+") ***", "dummy", 3);
//				dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" is owned by "+owner+" ("+user+")");
				}
				ret = 0;
			}
			else
			{
				if((state == "Excluded") || (state == "ExcludedPerm"))
				{
					if(state == "ExcludedPerm")
					{
//DebugN("SendingCommand",currDomain, currObj+"_FWM","ExcludePerm");
						fwUi_sendCommand(currDomain, currObj+"_FWM","ExcludePerm");
            dynAppend(excludedNodes, currDomain+"|"+currObj);
					}
					childState = fwUi_getCUMode(currObj, currObj);
//DebugN("Act On Including",currDomain, currObj, state, childState);
					if(childState == "Included")
					{
         //if(!isCMS())
            fwUi_sendCommand(currObj, currObj+"_FWM","Exclude");
            dynAppend(excludedNodes, currObj+"|"+currObj);
        /* else
         {
						  if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
						  {
						  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is "+childState+" mode ***", parent, 3);
//					  	dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" is "+childState+" mode");
						  }

         }
         */
					}
					else if ((childState == "InLocal")  || (childState == "InManual"))
					{
//DebugTN("Would have reported", currObj);
						if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
						{
//						  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is "+childState+" mode ***", parent, 3);
						  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is "+childState+" mode ***", "dummy", 3);
//						dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" is "+childState+" mode");
						}
					}
				}
			}
			if(disc)
			{
				sys = fwFsm_getSystem(dp);
				getSystemNames(syss, sys_ids);
				if(!dynContains(syss, sys))
				{
//DebugTN("Would have reported", currObj);
					if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
					{
//					  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" on system "+sys+" Not Reacheable ***", parent, 3);
					  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" on system "+sys+" Not Reacheable ***", "dummy", 3);
//					dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" on system "+sys+" Not Reacheable");
					}
					ret = 0;
				}
			}
			if(!running)
			{
				sys = fwFsm_getSystem(dp);
//DebugTN("Would have reported", currObj);
				if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
				{
//				  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" on system "+sys+" is DEAD ***", parent, 3);
				  fwUi_report("*** WARNING - Can not "+action+": "+currObj+" on system "+sys+" is DEAD ***", "dummy", 3);
//				dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" on system "+sys+" is DEAD");
				}
				ret = 0;
			}
			if((dynlen(dontreport)) && (dynContains(dontreport,currObj)))
				ret = 0;
			if(ret)
				fwUi_actOnObjectChildrenRec(action, currDomain, currObj, id, lockedNodes, notTakenNodes, excludedNodes, dontreport);
		}
		else
		{
//DebugN("*** LockedOut/LockedOutPerm ", currObj);
			if(state == "LockedOutPerm")
			{
//DebugN("SendingCommand",currDomain, currObj+"_FWM","LockOut");
        if(!RememberLockedOutPerm)
    		  fwUi_sendCommand(currDomain, currObj+"_FWM","LockOut");
        else
        {
			    if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
			    	dynAppend(lockedNodes,currObj +" (Not Propagated)");
        }
			}
      else
      {
			  if((!dynlen(dontreport)) || (!dynContains(dontreport,currObj)))
			  	dynAppend(lockedNodes,currObj);
      }
		}
	}
	return ret;
}
/*
int fwUi_actOnObjectChildrenObj(string action, string parent, string child, string id, int exclusive = -1, int dontreportperm = 0)
{
	dyn_string lockedNodes, notTakenNodes, items;
	string report;
	int ret, i;

	ret = fwUi_actOnObjectChildrenObjRec(action, parent, child, id, lockedNodes, notTakenNodes, dontreportperm);
//DebugN(action, parent, child, id, lockedNodes, notTakenNodes, isFunctionDefined("setValue"), shapeExists("LockedOut"));
	if( (isFunctionDefined("setValue")) && (shapeExists("LockedOut")) )
	{
		getValue("LockedOut", "items", items);
		dynAppend(items, lockedNodes);
		setValue("LockedOut", "items", items);
	}
	return ret;
}

int fwUi_actOnObjectChildrenObjRec(string action, string parent, string child, string id,
	dyn_string &lockedNodes, dyn_string &notTakenNodes, int dontreportperm = 0)
{
	int owned;
	string owner;
	string itsid;
	string currDomain, currObj;
	int operatable;
	dyn_string objs, syss, children;
	string dp, sys;
	int disc = 0, running = 0;
	dyn_uint sys_ids;
	int i, ret = 1;
	string state, childState, user;


	currObj = fwFsm_getAssociatedObj(child);
	currDomain = fwFsm_getAssociatedDomain(child);
	if(currDomain == "")
		currDomain = parent;

//DebugTN("checking child", currDomain, currObj, id);
		ret = 1;
		state = fwUi_getCUMode(currDomain, currObj);
		if((state != "LockedOut") && (state != "LockedOutPerm"))
		{
			fwUi_getDomainPrefix(currObj, dp);
			fwUi_checkOwnership(currObj, owned, owner, id);

			if(!dpExists(dp))
				disc = 1;
			else
				dpGet(dp+".running", running);
//DebugTN("actOnObjectChildren",action, currDomain, currObj, dp, owned, owner, id);
			if(!owned)
			{
//DebugTN("Would have reported", currObj);
				if((!dontreportperm) || (state != "ExcludedPerm"))
				{
				user = fwUi_getManagerIdInfo(owner);
				fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is owned by "+owner+" ("+user+") ***", parent, 3);
//				dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" is owned by "+owner+" ("+user+")");
				}
				ret = 0;
			}
			else
			{
				if((state == "Excluded") || (state == "ExcludedPerm"))
				{
					childState = fwUi_getCUMode(currObj, currObj);
//DebugN("Act On Including",currDomain, currObj, state, childState);
					if(childState == "Included")
					{
						fwUi_sendCommand(currObj, currObj+"_FWM","Exclude");

					}
					else if ((childState == "InLocal")  || (childState == "InManual"))
					{
//DebugTN("Would have reported", currObj);
						if((!dontreportperm) || (state != "ExcludedPerm"))
						{
						fwUi_report("*** WARNING - Can not "+action+": "+currObj+" is "+childState+" mode ***", parent, 3);
//						dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" is "+childState+" mode");
						}
					}
				}
			}
			if(disc)
			{
				sys = fwFsm_getSystem(dp);
				getSystemNames(syss, sys_ids);
				if(!dynContains(syss, sys))
				{
//DebugTN("Would have reported", currObj);
					if((!dontreportperm) || (state != "ExcludedPerm"))
					{
					fwUi_report("*** WARNING - Can not "+action+": "+currObj+" on system "+sys+" Not Reacheable ***", parent, 3);
//					dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" on system "+sys+" Not Reacheable");
					}
					ret = 0;
				}
			}
			if(!running)
			{
				sys = fwFsm_getSystem(dp);
//DebugTN("Would have reported", currObj);
				if((!dontreportperm) || (state != "ExcludedPerm"))
				{
				fwUi_report("*** WARNING - Can not "+action+": "+currObj+" on system "+sys+" is DEAD ***", parent, 3);
//				dynAppend(notTakenNodes,"Can not "+action+": "+currObj+" on system "+sys+" is DEAD");
				}
				ret = 0;
			}
//			if(ret)
//				fwUi_actOnObjectChildrenRec(action, currDomain, currObj, id, lockedNodes, notTakenNodes, excludedNodes, dontreportperm);
		}
		else
		{
			dynAppend(lockedNodes,currObj);
		}
return ret;
}
*/


int fwUi_actOnTree(string action, string parent, string child, string id = "", int exclusive = -1)
{
string currDomain, currObj, state;
dyn_string children;
int i, ret = 0;

//DebugN("***************** actOnTree", parent, child, action);
	currObj = fwFsm_getAssociatedObj(child);
	currDomain = fwFsm_getAssociatedDomain(child);
	if(currDomain == "")
//		currDomain = child;
//	if(currDomain == currObj)
		currDomain = parent;
	state = fwUi_getCUMode(currDomain, currObj);
//DebugN("actOnTree", parent, child, currObj, state, action);
	if(((state != "LockedOut") && (state != "LockedOutPerm")) || (action == "Release"))
	{
//DebugN("actOnObject",action, parent, currDomain+"::"+currObj, id);
		ret = fwUi_actOnObject(action, parent, currDomain+"::"+currObj, id, exclusive);
/* for parallel exec
		if(ret)
		{
			fwUi_getChildren(currObj, children);
			for(i = 1; i <= dynlen(children); i++)
			{
				fwUi_actOnTree(action, parent, currObj+"::"+children[i], id);
			}
		}
*/
	}
	return ret;
}

fwUi_getTreeDevices(string domain, dyn_string &devices)
{
dyn_string children;
int i;

	children = fwFsm_getDomainDevices(domain);
	dynAppend(devices, children);
	fwUi_getChildren(domain, children);
	for(i = 1; i <= dynlen(children); i++)
	{
		fwUi_getTreeDevices(children[i], devices);
	}
}

fwUi_startEnDisableDevices()
{
	if(FwUi_ActOnMultiple >= 0)
		FwUi_ActOnMultiple++;
//DebugTN("StartActOnMulti", getThreadId(), FwUi_ActOnMultiple);
}

fwUi_stopEnDisableDevices()
{
dyn_string dpes;
dyn_anytype values;
int i, send;
string sys, old_sys;

	FwUi_ActOnMultiple--;
//DebugTN("StopActOnMulti begin", getThreadId(), FwUi_ActOnMultiple);
	if((FwUi_ActOnMultiple <= 0) && (FwUi_ActOnMultiple != -10))
	{
		FwUi_ActOnMultiple = -10;
		for(i = 1; i <= dynlen(FwUi_MultiDPList); i++)
		{
			send = 0;
			if(!dynContains(dpes, FwUi_MultiDPList[i]))
			{
				sys = dpSubStr(FwUi_MultiDPList[i],DPSUB_SYS);
				if(old_sys == "")
					old_sys = sys;
//DebugN("syss",old_sys, sys);
				if(old_sys != sys)
					send = 1;
				else
				{
					dynAppend(dpes, FwUi_MultiDPList[i]);
					dynAppend(values, FwUi_MultiDPValues[i]);
				}

			}
			else
				send = 1;
			if(send)
			{
//if(dynlen(FwUi_MultiDPList) < i)
//DebugN("Setting 0 ",dpes, values, FwUi_MultiDPList, i);
				dpSetWait(dpes, values);
//DebugTN("Setting part", getThreadId(), dynlen(dpes), dpes, values);
				dynClear(dpes);
				dynClear(values);
//if(dynlen(FwUi_MultiDPList) < i)
//DebugN("Setting 1 ",dpes, values, FwUi_MultiDPList, i);
//DebugTN("Setting", getThreadId(), dynlen(FwUi_MultiDPList), i);
				dynAppend(dpes, FwUi_MultiDPList[i]);
				dynAppend(values, FwUi_MultiDPValues[i]);
				old_sys = sys;
			}
		}
		if(dynlen(dpes))
		{
//DebugTN("Setting end", getThreadId(), dynlen(dpes), dpes, values);
			dpSetWait(dpes, values);
		}
/*
		if(dynlen(FwUi_MultiDPList))
		{
			dpSetWait(FwUi_MultiDPList, FwUi_MultiDPValues);
DebugN("**************** DPSet Multi",FwUi_MultiDPList, FwUi_MultiDPList, FwUi_MultiDPValues);
		}
*/
		dynClear(FwUi_MultiDPList);
		dynClear(FwUi_MultiDPValues);
		FwUi_ActOnMultiple = 0;
//DebugTN("StopActOnMulti end", getThreadId(), FwUi_ActOnMultiple);
	}
}

fwUi_disableDevice(string parent, string child, int permanent = 0, int fast = 0)
{
string obj, type, node, dev;
dyn_string items;
int i, pos;
//string cu, owner, id;
//int enabled;

	dev = child;
	node = fwUi_setEnabled(parent, child, permanent, fast);
//DebugTN("fwUi_disableDevice", parent, child, node);
 /* CG
	obj = parent+"::"+child;
	fwFsm_getObjectType(obj, type);
	if(type == "")
		return;
  if((pos = strpos(type,fwFsm_typeSeparator)) > 0)
	  type = substr(type, 0, pos);
//DebugN("Disable",parent, child, obj, type, node);
	child = fwFsm_capitalize(child);
	strreplace(child,fwDev_separator,":");
  items = strsplit(node,",");
  if(!dynlen(items))
    items[1] = "";
  for(i = 1; i <= dynlen(items); i++)
	  fwUi_sendCommand(parent, items[i]+type+"_FWDM","DISABLE/DEVICE(S)="+child);
*/
  if(fast)
    return;
	if(isFunctionDefined("fwFsmUser_nodeDisabled"))
		fwFsmUser_nodeDisabled(parent, dev);

}

fwUi_disableDevices(string parent, dyn_string children, dyn_int permanents)
{
string obj, type, node, child, cmd;
int i, j, index;
dyn_string parts, items;
dyn_string objs;
dyn_dyn_string devs;
int pos;


	fwUi_setEnableds(parent, children, permanents, parts);
//DebugTN("DisableDevices", parent, children, permanents, parts);
	for(i = 1; i <= dynlen(children); i++)
	{
		obj = parent+"::"+children[i];
		fwFsm_getObjectType(obj, type);
		if(type == "")
			continue;
   if((pos = strpos(type,fwFsm_typeSeparator)) > 0)
	   type = substr(type, 0, pos);
		child = fwFsm_capitalize(children[i]);
		strreplace(child,fwDev_separator,":");

   items = strsplit(parts[i],",");
   if(!dynlen(items))
     items[1] = "";
   for(j = 1; j <= dynlen(items); j++)
   {
		  if(!(index = dynContains(objs, items[j]+type)))
		  {
		  	index = dynAppend(objs, items[j]+type);
		  	devs[index] = makeDynString();
		  }
		  dynAppend(devs[index], child);
    }
//		fwUi_sendCommand(parent, parts[i]+type+"_FWDM","DISABLE/DEVICE(S)="+child);

	}
	for(i = 1; i <= dynlen(objs); i++)
	{
		obj = objs[i]+"_FWDM";
		cmd = "DISABLE/DEVICES(S)=";
		for(j = 1; j <= dynlen(devs[i]); j++)
		{
			cmd += devs[i][j];
			if(j != dynlen(devs[i]))
				cmd += "|";
		}
		fwUi_sendCommand(parent, obj, cmd);
//DebugN("******** Sending ", parent, obj, cmd);
	}
	for(i = 1; i <= dynlen(children); i++)
	{
		if(isFunctionDefined("fwFsmUser_nodeDisabled"))
			fwFsmUser_nodeDisabled(parent, children[i]);
	}
}

string fwUi_setEnableds(string domain, dyn_string objs, dyn_int enableds, dyn_string &parts)
{
	string dp, prefix;
	dyn_string exInfo, dps, part_dps;
	string tnode, parent, obj;
	int i;
	dyn_int values;

	parent = "";
	fwUi_getSysPrefix(domain, prefix);
	for(i = 1; i <= dynlen(objs); i++)
	{
		obj = fwFsm_convertAssociated(objs[i]);
		obj = fwFsm_convertAssociated(obj);
		dp = prefix+fwFsm_separator+obj;
//		dpGet(dp+".part",parts[i]);
		dynAppend(part_dps, dp+".part");
//		if(dpExists(dp))
//		{
//			dynAppend(dps, dp+".mode.enabled");
//			dynAppend(values, enableds[i]);
//		}
////		fwFsm_actOnSummaryAlarm(enabled, obj, domain, parent);
	}
//	dpSetWait(dps,values);
	if(dynlen(part_dps))
		dpGet(part_dps,parts);
	return parent;
}

fwUi_enableDevice(string parent, string child, int fast = 0)
{
string obj, type, node, dev;
dyn_string items;
int i, pos;

	dev = child;
	node = fwUi_setEnabled(parent, child, 1, fast);
/* CG
//DebugTN("fwUi_enableDevice", parent, child, node);
//DebugN("Enable", parent, child, node);
	obj = parent+"::"+child;
//DebugN("Enable", parent, child, node, obj, type);
	fwFsm_getObjectType(obj, type);
	if(type == "")
		return;
  if((pos = strpos(type,fwFsm_typeSeparator)) > 0)
	  type = substr(type, 0, pos);
	child = fwFsm_capitalize(child);
	strreplace(child,fwDev_separator,":");
  items = strsplit(node,",");
  if(!dynlen(items))
    items[1] = "";
  for(i = 1; i <= dynlen(items); i++)
	  fwUi_sendCommand(parent, items[i]+type+"_FWDM","ENABLE/DEVICE(S)="+child);
*/
  if(fast)
    return;
	if(isFunctionDefined("fwFsmUser_nodeEnabled"))
		fwFsmUser_nodeEnabled(parent, dev);

}

fwUi_sendDirectSmiCommand(string domain, string obj, string cmnd)
{
	string domain1, obj1, cmnd1;
	string dns_node, env;
	string str;

	domain1 = strtoupper(domain);
	obj1 = strtoupper(obj);
	cmnd1 = strtoupper(cmnd);
	dns_node = fwFsm_getDimDnsNode();
//	str = "\""+domain1+"::"+obj1+"\" \""+cmnd1+"\"";
	str = "\""+domain1+"::"+obj1+"\" \""+cmnd1+"\" -dns "+dns_node;
//	os = getenv("OSTYPE");
//	if(strpos(os,"linux") >= 0)
//		os = "Linux";
	if (os=="Linux")
	{
		env = "export LD_LIBRARY_PATH="+fwFsm_getFsmPath()+":"
			+"${LD_LIBRARY_PATH};";
//			+"export DIM_DNS_NODE="+dns_node+";";
		system(env+fwFsm_getFsmPath()+"/smi_send_command "+str);
	}
	else
	{
//		env = "SET DIM_DNS_NODE="+dns_node+"&&";
//		system("start /B cmd /c \""+env+fwFsm_getFsmPath()+"/bin/smi_send_command "+str);
//DebugN("******* smiSendCommand ", str);
		system("start /B "+fwFsm_getFsmPath()+"\\smi_send_command "+str);
	}
}
/*
int fwUi_sendTreeAction(string action, string domain, string obj, string id)
{
	int enabled;
	string modeObj, owner;

	domain = parent;
	modeObj = fwUi_getModeObj(domain, obj);
	fwUi_checkOwnership(modeObj, enabled, owner, id);

	if((enabled) && (action != ""))
		fwUi_sendCommand(domain, modeObj+"_FWM",action);
	return enabled;
}
*/

fwUi_shareTree(string parent, string child, string id = "", int doit = 1)
{
int enabled;
string cu, owner;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
	if(enabled == 2)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
			fwUi_sendCommand(parent, cu+"_FWM","SetMode/OWNER="+id+"/EXCLUSIVE=NO");
		else
			fwUi_actOnTree("Share", parent, cu, id);
	}
}

fwUi_exclusiveTree(string parent, string child, string id = "", int doit = 1)
{
int enabled;
string cu, owner;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
	if(enabled == 2)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
			fwUi_sendCommand(parent, cu+"_FWM","SetMode/OWNER="+id+"/EXCLUSIVE=YES");
		else
			fwUi_actOnTree("Exclusive", parent, cu, id);
	}
}

fwUi_includeTree(string parent, string child, string id = "", int doit = 1, int exclusive = 1, int lock = 0, bool actOnChildren = TRUE)
{
	int exclusive1;
	int enabled, ret;
	dyn_string dontreport;
	string cu, owner, excl, state, childState, lockstr;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
//DebugN("Including", parent, child, cu, enabled, doit);
	if(enabled)
	{
		state = fwUi_getCUMode(parent, child);
/*
		if((state == "Excluded")||(state == "LockedOut"))
		{
			childState = fwUi_getCUMode(cu, cu);
DebugN("Including", parent, child, state, childState, doit);
			if((childState == "Manual") || (childState == "Included"))
			{
				fwUi_sendCommand(cu, cu+"_FWM","Exclude");
//				fwUi_report("*** WARNING - Can not Include: "+cu+" is in "+childState+" mode", "", 3);
				return;
			}
		}
*/
		if(doit)
		{
//			if(state != "LockedOut")
//			{
				if(id == "")
					id = fwUi_getUiId();
				fwUi_getExclusivity(parent, exclusive1);
				if(exclusive1)
					excl = "/EXCLUSIVE=YES";
				else
					excl = "/EXCLUSIVE=NO";
				if((lock) && ((state == "LockedOut")||(state == "LockedOutPerm")))
				{
// CG					lockstr = "UnLockOut&"; //was 0 below
					fwUi_setLockedOut(parent, child, 0);
				}
				if((lock) || ((state != "LockedOut")&&(state != "LockedOutPerm")))
				{
					if(isFunctionDefined("fwFsmUser_preNodeIncluded"))
						dontreport = fwFsmUser_preNodeIncluded(parent, fwFsm_getAssociatedObj(child));
				}
        if(actOnChildren)
				  fwUi_actOnObjectChildren("Include",parent, cu, id, exclusive, dontreport, 1);
				fwUi_sendCommand(parent, cu+"_FWM",lockstr+"Include/OWNER="+id+excl);
				if((lock) || ((state != "LockedOut")&&(state != "LockedOutPerm")))
				{
					if(isFunctionDefined("fwFsmUser_nodeIncluded"))
					{
//DebugTN("Calling nodeIncluded", parent, fwFsm_getAssociatedObj(child));
						fwFsmUser_nodeIncluded(parent, fwFsm_getAssociatedObj(child));
					}
				}
//			}
		}
		else
		{
			if(id != "")
			{
				ret = fwUi_actOnTree("Include", parent, cu, id, exclusive);
				if(ret && (isFunctionDefined("fwFsmUser_nodeIncludedRec")))
				{
					if(parent != fwFsm_getAssociatedObj(child))
						fwFsmUser_nodeIncludedRec(parent, fwFsm_getAssociatedObj(child));
				}
			}
		}
//DebugN("Including", parent, child);
	}
}

int fwUi_takeTree(string parent, string child, string id = "", int doit = 1, int exclusive = 1, bool actOnChildren = TRUE)
{
	int enabled, ret;
	string cu, owner, excl;
	bit32 bits;
	dyn_string dontreport;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
//	if(enabled == 1)
	if(enabled >= 1)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
		{
			if(isFunctionDefined("fwFsmUser_preNodeTaken"))
				dontreport = fwFsmUser_preNodeTaken(cu);
			fwUi_getExclusivity(parent, exclusive);
			if(exclusive)
				excl = "/EXCLUSIVE=YES";
			else
				excl = "/EXCLUSIVE=NO";
			fwUi_setManagerIdInfo(id);
      fwUi_addManagerIdNodeTaken(id,parent);
      if(actOnChildren)
			  fwUi_actOnObjectChildren("Take",parent, cu, id, exclusive, dontreport, 1);
			fwUi_sendCommand(parent, cu+"_FWM","Take/OWNER="+id+excl);
//DebugN("Taking tree", cu, enabled, owner, id);
			if(isFunctionDefined("fwFsmUser_nodeTaken"))
				fwFsmUser_nodeTaken(cu);
		}
		else
		{
			ret = fwUi_actOnTree("Take",parent, cu, id, exclusive);
//			if(ret && (isFunctionDefined("fwFsmUser_nodeTakenRec")))
//				fwFsmUser_nodeTakenRec(parent, fwFsm_getAssociatedObj(child));
		}
		return 1;
	}
	return 0;
}

int fwUi_releaseTree(string parent, string child, string id = "", int doit = 1)
{
	int enabled, ret;
	string cu, owner, state;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);

	if(enabled == 2)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
		{
			state = fwUi_getCUMode(parent, child);
			if((state == "InLocal") || (state == "InManual"))
			{
        fwUi_removeManagerIdNodeTaken(id,parent);
				fwUi_sendCommand(parent, cu+"_FWM","Release/OWNER="+id);
//				fwUi_actOnObjectChildren("Release",parent, cu, id);
				if(isFunctionDefined("fwFsmUser_nodeReleased"))
					fwFsmUser_nodeReleased(cu);
			}
		}
		else
		{
			ret = fwUi_actOnTree("Release", parent, cu, id);
//			if(ret && (isFunctionDefined("fwFsmUser_nodeReleasedRec")))
//				fwFsmUser_nodeReleasedRec(parent, fwFsm_getAssociatedObj(child));
		}
		return 1;
	}
	return 0;
}

int fwUi_releaseTreeAll(string parent, string child, string id = "", int doit = 1)
{
	int enabled, ret;
	string cu, owner, state;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
	if(enabled == 2)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
		{
			state = fwUi_getCUMode(parent, child);
			if((state == "InLocal") /*|| (state == "InManual")*/)
			{
      fwUi_removeManagerIdNodeTaken(id,parent);
				fwUi_sendCommand(parent, cu+"_FWM","ReleaseAll/OWNER="+id);
//				fwUi_actOnObjectChildren("Release",parent, cu, id);
				if(isFunctionDefined("fwFsmUser_nodeReleasedAll"))
					fwFsmUser_nodeReleasedAll(cu);
			}
		}
		else
		{
			ret = fwUi_actOnTree("Release", parent, cu, id);
//			if(ret && (isFunctionDefined("fwFsmUser_nodeReleasedAllRec")))
//				fwFsmUser_nodeReleasedAllRec(parent, fwFsm_getAssociatedObj(child));
		}
		return 1;
	}
	return 0;
}

fwUi_excludeTree(string parent, string child, string id = "", int doit = 1, int lock = 0)
{
	int enabled, ret;
	string cu, owner, state, lockstr;

	cu = fwUi_getModeObj(parent, child);
//	fwUi_checkOwnership(cu, enabled, owner, id);
	fwUi_checkOwnership(parent, enabled, owner, id);
	if(id == "")
		id = fwUi_getUiId();
	state = fwUi_getCUMode(parent, child);
	if(state == "Manual")
		enabled = 1;
//DebugN("ExcludeTree", parent, child, cu, enabled, id, doit, state, lock);
	if(doit)
	{
		if(enabled)
		{
			lockstr = "Exclude";
// CG new
 			fwUi_sendCommand(parent, cu+"_FWM",lockstr+"/OWNER="+id);
			if(lock)
			{
/* CG
				lockstr += "&LockOut";
				if((state == "LockedOut")||(state == "LockedOutPerm"))
					lockstr = "LockOut";
*/
				fwUi_setLockedOut(parent, child, 1);
			}
// CG			fwUi_sendCommand(parent, cu+"_FWM",lockstr+"/OWNER="+id);
//			fwUi_actOnObjectChildren("Exclude",parent, cu, id);
//			if((state != "Excluded") && (state != "ExcludedPerm"))
//			{
				if(isFunctionDefined("fwFsmUser_nodeExcluded"))
					fwFsmUser_nodeExcluded(parent, fwFsm_getAssociatedObj(child));
//			}
		}
	}
	else
	{
//		if(enabled == 2)
		if(enabled)
		{
			ret = fwUi_actOnTree("Release", parent, cu, id);
			if(ret && (isFunctionDefined("fwFsmUser_nodeExcludedRec")))
			{
				if(parent != fwFsm_getAssociatedObj(child))
					fwFsmUser_nodeExcludedRec(parent, fwFsm_getAssociatedObj(child));
			}
		}
//DebugN("Excluding", parent, child);
	}
}

fwUi_excludeTreePerm(string parent, string child, string id = "", int doit = 1, int lock = 0)
{
	int enabled, ret;
	string cu, owner, state;

	cu = fwUi_getModeObj(parent, child);
//	fwUi_checkOwnership(cu, enabled, owner, id);
	fwUi_checkOwnership(parent, enabled, owner, id);
	if(id == "")
		id = fwUi_getUiId();
	state = fwUi_getCUMode(parent, child);
	if(state == "Manual")
		enabled = 1;
	if(doit)
	{
		if(enabled)
		{
			if(lock)
			{
/* CG
				fwUi_setLockedOut(parent, child, 2);
				fwUi_sendCommand(parent, cu+"_FWM","Exclude&LockOut/OWNER="+id);
				fwUi_sendCommand(parent, cu+"_FWM","LockOutPerm");
*/
				fwUi_sendCommand(parent, cu+"_FWM","Exclude/OWNER="+id);
				fwUi_setLockedOut(parent, child, 2);
			}
			else
      {
				fwUi_sendCommand(parent, cu+"_FWM","ExcludePerm/OWNER="+id);
//			fwUi_actOnObjectChildren("Exclude",parent, cu, id);
//			if((state != "Excluded") && (state != "ExcludedPerm"))
//			{
				if(isFunctionDefined("fwFsmUser_nodeExcluded"))
					fwFsmUser_nodeExcluded(parent, fwFsm_getAssociatedObj(child));
//			}
      }
		}
	}
	else
	{
//		if(enabled == 2)
		if(enabled)
		{
			ret = fwUi_actOnTree("Release", parent, cu, id);
			if(ret && (isFunctionDefined("fwFsmUser_nodeExcludedRec")))
			{
				if(parent != fwFsm_getAssociatedObj(child))
					fwFsmUser_nodeExcludedRec(parent, fwFsm_getAssociatedObj(child));
			}
		}
//DebugN("Excluding", parent, child);
	}
}

int fwUi_excludeChildren(string parent, string child, string id = "", int doit = 1)
{
	int i, enabled, done = 0;
	string cu, owner;
	dyn_string children;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
	if(id == "")
		id = fwUi_getUiId();
	if(doit)
	{
		if(enabled)
		{
			fwUi_getChildren(cu, children);
			for(i = 1; i <= dynlen(children); i++)
			{
//				fwUi_sendCommand(cu, children[i]+"_FWM","Exclude/OWNER="+id);
				fwUi_sendCommand(cu, children[i]+"::"+children[i]+"_FWM","Exclude/OWNER="+id);
//				fwUi_sendCommand(children[i], children[i]+"_FWM","Exclude/OWNER="+id);
			}
			done = dynlen(children);
		}
	}
	else
	{
		if(enabled == 2)
		{
			fwUi_actOnTree("Release", parent, cu, id);
		}
	}
	return done;
}

fwUi_excludeTreeAll(string parent, string child, string id = "", int doit = 1)
{
	int enabled, ret;
	string cu, owner;

	cu = fwUi_getModeObj(parent, child);
//	fwUi_checkOwnership(cu, enabled, owner, id);
	fwUi_checkOwnership(parent, enabled, owner, id);
	if(id == "")
		id = fwUi_getUiId();
	if(doit)
	{
		if(enabled)
		{
			fwUi_sendCommand(parent, cu+"_FWM","ExcludeAll/OWNER="+id);
//			fwUi_actOnObjectChildren("Exclude",parent, cu, id);
			if(isFunctionDefined("fwFsmUser_nodeExcludedAll"))
				fwFsmUser_nodeExcludedAll(parent, fwFsm_getAssociatedObj(child));
		}
	}
	else
	{
		if(enabled == 2)
		{
			ret = fwUi_actOnTree("Release", parent, cu, id);
			if(ret && (isFunctionDefined("fwFsmUser_nodeExcludedAllRec")))
			{
				if(parent != fwFsm_getAssociatedObj(child))
					fwFsmUser_nodeExcludedAllRec(parent, fwFsm_getAssociatedObj(child));
			}
		}
	}
}

fwUi_delegateTree(string parent, string child, string id = "", int doit = 1)
{
	int enabled, ret;
	string cu, owner, state;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
//DebugN("delegate", parent, child, enabled, owner, id, doit);
	if(enabled == 2)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
		{
			fwUi_sendCommand(parent, cu+"_FWM","Manual/OWNER="+id);
//			fwUi_actOnObjectChildren("Delegate",parent, cu, id);
			if(isFunctionDefined("fwFsmUser_nodeDelegated"))
				fwFsmUser_nodeDelegated(parent, fwFsm_getAssociatedObj(child));
		}
		else
		{
			state = fwUi_getCUMode(parent, child);
//DebugN("delegate", parent, child, cu, state);
			if(state != "Excluded")
			{
				ret = fwUi_actOnTree("Delegate", parent, cu, id);
//				if(ret && (isFunctionDefined("fwFsmUser_nodeDelegatedRec")))
//					fwFsmUser_nodeDelegatedRec(parent, fwFsm_getAssociatedObj(child));
			}
		}
	}
}

fwUi_ignoreTree(string parent, string child, string id = "", int doit = 1)
{
	int enabled, ret;
	string cu, owner;

	cu = fwUi_getModeObj(parent, child);
	fwUi_checkOwnership(cu, enabled, owner, id);
	if(enabled == 2)
	{
		if(id == "")
			id = fwUi_getUiId();
		if(doit)
		{
			fwUi_sendCommand(parent, cu+"_FWM","Ignore/OWNER="+id);
			if(isFunctionDefined("fwFsmUser_nodeIgnored"))
				fwFsmUser_nodeIgnored(parent, fwFsm_getAssociatedObj(child));
		}
		else
		{
			ret = fwUi_actOnTree("Ignore", parent, cu, id);
//			if(ret && (isFunctionDefined("fwFsmUser_nodeIgnoredRec")))
//				fwFsmUser_nodeIgnoredRec(parent, fwFsm_getAssociatedObj(child));
		}
	}
}

fwUi_lockOutTree(string parent, string child, string id = "", int doit = 1)
{
	int enabled;
	string cu, owner;

	cu = fwUi_getModeObj(parent, child);
//	fwUi_checkOwnership(cu, enabled, owner, id);
	fwUi_checkOwnership(parent, enabled, owner, id);
//DebugN("received: ",parent, child, cu+"_FWM","LockOut", doit);
	if(enabled)
	{
// CG		fwUi_sendCommand(parent, cu+"_FWM","LockOut");
//		fwUi_actOnTree("LockOut", parent, cu, id);
		fwUi_setLockedOut(parent, child, 1);
	}
}

fwUi_lockOutTreePerm(string parent, string child, string id = "", int doit = 1)
{
	int enabled;
	string cu, owner;

	cu = fwUi_getModeObj(parent, child);
////	fwUi_checkOwnership(cu, enabled, owner, id);
//	fwUi_checkOwnership(parent, enabled, owner, id);
////DebugN("received: ",parent, child, cu+"_FWM","LockOut", doit);
//	if(enabled)
//	{
// CG		fwUi_sendCommand(parent, cu+"_FWM","LockOutPerm");
//		fwUi_actOnTree("LockOut", parent, cu, id);
		fwUi_setLockedOut(parent, child, 2);
//	}
}

fwUi_unLockOutTree(string parent, string child, string id = "", int doit = 1)
{
	int enabled;
	string cu, owner;

	cu = fwUi_getModeObj(parent, child);
//	fwUi_checkOwnership(cu, enabled, owner, id);
	fwUi_checkOwnership(parent, enabled, owner, id);
//DebugN("received: ",parent, child, cu+"_FWM","UnLockOut", doit);
	if(enabled)
	{
// CG		fwUi_sendCommand(parent, cu+"_FWM","UnLockOut");
//		fwUi_actOnTree("UnLockOut", parent, cu, id);
		fwUi_setLockedOut(parent, child, 0);
	}
}

fwUi_getOwnership(string child, string &id)
{
	string dp;

	child = fwFsm_getAssociatedObj(child);
	fwUi_getDomainPrefix(child, dp);
	dpGet(dp+".mode.owner:_online.._value",id);
}

fwUi_checkOwnership(string child, int &enabled, string &owner, string id = "")
{
	string itsid, dp, sys;

	if(id == "")
		itsid = fwUi_getGlobalUiId();
	else
		itsid = id;
	child = fwFsm_getAssociatedObj(child);
	fwUi_getDomainPrefix(child, dp);
	if(dpExists(dp))
		dpGet(dp+".mode.owner:_online.._value",owner);
	if(owner == "")
		enabled = 1;
	else if(owner == itsid)
		enabled = 2;
	else enabled = 0;
//DebugTN("CheckOwnership",child, id, itsid, dp, owner, enabled, getStackTrace());
}

// In fwFsmBasics
/*
int fwUi_checkOwnershipMode(string owner, string id = "")
{
	string itsid;
	int enabled;

	if(id == "")
		itsid = fwUi_getUiId();
	else
		itsid = id;
	if(owner == "")
		enabled = 1;
	else if(owner == itsid)
		enabled = 2;
	else enabled = 0;
	return enabled;
}
*/

fwUi_report(string msg, string node = "", int severity = 1)
{
time t;
string str, dp;
int count;

//	os = getenv("OSTYPE");
//	if(strpos(os,"linux") >= 0)
//		os = "Linux";
	t = getCurrentTime();
	str = formatTime("%d-%b-%Y %H:%M:%S",t);
	str += " - "+msg;
//DebugTN(getStackTrace());
DebugN("Reporting "+str);
  if(node != "")
  {
	  fwUi_getDomainPrefix(node, dp);
    if(dpExists(dp+".message"))
			dpSet(dp+".message", str);
    if((isFunctionDefined("setValue")) && (shapeExists("Message")))
      setValue("Message","appendItem",str);
  }
	else if( (isFunctionDefined("setValue")) && (shapeExists("MessageNew")) )
	{
		int count;
		string color;
		MessageNew.appendLine("#1",str);
  		count = MessageNew.lineCount;
		if(severity == 4)
			color = "FwStateAttention3";
 		if(severity == 3)
			color = "FwStateAttention2";
 		if(severity == 2)
			color = "FwStateAttention1";
    if(strpos(msg,"*** INFO -") >= 0)
      color = "FwStateAttention2";
    else if(strpos(msg,"*** WARNING -") >= 0)
      color = "{255,81,12}";
    else if(strpos(msg,"*** ERROR -") >= 0)
      color = "FwStateAttention3";
    MessageNew.cellForeColRC(count-1,"#1",color);
    if(shapeExists("Message"))
     setValue("Message","appendItem",str);
	}
	else if( (isFunctionDefined("setValue")) && (shapeExists("Message")) )
	{
		setValue("Message","appendItem",str);
		getValue("Message","itemCount",count);
		if (os=="Linux")
			setValue("Message","bottomPos",count);
		else
			setValue("Message","topPos",count - 1);
	}
/*
	if( (isFunctionDefined("setValue")) && (shapeExists("MessageNew")) )
	{
		int count;
		string color;
		MessageNew.appendLine("#1",str);
  		count = MessageNew.lineCount;
		if(severity == 4)
			color = "FwStateAttention3";
 		if(severity == 3)
			color = "FwStateAttention2";
 		if(severity == 2)
			color = "FwStateAttention1";
  if(strpos(msg,"*** INFO -") >= 0)
    color = "FwStateAttention2";
  else if(strpos(msg,"*** WARNING -") >= 0)
    color = "{255,81,12}";
  else if(strpos(msg,"*** ERROR -") >= 0)
    color = "FwStateAttention3";
   MessageNew.cellForeColRC(count-1,"#1",color);
	}
	else if( (isFunctionDefined("setValue")) && (shapeExists("Message")) )
	{
		setValue("Message","appendItem",str);
		getValue("Message","itemCount",count);
		if (os=="Linux")
			setValue("Message","bottomPos",count);
		else
			setValue("Message","topPos",count - 1);
	}
	else
	{
		if(node != "")
		{
			fwUi_getDomainPrefix(node, dp);
     			if(dpExists(dp+".message"))
			  dpSet(dp+".message", str);
		}
	}
*/
}
/*
int fwUi_isModeObj(string domain, string obj, string & cu)
{
	int pos;

	if(fwFsm_isAssociated(obj))
		cu = fwFsm_getAssociatedDomain(obj);
	else
	{
		if((pos = strpos(obj,"_FWM")) >= 1)
			cu = substr(obj, 0, pos);
		else
			cu = domain;
	}
	if((pos = strpos(obj,"_FW")) >= 1)
		return 1;
	return 0;
}
*/
fwUi_convertObjState(string domain, string obj, string &state)
{
	int pos, free;
	string alloc;
	string cu;

//	if(fwUi_isModeObj(domain, obj, cu))
//	{
		switch(state)
		{
			case "INCLUDED":
				state = "Included";
				break;
			case "EXCLUDED":
				state = "Excluded";
				break;
			case "EXCLUDEDPERM":
				state = "ExcludedPerm";
				break;
			case "INLOCAL":
				state = "InLocal";
				break;
			case "MANUAL":
				state = "Manual";
				break;
			case "INMANUAL":
				state = "InManual";
				break;
			case "IGNORED":
				state = "Ignored";
				break;
			case "LOCKEDOUT":
				state = "LockedOut";
				break;
			case "LOCKEDOUTPERM":
				state = "LockedOutPerm";
				break;
			case "COMPLETE":
				state = "Complete";
				break;
			case "INCOMPLETE":
				state = "Incomplete";
				break;
			default:
				break;
		}
//	}
}
/*
fwUi_convertObjAction(string domain, string obj, string & action)
{
	int pos;
	string cu;

	if(fwUi_isModeObj(domain, obj, cu))
	{
		switch(action)
		{
			case "Exclude":
				fwUi_delegateTree(domain, cu);
				break;
//			case "Delegate":
//				break;
			case "Take":
				fwUi_takeTree(domain, cu);
				break;
			case "Release":
				fwUi_releaseTree(domain, cu);
				break;
			case "Manual":
//				fwUi_disableTree(domain, cu);
				fwUi_delegateTree(domain, cu);
				break;
			case "Ignore":
				fwUi_ignoreTree(domain, cu);
				break;
			case "Include":
				fwUi_includeTree(domain, cu);
				break;
			default:
				break;
		}
	}
}
*/
fwUi_getExclusivity(string child, int & flag)
{
	string cu, dp, sys;

	cu = fwFsm_getAssociatedObj(child);
	fwUi_getDomainPrefix(cu, dp);
//DebugN("getExclusivity", child, cu, dp);
	dpGet(dp+".mode.exclusivity:_online.._value",flag);
}

fwUi_getOwnerExclusivity(string domain, string obj, int & exclusive, int & enabled)
{
	string cu, owner, sys;

//	fwUi_isModeObj(domain, obj, cu);
	cu = fwUi_getModeObj(domain, obj);
	fwUi_checkOwnership(cu, enabled, owner);
	fwUi_getExclusivity(cu, exclusive);
}


int fwUi_connectOwnerExclusivity(string rout, string domain, string obj)
{
	string dp, cu, sys;
	int pos, ret;

//	fwUi_isModeObj(domain, obj, cu);
	cu = fwUi_getModeObj(domain, obj);
	fwUi_getDomainPrefix(cu, dp);
//	if(!dpExists(dp))
//		return -1;
	while(!dpExists(dp))
		delay(5);
	ret = dpConnect(rout, dp+".mode.owner:_online.._value",
		dp+".mode.exclusivity:_online.._value");
	return ret;
}

synchronized fwUi_externalTreeOwnership(string action, string parent, string domain, string owner, int exclusive)
{
dyn_string children;
int i, flag;
string curr_owner, dp;

	action = fwFsm_capitalize(action);
//DebugN("************** Received external Action", action, domain, parent, owner, exclusive);
	switch(action)
	{
		case "EXCLUDE":
			fwUi_excludeTree(parent, domain, owner, 0);
			break;
		case "EXCLUDEPERM":
			fwUi_excludeTree(parent, domain, owner, 0);
			break;
		case "EXCLUDEALL":
			fwUi_excludeTreeAll(parent, domain, owner, 0);
			break;
		case "EXCLUDE&LOCKOUT":
			fwUi_excludeTree(parent, domain, owner, 0);
			break;
		case "TAKE":
			fwUi_takeTree(parent, domain, owner, 0, exclusive);
			break;
		case "RELEASE":
			fwUi_releaseTree(parent, domain, owner, 0);
			break;
		case "RELEASEALL":
			fwUi_releaseTreeAll(parent, domain, owner, 0);
			break;
		case "MANUAL":
			fwUi_delegateTree(parent, domain, owner, 0);
			break;
		case "IGNORE":
			fwUi_ignoreTree(parent, domain, owner, 0);
			break;
		case "INCLUDE":
			fwUi_includeTree(parent, domain, owner, 0, exclusive);
			break;
		case "UNLOCKOUT&INCLUDE":
			fwUi_includeTree(parent, domain, owner, 0, exclusive);
			break;
		case "FREE":
			fwUi_delegateTree(parent, domain, owner, 0);
			break;
		case "SETMODE":
			if(exclusive == 1)
				fwUi_exclusiveTree(parent, domain, owner, 0);
			else if(exclusive == 0)
				fwUi_shareTree(parent, domain, owner, 0);
			break;
/*
		case "LOCKOUT":
			fwUi_lockOutTree(parent, domain, owner, 0);
			break;
		case "UNLOCKOUT":
			fwUi_unLockOutTree(parent, domain, owner, 0);
			break;
*/
		default:
			break;
	}
}

int fwUi_getDomainPid(string domain)
{
//	dyn_string in, out;
//	int ret;

//	in = makeDynString(domain);
//	out = makeDynString("");
//	ret = userDefFunc("FwUi","fwUiGetPid",in,out);
//	return out[1];
	return fwUiGetPid(domain);
}

fwUi_restartDomain(string domain)
{
	int pid;

	pid = fwUi_getDomainPid(domain);
	system("kill "+pid);
DebugN("Killing",pid);
	delay(1);
	system("start smiSM "+domain+" smi/"+domain);
}

fwUi_closeFsmObject(string domain, string obj)
{
  string id;
  int doit = 1;
/*
DebugTN("Closing panel, checking", FwFSM_CloseFunction);
  if(FwFSM_CloseFunction != "")
  {
//    if(isFunctionDefined(FwFSM_CloseFunction))
      invokeMethod("specific", FwFSM_CloseFunction);
//      execScript("int main()"
//         + "{"
//         + FwFSM_CloseFunction+"();"
//         + "}",
//         makeDynString("$1:"+$1, "$2:"+$2) );
    DebugN( "end close" );
  }
*/
//DebugTN("Closing panel, checking", isFunctionDefined("fwFsmUser_close"));
  if(shapeExists("specific"))
    if(hasMethod("specific", "fwFsmUser_close"))
      invokeMethod("specific", "fwFsmUser_close");
  if(isFunctionDefined("fwFsmUser_closeOperationPanel"))
    doit = fwFsmUser_closeOperationPanel(domain, obj);

  if(!doit)
    return;
  if(domain == obj)
  {
    id = fwUi_getUiId();
    fwUi_releaseTree(domain, obj, id);
  }
  if(isModuleOpen(obj))
    ModuleOff(obj);
  else
    PanelOff();
}

fwUi_setPanelSize(string domain, string obj)
{
	dyn_int size, main_size;
	int x, y;
  int lenx, leny;
	int neww,newl, oldw, oldl;

  fwUi_getModuleSize(domain, obj, x, y, 0);
//DebugTN("Got Module size", domain);

	main_size = fwFsm_getMainPanelSize();
	if(main_size[1] == 0)
	{
		lenx = x;
		leny = y;
	}
	else
	{
		lenx = main_size[1];
		leny = main_size[2];
	}
  neww = lenx;
  newl = leny;
//DebugTN("Changed panel size", domain, obj, w, l, neww, newl);
//	fwUi_changePanelSize(panel, w, l, neww, newl);
  panelSize("", oldw, oldl);
//DebugTN("Set panel size", domain, obj, neww, newl, oldw, oldl);
  if((oldw != neww) || (oldl != newl))
    setPanelSize(myModuleName(), myPanelName(), 0, neww, newl);
  moduleOriginalSize();
}

int fwUi_showFsmObject(string domain, string obj, string parent = "", int posx = -1, int posy = -1,
	int posx_offset = 100, int posy_offset = 70)
{
	string panel;
	dyn_int size, main_size;
	int x, y;
  int lenx, leny, px, py;
	string w,l,neww,newl, physobj;
//DebugTN("Preparing panel", domain);
	fwUi_getPanel(domain, obj, panel);
//DebugN("Panel", domain, obj, panel);
/* CG
	size = _PanelSize(panel);
//DebugN(panel, size);
	x = size[1];
	y = size[2];
	w = x;
	l = y;

	fwUi_getModuleSize(domain, obj, x, y);
//DebugTN("Got Module size", domain);

	main_size = fwFsm_getMainPanelSize();
	if(main_size[1] == 0)
	{
		lenx = x;
		leny = y;
	}
	else
	{
		lenx = main_size[1];
		leny = main_size[2];
	}
  {
    string type;

    fwCU_getType(obj, type);
    if(type == "ECS_Domain_v1")
      leny += 30;
  }
  neww = lenx;
  newl = leny;
	fwUi_changePanelSize(panel, w, l, neww, newl);
*/

//  fwUi_setPanelSize(domain, obj);
	fwUi_getModuleSize(domain, obj, x, y);
//DebugTN("ModuleSize",domain, obj, x, y);
  if((posx == -1) || (posy == -1))
	{
//		if(parent == "")
//		{
//			posx = 0;
//			posy = 0;
//		}
//		else
//		{
      px = posx;
      py = posy;
			panelPosition(myModuleName(), "", posx, posy);
//		}
      if(px != -1)
        posx = px;
      if(py != -1)
        posy = py;
		if(posx < 0)
			posx = 0;
		if(posy < 0)
			posy = 0;
    if(py == -1)
    {
		  posx += posx_offset;
		  posy += posy_offset;
    }
	}
	fwUi_setTopDomain(domain, obj, parent);
	if(isModuleOpen(obj))
	{
//DebugTN("ModuleOpen", domain, obj, parent);
   		if((domain == obj) && (domain == parent))
   		{
     			fwUi_closeFsmObject(domain, obj);
     			return -1;
   		}
		ModuleOff(obj);
		delay(0,100);
	}
//DebugTN("Started Opening", domain, obj, parent, posx, posy, x, y);
	ModuleOnWithPanel(obj,posx,posy,x,y,1,1,"None",
		panel,fwUi_getUiId(),
		makeDynString("$node:"+domain,"$obj:"+obj));
//DebugTN("Finished Opening", domain, obj);
/* try...
	ChildPanelOn(panel,obj+":"+fwUi_getUiId(),
		makeDynString("$node:"+domain,"$obj:"+obj), posx, posy);
*/
  return y;
}

fwUi_setTopDomain(string domain, string obj, string parent)
{
	int index = 0, index1;

	if(!globalExists("FwFsm_TopDomains"))
	{
  		addGlobal("FwFsm_TopDomains",DYN_STRING_VAR);
  		addGlobal("FwFsm_TopDomainNodePointers",DYN_STRING_VAR);
  		addGlobal("FwFsm_TopDomainIndexPointers",DYN_INT_VAR);
	}
	if( parent == domain)
		parent = "";
	else if(!dynContains(FwFsm_TopDomainNodePointers, parent))
		parent = "";
	if(parent == "")
	{
		if(!(index = dynContains(FwFsm_TopDomains, domain)))
			index = dynAppend(FwFsm_TopDomains, domain);
		if(!(index1 = dynContains(FwFsm_TopDomainNodePointers, domain)))
		{
			dynAppend(FwFsm_TopDomainNodePointers, domain);
			dynAppend(FwFsm_TopDomainIndexPointers, index);
		}
		else
			FwFsm_TopDomainIndexPointers[index1] = index;
	}
	else
	{
		index1 = dynContains(FwFsm_TopDomainNodePointers, parent);
		index = FwFsm_TopDomainIndexPointers[index1];
		if(!(index1 = dynContains(FwFsm_TopDomainNodePointers, domain)))
		{
			dynAppend(FwFsm_TopDomainNodePointers, domain);
			dynAppend(FwFsm_TopDomainIndexPointers, index);
		}
		else
			FwFsm_TopDomainIndexPointers[index1] = index;
	}
}


string fwUi_getTopDomain(string domain, string obj)
{
int index, index1;


	if(!globalExists("FwFsm_TopDomains"))
		return domain;
	index1 = dynContains(FwFsm_TopDomainNodePointers, domain);
	if(index1)
	{
		index = FwFsm_TopDomainIndexPointers[index1];
		return FwFsm_TopDomains[index];
	}
	else
		return domain;
}


fwUi_removeNotVisibleChildrenFlags(string domain, dyn_string &children, dyn_int &flags)
{
	int i, visible;

	for(i = 1; i <= dynlen(children); i++)
	{
		fwUi_getVisibility(domain, children[i], visible);
		if(!visible)
		{
			dynRemove(children, i);
			dynRemove(flags, i);
			i--;
		}
	}
}

fwUi_removeNotVisibleChildren(string domain, dyn_string &children)
{
	int i, visible;

	for(i = 1; i <= dynlen(children); i++)
	{
		fwUi_getVisibility(domain, children[i], visible);
		if(!visible)
		{
			dynRemove(children, i);
			i--;
		}
	}
}

fwUi_getModuleSize(string node, string obj, int &x, int &y,
                   int getInfoFlag = 1)
{
	string panel, panel_path;
	dyn_int size;
	dyn_string files, children, children1;
	dyn_string nodes;
	dyn_int flags, flags1;
	int xpanel, ypanel;
	int i, visible, count, ychildren = 0;
//	int MIN_WIDTH = 588;
//	int MIN_HEIGHT = 377;
	int MIN_WIDTH = 750;
	int MIN_HEIGHT = 400;

	x = 0;
	xpanel = 0;
	y = 0;
	ypanel = 0;
	fwUi_getUserPanel(node, obj, panel);
	count = 0;
	dynAppend(nodes, node);
	dynAppend(nodes, obj);
/*
	if(fwFsm_isDomain(obj))
	{
//		fwUi_getChildren(obj, children);
		children = fwFsmUi_getChildrenCUs(obj);
		count = dynlen(children);
//		for(i = 1; i <= dynlen(children); i++)
//			children[i] = children[i]+"::"+children[i];
DebugN("***",children);
		dynAppend(nodes, children);
//		children = fwFsm_getDomainLogicalObjects(obj);
		children = fwFsmUi_getChildrenObjs(obj);
DebugN("getting size Objs",children);
		count += dynlen(children);
		dynAppend(nodes, children);
//		children = fwFsm_getDomainDevices(obj);
		children = fwFsmUi_getChildrenDUs(obj);
DebugN("getting size DUs",children);
		for(i = 1; i <= dynlen(children); i++)
		{
			if(children[i] == obj)
			{
				dynRemove(children, i);
				i--;
				continue;
			}
			fwUi_getVisibility(obj, children[i], visible);
			if(!visible)
			{
				dynRemove(children, i);
				i--;
			}
		}
		count += dynlen(children);
		dynAppend(nodes, children);
	}
	else
	{
		children = fwFsmUi_getChildrenDUs(node, obj);
DebugN("getting size DUs",children);
		for(i = 1; i <= dynlen(children); i++)
		{
			if(children[i] == obj)
			{
				dynRemove(children, i);
				i--;
				continue;
			}
			fwUi_getVisibility(node, children[i], visible);
			if(!visible)
			{
				dynRemove(children, i);
				i--;
			}
		}
		count += dynlen(children);
		dynAppend(nodes, children);
	}
*/
//	children = fwFsm_getLogicalUnitChildren(node, obj);
//	fwUi_removeNotVisibleChildren(node, children);
//	count += dynlen(children);
//	dynAppend(nodes, children);
	children = fwFsm_getObjChildren(node, obj, flags);
	fwUi_removeNotVisibleChildrenFlags(node, children, flags);
	count += dynlen(children);
  if(getInfoFlag)
  {
	  children1 = children;
	  dynAppend(nodes, children1);
	  for(i=1; i <=dynlen(children);i++)
	  {
	  	if(flags[i] == 0)
	  	{
	  		children1 = fwFsm_getObjChildren(node, children[i], flags1);
	  		dynAppend(nodes, children1);
	  	}
	  }
//DebugTN("GettingDisplayInfo", dynlen(nodes));
	  fwUi_getDisplayInfo(nodes);
  }
	if(count)
	{
		ychildren = 20 + (count * 28);
		if( ychildren > y)
			y = ychildren;
		y += 80+100;
	}
	if(panel != "")
	{
		panel_path = fwUi_getPanelPath(panel);
/*
		files = getFileNames(PROJ_PATH+"panels/fwFSMuser",panel);
		if(dynlen(files))
			panel_path = "fwFSMuser/"+panel;
		else
			panel_path = panel;
*/
		if(panel_path == "")
			panel_path = panel;
// obsolete
//		size = _PanelSize(panel_path);
    if(getPath(PANELS_REL_PATH,panel_path) != "")
		  size = getPanelSize(panel_path);
    else
    {
      size[1] = 0;
      size[2] = 0;
    }
//DebugTN("panel path", panel_path, size);
		xpanel = size[1];
		ypanel = size[2];
		ypanel += 100+100;
		if(count)
			xpanel += 360 + 10;
		else
			xpanel += 10 + 10;
	}
	if( xpanel > x )
		x = xpanel;
	if( ypanel > y )
		y = ypanel;
	if(x < MIN_WIDTH)
		x = MIN_WIDTH;
	if(y < MIN_HEIGHT)
		y = MIN_HEIGHT;
  else
  {
    string type;

    fwCU_getType(obj, type);
    if(type == "ECS_Domain_v1")
      y += 30;
  }
}

string fwUi_getPanelPath(string panel)
{
	string panel_path;

	panel_path = "";
	if(getPath(PANELS_REL_PATH,"fwFSMuser/"+panel) != "")
		panel_path = "fwFSMuser/"+panel;
	else
	{
		if(getPath(PANELS_REL_PATH,panel) != "")
			panel_path = panel;
	}
	return panel_path;
}

fwUi_changePanelSize(string panel, string w, string l, string neww, string newl)
{
string panel_path;
file f;
dyn_string s;
int i, index, done, err;

	panel_path = getPath(PANELS_REL_PATH,panel);
//	f = fopen(fwFsm_getProjPath()+"/panels/"+panel,"r");
	f = fopen(panel_path,"r");
	if(f == 0)
	{
//		DebugN("Could not open "+fwFsm_getProjPath()+"/panels/"+panel);
		DebugN("Could not open "+panel_path+" for reading");
		return;
	}
	index = 1;
	while(!feof(f))
	{
		fgets(s[index],2000,f);
		if(!done)
		{
			done = strreplace(s[index],w+" "+l,neww+" "+newl);
//			done = strreplace(s[index],l,newl);
		}
		index++;
	}
	fclose(f);
//	f = fopen(fwFsm_getProjPath()+"/panels/"+panel,"w");
	f = fopen(panel_path,"w");
	if(f == 0)
	{
//		DebugN("Could not open "+fwFsm_getProjPath()+"/panels/"+panel);
		DebugN("Could not open "+panel_path+" for writing");
		return;
	}
	for(i = 1; i <= dynlen(s); i++)
	{
		fputs(s[i],f);
	}
	fclose(f);
}
/*
fwUi_connectIncludedTree(string callback, string domain, string lunit = "")
{
	dyn_string children, dps;
	dyn_int flags;
	int i;
	string node, obj, sys;

	if(lunit == "")
		lunit = domain;
	fwUi_getIncludedTreeNodes(domain, domain, lunit, children);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(fwFsm_isAssociated(children[i]))
		{
			node = fwFsm_getAssociatedDomain(children[i]);
			obj = fwFsm_getAssociatedObj(children[i]);
			fwUi_getDomainSys(node, sys);
			dynAppend(dps,sys+node+"|"+obj+"_FWM.fsm.currentState");
			dynAppend(dps,sys+node+"|"+obj+"_FWM.fsm.currentState");
		}
	}
DebugN("Connecting Mode Bits", domain, lunit, children);
}


fwUi_getIncludedTreeNodes(string top, string domain, string lunit, dyn_string &nodes)
{
	dyn_string children;
	dyn_int flags;
	int i;

	if(lunit == "")
		lunit = domain;

	children = fwFsm_getObjChildren(domain, lunit, flags);
	if(dynlen(children))
	{
		if(domain == lunit)
		{
			dynAppend(nodes, top+"::"+domain);
			top = domain;
		}
		else
			dynAppend(nodes, domain+"/"+lunit);
	}
	for(i = 1; i <= dynlen(children); i++)
	{
		if(flags[i] == 2)
		{
		}
		else if (flags[i] == 1)
		{
			if(fwFsm_isAssociated(children[i]))
			{
				domain = fwFsm_getAssociatedDomain(children[i]);
				lunit = fwFsm_getAssociatedObj(children[i]);
			}
			fwUi_getIncludedTreeNodes(top, domain, lunit, nodes);
		}
		else
		{
			fwUi_getIncludedTreeNodes(top, domain, children[i], nodes);
		}
	}
}
*/


dyn_string fwUi_getIncludedTreeDevices(string domain, string lunit = "")
{
string state;
dyn_string devices;

	if(lunit == "")
		lunit = domain;
	state = fwUi_getCUMode(domain, domain);
	if((state != "Excluded") && (state != "LockedOut") && (state != "LockedOutPerm") && (state != "ExcludedPerm") && (state != "DEAD"))
	{
		if(fwFsm_isDU(domain, lunit))
			fwUi_getIncludedDevices(domain, lunit, devices, 1);
		else
			fwUi_getIncludedDevices(domain, lunit, devices);
	}
	return devices;
}

int fwUi_getIncludedDevicesTypesCus(string domain, string lunit, dyn_string checkTypes, dyn_string &devices, dyn_string &types, dyn_string &cus,
                                    dyn_string maskCUs = makeDynString())
{
dyn_string children;
dyn_int flags;
int i, j, index, enabled, ret, ret1;
string state, sys, node, obj, type;

//DebugTN("******** Entering", domain, lunit);
	fwUi_getDomainSys(domain, sys);

	if(lunit == "")
		lunit = domain;
/*
	if(fwFsm_isDU(domain,lunit))
	{
		fwUi_getEnabledType(domain, lunit, enabled, type);
		if((enabled == 1) || (ignore_disabled))
		{
			dynAppend(devices, sys+lunit);
			dynAppend(types, type);
		}
		return 1;
	}
*/
/*
	if(fwFsm_isCU(domain,lunit))
	{
		domain = lunit;
    	       state = fwUi_getCUMode(domain, domain);
	       if((state == "Excluded") || (state == "LockedOut") || (state == "ExcludedPerm") || (state == "DEAD"))
	       {
                 return 0;
	       }
	}
*/
       obj = lunit;
	children = fwFsm_getObjChildren(domain, lunit, flags);
//	children = fwFsm_getLogicalUnitDevices(domain, lunit);
//	children = fwFsm_getDomainDevices(domain);
//	if(index = dynContains(children, domain+"_FWDM"))
//		dynRemove(children, index);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(flags[i] == 2)
		{
			if ( (strpos(children[i],"_FWDM") > 0) ||
		     	(strpos(children[i],"_FWMAJ") > 0))
				continue;
		       fwUi_getEnabledType(domain, children[i], enabled, type);
		       if((enabled == 1) /*|| (ignore_disabled)*/)
		       {
                           if(dynlen(checkTypes))
                           {
                              for(j = 1; j <= dynlen(checkTypes); j++)
                              {
                                if(patternMatch(checkTypes[j],type))
                                {
 			              dynAppend(devices, sys+children[i]);
			              dynAppend(types, type);
//DebugTN("******** found", domain, lunit, children[i]);
                                   ret = 1;
                                }
                              }
                            }
                           else
                           {
			        dynAppend(devices, sys+children[i]);
			        dynAppend(types, type);
                             ret = 1;
                           }
		       }
//			fwUi_getEnabled(domain, children[i], enabled);
//			if((enabled == 1) || (ignore_disabled))
//			{
//				dynAppend(devices, sys+children[i]);
//				dynAppend(syss, sys);
//			}
		}
		else if (flags[i] == 1)
		{
			state = fwUi_getCUMode(domain, children[i]);
			node = domain;
			obj = children[i];
			if((state != "Excluded") && (state != "LockedOut") && (state != "LockedOutPerm") && (state != "ExcludedPerm") && (state != "DEAD"))
			{
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
                            if(dynlen(maskCUs))
                            {
                              if(!dynContains(maskCUs, obj))
                              {
//                                DebugTN("skipping CU", obj);
                                continue;
                              }
                            }
				ret1 = fwUi_getIncludedDevicesTypesCus(node, obj, checkTypes, devices, types, cus, maskCUs);
                            if(!ret)
                              ret = ret1;
			}
		}
		else
		{
			fwUi_getEnabled(domain, children[i], enabled);
			if(enabled == 1)
			{
				node = domain;
				obj = children[i];
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
                            if(dynlen(maskCUs))
                            {
                              if(!dynContains(maskCUs, obj))
                              {
//                                DebugTN("skipping CU", obj);
                                continue;
                              }
                            }
				ret1 = fwUi_getIncludedDevicesTypesCus(node, obj, checkTypes, devices, types, cus, maskCUs);
                            if(!ret)
                              ret = ret1;
			}
		}
	}
//DebugTN("Checking", domain, lunit, obj, ret);
       if(ret)
       {
            dynAppend(cus, lunit);
       }
       return ret;
}

int fwUi_getDevicesTypesCus(string domain, string lunit, dyn_string checkTypes, dyn_string &devices, dyn_string &types, dyn_string &cus, dyn_string maskCUs = makeDynString())
{
dyn_string children;
dyn_int flags;
int i, j, index, enabled, ret, ret1;
string state, sys, node, obj, type;

//DebugTN("******** Entering", domain, lunit);
	fwUi_getDomainSys(domain, sys);

	if(lunit == "")
		lunit = domain;
/*
	if(fwFsm_isDU(domain,lunit))
	{
		fwUi_getEnabledType(domain, lunit, enabled, type);
		if((enabled == 1) || (ignore_disabled))
		{
			dynAppend(devices, sys+lunit);
			dynAppend(types, type);
		}
		return 1;
	}
*/
/*
	if(fwFsm_isCU(domain,lunit))
	{
		domain = lunit;
//    	       state = fwUi_getCUMode(domain, domain);
//	       if((state == "Excluded") || (state == "LockedOut") || (state == "ExcludedPerm") || (state == "DEAD"))
//	       {
//               return 0;
//	       }
	}
*/
       obj = lunit;
	children = fwFsm_getObjChildren(domain, lunit, flags);
//	children = fwFsm_getLogicalUnitDevices(domain, lunit);
//	children = fwFsm_getDomainDevices(domain);
//	if(index = dynContains(children, domain+"_FWDM"))
//		dynRemove(children, index);
//DebugTN("check types", dynlen(children));
	for(i = 1; i <= dynlen(children); i++)
	{
		if(flags[i] == 2)
		{
			if ( (strpos(children[i],"_FWDM") > 0) ||
		     	(strpos(children[i],"_FWMAJ") > 0))
				continue;
		       fwUi_getEnabledType(domain, children[i], enabled, type);
//		       if((enabled == 1) || (ignore_disabled))
//		       {
                           if(dynlen(checkTypes))
                           {
                              for(j = 1; j <= dynlen(checkTypes); j++)
                              {
                                if(patternMatch(checkTypes[j],type))
                                {
 			              dynAppend(devices, sys+children[i]);
			              dynAppend(types, type);
//DebugTN("******** found", domain, lunit, children[i]);
                                   ret = 1;
                                }
                              }
                           }
                           else
                           {
			        dynAppend(devices, sys+children[i]);
			        dynAppend(types, type);
                             ret = 1;
                           }
//		       }
//			fwUi_getEnabled(domain, children[i], enabled);
//			if((enabled == 1) || (ignore_disabled))
//			{
//				dynAppend(devices, sys+children[i]);
//				dynAppend(syss, sys);
//			}
		}
		else if (flags[i] == 1)
		{
//			state = fwUi_getCUMode(domain, children[i]);
			node = domain;
			obj = children[i];
//			if((state != "Excluded") && (state != "LockedOut") && (state != "ExcludedPerm") && (state != "DEAD"))
//			{
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
                  if(dynlen(maskCUs))
                  {
                    if(!dynContains(maskCUs, obj))
                    {
//                      DebugTN("skipping CU", obj);
                      continue;
                    }
                  }
//                  DebugTN("recursing", node, obj);
				ret1 = fwUi_getDevicesTypesCus(node, obj, checkTypes, devices, types, cus, maskCUs);
                            if(!ret)
                              ret = ret1;
//			}
		}
		else
		{
//			fwUi_getEnabled(domain, children[i], enabled);
//			if(enabled == 1)
//			{
				node = domain;
				obj = children[i];
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
                  if(dynlen(maskCUs))
                  {
                    if(!dynContains(maskCUs, obj))
                    {
//                      DebugTN("skipping LU", obj);
                      continue;
                    }
                  }
//                  DebugTN("recursing LU", node, obj);
				ret1 = fwUi_getDevicesTypesCus(node, obj, checkTypes, devices, types, cus, maskCUs);
                            if(!ret)
                              ret = ret1;
//			}
		}
	}
//DebugTN("check types done", dynlen(children));
//DebugTN("Checking", domain, lunit, obj, ret);
       if(ret)
       {
            dynAppend(cus, lunit);
       }
       return ret;
}

fwUi_getIncludedDevices(string domain, string lunit, dyn_string &devices, int ignore_disabled = 0)
{
dyn_string children;
dyn_int flags;
int i, index, enabled;
string state, sys, node, obj;

	fwUi_getDomainSys(domain, sys);

	if(fwFsm_isDU(domain,lunit,sys))
	{
		fwUi_getEnabled(domain, lunit, enabled);
		if((enabled == 1) || (ignore_disabled))
		{
			dynAppend(devices, sys+lunit);
		}
		return;
	}
	if(fwFsm_isCU(domain,lunit,sys))
	{
		domain = lunit;
	}
	children = fwFsm_getObjChildren(domain, lunit, flags);
//	children = fwFsm_getLogicalUnitDevices(domain, lunit);
//	children = fwFsm_getDomainDevices(domain);
//	if(index = dynContains(children, domain+"_FWDM"))
//		dynRemove(children, index);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(flags[i] == 2)
		{
			if ( (strpos(children[i],"_FWDM") > 0) ||
		     	(strpos(children[i],"_FWMAJ") > 0))
				continue;
			fwUi_getEnabled(domain, children[i], enabled);
			if((enabled == 1) || (ignore_disabled))
			{
				dynAppend(devices, sys+children[i]);
//				dynAppend(syss, sys);
			}
		}
		else if (flags[i] == 1)
		{
			state = fwUi_getCUMode(domain, children[i]);
			node = domain;
			obj = children[i];
			if((state != "Excluded") && (state != "LockedOut") && (state != "LockedOutPerm") && (state != "ExcludedPerm") && (state != "DEAD"))
			{
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
				fwUi_getIncludedDevices(node, obj, devices);
			}
		}
		else
		{
			fwUi_getEnabled(domain, children[i], enabled);
			if(enabled == 1)
			{
				node = domain;
				obj = children[i];
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
				fwUi_getIncludedDevices(node, obj, devices);
			}
		}
	}
}

dyn_int fwUi_getIncludedChildren(string domain, string lunit, dyn_string &nodes, int ignore_disabled = 0)
{
dyn_string children;
dyn_int flags, types;
int i, index, enabled;
string state, sys, node, obj;

	fwUi_getDomainSys(domain, sys);

	children = fwFsm_getObjChildren(domain, lunit, flags);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(flags[i] == 2)
		{
			if ( (strpos(children[i],"_FWDM") > 0) ||
		     	(strpos(children[i],"_FWMAJ") > 0))
				continue;
			fwUi_getEnabled(domain, children[i], enabled);
			if((enabled == 1) || (ignore_disabled))
			{
				dynAppend(nodes, children[i]);
				dynAppend(types, flags[i]);
//				dynAppend(devices, sys+children[i]);
			}
		}
		else if (flags[i] == 1)
		{
			state = fwUi_getCUMode(domain, children[i]);
//			node = domain;
//			obj = children[i];
			if((state != "Excluded") && (state != "LockedOut") && (state != "LockedOutPerm") && (state != "ExcludedPerm") && (state != "DEAD"))
			{
				dynAppend(nodes, children[i]);
				dynAppend(types, flags[i]);
/*
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
				fwUi_getIncludedDevices(node, obj, devices);
*/
			}
		}
		else
		{
			fwUi_getEnabled(domain, children[i], enabled);
			if(enabled == 1)
			{
				dynAppend(nodes, children[i]);
				dynAppend(types, flags[i]);
/*
				node = domain;
				obj = children[i];
				if(fwFsm_isAssociated(children[i]))
				{
					node = fwFsm_getAssociatedDomain(children[i]);
					obj = fwFsm_getAssociatedObj(children[i]);
				}
				fwUi_getIncludedDevices(node, obj, devices);
*/
			}
		}
	}
 	for (i = 1; i <= dynlen(nodes); i++)
	{
		if(fwFsm_isAssociated(nodes[i]))
		{
			domain = fwFsm_getAssociatedDomain(nodes[i]);
			obj = fwFsm_getAssociatedObj(nodes[i]);
			if(domain == obj)
 				nodes[i] = domain;
		}
	}
	return types;
}

string fwUi_getModeObj(string domain, string obj)
{
string modeObj;

  modeObj = domain;
  if(fwFsm_isCU(domain, obj))
  {
  	if(fwFsm_isAssociated(obj))
  		modeObj = fwFsm_getAssociatedDomain(obj);
  	else
  		modeObj = obj;
  }
/*
  else
  {
    if(!fwFsm_objExists(domain, obj))
    {
DebugTN("************* Failed fwUi_getModeObj", domain, obj, modeObj);
      modeObj = "";
    }
  }
*/
  return modeObj;
}


int fwUi_connectDUModeBits(string rout, string domain, string obj, int wait_flag = 1, bool first = TRUE)
{
	string dp;
	int pos;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".mode.modeBits";
//	if(dpExists(dp))
//	{
//		dpConnect(rout, dp+":_online.._value");
//		return 1;
//	}
//	return 0;
	if(wait_flag)
	{
		while(!dpExists(dp))
		{
			delay(5);
		}
	}
	else
	{
		if(!dpExists(dp))
			return 0;
	}
//DebugN("calling dpConnect", rout, dp);
	dpConnect(rout, first, dp+":_online.._value");
	return 1;
}

int fwUi_disconnectDUModeBits(string rout, string domain, string obj)
{
	string dp;
	int pos;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".mode.modeBits";
	if(!dpExists(dp))
		return 0;
	dpDisconnect(rout, dp+":_online.._value");
	return 1;
}

int fwUi_connectCUModeBits(string rout, string domain, string obj, int cu, int wait_flag = 1)
{
	string modeObj, dp, parent, child;
	int ret, index;

	modeObj = fwUi_getModeObj(domain, obj);
	fwUi_getDomainPrefix(modeObj, dp);
//DebugN("Connecting ",domain, obj, dp+".mode.modeBits");
	if(wait_flag)
	{
		while(!dpExists(dp))
		{
			delay(5);
		}
	}
	else
	{
		if(!dpExists(dp))
			return 0;
	}
	ret = dpConnect(rout, dp+".mode.modeBits:_online.._value");
//DebugN("dpConnect",dp+".mode.modeBits:_online.._value", ret);
	if((domain != obj) && (cu))
	{
		if(fwFsm_isAssociated(obj))
		{
			parent = fwFsm_getAssociatedDomain(obj);
			child = fwFsm_getAssociatedObj(obj);
			if(parent == child)
				obj = child;
		}
		fwUi_connectCurrentState(rout, domain, obj+"_FWM");
	}
	return 1;
}

int fwUi_disconnectCUModeBits(string rout, string domain, string obj, int cu)
{
	string modeObj, dp;
	int ret, index;

	modeObj = fwUi_getModeObj(domain, obj);
	fwUi_getDomainPrefix(modeObj, dp);
//DebugN("Connecting ",dp+".mode.modeBits");
	if(!dpExists(dp))
		return 0;
	ret = dpDisconnect(rout, dp+".mode.modeBits:_online.._value");
	if((domain != obj) && (cu))
	{
		fwUi_disconnectCurrentState(rout, domain, obj+"_FWM");
	}
	return ret;
}

bit32 fwUi_getDUModeBits(string domain, string obj)
{
	string dp;
	bit32 bits;

	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj+".mode.modeBits";
	if(dpExists(dp))
	{
		dpGet(dp+":_online.._value", bits);
	}
	return bits;
}

bit32 fwUi_getCUModeBits(string domain)
{
	string dp;
	bit32 bits;
	int ret = 123;

	fwUi_getDomainPrefix(domain, dp);
	if(dpExists(dp))
	{
		ret = dpGet(dp+".mode.modeBits:_online.._value", bits);
	}
	return bits;
}

string FwUiModeCallback;
string FwUiDomain;
string FwUiObj;
string FwUiPart;

int fwUi_connectModeBits(string callback, string domain, string obj, int wait_flag = 1, string part = "")
{
string modeObj;
int ret = 1;

	FwUiModeCallback = callback;
	FwUiDomain = domain;
	FwUiObj = obj;
	FwUiPart = part;
//	modeObj = fwUi_getModeObj(domain, obj);
	if(fwFsm_isCU(domain, obj))
	{
//DebugN("connecting", domain, obj, part, callback);
		if((part != "") && (part != domain))
			ret = fwUi_connectDUModeBits("fwUi_showIt", domain, obj, wait_flag);
		else
			ret = fwUi_connectCUModeBits("fwUi_showIt", domain, obj, 1, wait_flag);
	}
	else if(fwFsm_isDU(domain, obj))
	{
		ret = fwUi_connectDUModeBits("fwUi_showIt", domain, obj, wait_flag);
	}
	else
	{
		ret = fwUi_connectDUModeBits("fwUi_showIt", domain, obj, wait_flag);
	}
	return ret;
}

fwUi_disconnectModeBits(string domain, string obj, string part = "")
{
string modeObj;

	modeObj = fwUi_getModeObj(domain, obj);
	if(fwFsm_isCU(domain, obj))
	{
		if((part != "") && (part != domain))
			fwUi_disconnectDUModeBits("fwUi_showIt", domain, obj);
		else
			fwUi_disconnectCUModeBits("fwUi_showIt", domain, obj, 1);
	}
	else if(fwFsm_isDU(domain, obj))
	{
		fwUi_disconnectDUModeBits("fwUi_showIt", domain, obj);
	}
	else
	{
		fwUi_disconnectDUModeBits("fwUi_showIt", domain, obj);
	}
}

fwUi_showIt(string dp, bit32 bits)
{
string callback, node, obj;

//DebugN("callback called",dp, bits);

	if(isFunctionDefined(FwUiModeCallback))
	{
/*
		execScript("main() { "+
			ModeCallback+"();}",
			makeDynString());
*/
    if(!isATLAS())
		  startThread(FwUiModeCallback, dp);
    else
		  startThread(FwUiModeCallback, dp, bits);
	}
}


bit32 fwUi_getOwnModeBits()
{
	bit32 bits;

	bits = fwUi_getModeBits(FwUiDomain, FwUiObj, FwUiPart);
//DebugN(FwUiDomain, FwUiObj, FwUiPart, bits);
	return bits;
}

bit32 fwUi_getModeBits(string domain, string obj, string part = "")
{
	int exclusive, enabled, cu;
	bit32 bits, parentBits;
	string modeObj, dp, mode;

//DebugN("getModeBits",domain, obj);
	modeObj = fwUi_getModeObj(domain, obj);
	fwUi_getDomainPrefix(modeObj, dp);
	if(!dpExists(dp))
	{
		return bits;
	}
	fwUi_getOwnerExclusivity(domain, obj, exclusive, enabled);
	if(fwFsm_isCU(domain, obj))
	{
		if((part != "") && (part != domain))
		{
			bits = fwUi_getDUModeBits(domain, obj);
		}
		else
		{
			bits = fwUi_getCUModeBits(modeObj);
			cu = 1;
		}
	}
	else if(fwFsm_isDU(domain, obj))
	{
		bits = fwUi_getDUModeBits(domain, obj);
	}
	else
	{
//		bits = fwUi_getCUModeBits(modeObj);
		bits = fwUi_getDUModeBits(domain, obj);
	}
//DebugN("getModeBits",domain, obj, cu, enabled);
	if(enabled == 2)
		setBit(bits,FwOwnerBit,1);
	else
		setBit(bits,FwOwnerBit,0);
	if(bits == 0)
		return bits;
	if((domain != obj) && (cu))
	{
		parentBits = fwUi_getModeBits(domain, domain);
//DebugTN("ParentBits",domain, obj, parentBits);
   if(isLHCb())
   {
      if((!getBit(parentBits,FwOwnerBit)) && (getBit(parentBits,FwExclusiveBit)))
        setBit(bits, FwCUNotOwnerBit,1);
      if(getBit(parentBits,FwFreeBit))
        setBit(bits, FwCUNotOwnerBit,1);
      if(getBit(parentBits,FwCUSharedBit))
        setBit(bits, FwCUSharedBit,1);
   }
   else
   {
 		  if(!getBit(parentBits,FwOwnerBit))
		  	setBit(bits, FwCUNotOwnerBit,1);
    }
		if(getBit(parentBits,FwFreeBit))
   {
		  setBit(bits, FwCUFreeBit,1);
   }
		fwUi_getCurrentState(domain, modeObj+"_FWM", mode);
		fwUi_convertObjState(domain, modeObj+"_FWM", mode);
//DebugN("getModeBits1",domain, obj, cu, enabled, mode);
		if((mode == "Excluded") || (mode == "LockedOut") || (mode == "LockedOutPerm") || (mode == "ExcludedPerm") || (mode == "DEAD"))
			setBit(bits, FwUseStatesBit,0);
	}
	else if(cu)
	{
   if(isLHCb())
   {
      if((!getBit(bits,FwOwnerBit)) && (!getBit(bits,FwExclusiveBit)))
      {
          setBit(bits, FwCUSharedBit,1);
      }
      if(getBit(bits,FwFreeBit))
      {
        setBit(bits, FwCUSharedBit,0);
      }
    }
 }
	if(!cu)
	{
		if(getBit(bits,FwCUNotOwnerBit))
		{
//			setBit(bits, FwCUNotOwnerBit,0);
			setBit(bits,FwOwnerBit,0);
			setBit(bits,FwUseStatesBit,0);
		}
	}
//DebugN("getModeBits",domain, obj, cu, enabled, bits);
	return bits;
}

string fwUi_getCUMode(string domain, string obj)
{
	string mode, modeObj;

	modeObj = fwUi_getModeObj(domain, obj);
	fwUi_getCurrentState(domain, modeObj+"_FWM", mode);
  	fwUi_convertObjState(domain, modeObj+"_FWM", mode);
	return mode;
}

string fwUi_getDUMode(string domain, string obj)
{
	int enabled;
	string mode;

	fwUi_getEnabled(domain, obj, enabled);
	if(enabled == 1)
	{
		mode = "Enabled";
	}
	else if(enabled == 0)
	{
		mode = "Disabled";
	}
	else if(enabled == -1)
	{
		mode = "Disabled (not propagated)";
	}
	return mode;
}

dyn_string fwUi_getCUModeActions(string domain, string obj)
{
	string mode, modeObj, text;
	dyn_string modes, actions;
	bit32 statusBits, parentBits;
	int opAllowed, i, index, differentOwner = 0;

	statusBits = fwUi_getModeBits(domain, obj);
	modeObj =fwUi_getModeObj(domain, obj);

	fwUi_getCurrentState(domain, modeObj+"_FWM", mode);
	fwUi_convertObjState(domain, modeObj+"_FWM", mode);

  opAllowed = fwFsmUi_isParentOperationAllowed(domain, obj);

  if((isLHCb()) && (getBit(statusBits, FwCUSharedBit)))
  {
    if((getBit(statusBits, FwOwnerBit)) ||
       (!getBit(statusBits, FwExclusiveBit)) ||
       (getBit(statusBits, FwFreeBit)))
	  {
      fwUi_getObjStateActions(domain, modeObj+"_FWM", mode, actions);
      dynAppend(modes, actions);
//      if((!getBit(statusBits, FwOwnerBit)) && (!getBit(statusBits, FwFreeBit)))
      if(!getBit(statusBits, FwFreeBit))
      {
        if((domain == obj) && (!getBit(statusBits, FwOwnerBit)))
        {
          if(index = dynContains(modes, "Release"))
            dynRemove(modes, index);
           if(index = dynContains(modes, "ReleaseAll"))
            dynRemove(modes, index);
        }
        else
        {
          if(dynlen(dynPatternMatch("*Include", modes)))
          {
            string ownerObj, ownerDomain;
            fwUi_getOwnership(obj, ownerObj);
            fwUi_getOwnership(domain, ownerDomain);
//DebugTN("Got Owners", obj, ownerObj,domain, ownerDomain);
            if(ownerObj != ownerDomain)
            {
              dynClear(modes);
              differentOwner = 1;
            }
          }
        }
      }
    }
  }
  else
  {
    if(((getBit(statusBits, FwOwnerBit)) ||
        (getBit(statusBits, FwFreeBit))) &&
        (!getBit(statusBits, FwCUNotOwnerBit)) )
    {
      fwUi_getObjStateActions(domain, modeObj+"_FWM", mode, actions);
      dynAppend(modes, actions);
    }
  }

//DebugTN("getCUModeActions",domain, obj, mode, opAllowed, statusBits, modes);
/*
  if(!opAllowed)
  {
    if(dynContains(modes,"Ignore"))
      modes = makeDynString("Ignore");
    else if ((dynContains(modes,"Include")) && (mode == "Ignored"))
      modes = makeDynString("Include");
  }
*/
	for(i = 1; i <= dynlen(modes); i++)
	{
		text = modes[i];
		if( ((text == "Exclude") || (text == "ExcludeAll") || (text == "Include") ||
                     (text == "Manual") || (text == "Exclude&LockOut") || (text == "UnLockOut&Include"))
                  && (!opAllowed))
		{
     if(!((mode == "Ignored") && (!opAllowed) && (text == "Include")))
     {
			  dynRemove(modes, i);
			  i--;
     }
		}
	}
	if(!dynlen(modes))
	{
	  if( (!getBit(statusBits, FwCUNotOwnerBit)) || (getBit(statusBits, FwCUFreeBit)) )
	  {
	  	if(mode == "Manual")
	  	{
	  		dynAppend(modes,"Exclude");
	  		dynAppend(modes,"ExcludeAll");
	  		if(domain != obj)
	  			dynAppend(modes,"Exclude&LockOut");
	  	}
	  	if(mode == "Excluded")
	  	{
	  		dynAppend(modes,"LockOut");
//			dynAppend(modes,"ExcludePerm");
  		}
  		else if(mode == "ExcludedPerm")
  		{
  			dynAppend(modes,"LockOut");
//			dynAppend(modes,"Exclude");
  		}
  		else if(mode == "LockedOut")
  		{
  			dynAppend(modes,"UnLockOut");
  		}
  		else if(mode == "LockedOutPerm")
  		{
  			dynAppend(modes,"UnLockOut");
  		}
  		if( (getBit(statusBits, FwFreeBit)) && ((mode == "Included") || (mode == "Manual")) )
  		{
  			dynAppend(modes,"Exclude");
  			dynAppend(modes,"ExcludeAll");
  			if(domain != obj)
  				dynAppend(modes,"Exclude&LockOut");
  		}
  	}
	}
//DebugN(domain, obj, modeObj, statusBits, mode, modes);
	if( (statusBits == 0) && ((mode == "Included") || (mode == "Manual")) )
	{
		if(!dynlen(modes))
		{
			dynAppend(modes,"Exclude");
			dynAppend(modes,"ExcludeAll");
			if(domain != obj)
				dynAppend(modes,"Exclude&LockOut");
		}
	}
	if((getBit(statusBits, FwOwnerBit)) && (!differentOwner))
	{
		if(getBit(statusBits, FwExclusiveBit))
		{
			dynAppend(modes,"Share");
		}
		else
		{
			dynAppend(modes,"Exclusive");
		}
	}
	return modes;
}

dyn_string fwUi_getDUModeActions(string domain, string obj, string part = "")
{
	dyn_string modes;
	bit32 statusBits;
	int opAllowed;

	statusBits = fwUi_getModeBits(domain, obj, part);

        opAllowed = fwFsmUi_isParentOperationAllowed(domain, obj);

	if(opAllowed)
	{
	if( (getBit(statusBits, FwOwnerBit)) ||
			( (!getBit(statusBits, FwFreeBit)) &&
				(!getBit(statusBits, FwExclusiveBit))) )
	{
		if(getBit(statusBits, FwUseStatesBit))
		{
			dynAppend(modes,"Disable");
		}
		else
		{
			dynAppend(modes,"Enable");
		}
	}
	}
	return modes;
}

fwUi_setCUModeByName(string domain, string obj, string cmd)
{
	string id, itsId;
	bit32 statusBits;

//DebugN("SetCUModeByName", domain, obj, cmd);
	id = fwUi_getGlobalUiId();
	statusBits = fwUi_getModeBits(domain, obj);
  if((isLHCb()) && (getBit(statusBits, FwCUSharedBit)))
  {
//DebugTN("setCUModeByName",domain, obj, id, statusBits);
/*
    if(((!getBit(statusBits, FwOwnerBit)) && (!getBit(statusBits, FwExclusiveBit))) ||
       ((getBit(statusBits, FwFreeBit)) && (!getBit(statusBits, FwCUNotOwnerBit))))
*/
				fwUi_getOwnership(domain, id);
  }

//DebugTN("fwUi_setCUModeByName",domain, obj, cmd, id);
	if(cmd == "Share")
		fwUi_shareTree(domain, obj, id);
	else if(cmd == "Exclusive")
		fwUi_exclusiveTree(domain, obj, id);
	else
	{
		switch(cmd)
		{
			case "Exclude":
				fwUi_excludeTree(domain, obj, id);
				break;
			case "ExcludePerm":
				fwUi_excludeTreePerm(domain, obj, id);
				break;
			case "ExcludeAll":
				fwUi_excludeTreeAll(domain, obj, id);
				break;
			case "Exclude&LockOut":
				fwUi_excludeTree(domain, obj, id, 1, 1);
				break;
			case "Take":
				fwUi_takeTree(domain, obj, id);
				break;
			case "Release":
				fwUi_releaseTree(domain, obj, id);
				break;
			case "ReleaseAll":
				fwUi_releaseTreeAll(domain, obj, id);
				break;
			case "Manual":
				fwUi_delegateTree(domain, obj, id);
				break;
			case "Ignore":
				fwUi_ignoreTree(domain, obj, id);
				break;
			case "UnLockOut&Include":
				fwUi_includeTree(domain, obj, id, 1, 1, 1);
				break;
			case "Include":
				fwUi_includeTree(domain, obj, id);
				break;
			case "LockOut":
				fwUi_lockOutTree(domain, obj, id);
				break;
			case "LockOutPerm":
				fwUi_lockOutTreePerm(domain, obj, id);
				break;
			case "UnLockOut":
				fwUi_unLockOutTree(domain, obj, id);
				break;
			case "ForceExclude":
				fwUi_getOwnership(obj, itsId);
				fwUi_excludeTree(domain, obj, itsId);
				break;
			case "ForceRelease":
				fwUi_getOwnership(obj, itsId);
				fwUi_releaseTree(domain, obj, itsId);
				break;
			case "ForceShare":
				fwUi_getOwnership(obj, itsId);
				fwUi_shareTree(domain, obj, itsId);
				break;
			case "ForceExclusive":
				fwUi_getOwnership(obj, itsId);
				fwUi_exclusiveTree(domain, obj, itsId);
				break;
			default:
				break;
		}
	}
}

fwUi_setDUModeByName(string domain, string obj, string cmd, string part = "")
{
	if(cmd == "Enable")
		fwUi_enableDevice(domain, obj);
	else if(cmd == "Disable")
		fwUi_disableDevice(domain, obj, 0);
	else if(cmd == "DisablePermanently")
		fwUi_disableDevice(domain, obj, -1);
}

fwUi_setCUMode(string domain, string obj, int exclusive, int useStates, int sendCommands)
{
	bit32 statusBits;
	string id;

	statusBits = fwUi_getModeBits(domain, obj);

	id = fwUi_getGlobalUiId();

	if(exclusive != -1)
	{
		if(exclusive == 0)
			fwUi_shareTree(domain, obj, id);
		else if(exclusive == 1)
			fwUi_exclusiveTree(domain, obj, id);
	}
	if(useStates == -1)
		useStates = getBit(statusBits, FwUseStatesBits);
	if(sendCommands == -1)
		sendCommands = getBit(statusBits, FwSendCommandsBits);

	if(domain == obj)
	{
		if(useStates || sendCommands)
			fwUi_takeTree(domain, obj, id);
		else
			fwUi_releaseTree(domain, obj, id);
	}
	else
	{
		if((!useStates) && (!sendCommands))
			fwUi_excludeTree(domain, obj, id);
		else if((!useStates) && (sendCommands))
			fwUi_ignoreTree(domain, obj, id);
		else if((useStates) && (!sendCommands))
			fwUi_delegateTree(domain, obj, id);
		else if((useStates) && (sendCommands))
			fwUi_includeTree(domain, obj, id);
	}
}

fwUi_setDUMode(string domain, string obj, int enable)
{
	bit32 statusBits;

	statusBits = fwUi_getModeBits(domain, obj);
	if(getBit(statusBits, FwOwnerBit))
	{
		if(enable == 1)
			fwUi_enableDevice(domain, obj);
		else
			fwUi_disableDevice(domain, obj, enable);
	}
}

fwUi_getCUNodeNames(string &node, string &obj)
{
int i;
string type, parent, sys;
dyn_string objs, exInfo;

	if(obj == "")
		obj = node;
	if(!fwFsm_isDomain(node))
	{
		if(fwFsm_isAssociated(obj))
			obj = fwFsm_getAssociatedDomain(obj);
		objs = fwTree_getNamedNodes(obj, exInfo);
		{
			if(!dynlen(objs))
			{
				objs[1] = fwTree_getNodeSys(node, exInfo) +":"+node;
			}
			for(i = 1; i <= dynlen(objs); i++)
			{
				fwTree_getParent(objs[i], parent, exInfo);
				parent = fwTree_getNodeDisplayName(parent, exInfo);
				if(parent == node)
					obj = objs[i];
			}
		}
		sys = fwTree_getNodeSys(node, exInfo);
		if(sys == "")
		{
			return;
		}
		fwTree_getCUName(sys+":"+obj, parent, exInfo);
		if(strpos(obj,"&") == 0)
			obj = fwFsm_getReferencedObjectDevice(obj);
//		fwTree_getNodeDevice(obj, obj, type, exInfo);
//		obj = fwFsm_extractSystem(obj);
		node = parent;
	}
}

fwUi_getNodeParent(string domain, string obj, string &parent, int &cu)
{
	string dp, tnode, sys;
	dyn_string exInfo;
	dyn_string refs, syss;
	int i;


	cu = -1;
	obj = fwFsm_convertAssociated(obj);
	obj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+obj;
	if(dpExists(dp))
	{
		dpGet(dp+".tnode",tnode);
		sys = fwFsm_getSystem(dp);
		fwTree_getParent(tnode, parent, exInfo);
		parent = fwTree_getNodeDisplayName(parent, exInfo);
		if(parent == "FSM")
			parent = "";
	}
	if((parent == "") && (domain == obj))
	{
		fwFsm_getObjectReferences(domain, refs, syss);
		for(i = 1; i <= dynlen(refs); i++)
		{
			fwTree_getNodeCU(syss[i]+":"+refs[i], cu, exInfo);
			if(cu)
			{
				fwTree_getParent(syss[i]+":"+refs[i], parent, exInfo);
				sys = syss[i];
				break;
			}
		}
	}
	if(parent != "")
		fwTree_getNodeCU(sys+":"+parent, cu, exInfo);
}

fwUi_getObjDp(string node, string obj, string &dp)
{
	string sys;

	if(fwFsm_isDU(node, obj))
	{
		fwUi_getDomainSys(node, sys);
		dp = fwFsm_getPhysicalDeviceName(sys+obj);
		dp = sys+dp;
	}
	else
	{
		obj  = fwFsm_convertAssociated(obj);
		obj = fwFsm_convertAssociated(obj);
		fwUi_getSysPrefix(node, dp);
		dp += fwFsm_separator+obj;
	}
}

fwUi_getObjFSMDp(string node, string obj, string &dp)
{
	string sys;

//	if(fwFsm_isDU(node, obj))
//	{
//		fwUi_getDomainSys(node, sys);
//		dp = fwFsm_getPhysicalDeviceName(sys+obj);
//		dp = sys+dp;
//	}
//	else
//	{
		obj  = fwFsm_convertAssociated(obj);
		obj = fwFsm_convertAssociated(obj);
		fwUi_getSysPrefix(node, dp);
		dp += fwFsm_separator+obj;
//	}
}

dyn_dyn_string FwUiCallbacks;
dyn_string FwUiObjects;
dyn_string FwUiUserObjects;

int fwUi_registerObjCallback(string callback, string node, string obj, string type = "", string userObj = "")
{
	int index;

	if(type == "")
		type = "STATE";
	if(userObj == "")
		userObj = node+"::"+obj;
	if(!(index = dynContains(FwUiObjects,node+"/"+obj+"/"+type)))
	{
		index = dynAppend(FwUiObjects,node+"/"+obj+"/"+type);
		FwUiCallbacks[index] = makeDynString();
	}
	if(!dynContains(FwUiCallbacks[index], callback))
		dynAppend(FwUiCallbacks[index], callback);
//DebugN("fwUi_registerCallback", FwUiObjects, FwUiCallbacks, index);
	FwUiUserObjects[index] = userObj;
	return index;
}

int fwUi_getObjCallbacks(string dp, dyn_string &callbacks, string &node, string &obj, string &userNode)
{
dyn_string dpitems, items, devs;
string type;
int index, pos;

	dpitems = strsplit(dp,":.");
	items = strsplit(dpitems[2],fwFsm_separator);
	if(dynlen(items) == 1)
	{
		node = dpitems[2];
		if(strpos(node,"fwCU_") >= 0)
		{
			strreplace(node,"fwCU_","");
			obj = node;
		}
		else
		{
			obj = fwFsm_getLogicalDeviceName(dpitems[1]+":"+node);
			devs = fwFsm_getDps(dpitems[1]+":"+"*|"+obj,"_FwFsmDevice");
			if(!dynlen(devs))
			{
				devs = fwFsm_getDps(dpitems[1]+":"+"*|"+node,"_FwFsmDevice");
			}
			if(dynlen(devs))
			{
				items = strsplit(devs[1],fwFsm_separator);
				node = items[1];
				obj = items[2];
			}
		}
	}
	else
	{
		node = items[1];
		obj = items[2];
	}
	if(dynlen(items) > 2)
	{
		obj += "::"+items[3];
	}
//DebugN("getObjCallback", dpitems, items, node, obj, type);
	if((dpitems[3] == "fsm") && (dpitems[4] == "currentState"))
		type = "STATE";
	else if ((dpitems[3] == "fsm") && (dpitems[4] == "executingAction"))
		type = "COMMAND";
	else if (dpitems[3] == "mode")
		type = "MODE";
	else if (dpitems[4] == "_alert_hdl")
		type = "ALARM";
	pos = strpos(obj,"_FWM");
	if((pos >= 0)  && (pos == (strlen(obj) - 4)))
	{
		strreplace(obj,"_FWM","");
		type = "MODE";
	}
	if(index = dynContains(FwUiObjects,node+"/"+obj+"/"+type))
	{
		callbacks = FwUiCallbacks[index];
		userNode = FwUiUserObjects[index];
	}
	return index;
}

fwUi_unRegisterObjCallback(string node, string obj, string type = "")
{
	int index;

	if(type == "")
		type = "STATE";
	if(index = dynContains(FwUiObjects,node+"/"+obj+"/"+type))
	{
		dynRemove(FwUiObjects, index);
		dynRemove(FwUiCallbacks, index);
	}
}

int fwUi_getSummaryAlarm(string node, string lunit = "")
{
string local_dp;
int al_state, active;

	if(lunit == "")
		lunit = node;
	fwUi_getObjDp(node, lunit, local_dp);
	local_dp += ".";

	if(dpExists(local_dp))
	{
		dpGet(local_dp+":_alert_hdl.._act_state", al_state,
		      local_dp+":_alert_hdl.._active", active);
		if(al_state && active)
			return 1;
	}
	return 0;
}

string FwUiAlarmCallback;
string FwUiAlarmDomain;
string FwUiAlarmObj;

int fwUi_connectSummaryAlarm(string callback, string node, string lunit = "")
{
string local_dp;

	if(lunit == "")
		lunit = node;
	fwUi_getObjDp(node, lunit, local_dp);
	local_dp += ".";
//DebugN("Connecting Alarm", node, lunit, local_dp);
	FwUiAlarmCallback = callback;
	FwUiAlarmDomain = node;
	FwUiAlarmObj = lunit;

	if(dpExists(local_dp))
	{
		dpConnect("fwUi_alarmShowIt", local_dp+":_alert_hdl.._act_state",
					      local_dp+":_alert_hdl.._active");
	}
	else
	{
		return 0;
	}
	return 1;
}

fwUi_disconnectSummaryAlarm(string node, string lunit = "")
{
string local_dp;

	if(lunit == "")
		lunit = node;
	fwUi_getObjDp(node, lunit, local_dp);
	local_dp += ".";
	if(dpExists(local_dp))
	{
		dpDisconnect("fwUi_alarmShowIt", local_dp+":_alert_hdl.._act_state",
						 local_dp+":_alert_hdl.._active");
	}
}

fwUi_alarmShowIt(string dp1, int al_state, string dp2, int active)
{
//DebugN("alarm", dp1, al_state, active);
	if((al_state) && (active))
		startThread(FwUiAlarmCallback, 1, dp1);
	else
		startThread(FwUiAlarmCallback, 0, dp1);
}

dyn_string FwUiRemoteDps, FwUiLocalDps;

fwUi_connectRemoteSummaryAlarm(string local_dp, string rem_dp)
{
int index;

	if(!(index = dynContains(FwUiRemoteDps, rem_dp)))
		index = dynAppend(FwUiRemoteDps, rem_dp);
	FwUiLocalDps[index] = local_dp;
	if(dpExists(rem_dp))
		dpConnect("fwUi_RemoteAlarmChanged",rem_dp+":_alert_hdl.._act_state",
				      	    rem_dp+":_alert_hdl.._active",rem_dp+":_alert_hdl.._act_prior");
}

fwUi_disconnectRemoteSummaryAlarm(string local_dp, string rem_dp)
{
int index;

	if(dpExists(rem_dp))
		dpDisconnect("fwUi_RemoteAlarmChanged",rem_dp+":_alert_hdl.._act_state",
				      	       		rem_dp+":_alert_hdl.._active",rem_dp+":_alert_hdl.._act_prior");
	if((index = dynContains(FwUiRemoteDps, rem_dp)))
	{
		dynRemove(FwUiRemoteDps, index);
		dynRemove(FwUiLocalDps, index);
	}
}

fwUi_RemoteAlarmChanged(string dp1, int al_state, string dp2, int al_active,
	string dp3, int al_prior)
{
	string local_dp;
	int index;

	strreplace(dp1,":_alert_hdl.._act_state","");
	if((index = dynContains(FwUiRemoteDps, dp1)))
		local_dp = FwUiLocalDps[index];

//DebugN(dp1, al_state, al_active, al_prior, local_dp);
	if(al_state && al_active)
	{
		fwFsm_setLocalRemoteAlarmClass(local_dp+"hasAlarms", al_prior);
		dpSetWait(local_dp+"hasAlarms", 1);
	}
	else
	{
		dpSetWait(local_dp+"hasAlarms", 0);
	}
}


fwUi_setAlarmFilter(dyn_string devices)
{
string propDp;
dyn_string      dsSystemNames;
dyn_uint        duSystemIds;

	propDp=aes_getPropDpName( AES_DPTYPE_PROPERTIES, true, AESTAB_TOP, true );

	aes_doStop( propDp );

	dynAppend(devices,"_Config");
	getSystemNames( dsSystemNames, duSystemIds );
  	dpSetWait( propDp + ".Alerts.Filter.DpList" + AES_ORIVAL, devices,
  		propDp + ".Both.Systems.Selections" + AES_ORIVAL, dsSystemNames,
  		propDp + ".Alerts.FilterTypes.AlertSummary" + AES_ORIVAL, 0 );
//DebugN("Alert_dp",propDp + ".Alerts.Filter.DpList" + AES_ORIVAL);
  	aes_doRestart( propDp );
}

int fwUi_getAccessInfo(int topIndex, dyn_string nodes)
{
	int i, index;
	string dp;
	string tnode, accessc;

	for(i = 1; i <= dynlen(nodes); i++)
	{
		fwUi_getSysPrefix(nodes[i], dp);
		dp += fwFsm_separator+nodes[i];
		if(dpExists(dp))
		{
			dpGet(dp+".tnode",tnode);
			fwFsmTree_getNodeAccessControl(tnode, accessc);
			if(!(index = dynContains(AccessControlNodes[topIndex], nodes[i])))
			{
				index = dynAppend(AccessControlNodes[topIndex], nodes[i]);
			}
			AccessControlNodeSettings[topIndex][index] = accessc;
			if((accessc != "") && (accessc[0] != "!"))
			{
				AccessControlOperatorGranted[topIndex][index] = 0;
				AccessControlExpertGranted[topIndex][index] = 0;
			}
			else
			{
				AccessControlOperatorGranted[topIndex][index] = 1;
				AccessControlExpertGranted[topIndex][index] = 1;
			}

		}
	}
	return index;
}

fwUi_getAccess(string domain)
{
	dyn_string exInfo;
	dyn_string children, nodes;
	string node;
	int i, topIndex;
  int firstTime = 0;

	if(!globalExists("AccessControlNodes"))
	{
		addGlobal("AccessControlCurrentUser",STRING_VAR);
    if(isATLAS())
  		addGlobal("AccessControlCurrentDomain",STRING_VAR);
		addGlobal("AccessControlTopNodes",DYN_STRING_VAR);
		addGlobal("AccessControlTopNodeBusy",DYN_INT_VAR);
		addGlobal("AccessControlNodes",DYN_DYN_STRING_VAR);
		addGlobal("AccessControlNodeSettings",DYN_DYN_STRING_VAR);
		addGlobal("AccessControlOperatorGranted",DYN_DYN_INT_VAR);
		addGlobal("AccessControlExpertGranted",DYN_DYN_INT_VAR);
    firstTime = 1;
	}
	if(!(topIndex = dynContains(AccessControlTopNodes, domain)))
	{
		topIndex = dynAppend(AccessControlTopNodes, domain);
		AccessControlNodes[topIndex] = makeDynString();
		AccessControlNodeSettings[topIndex] = makeDynString();
		AccessControlOperatorGranted[topIndex] = makeDynInt();
		AccessControlExpertGranted[topIndex] = makeDynInt();
	}
	children = fwFsm_getLogicalUnitCUs(domain);

	dynAppend(nodes, domain);
	for(i = 1; i <= dynlen(children); i++)
	{
		node = fwFsm_getAssociatedObj(children[i]);
		dynAppend(nodes, node);
	}

  if(!isATLAS())
  {
	  fwUi_getAccessInfo(topIndex, nodes);
	  if(isFunctionDefined("fwAccessControl_setupPanel"))
	  {
	  	AccessControlTopNodeBusy[topIndex] = 1;
	  	fwAccessControl_setupPanel("fwUi_loggedUserAccessControlCallback",exInfo);
	  }
  }
  else
  {
	  if(firstTime && isFunctionDefined("fwAccessControl_setupPanel"))
	  {
	  	// commented since ATLAS avoids acces control issues from cascade buttons
	  	//
//   		AccessControlTopNodeBusy[topIndex] = 1;
	  	fwUi_getAccessInfo(topIndex, nodes);
	  	fwAccessControl_setupPanel("fwUi_loggedUserAccessControlCallback",exInfo);
	  }
	  else if (AccessControlCurrentDomain != domain)
    {
	  	fwUi_getAccessInfo(topIndex, nodes);
	  	fwUi_checkNewUser(AccessControlCurrentUser, domain);
	  }
	  else
      DebugTN("AC cache doesn't need refresh");
  }
}


fwUi_loggedUserAccessControlCallback(string s1, string s2)
{
	int topIndex;
	string userName;
	fwAccessControl_getUserName(userName);

  if(!isATLAS())
  {
  	topIndex = dynContains(AccessControlTopNodes, $node);
  	if(!topIndex)
  		return;
  	AccessControlTopNodeBusy[topIndex] = 1;
  	if(userName != "NO USER")
  	{
  		AccessControlCurrentUser = userName;
  		fwUi_checkNewUser(userName);
  	}
  	else
  	{
  		fwUi_checkNewUser(userName);
  		fwUi_logoutUser();
  	}
  	AccessControlTopNodeBusy[topIndex] = 0;
  }
  else
  {
	  AccessControlCurrentUser = userName;
	  fwUi_checkNewUser(userName);
  }
}

fwUi_checkNewUser(string user = "", string checkDomain = "")
{
int i, index, topIndex;
string domain, accessc;
dyn_string items, exInfo, domains;
int granted, expert_granted;

  if(checkDomain=="")
     checkDomain=$node;
  topIndex = dynContains(AccessControlTopNodes, checkDomain);
  if(!isATLAS())
  {
	  if(!topIndex)
	  	return;
  }
  else
  {
  	AccessControlCurrentDomain = checkDomain;
  	if(!topIndex)
    {
  		warning("No access control set up for "+checkDomain);
  		return;
  	}
  }
	for(i = 1; i <= dynlen(AccessControlNodes[topIndex]); i++)
	{
		granted = 1;
		expert_granted = 1;
		domain = AccessControlNodes[topIndex][i];
		accessc = AccessControlNodeSettings[topIndex][i];
		if((accessc != "") && (accessc[0] != "!"))
		{
			items = strsplit(accessc,"|");
			fwAccessControl_isGranted (items[1], granted, exInfo);
			expert_granted = granted;
			if(dynlen(items) == 2)
				fwAccessControl_isGranted (items[2], expert_granted, exInfo);
			if(!granted)
			{
				if(domain == checkDomain)
				{
					dynAppend(domains, domain);
				}
			}
		}
		AccessControlOperatorGranted[topIndex][i] = granted;
		AccessControlExpertGranted[topIndex][i] = expert_granted;
//DebugN("AccessControlOperatorGranted", $node, topIndex, i, domain, accessc, AccessControlOperatorGranted[topIndex][i]);
	}
	if(dynlen(domains))
	{
		if(!shapeExists("Message"))
			delay(2);
    if(!isATLAS())
		  fwUi_logoutUser();
		for(i = 1; i <= dynlen(domains); i++)
		{
//			fwUi_report("Access Control: User "+AccessControlCurrentUser+" Can Not Operate "+domains[i]+"");
			fwUi_report("*** WARNING - Access Control: User "+user+" Can Not Operate "+domains[i]+" ***");
		}
	}
}

fwUi_logoutUser()
{
string mode;

	if(fwUi_releaseTree($node, $obj))
	{
		fwUi_report("*** INFO - Access Control: User "+AccessControlCurrentUser+" Logged Out, "+$node+" Released.");
	}
}

int fwUi_getOperatorAccess(string domain)
{
int index, topIndex;
string accessc;
dyn_string items, exInfo;
int granted, expert_granted;

	granted = 1;
	expert_granted = 1;
	topIndex = dynContains(AccessControlTopNodes, $domain);
	if(!topIndex)
		return 1;
	index = fwUi_getAccessInfo(topIndex, makeDynString(domain));
	if(!index)
		return 1;
	accessc = AccessControlNodeSettings[topIndex][index];
	if((accessc != "") && (accessc[0] != "!"))
	{
		items = strsplit(accessc,"|");
		fwAccessControl_isGranted (items[1], granted, exInfo);
		expert_granted = granted;
		if(dynlen(items) == 2)
			fwAccessControl_isGranted (items[2], expert_granted, exInfo);
	}
	AccessControlOperatorGranted[topIndex][index] = granted;
	AccessControlExpertGranted[topIndex][index] = expert_granted;
	return granted;
}

int fwUi_getExpertAccess(string domain)
{
int index, topIndex;
string accessc;
dyn_string items, exInfo;
int granted, expert_granted;

	granted = 1;
	expert_granted = 1;
	topIndex = dynContains(AccessControlTopNodes, $domain);
	if(!topIndex)
		return 1;
	index = fwUi_getAccessInfo(topIndex, makeDynString(domain));
	if(!index)
		return 1;
	accessc = AccessControlNodeSettings[topIndex][index];
	if((accessc != "") && (accessc[0] != "!"))
	{
		items = strsplit(accessc,"|");
		fwAccessControl_isGranted (items[1], granted, exInfo);
		expert_granted = granted;
		if(dynlen(items) == 2)
			fwAccessControl_isGranted (items[2], expert_granted, exInfo);
	}
	AccessControlOperatorGranted[topIndex][index] = granted;
	AccessControlExpertGranted[topIndex][index] = expert_granted;
	return expert_granted;
}
