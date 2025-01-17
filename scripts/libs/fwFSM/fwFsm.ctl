#uses "fwFSM/fwCU.ctl"
#uses "fwFSM/fwDU.ctl"
#uses "fwFSM/fwUi.ctl"
#uses "fwFSM/fwFsmTreeDisplay.ctl"
#uses "fwFSM/fwFsmUi.ctl"
#uses "fwFSM/fwDevModeDU.ctl"
#uses "fwFSM/fwFsmUtil.ctl"

const string fwFsm_separator = "|";
const string fwDev_separator = "/";
const string fwFsm_clipboardNodeName = "---ClipboardFSM---";
const int FwFSM_UnionFlag = 1;

dyn_string CurrfwChildrenObjs;
dyn_string CurrfwChildrenTypes;
dyn_string CurrObjTypes;
dyn_dyn_string CurrObjsTypes;
dyn_string CurrObjs, CurrUsedObjs, CurrUsedTypes, CurrUsedAllObjs, CurrUsedAllTypes;
string CurrObj;
int RemCurrObj;
string CurrPart;
dyn_string CurrParts;

const string fwFsm_typeSeparator = "___&";
const string fwFsm_actionSeparator = "----------";

/* temporary fix for PVSS beta 3.0 */

dyn_string mydpNames(string search, string type)
{
  dyn_string all_dps, dps;
  int i;
  string dptype;

  all_dps = dpNames(search);
  for(i = 1; i <= dynlen(all_dps); i++)
  {
    dptype = dpTypeName(all_dps[i]);
    if(dptype == type)
      dynAppend(dps, all_dps[i]);
  }
  return dps;
}

string fwFsm_capitalize(string str)
{
  string newstr;

  newstr = strtoupper(str);
  return(newstr);
}

string fwFsm_formSetName(string type, string end)
{
  string setname;

  setname = fwFsm_capitalize(type) + "_FWSET"+end;
  return setname;
}

int fwFsm_isAssociated(string obj)
{
  int pos;

  if((pos = strpos(obj,"::")) >= 0)
    return 1;
  if((pos = strpos(obj,fwFsm_separator)) >= 0)
    return 1;
  else
    return 0;
}
/*
int fwFsm_isProxy(string obj)
{
dyn_string syss;
dyn_uint ids;
int i;

	getSystemNames(syss, ids);
	for(i = 1; i <= dynlen(syss); i++)
	{
//		if(dpExists(syss[i]+":"+"fwDU_"+obj))
		if(dpExists(syss[i]+":"+obj))
		{
			if(dpTypeName(syss[i]+":"+obj) != "_FwNode")
				return(1);
		}
	}
	return(0);

}
*/

int fwFsm_isProxyDp(string dp)
{
//DebugTN("isProxyType",dp, dpTypeName(dp), "_FwFsmDevice");
//DebugTN("isProxyDp1",dp, dpTypeName(dp));
  if(dpTypeName(dp) == "_FwFsmDevice")
    return(1);
  return(0);
}

int fwFsm_isProxy(string obj)
{
  dyn_string dps;

//	if(fwFsm_isLogicalDeviceName(obj))
//		obj = fwFsm_getPhysicalDeviceName(obj);
  if(fwFsm_isAssociated(obj))
    obj = fwFsm_convertAssociated(obj);
  dps = fwFsm_getDps("*:*"+fwFsm_separator+obj,"_FwFsmDevice");
  if(dynlen(dps))
  {
    return(1);
  }
  return(0);
}

int fwFsm_isProxyType(string obj_type)
{
  dyn_string types, items;
  string type, type1;

  types = dpTypes();
  if(dynContains(types,obj_type))
    return(1);
  type = fwFsm_getDeviceBaseType(obj_type);
  if(type != "")
  {
    if(dynContains(types,type))
    {
      type1 = fwFsm_formType(obj_type);
      dpGet(type1+".components:_online.._value", items);
      if(!dynlen(items))
        return 0;
      return 1;
    }
  }
  return 0;
}

string fwFsm_convertAssociated(string obj)
{
  int pos;
  string res, aux;

//	res = obj;
//	strreplace(res,"::",fwFsm_separator);

  if((pos = strpos(obj,"::")) >= 0)
  {
    aux = substr(obj,pos+2);
    res = substr(obj,0,pos);
    res += fwFsm_separator+aux;
  }
  else
    res = obj;

  return res;
}

string fwFsm_getAssociatedDomain(string obj)
{
  int pos;
  string res, aux;

  if((pos = strpos(obj,"::")) >= 0)
  {
    res = substr(obj,0,pos);
  }
  else
    res = "";
  return res;
}

string fwFsm_getAssociatedObj(string obj)
{
  int pos;
  string res, aux;

  if((pos = strpos(obj,"::")) >= 0)
  {
    res = substr(obj,pos+2);
  }
  else
    res = obj;
  return res;
}

string fwFsm_convertToAssociated(string obj)
{
  int pos;
  string res, aux;

  if((pos = strpos(obj,fwFsm_separator)) >= 0)
  {
    aux = substr(obj,pos+1);
		  res = substr(obj,0,pos);
		  res += "::"+aux;
  }
  else
    res = obj;
  return res;
}

string fwFsm_deleteOtherDps(string search, string type, dyn_string list)
{
  dyn_string names;
  int i, j, found;

  names = dpNames(search,type);
  for(i = 1; i <= dynlen(names); i++)
  {
    names[i] = fwFsm_extractSystem(names[i]);
    if(!dynContains(list, names[i]))
    {
      if(dpExists(names[i]+".mode.modeBits"))
      {
        dpSetWait(names[i]+".mode.modeBits:_dp_fct.._type", 0);
//DebugN("Disconnected",names[i]+".mode.modeBits:_dp_fct.._type");
      }
      dpDelete(names[i]);
    }
  }
}

fwFsm_createDomainObjects(string domain, dyn_string objs, dyn_string types, dyn_int cus, dyn_string tnodes)
{
  dyn_string full_objs, domain_objs, phys_objs, diff_types;
  dyn_dyn_string type_objs;
  string subdomain, subobj, type, tmp_obj;
  int i, j, ass, index, answer, done = 0;
  string dp, old_label, panel, sys, dev, devtype;
  dyn_string old_panels, items, lunits, lus, refs, exInfo;
  int pos, hasProxys = 0, hasLogicals = 0;
  mapping obj_parts;

//DebugN("fwFsm_createDomainObjects",domain, objs, types, cus, tnodes);
//DebugTN("Gen 111");
  for(i = 1; i <= dynlen(objs); i++)
  {
    dynAppend(lus, "");
//		dynAppend(refs, "");
  }
//DebugTN("Gen 112");
  if(!(index = dynContains(objs,domain+"_FWM")))
  {
    dynAppend(objs,domain+"_FWM");
    dynAppend(types,"FwMode");
    dynAppend(cus, 0);
    dynAppend(tnodes,"");
    dynAppend(lus, "");
//		dynAppend(refs, "");
  }
  else
  {
    types[index] = "FwMode";
  }

//DebugTN("Gen 113");
  if(!(index = dynContains(objs,domain+"_FWCNM")))
  {
    dynAppend(objs,domain+"_FWCNM");
		  dynAppend(types,"FwChildrenMode");
		  dynAppend(cus, 0);
		  dynAppend(tnodes,"");
		  dynAppend(lus, "");
//		dynAppend(refs, "");
  }
  else
  {
    types[index] = "FwChildrenMode";
  }
  for(i = 1; i <= dynlen(objs); i++)
  {
//DebugTN("Gen 114", objs[i]);
    if((pos = strpos(objs[i],"@")) >= 0)
    {
      subdomain = substr(objs[i],pos+1);
//DebugN("found subdomain",i, objs[i], subdomain);
      objs[i] = substr(objs[i],0,pos);
      lus[i] = subdomain;
//DebugN("obj",i, objs[i]);
      if(!(index = dynContains(objs, domain+"/"+subdomain+"_FWDM")))
      {
/*
				dynAppend(objs,domain+"/"+subdomain+"_FWDM");
				dynAppend(types,"FwDevMode");
				dynAppend(cus, 0);
				dynAppend(tnodes,"");
*/
        dynInsertAt(objs,domain+"/"+subdomain+"_FWDM",1);
				    dynInsertAt(types,"FwDevMode",1);
				    dynInsertAt(cus, 0,1);
				    dynInsertAt(tnodes,"",1);
				    dynInsertAt(lus, "", 1);
//				dynInsertAt(refs, "", 1);
        i++;
      }
      else
      {
        types[index] = "FwDevMode";
      }
      if(!dynContains(lunits, subdomain))
        dynAppend(lunits, subdomain);
    }
    if(fwFsm_isAssociated(objs[i]))
    {
//			if((pos = strpos(objs[i],"@")) >= 0)
//			{
//				objs[i] = substr(objs[i],0,pos);
//			}
      subdomain = fwFsm_getAssociatedDomain(objs[i]);
      subobj = fwFsm_getAssociatedObj(objs[i]);
      if(cus[i])
      {
        if(!(index = dynContains(objs,subdomain+"::"+subdomain+"_FWM")))
        {
          dynAppend(objs,subdomain+"::"+subdomain+"_FWM");
          dynAppend(types,"FwMode");
          dynAppend(cus, 0);
          dynAppend(tnodes,"");
          dynAppend(lus, "");
//					dynAppend(refs, "");
        }
        else
        {
          types[index] = "FwMode";
        }
        if(!(index = dynContains(objs,subdomain+"_FWM")))
        {
          dynAppend(objs,subdomain+"_FWM");
          dynAppend(types,"FwChildMode");
          dynAppend(cus, 0);
          dynAppend(tnodes,"");
          dynAppend(lus, "");
//					dynAppend(refs, "");
        }
        else
        {
          types[index] = "FwChildMode";
        }
        if(!(index = dynContains(objs, subdomain+"::"+subdomain+"_FWCNM")))
        {
          dynAppend(objs,subdomain+"::"+subdomain+"_FWCNM");
          dynAppend(types,"FwChildrenMode");
          dynAppend(cus, 0);
          dynAppend(tnodes,"");
          dynAppend(lus, "");
//					dynAppend(refs, "");
        }
        else
        {
          types[index] = "FwChildrenMode";
        }
      }
      else
      {
//				fwTree_getNodeDevice(tnodes[i], dev, devtype, exInfo);
//				strreplace(dev,"::","|");
//				refs[i] = dev;
//DebugN("is Reference", objs[i]);
        if( (strpos(objs[i],"_FW") < 0) && (subdomain != domain))
        {
          hasLogicals = 1;
        }
      }
    }
    else
    {
      if(fwFsm_isProxyType(types[i]))
      {
        hasProxys = 1;
      }
      else
      {
        if( (strpos(objs[i],"_FW") < 0) && (objs[i] != domain))
        {
          hasLogicals = 1;
        }
      }
//DebugTN("CreateDomainObj", domain, objs[i], types[i], hasProxys, hasLogicals);
    }
  }
//DebugN(objs, hasProxys, hasLogicals);
//DebugTN("Gen 115");
  if(hasProxys || hasLogicals)
  {
    dyn_string dev_modes, aux_dev_modes;
    string aux_type;
    int pos;

    if(!(index = dynContains(objs, domain+"_FWDM")))
    {
      dynAppend(objs,domain+"_FWDM");
      dynAppend(types,"FwDevMode");
      dynAppend(cus, 0);
      dynAppend(tnodes,"");
      dynAppend(lus, "");
//			dynAppend(refs, "");
    }
    else
    {
      types[index] = "FwDevMode";
    }
//DebugTN("CreateDomainObjects", objs, types, cus);
    for(i = 1; i <= dynlen(objs); i++)
    {
      if((cus[i] == 0) && (strpos(objs[i],"_FW") < 0))
      {
        if(!dynContains(dev_modes, lus[i]+types[i]+"_FWDM"))
          dynAppend(dev_modes, lus[i]+types[i]+"_FWDM");
        aux_type = types[i];
        if((pos = strpos(aux_type,fwFsm_typeSeparator)) > 0)
        {
          aux_type = substr(aux_type, 0, pos);
          dynAppend(aux_dev_modes, lus[i]+aux_type+"_FWDM");
        }
      }
    }
//DebugTN("fwFsm_createDomainObjects - Adding", dev_modes);
    for(i = 1; i <= dynlen(aux_dev_modes); i++)
    {
      if(!dynContains(dev_modes, aux_dev_modes[i]))
      {
        dynAppend(dev_modes, aux_dev_modes[i]);
      }
    }
//DebugTN("fwFsm_createDomainObjects - Adding 1", dev_modes);
    for(i = 1; i <= dynlen(dev_modes); i++)
    {
		    dynAppend(objs,dev_modes[i]);
      dynAppend(types,"");
      dynAppend(cus, 0);
      dynAppend(tnodes,"");
      dynAppend(lus, "");
//			dynAppend(refs, "");
    }
//DebugTN("CreateDomainObjects 1", objs, types, cus);
//DebugN("DEV_MODES", dev_modes);
  }
//DebugN("Really Creating", domain, objs, type, cus, lus);
  for(i = 1; i <= dynlen(objs); i++)
  {
//DebugTN("Gen 116", objs[i]);
    sys = fwFsm_getSystem(objs[i]);
    objs[i] = fwFsm_extractSystem(objs[i]);
    tmp_obj = objs[i];
    full_objs[i] = fwFsm_convertAssociated(tmp_obj);
    domain_objs[i] = domain+fwFsm_separator+full_objs[i];
    phys_objs[i] = fwFsm_getPhysicalDeviceName(tmp_obj);
    if(sys != "")
      phys_objs[i] = sys+":"+phys_objs[i];
//DebugN(i, domain_objs[i]);
    ass = 0;
    if(fwFsm_isAssociated(objs[i]))
      ass = 1;
    answer = 1;
    if((!ass) && (fwFsm_isProxyType(types[i])))
    {
      if(!dpExists(phys_objs[i]))
      {
/*
				if(!done)
				{
					fwUi_askUser("Do you want to create the devices of Domain "+domain+"?",120, 100, 0, answer);
					done = 1;
				}
*/
				// no automatic dp creation for ATLAS
        if(isATLAS() && strpos(phys_objs[i],"_FW")<0 )
          answer = 0;
        if(answer)
        {
          if(strpos(phys_objs[i],"_FW") < 0)
DebugTN("Generating Domain: "+domain+" - DP for DU "+phys_objs[i]+" did not Exist. Creating it...");
          type = fwFsm_getDeviceBaseType(types[i]);
          if(type != "")
            dpCreate(phys_objs[i],type);
          else
            dpCreate(phys_objs[i],types[i]);
//					fwFsm_setAlarm(phys_objs[i]);
        }
      }
      if(dpExists(phys_objs[i]) || ( isATLAS() && strpos(phys_objs[i],"_FW")<0 ) )
      {
//DebugN("Setting alarm for "+objs[i]);
//				fwFsm_setAlarm(phys_objs[i]);
/*
				fwFsm_createDeviceRef(objs[i], domain);
				fwFsm_setDeviceDomain(objs[i], domain);
*/
//DebugN("Creating dp for",domain_objs[i]);
        if(!dpExists(domain_objs[i]))
        {
          dpCreate(domain_objs[i],"_FwFsmDevice");
          dpSet(domain_objs[i]+".mode.enabled",1);
        }
//				dpSet(domain_objs[i]+".mode.enabled",1);
        if (strpos(full_objs[i],"_FWDM") < 0)
        {
//DebugN(domain_objs[i], "isDU");
          fwFsm_setupDUModeBits(domain, full_objs[i], lus[i]);
        }
//DebugN("Setup DU",domain, full_objs[i]);
      }
      if(!(index = dynContains(diff_types,types[i])))
        index = dynAppend(diff_types,types[i]);
//DebugN("curr_obj",diff_types, index, objs[i], full_objs[i], domain_objs[i], phys_objs[i]);
      if(sys != "")
        dynAppend(type_objs[index],sys+":"+objs[i]);
      else
        dynAppend(type_objs[index],objs[i]);
    }
    else
    {
      if(!dpExists(domain_objs[i]))
      {
        dpCreate(domain_objs[i],"_FwFsmObject");
        dpSet(domain_objs[i]+".mode.enabled",1);
      }
//			dpSet(domain_objs[i]+".mode.enabled",1);
//DebugN(domain_objs[i], "cu = ",cus[i]);
			  items = strsplit(domain_objs[i],"|");
//			if((items[dynlen(items)] != (items[dynlen(items)-1])) &&
//				(strpos(items[dynlen(items)],"_FW") < 0))
      if((!cus[i]) && (strpos(items[dynlen(items)],"_FW") < 0))
      {
        if(dynContains(lunits, full_objs[i]))
        {
          fwFsm_setupLobjModeBits(domain, full_objs[i], lus[i]);
//DebugN("isLobj",domain, i, full_objs[i]);
        }
        else
        {
//DebugN("isDU",domain, i, full_objs[i]);
          fwFsm_setupDUModeBits(domain, full_objs[i], lus[i]);
        }
//DebugN("setupLobj",domain, full_objs[i], lunits);
      }
    }
    if(dynlen(types) >= 1)
    {
      dpSet(domain_objs[i]+".type:_original.._value", types[i]);
    }
    if(dynlen(tnodes) >= 1)
    {
      string part = "";
      if(tnodes[i])
        tnodes[i] = getSystemName()+tnodes[i];

      if(lus[i] != "")
      {
        part = lus[i];

        if(!mappingHasKey(obj_parts, domain_objs[i]))
          obj_parts[domain_objs[i]] = part;
        else
        {
          obj_parts[domain_objs[i]] = obj_parts[domain_objs[i]]+","+part;
        }
        part = obj_parts[domain_objs[i]];
      }
//DebugTN("Setting part",domain_objs[i], part);
      dpSet(domain_objs[i]+".tnode:_original.._value", tnodes[i],
            domain_objs[i]+".part:_original.._value", part);
    }
/*
		fwFsm_getObjectLabelPanel(domain_objs[i], label, panel);
		if(label == "")
		{
			if(ass)
			{
				label = fwFsm_getAssociatedObj(objs[i]);
			}
		}
*/
/*

		dp = domain_objs[i];
		dpGet(dp+".ui.label:_online.._value",old_label);
		if(old_label == "")
		{
			if(ass)
			{
				old_label = fwFsm_getAssociatedObj(objs[i]);
//				fwFsm_getObjectReferenceSystem(tnodes[i], sys);
//				old_label = fwFsm_getLogicalDeviceName(sys+":"+old_label);
			}
		}
		dpGet(dp+".ui.panels:_online.._value",old_panels);
//		fwUi_getTypePanel(types[i], panel);
//		if(dynlen(old_panels) >= 2)
		if(dynlen(old_panels))
		{
//			if((old_panels[2] == types[i]+".pnl") && (panel != types[i]+".pnl"))
				fwFsm_setObjectLabelPanel(domain, full_objs[i], old_label, "", -1, -1);
		}
		else
		{
				fwFsm_setObjectLabelPanel(domain, full_objs[i], old_label, "", 1, 1);
		}
*/
    fwFsm_setObjectLabelPanel(domain, full_objs[i],"","",-1,-1);
  }

//DebugTN("Gen 117");
//  fwFsm_doRemoveTypeScripts(domain);
  fwFsm_cleanupDomainScripts(domain);
//DebugTN("Gen 118");
  for(i = 1; i <= dynlen(diff_types); i++)
  {
//DebugN("Creating scripts for", domain, diff_types[i], type_objs[i]);
//		dynRemove(type_objs[i],1);
//		dynRemove(type_objs[i],1);
//		fwFsm_doWriteDomainTypeScripts(domain, diff_types[i], type_objs[i]);
    fwFsm_writeDomainTypeScripts(domain, diff_types[i], type_objs[i]);
  }
//DebugTN("Gen 119");
  fwFsm_deleteOtherDps(domain+fwFsm_separator+"*","_FwFsmObject",domain_objs);
  fwFsm_deleteOtherDps(domain+fwFsm_separator+"*","_FwFsmDevice",domain_objs);
  fwFsm_setupSummaryAlarms(domain);
//DebugTN("Gen 120");
}

fwFsm_setMainPanel(string panel, int width = 0, int height = 0)
{
  dyn_string objs;
  int i;
  string domain, obj, old_panel;
  dyn_string panels, exInfo;

  fwTree_getNodeUserData("FSM", panels, exInfo);
  old_panel = panels[1];
  if(panel == "")
  {
    panel = panels[1];
  }
  panels[1] = panel;

  panels[2] = width;
  panels[3] = height;

  fwTree_setNodeUserData("FSM", panels, exInfo);

  if(panel != old_panel)
  {
    objs = fwFsm_getAllObjects();
    for(i = 1; i <= dynlen(objs); i++)
    {
      domain = fwFsm_getAssociatedDomain(objs[i]);
      obj = fwFsm_getAssociatedObj(objs[i]);
      fwFsm_setObjectMainPanel(domain, obj, panel);
    }
  }
}

dyn_int fwFsm_getMainPanelSize()
{
  dyn_int size;
  dyn_string panels, exInfo;

  size[1] = 0;
  size[2] = 0;
  fwTree_getNodeUserData("FSM", panels, exInfo);
  if(dynlen(panels) > 1)
  {
    size[1] = (int) panels[2];
    size[2] = (int) panels[3];
  }
  return size;
}

fwFsm_setObjectMainPanel(string domain, string obj, string panel)
{
  string dp;
  dyn_string panels;

  if(fwFsm_isAssociated(obj))
  {
    obj = fwFsm_convertAssociated(obj);
  }
  dp = domain+fwFsm_separator+obj;

  dpGet(dp+".ui.panels:_original.._value",panels);
  panels[1] = panel;
  dpSet(dp+".ui.panels:_original.._value",panels);
}

string fwFsm_getMainPanel()
{
  dyn_string panels, exInfo;
  string panel;

  fwTree_getNodeUserData("FSM", panels, exInfo);
  if(dynlen(panels))
    panel = panels[1];
  if(panel == "")
    panel = fwFsm_getDefaultMainPanel();
  return panel;
}

string fwFsm_getDefaultMainPanel()
{
  dyn_string panels, exInfo;
  string panel;

//	fwTree_getNodeUserData("FSM", panels, exInfo);
//	panel = panels[1];
  panel = "fwFSMuser/fwUi.pnl";
  return panel;
}

string fwFsm_getDefaultLabel(string domain, string obj)
{
  string obj_label;
  dyn_string items;
  int n;

  obj_label = obj;
  if(fwFsm_isAssociated(obj))
  {
    obj = fwFsm_convertAssociated(obj);
    obj_label = fwFsm_getAssociatedObj(obj);
  }
//DebugN(domain, obj, obj_label);
  items = strsplit(obj_label,"/|");
  if((n = dynlen(items)))
    obj_label = items[n];
  return obj_label;
}

string fwFsm_getDefaultPanel(string domain, string obj)
{
  string dp, type, type_panel;

  if(fwFsm_isAssociated(obj))
  {
    obj = fwFsm_convertAssociated(obj);
  }
  dp = domain+fwFsm_separator+obj;
  dpGet(dp+".type:_original.._value",type);
  fwUi_getTypePanel(type, type_panel);

  return type_panel;
}

fwFsm_setObjectLabelPanel(string domain, string obj, string label, string panel,
	int visi, int oper)
{
  string dp, suffix, old_label, main_panel, tnode, sys;
  dyn_string old_panels, obj_panels, items, udata, exInfo;
  int n, pos, old_visi, old_oper, set_udata;
  int set_flag = 0;

  pos = strpos(obj, "_FW");
  if(pos > 0)
  {
    suffix = substr(obj, pos);
    if((suffix == "_FWM") || (suffix == "_FWCNM") || (suffix == "_FWDM"))
      return;
  }

  if(fwFsm_isAssociated(obj))
  {
    obj = fwFsm_convertAssociated(obj);
  }
  dp = domain+fwFsm_separator+obj;
  if(!dpExists(dp))
  {
    fwUi_getDomainSys(domain, sys);
    dp = sys+domain+fwFsm_separator+obj;
  }
  dpGet(	dp+".ui.label", old_label,
  dp+".ui.panels", old_panels,
		dp+".ui.visible", old_visi,
		dp+".ui.operatorControl",old_oper,
		dp+".tnode", tnode);

  fwTree_getNodeUserData(tnode, udata, exInfo);

  main_panel = fwFsm_getMainPanel();
  if(!dynlen(udata))
  {
    if(old_label == "")
    {
      udata[1] = 1;
      udata[2] = 1;
      udata[3] = fwFsm_getDefaultLabel(domain, obj);
      udata[4] = "";
    }
    else
    {
      udata[1] = old_visi;
      udata[2] = old_oper;
      udata[3] = old_label;
      n = dynlen(old_panels);
      if(n)
      {
        main_panel = old_panels[1];
        if((n == 2) && (old_panels[2] != fwFsm_getDefaultPanel(domain, obj)))
          udata[4] = old_panels[2];
        else
          udata[4] = "";
      }
    }
    set_udata = 1;
  }

  if(label != "")
  {
    udata[3] = label;
  }
  else
  {
    if(udata[3] == "")
    {
      items = strsplit(old_label,"/|");
      if((n = dynlen(items)))
      {
        udata[3] = items[n];
      }
    }
  }


  if(panel != "")
  {
    if(panel != fwFsm_getDefaultPanel(domain, obj))
    {
      udata[4] = panel;
    }
    else
      udata[4] = "";
  }
  obj_panels[1] = main_panel;
  if(udata[4] != "")
    obj_panels[2] = udata[4];
  else
  {
    if(dynlen(obj_panels) == 2)
      dynRemove(obj_panels,2);
  }

  if(visi != -1)
    udata[1] = visi;
  if(oper != -1)
    udata[2] = oper;

  if(	(old_label != udata[3]) ||
		(old_panels != obj_panels) ||
		(old_visi != udata[1]) ||
		(old_oper != udata[2]) )
    set_flag = 1;

  if(set_flag)
  {
    dpSet(	dp+".ui.label", udata[3],
    dp+".ui.panels", obj_panels,
    dp+".ui.visible", udata[1],
    dp+".ui.operatorControl",udata[2]);
  }
  if( set_udata || set_flag)
  {
    fwTree_setNodeUserData(tnode, udata, exInfo);
  }
}

/*
fwFsm_setObjectLabelPanel(string domain, string obj, string label, string panel,
	int visi, int oper)
{
	string dp, obj_label, suffix, old_label, tnode;
	dyn_string old_panels, obj_panels, items, udata, exInfo, orig_panels;
	int n, pos, obj_visi, obj_oper, old_visi, old_oper, set_label, set_panel, set_udata;

	set_label = 0;
	set_panel = 0;
	set_udata = 0;

	pos = strpos(obj, "_FW");
	if(pos > 0)
	{
		suffix = substr(obj, pos);
		if((suffix == "_FWM") || (suffix == "_FWCNM") || (suffix == "_FWDM"))
			return;
	}

	if(fwFsm_isAssociated(obj))
	{
		obj = fwFsm_convertAssociated(obj);
	}
	dp = domain+fwFsm_separator+obj;
	dpGet(	dp+".ui.label", old_label,
		dp+".ui.panels", old_panels,
		dp+".tnode", tnode);

	obj_visi = visi;
	obj_oper = oper;

	orig_panels = old_panels;
	fwTree_getNodeUserData(tnode, udata, exInfo);

	if(old_label == "")
	{
		if(dynlen(udata))
		{
			obj_label = udata[3];
			obj_visi = udata[1];
			obj_oper = udata[2];
			if(udata[4] != "")
			{
				old_panels[1] = fwFsm_getDefaultMainPanel();
				old_panels[2] = udata[4];
			}
		}
		else
		{
			obj_label = fwFsm_getDefaultLabel(domain, obj);
			obj_visi = 1;
			obj_oper = 1;
		}
	}
	else
		obj_label = old_label;
	if(label != "")
		obj_label = label;

	if(old_label != obj_label)
		set_label = 1;

	if(!dynlen(old_panels))
		obj_panels[1] = fwFsm_getDefaultMainPanel();
	else
		obj_panels[1] = old_panels[1];
	if(panel != "")
	{
		if(panel != fwFsm_getDefaultPanel(domain, obj))
		{
			obj_panels[2] = panel;
		}
	}
	else
	{
		if(dynlen(old_panels) == 2)
		{
			if((old_panels[2] != fwFsm_getDefaultPanel(domain, obj)) && (old_panels[2] != ""))
				obj_panels[2] = old_panels[2];
		}
	}
	if(obj_panels != orig_panels)
		set_panel = 1;

	if(!dynlen(udata))
	{
		if(obj_visi == -1)
			dpGet(dp+".ui.visible",old_visi);
		if(obj_oper == -1)
			dpGet(dp+".ui.operatorControl",old_oper);
		udata[1] = old_visi;
		udata[2] = old_oper;
		udata[3] = obj_label;
		if(dynlen(obj_panels) == 2)
			udata[4] = obj_panels[2];
		else
			udata[4] = "";
		set_udata = 1;
	}
	if(set_label)
	{
		dpSet(dp+".ui.label",obj_label);
		udata[3] = obj_label;
	}
	if(set_panel)
	{
		dpSet(dp+".ui.panels",obj_panels);
		if(dynlen(obj_panels) == 2)
			udata[4] = obj_panels[2];
		else
			udata[4] = "";
	}
	if(obj_visi != -1)
	{
		dpSet(dp+".ui.visible",obj_visi);
		udata[1] = obj_visi;
	}
	if(obj_oper != -1)
	{
		dpSet(dp+".ui.operatorControl",obj_oper);
		udata[2] = obj_oper;
	}

	if( set_udata || set_label || set_panel || (obj_visi != -1) || (obj_oper != -1))
	{
		fwTree_setNodeUserData(tnode, udata, exInfo);
	}
}
*/
/*
fwFsm_setObjectLabelPanel(string domain, string obj, string label, string panel,
	int visi, int oper)
{
	string dp, obj_label, type, type_panel, suffix;
	dyn_string panels, items;
	int n, pos;

	pos = strpos(obj, "_FW");
	if(pos > 0)
	{
		suffix = substr(obj, pos);
		if((suffix == "_FWM") || (suffix == "_FWCNM") || (suffix == "_FWDM"))
			return;
	}
//	fwFsm_getTreeNode(domain, obj);
	obj_label = obj;
	if(fwFsm_isAssociated(obj))
	{
		obj = fwFsm_convertAssociated(obj);
		obj_label = fwFsm_getAssociatedObj(obj);
	}
	dp = domain+fwFsm_separator+obj;
	if(label == "")
		label = obj_label;
	items = strsplit(label,"/");
	if((n = dynlen(items)))
		label = items[n];
	dpSet(dp+".ui.label:_original.._value",label);

	dpGet(dp+".ui.panels:_original.._value",panels);
	if(!dynlen(panels))
		panels[1] = fwFsm_getDefaultMainPanel();
	if(panel != "")
		panels[2] = panel;
	if(dynlen(panels) == 2)
	{
		dpGet(dp+".type:_original.._value",type);
		fwUi_getTypePanel(type, type_panel);
		if((type_panel == panels[2]) || (panels[2] == "") || (panel == ""))
			dynRemove(panels,2);
	}
	dpSet(dp+".ui.panels:_original.._value",panels);
	if(strpos(dp,"_FWDM") >= 1)
	{
		dpSet(dp+".ui.visible:_original.._value",0);
		dpSet(dp+".ui.operatorControl:_original.._value",0);
	}
	else
	{
		if(visi != -1)
			dpSet(dp+".ui.visible:_original.._value",visi);
		if(oper != -1)
			dpSet(dp+".ui.operatorControl:_original.._value",oper);
	}
}


fwFsm_getTreeNode(string domain, string obj)
{
	dyn_string exInfo, tnodes;
	string tnode_parent, tnode_device, tnode_type;
	int i;
	dyn_string tnode_items;
	string tnode_obj, tnode_domain, tnode_full_obj, tnode;

//DebugN(domain, obj, label, panel, visi, oper);
	tnode_items = strsplit(obj,"|");
	if(dynlen(tnode_items))
		tnode_obj = tnode_items[dynlen(tnode_items)];
	else
		tnode_obj = obj;
	tnode_full_obj = obj;
	strreplace(tnode_full_obj,"|","::");
	if(dynlen(tnode_items) == 2)
	{
		if(tnode_items[1] == tnode_items[2])
			tnode_full_obj = tnode_obj;
	}
	tnodes = fwTree_getNamedNodes(tnode_obj, exInfo);
	for(i = 1; i <= dynlen(tnodes); i++)
	{
		fwTree_getParent(tnodes[i], tnode_parent, exInfo);
		fwTree_getNodeDevice(tnodes[i], tnode_device, tnode_type, exInfo);
		tnode_device = fwFsm_extractSystem(tnode_device);
		if(tnode_device == tnode_full_obj)
		{
			if(tnode_parent == domain)
			{
				tnode = tnodes[i];
//				DebugN("full1", tnode_full_obj, "tree", tnodes[i], tnode_device, tnode_parent);
				break;
			}
//			DebugN("full", tnode_full_obj, "tree", tnodes[i], tnode_device, tnode_parent);
			tnode = tnodes[i];
		}
	}
//DebugN("**** Found:", domain, obj, tnode);
}
*/
/*
fwFsm_getObjectTreeNode(string domain, string obj, string &tnode)
{
	string dp, aux_domain, aux_obj, sys;
	dyn_string devs;


	fwUi_getDomainSys(domain, sys);
	if(fwFsm_isAssociated(obj))
	{
		aux_domain = fwFsm_getAssociatedDomain(obj);
	}
	obj = fwFsm_convertAssociated(obj);
	dp = sys+domain+fwFsm_separator+obj;
	if(dpExists(dp))
		dpGet(dp+".treeNode:_online.._value",tnode);
	else
	{
		devs = fwFsm_getDomainDevices(aux_domain);
		if(dynlen(devs) == 1)
		{
			dp = sys+domain+fwFsm_separator+aux_domain+fwFsm_separator+devs[1];
			if(dpExists(dp))
				dpGet(dp+".treeNode:_online.._value",tnode);
		}
	}
	if((tnode != "") && (sys != getSystemName()))
		tnode = sys+tnode;
}
*/
/*
int fwFsm_isCU(string domain, string obj)
{
	string dp, subdomain, sys;
	int flag = 0;
*/
/*
	if(domain == obj)
	{
		if(fwFsm_isProxy(obj))
			flag = 0;
		else
			flag = 1;
	}
	else
	{
*/
/*
		if(fwFsm_isAssociated(obj))
		{
			subdomain = fwFsm_getAssociatedDomain(obj);
			obj = fwFsm_getAssociatedObj(obj);
//			obj = fwFsm_convertAssociated(obj);
			fwFsm_getObjectReferenceSystem(obj, sys);
			obj = fwFsm_getLogicalDeviceName(sys+":"+obj);
			obj = subdomain+fwFsm_separator+obj;
		}
		else
		{
			fwFsm_getObjectReferenceSystem(obj, sys);
			obj = fwFsm_getLogicalDeviceName(sys+":"+obj);
		}
//		obj = fwFsm_convertAssociated(obj);
//		obj = fwFsm_convertAssociated(obj);
//		strreplace(obj,":",fwDev_separator);
//		strreplace(domain,":",fwDev_separator);
//		obj = fwFsm_getLogicalDeviceName(obj);
		fwUi_getSysPrefix(domain, dp);
		dp += fwFsm_separator+obj;
		if(dpExists(dp+"_FWM"))
			flag = 1;
//	}
	return flag;
}
*/

string fwFsm_getObjDp(string domain, string obj, string sys = "*")
{
  string dp, ret;

  obj = fwFsm_convertAssociated(obj);
  dp = domain+fwFsm_separator+obj;
  if(sys == "*")
  {
    fwUi_getDomainSys(domain, sys);
  }
  strreplace(sys,":","");
  ret = sys+":"+dp;
  return ret;
}

int fwFsm_objExists(string domain, string obj, string sys = "*")
{
  string dp;
  int ret;

// Attention: doesn't work for all CUs, have to test if isCU first
  ret = 0;
  dp = fwFsm_getObjDp(domain, obj, sys);
  if(dpExists(dp))
    ret = 1;
//DebugTN("------------------------- fwFsm_objExists",domain, obj, dp, ret);
  return ret;
}

int fwFsm_isCU(string domain, string obj, string sys = "*")
{
  string dp;
  int cu;

  cu = 0;
  dp = fwFsm_getObjDp(domain, obj, sys);
  if(dpExists(dp+"_FWM"))
    cu = 1;
//DebugN("**** IsCU?",domain, obj, dp, cu);
  return cu;
}

int fwFsm_isObj(string domain, string obj, string sys = "*")
{
  string dp;
  int ret;

  ret = 0;
  dp = fwFsm_getObjDp(domain, obj, sys);
  if(dpExists(dp))
  {
    if(dpTypeName(dp) == "_FwFsmObject")
    ret = 1;
  }
//DebugN("**** IsObj?",domain, obj, dp, cu);
  return ret;
}

int fwFsm_isLU(string domain, string obj, string sys = "*")
{
  if(fwFsm_isObj(domain, obj, sys))
  {
    if(!fwFsm_isCU(domain, obj, sys))
      return 1;
  }
  return 0;
}

int fwFsm_isDU(string domain, string obj, string sys = "*")
{
  string dp;
  int du;

  du = 0;
  if(fwFsm_isAssociated(obj))
    return du;
  dp = fwFsm_getObjDp(domain, obj, sys);
  if(dpExists(dp))
  {
    if(dpTypeName(dp) == "_FwFsmDevice")
    du = 1;
  }
//DebugN("**** IsDU?",domain, obj, dp, du);
  return du;
}

int fwFsm_isDomain(string domain)
{
  string dp;

  if(fwFsm_isAssociated(domain))
    return 0;

  fwUi_getDomainPrefix(domain, dp);
  if(dpExists(dp))
  {
    return 1;
  }
  return 0;
}

int fwFsm_isDomainInSys(string domain, string sys)
{
  string dp, dpsys;

  fwUi_getDomainPrefix(domain, dp);
  if(dpExists(dp))
  {
    dpsys = fwFsm_getSystem(dp);
    if(dpsys == sys)
      return 1;
  }
  return 0;
}

fwFsm_createDomain(string domain/*, dyn_string obj_list, string label, string panel*/)
{
  if(!dpExists("fwCU_"+domain))
  {
    dpCreate("fwCU_"+domain,"_FwCtrlUnit");
  }
  dpSet("fwCU_"+domain+".mode.exclusivity",1);
  fwUi_setDomainOperation(domain,1);
//	fwFsm_setupCUModeBits(domain);
}

dyn_string fwFsm_getAllObjects()
{
  dyn_string dps, dps1, objs;
  int i;

  dps = fwFsm_getDps("*","_FwFsmObject");
  dps1 = fwFsm_getDps("*","_FwFsmDevice");
  dynAppend(dps, dps1);
  for(i = 1; i <= dynlen(dps); i++)
  {
    objs[i] = fwFsm_convertToAssociated(dps[i]);
    objs[i] = fwFsm_convertToAssociated(objs[i]);
    objs[i] = fwFsm_convertToAssociated(objs[i]);
  }
  return objs;
}

dyn_string fwFsm_getAllObjectDps()
{
  dyn_string dps, dps1, objs;
  int i;

  dps = fwFsm_getDps("*","_FwFsmObject");
  dps1 = fwFsm_getDps("*","_FwFsmDevice");
  dynAppend(dps, dps1);
//	for(i = 1; i <= dynlen(dps); i++)
//	{
//		objs[i] = fwFsm_convertToAssociated(dps[i]);
//		objs[i] = fwFsm_convertToAssociated(objs[i]);
//		objs[i] = fwFsm_convertToAssociated(objs[i]);
//	}
//	return objs;
  return dps;
}

dyn_string fwFsm_getDomainObjects(string domain, int logicals, int devices)
{
  dyn_string dps, dps1, remdps, objs;
  int i, pos;
  string subdomain;

/*
	if(logicals)
		dps = fwFsm_getDps("*:"+domain+fwFsm_separator+"*","_FwFsmObject");
	if(devices)
		dps1 = fwFsm_getDps("*:"+domain+fwFsm_separator+"*","_FwFsmDevice");
*/
  if(logicals)
    dps = fwFsm_getDps(domain+fwFsm_separator+"*","_FwFsmObject");
  if(devices)
    dps1 = fwFsm_getDps(domain+fwFsm_separator+"*","_FwFsmDevice");
  dynAppend(dps, dps1);
  for(i = 1; i <= dynlen(dps); i++)
  {
    pos = strpos(dps[i],fwFsm_separator);
    objs[i] = substr(dps[i],pos+1);
    objs[i] = fwFsm_convertToAssociated(objs[i]);
    objs[i] = fwFsm_convertToAssociated(objs[i]);
  }
  return objs;
}

dyn_string fwFsm_getDomainDevices(string domain)
{
  dyn_string dps, objs, proxies;
  int i, pos, index;
  string subdomain, obj;

  dps = fwFsm_getDomainObjects(domain, 0, 1);
  return dps;
}

dyn_string fwFsm_getDomainDeviceReferences(string domain)
{
  dyn_string dps, refs;
  int i;
  string subdomain, obj;

  dps = fwFsm_getDomainObjects(domain, 1, 0);
//DebugTN("getDomainDeviceReferences", domain, dps);
  for(i = 1; i <= dynlen(dps); i++)
  {
    if(fwFsm_isAssociated(dps[i]))
    {
      subdomain = fwFsm_getAssociatedDomain(dps[i]);
      obj = fwFsm_getAssociatedObj(dps[i]);
      if(subdomain != obj)
      {
        dynAppend(refs, dps[i]);
      }
    }
  }
  return refs;
}

// flags: 1 = CU, 2 = DU, 0 = Obj
dyn_string fwFsm_getObjChildren(string domain, string obj, dyn_int &flags)
{
  dyn_string children, objs, exInfo, devs;
  string sys, dp, tnode;
  int i, dont_add;

//DebugTN("getObjChidlren",domain, obj);
  fwUi_getDomainSys(domain, sys);

  dynClear(flags);
  if(fwFsm_isAssociated(obj))
  {
    obj = fwFsm_convertAssociated(obj);
  }
  dp = sys+domain+fwFsm_separator+obj;

  if(dpExists(dp))
  {
    dpGet(dp+".tnode",tnode);
    fwTree_getChildren(tnode, children, exInfo);
  }
//DebugTN("got Children", tnode, dynlen(children));
  for(i = 1; i <= dynlen(children); i++)
  {
    dont_add = 0;
    if(strpos(children[i],"&") == 0)
    {
      children[i] = fwFsm_getReferencedObjectDevice(sys+children[i]);
      if(domain != obj)
        dont_add = 1;
//DebugN("dont add?", domain, obj, children[i]);
    }
    children[i] = fwFsm_extractSystem(children[i]);
    if(fwFsm_isCU(domain, children[i], sys))
    {
      if(!dont_add)
        children[i] = children[i]+"::"+children[i];
      if(domain == obj)
        dynAppend(flags, 1);
      else
        dynAppend(flags, 0);
    }
    else if(fwFsm_isDU(domain, children[i], sys))
    {
      dynAppend(flags, 2);
    }
    else
    {
      dynAppend(flags, 0);
    }
  }
//DebugN(dp, tnode, children);
//        DebugTN("done tree domain", domain, obj);
  return children;
}

dyn_string fwFsm_getLogicalUnitChildren(string domain, string lunit)
{
  dyn_string children;
  dyn_int flags;

  children = fwFsm_getObjChildren(domain, lunit, flags);
//DebugN("ALL", flags);
  return children;
}

dyn_string fwFsm_getLogicalUnitCUs(string domain)
{
  dyn_string children;
  dyn_int flags;
  int i;

  children = fwFsm_getObjChildren(domain, domain, flags);
  for(i = 1; i <= dynlen(children); i++)
  {
    if(flags[i] != 1)
    {
      dynRemove(children, i);
      dynRemove(flags, i);
      i--;
    }
  }
  return children;
}

dyn_string fwFsm_getLogicalUnitDevices(string domain, string lunit)
{
  dyn_string children;
  dyn_int flags;
  int i;

  children = fwFsm_getObjChildren(domain, lunit, flags);
  for(i = 1; i <= dynlen(children); i++)
  {
    if(flags[i] != 2)
    {
      dynRemove(children, i);
      dynRemove(flags, i);
      i--;
    }
  }
  return children;
}

dyn_string fwFsm_getLogicalUnitObjects(string domain, string lunit)
{
  dyn_string children;
  dyn_int flags;
  int i;

  children = fwFsm_getObjChildren(domain, lunit, flags);
  for(i = 1; i <= dynlen(children); i++)
  {
    if(flags[i] != 0)
    {
      dynRemove(children, i);
      dynRemove(flags, i);
      i--;
    }
  }
  return children;
}
/*
dyn_string fwFsm_getLogicalUnitDevicesOld(string domain, string lunit)
{
	dyn_string devs, logobjs, objs;
	dyn_int flags;
	int i, j, index;

	if(domain == lunit)
	{
		devs = fwFsm_getDomainDevices(domain);
		logobjs = fwFsm_getDomainLogicalObjects(domain);
		for(i = 1; i <= dynlen(logobjs); i++)
		{
			objs = fwFsm_getObjChildren(domain, logobjs[i], flags);
			if(dynlen(objs))
			{
				for(j = 1; j <= dynlen(objs); j++)
				{
					if(index = dynContains(devs, objs[j]))
					{
						dynRemove(devs, index);
					}
				}
			}
		}
	}
	else
	{
		devs = fwFsm_getObjChildren(domain, lunit, flags);
	}
	return devs;
}

dyn_string fwFsm_getLogicalUnitObjectsOld(string domain, string lunit)
{
	dyn_string logobjs, objs;
	dyn_int flags;
	int i;

	if(domain == lunit)
	{
		logobjs = fwFsm_getDomainLogicalObjects(domain);
		objs = fwFsm_getObjChildren(domain, lunit, flags);
//DebugN(logobjs, objs);
		for(i = 1; i <= dynlen(logobjs); i++)
		{
			if(!dynContains(objs, logobjs[i]))
			{
				dynRemove(logobjs, i);
				i--;
				continue;
			}
		}
	}
	else
	{
		logobjs = fwFsm_getObjChildren(domain, lunit, flags);
	}
	return logobjs;
}
*/

dyn_string fwFsm_getLogicalUnitChildrenOfType(string domain, string lunit, string type)
{
  dyn_string children, objs, exInfo;
  dyn_int flags;
  string obj_type;
  int i;

  children = fwFsm_getObjChildren(domain, lunit, flags);
  for(i = 1; i <= dynlen(children); i++)
  {
    fwFsm_getObjectType(domain+"::"+children[i], obj_type);
    if(obj_type == type)
      dynAppend(objs,children[i]);
  }
  return(objs);
}

/*
dyn_string fwFsm_getLogicalUnitChildrenOfType(string domain, string lunit, string type)
{
	dyn_string allobjs, logobjs, objs;
	dyn_int flags;
	int i, j, index;

	fwFsm_getDomainObjectsOfType(domain, type, allobjs);
	if(domain == lunit)
	{
//		devs = fwFsm_getDomainDevices(domain);
		logobjs = fwFsm_getDomainLogicalObjects(domain);
		for(i = 1; i <= dynlen(logobjs); i++)
		{
			objs = fwFsm_getObjChildren(domain, logobjs[i], flags);
			if(dynlen(objs))
			{
				for(j = 1; j <= dynlen(objs); j++)
				{
					if(index = dynContains(allobjs, objs[j]))
					{
						dynRemove(allobjs, index);
					}
				}
			}
		}
	}
	else
	{
		objs = fwFsm_getObjChildren(domain, lunit, flags);
		for(i = 1; i <= dynlen(objs); i++)
		{
			if(!dynContains(allobjs, objs[i]))
			{
				dynRemove(objs, i);
				i--;
				continue;
			}
		}
		allobjs = objs;
	}
	return allobjs;
}
*/

dyn_string fwFsm_getDomainLogicalObjects(string domain)
{
  dyn_string dps, objs, logicals;
  int i, pos;
  string subdomain, obj;

  dps = fwFsm_getDomainObjects(domain, 1, 0);
  for(i = 1; i <= dynlen(dps); i++)
  {
    if(strpos(dps[i],"_FW") < 0)
    {
      if(!fwFsm_isCU(domain, dps[i]))
      {
//				objs[i] = fwFsm_getAssociatedObj(dps[i]);
//				if(!fwFsm_isProxy(objs[i]))
//				{
        dynAppend(logicals, dps[i]);
//				}
      }
    }
  }
  return logicals;
}

fwFsm_getDevicesOfType(string type, dyn_string &syss, dyn_string &devs, string from = "*")
{
  dyn_string dps;
  string sys;
  int i, pos;

  dynClear(devs);
  dynClear(syss);
  strreplace(from,":","");
  dps = dpNames(from+":*.",type);
  for(i = 1; i <= dynlen(dps); i++)
  {
    sys = fwFsm_getSystem(dps[i]);
    dps[i] = fwFsm_extractSystem(dps[i]);
    pos = strpos(dps[i],".");
    dps[i] = substr(dps[i],0,pos);
    if(strpos(dps[i],"_mp_") != 0)
    {
      dynAppend(syss,sys);
      dynAppend(devs,dps[i]);
    }
  }
}

fwFsm_deleteDomainDevice(string domain, string obj)
{
  string dev;

  obj = fwFsm_convertAssociated(obj);
  obj = fwFsm_convertAssociated(obj);
  dev = domain+fwFsm_separator+obj;
//DebugN("Deleting dev", dev);
  if(dpExists(dev))
  {
    if(dpExists(dev+".mode.modeBits"))
    {
      dpSetWait(dev+".mode.modeBits:_dp_fct.._type", 0);
//DebugN("Disconnected",dev+".mode.modeBits:_dp_fct.._type");
    }
    dpDelete(dev);
  }
  if( (strpos(obj,"_FWDM") > 0) || (strpos(obj,"_FWMAJ") > 0))
  {
    dpDelete(obj);
  }
}

fwFsm_cleanupDomainDUs(string domain)
{
  dyn_string children;
  int i;
  string dev, tnode;

  children = fwFsm_getDomainDevices(domain);
  for(i = 1; i <= dynlen(children); i++)
  {
    dev = domain+fwFsm_separator+children[i];
    if(dpExists(dev+".mode.modeBits"))
    {
      dpSetWait(dev+".mode.modeBits:_dp_fct.._type", 0);
//DebugN("Disconnected",dev+".mode.modeBits:_dp_fct.._type");
    }
//		if( (strpos(children[i],"_FWDM") > 0) || (strpos(children[i],"_FWMAJ") > 0))
//		{
/*
			dev = domain+fwFsm_separator+children[i];
			if(dpExists(dev+".mode.modeBits"))
			{
				dpSetWait(dev+".mode.modeBits:_dp_fct.._type", 0);
DebugN("Disconnected",dev+".mode.modeBits:_dp_fct.._type");
			}
*/
//			dpDelete(children[i]);
//		}
    if(strpos(children[i],"_FWDM") > 0)
    {
      dpDelete(children[i]);
    }
    if(strpos(children[i],"_FWMAJ") > 0)
    {
      dpGet(dev+".tnode",tnode);
      if(!dpExists(tnode))
        dpDelete(children[i]);
    }
  }
  children = fwFsm_getDomainLogicalObjects(domain);
  for(i = 1; i <= dynlen(children); i++)
  {
    dev = domain+fwFsm_separator+children[i];
    if(dpExists(dev+".mode.modeBits"))
    {
      dpSetWait(dev+".mode.modeBits:_dp_fct.._type", 0);
//DebugN("Disconnected",dev+".mode.modeBits:_dp_fct.._type");
    }
  }
}

fwFsm_deleteDomainRef(string domain, string ref)
{
  fwFsm_deleteDps(domain+fwFsm_separator+ref+fwFsm_separator+"*","_FwFsmObject");
  fwFsm_deleteDps(domain+fwFsm_separator+ref+"_FWM","_FwFsmObject");
}

fwFsm_deleteDomain(string domain)
{
  dyn_string devs, nodes, children;
  int i, j, index;
  fwFsm_cleanupDomainDUs(domain);
  fwFsm_deleteDps(domain+fwFsm_separator+"*","_FwFsmObject");
  fwFsm_deleteDps(domain+fwFsm_separator+"*","_FwFsmDevice");
  fwFsm_cleanupDomain(domain);
  fwFsm_cleanupDomainScripts(domain);
  dpSetWait("fwCU_"+domain+".mode.modeBits:_dp_fct.._type", 0);
//DebugN("Disconnected","fwCU_"+domain+".mode.modeBits:_dp_fct.._type");
  dpDelete("fwCU_"+domain);
}

fwFsm_getDomainsRec(string domain, dyn_string &dps)
{
  int cu;
  dyn_string exInfo, children;
  int i;

  fwTree_getNodeCU(domain, cu, exInfo);
  if(cu)
  {
    dynAppend(dps, domain);
    fwTree_getChildren(domain, children, exInfo);
    for(i = 1; i <= dynlen(children); i++)
    {
      fwFsm_getDomainsRec(children[i], dps);
    }
  }
}

dyn_string fwFsm_getDomains()
{
  dyn_string dps;
  dyn_string exInfo, domains;
  int i;

//	fwTree_getRootNodes(domains, exInfo);
  fwTree_getChildren("FSM",domains, exInfo);
  for(i = 1; i <= dynlen(domains); i++)
  {
//		if(domains[i] != fwFsm_clipboardNodeName)
//		{
    fwFsm_getDomainsRec(domains[i],dps);
//		}
  }
/*
	dps = fwFsm_getDps("*","_FwCtrlUnit");
	for(i = 1; i <= dynlen(dps) ; i++)
		dps[i] = substr(dps[i],5);
*/
  return(dps);
}

dyn_string fwFsm_getLocalDomains()
{
  dyn_string dps;
  dyn_string exInfo, domains;
  int i;

/*
//	fwTree_getRootNodes(domains, exInfo);
	fwTree_getChildren("FSM",domains, exInfo);
	for(i = 1; i <= dynlen(domains); i++)
	{
//		if(domains[i] != fwFsm_clipboardNodeName)
//		{
			fwFsm_getDomainsRec(domains[i],dps);
//		}
	}
*/
  dps = fwFsm_getDps("*","_FwCtrlUnit");
  for(i = 1; i <= dynlen(dps) ; i++)
    dps[i] = substr(dps[i],5);

  return(dps);
}

dyn_string fwFsm_getAllDeviceTypes()
{
  int i, pos;
  dyn_string dps, more_dps, types, all;
  string devdef;

  all = dpTypes();
  if(dynContains(all,"_FwDeviceDefinition"))
  {
    types = fwFsm_getDps("*","_FwDeviceDefinition");
    for(i = 1; i <= dynlen(types); i++)
    {
      devdef = types[i];
      if(pos = strpos(devdef,"Info"))
      {
        devdef = substr(types[i],0,pos);
        if(fwFsm_isProxyType(devdef))
          dynAppend(dps,devdef);
      }
    }
  }
  more_dps = fwFsm_getDeviceTypes();
  dynAppend(dps,more_dps);
  return dps;
}

dyn_string fwFsm_getFwDeviceTypes()
{
  int i, pos;
  dyn_string dps, types, all;
  string devdef;

  all = dpTypes();
  if(dynContains(all,"_FwDeviceDefinition"))
  {
    types = fwFsm_getDps("*","_FwDeviceDefinition");
    for(i = 1; i <= dynlen(types); i++)
    {
      devdef = types[i];
      if(pos = strpos(devdef,"Info"))
      {
        devdef = substr(types[i],0,pos);
        if(fwFsm_isProxyType(devdef))
          dynAppend(dps,devdef);
      }
    }
  }
  return dps;
}

dyn_string fwFsm_getDeviceTypes()
{
  int i, index;
  dyn_string dps, types;

  types = fwFsm_getAllObjectTypes();
  for(i = 1; i <= dynlen(types); i++)
  {
    if(fwFsm_isProxyType(types[i]))
      dynAppend(dps,types[i]);
  }
  if(!ShowFwObjects)
  {
    if(index = dynContains(dps,"FwDevMode"))
      dynRemove(dps,index);
    if(index = dynContains(dps,"FwDevMajority"))
      dynRemove(dps,index);
  }
  return dps;
}

fwFsm_startShowFwObjects()
{
  addGlobal("ShowFwObjects",INT_VAR);
  ShowFwObjects = 0;
}

fwFsm_showFwObjects(int flag)
{
  ShowFwObjects = flag;
}

dyn_string fwFsm_getObjectTypes()
{
  dyn_string dps, full_dps;
  int i, index;
  string type;

  index = 1;
  fwFsm_getObjectTypeDps(full_dps);
  for(i = 1; i <= dynlen(full_dps); i++)
  {
    if(!fwFsm_isProxyType(full_dps[i]))
      dps[index++] = full_dps[i];
  }
  if(!ShowFwObjects)
  {
    if(index = dynContains(dps,"FwMode"))
      dynRemove(dps,index);
    if(index = dynContains(dps,"FwChildMode"))
      dynRemove(dps,index);
    if(index = dynContains(dps,"FwChildrenMode"))
      dynRemove(dps,index);
  }
/*
	for(i = 1; i <= dynlen(dps); )
	{
		type = fwFsm_getDeviceBaseType(dps[i]);
		if(type != "")
		{
			dynRemove(dps,i);
		}
		else
			i++;
	}
*/
  return dps;
}

dyn_string fwFsm_getAllObjectTypes()
{
  dyn_string dps;
  int index;

  fwFsm_getObjectTypeDps(dps);
  if(!ShowFwObjects)
  {
    if(index = dynContains(dps,"FwMode"))
      dynRemove(dps,index);
    if(index = dynContains(dps,"FwChildMode"))
      dynRemove(dps,index);
    if(index = dynContains(dps,"FwChildrenMode"))
		    dynRemove(dps,index);
    if(index = dynContains(dps,"FwDevMode"))
      dynRemove(dps,index);
    if(index = dynContains(dps,"FwDevMajority"))
      dynRemove(dps,index);
  }
  return dps;
}

dyn_string fwFsm_getOtherObjectTypes()
{
  dyn_string types;
  string type;
  int index;

  type = fwFsm_getSmiObject();
  fwFsm_getObjectTypeDps(types);
  if((index = dynContains(types,type)) > 0)
  {
    dynRemove(types, index);
  }
  return types;
}

fwFsm_createObjectType(string obj, int dev = 0)
{
  fwFsm_createObjectTypeDp(obj, dev);
}

fwFsm_deleteObjectType(string type)
{
  fwFsm_deleteObjectTypeDp(type);
  fwFsm_cleanupObjectType(type);
}

fwFsm_copyObjectType(string old_obj, string new_obj)
{
  int i, j;
  dyn_string states, actions, colors, when_txt, pars/*, action_txt*/;
  dyn_int visis;
  string action_txt;
  int action_time;

  fwFsm_createObjectTypeDp(new_obj);
  fwFsm_getObjectStatesColors(old_obj, states, colors);
  fwFsm_setObjectStatesColors(new_obj, states, colors);
  for(i = 1; i <= dynlen(states); i++)
  {
    fwFsm_readObjectWhens(old_obj,states[i],when_txt);
    fwFsm_writeObjectWhens(new_obj,states[i],when_txt);
    fwFsm_readObjectParameters(old_obj,pars);
    fwFsm_writeObjectParameters(new_obj,pars);

    fwFsm_readObjectActions(old_obj, actions, 1);
    fwFsm_writeObjectActions(new_obj, actions, 1);
    for(j = 1; j <= dynlen(actions); j++)
    {
      fwFsm_readObjectActionText(old_obj,states[i],actions[j],action_txt, 1);
      fwFsm_writeObjectActionText(new_obj,states[i],actions[j],action_txt, 1);
      fwFsm_readObjectActionParameters(old_obj,states[i],actions[j],pars, 1);
      fwFsm_writeObjectActionParameters(new_obj,states[i],actions[j],pars, 1);
    }

    fwFsm_getObjectStateActionsV(old_obj, states[i], actions, visis);
    fwFsm_setObjectStateActionsV(new_obj, states[i], actions, visis);
    for(j = 1; j <= dynlen(actions); j++)
    {
      fwFsm_readObjectActionText(old_obj,states[i],actions[j],action_txt);
      fwFsm_writeObjectActionText(new_obj,states[i],actions[j],action_txt);
      fwFsm_readObjectActionParameters(old_obj,states[i],actions[j],pars);
      fwFsm_writeObjectActionParameters(new_obj,states[i],actions[j],pars);
      fwFsm_readObjectActionTime(old_obj,states[i],actions[j],action_time);
      fwFsm_writeObjectActionTime(new_obj,states[i],actions[j],action_time);
    }
  }
}

fwFsm_copyDeviceType(string old_obj, string new_obj)
{
  int i, j;
  dyn_string states, actions, colors, when_txt, pars/*, action_txt*/;
  dyn_string comps, types, state_comps, action_comps;
  dyn_int visis;
  string action_txt, script;
  int action_time;

  fwFsm_createObjectTypeDp(new_obj);
  fwFsm_getObjectStatesColors(old_obj, states, colors);
  fwFsm_setObjectStatesColors(new_obj, states, colors);
  fwFsm_readObjectParameters(old_obj,pars);
  fwFsm_writeObjectParameters(new_obj,pars);
  fwFsm_readDeviceStateComps(old_obj, comps, types);
  for(i = 1; i <= dynlen(comps); i++)
  {
    dynAppend(state_comps,types[i]+" "+comps[i]);
  }
  fwFsm_readDeviceActionComps(old_obj, comps, types);
  for(i = 1; i <= dynlen(comps); i++)
  {
    dynAppend(action_comps,types[i]+" "+comps[i]);
  }
  fwFsm_writeDeviceTopScript(new_obj,state_comps, action_comps);
  fwFsm_readDeviceInitScript(old_obj, script);
  strreplace(script,old_obj, new_obj);
  fwFsm_writeDeviceInitScript(new_obj, script);

  fwFsm_readDeviceStateScript(old_obj, script);
  strreplace(script,old_obj, new_obj);
  fwFsm_writeDeviceStateScript(new_obj, script);
  fwFsm_readDeviceActionScript(old_obj, script);
  strreplace(script,old_obj, new_obj);
  fwFsm_writeDeviceActionScript(new_obj, script);
  for(i = 1; i <= dynlen(states); i++)
  {
    fwFsm_readObjectWhens(old_obj,states[i],when_txt);
    fwFsm_writeObjectWhens(new_obj,states[i],when_txt);
    fwFsm_getObjectStateActionsV(old_obj, states[i], actions, visis);
    fwFsm_setObjectStateActionsV(new_obj, states[i], actions, visis);
    for(j = 1; j <= dynlen(actions); j++)
    {
      fwFsm_readObjectActionText(old_obj,states[i],actions[j],action_txt);
      fwFsm_writeObjectActionText(new_obj,states[i],actions[j],action_txt);
      fwFsm_readObjectActionParameters(old_obj,states[i],actions[j],pars);
      fwFsm_writeObjectActionParameters(new_obj,states[i],actions[j],pars);
      fwFsm_readObjectActionTime(old_obj,states[i],actions[j],action_time);
      fwFsm_writeObjectActionTime(new_obj,states[i],actions[j],action_time);
    }
  }
}

fwFsm_copyObjectTypeHeader(string old_obj, string new_obj)
{
  int i, j;
  dyn_string states, actions, colors, when_txt, pars, items;
  dyn_int visis;
  string action_txt;
  string end_state;
  int action_time;

  fwFsm_createObjectTypeDp(new_obj);
  fwFsm_getObjectStatesColors(old_obj, states, colors);
  fwFsm_setObjectStatesColors(new_obj, states, colors);
  fwFsm_readObjectParameters(old_obj,pars);
  fwFsm_writeObjectParameters(new_obj,pars);
  for(i = 1; i <= dynlen(states); i++)
  {
//		fwFsm_readObjectWhens(old_obj,states[i],when_txt);
//		fwFsm_writeObjectWhens(new_obj,states[i],when_txt);
    fwFsm_getObjectStateActionsV(old_obj, states[i], actions, visis);
    fwFsm_setObjectStateActionsV(new_obj, states[i], actions, visis);

    for(j = 1; j <= dynlen(actions); j++)
    {
      fwFsm_readObjectActionText(old_obj,states[i],actions[j],action_txt);
//DebugTN(old_obj, states[i], actions[j], action_txt);
      end_state = "";
      if(action_txt != "")
      {
        items = strsplit(action_txt,"\n");
        end_state = items[dynlen(items)];
      }
      fwFsm_writeObjectActionText(new_obj,states[i],actions[j],end_state);
      fwFsm_readObjectActionParameters(old_obj,states[i],actions[j],pars);
      fwFsm_writeObjectActionParameters(new_obj,states[i],actions[j],pars);
      fwFsm_readObjectActionTime(old_obj,states[i],actions[j],action_time);
      fwFsm_writeObjectActionTime(new_obj,states[i],actions[j],action_time);
    }
  }
}

string fwFsm_formatParameters(dyn_string par_list, string offset, string begin, string end)
{
  string s;
  string indent;
  int i;

  for(i = 1; i <= dynlen(par_list); i++)
  {
    if(i == 1)
    {
      s += offset+begin;
    }
    s += par_list[i];
    if(i < dynlen(par_list))
    {
        s += ", ";
    }
    else
    {
      s += end;
    }
  }
  return s;
}

string fwFsm_formatState(string state, string color, string offset)
{
  string s;
  s += offset+"state: "+state+"\n"+offset+"!color: "+color+"\n";
  return s;
}

string fwFsm_formatWhens(string state, dyn_string when_list, string offset, int &flag)
{
  string s, str;
  string indent;
  int i;

  for(i = 1; i <= dynlen(when_list); i++)
  {
    when_list[i] = strrtrim(when_list[i]);
    str = when_list[i];
    if(strpos(str,"$ASS") >= 0)
       flag = 1;
    s+=offset+str+"\n";
  }
  return s;
}

string fwFsm_formatAction(string action, dyn_string par_list, string offset, string begin, string end, int &sep)
{
  string s;
  string indent;
  int i;

  sep = 0;
  if(action == fwFsm_actionSeparator)
  {
    s += offset+"!"+begin+action+"\n";
    return s;
  }
  s += offset+begin+action;

  if(dynlen(par_list))
  {
    s += fwFsm_formatParameters(par_list, "", "(", ")");
  }
  s += end;
  return s;
}

string fwFsm_formatActionText(string action, dyn_string action_text, string offset, int &flag)
{
  string s, str;
  string indent;
  int i;

  for(i = 1; i <= dynlen(action_text); i++)
  {
    str = action_text[i];
    if(strpos(str,"$ASS") >= 0)
      flag = 1;
    s += offset+str+"\n";
  }
/* if(!proxy)
      }
      else
      {
        if(dynlen(action_txt) > 1)
        {
          s += " (";
//          s1 += " (";
          for(k = 2; k <= dynlen(action_txt); k++)
          {
            s += action_txt[k];
//            s1 += action_txt[k];
            if(k != dynlen(action_txt))
            {
              s += ", ";
//              s1 += ", ";
            }
          }
          s += " )";
//          s1 += " )";
        }
        s += "\n";
//        s1 += "\n";
      }
*/
  return s;
}

fwFsm_doWriteObjectType(string obj, string &s, string &s1, string &s2)
{
  dyn_string states, colors, action_list, par_list, when_list, action_txt, action_pars, split1, split2, tempDyn, arguments, types, vars;
  int i, j, k, m, pos, pos1, proxy, flag = 0;
  string action, str, str1, str2, action_line, panel, header, params, fText, temp, parsed;
  dyn_int visi_list;
  file f;
  int sep;
  string tmp;

// DebugN("DoWriteObjectType", obj);
  proxy = fwFsm_isProxyType(obj);
  if(proxy)
  {
    s2 = "class: $FWPART_"+obj+"_FwDevMode_CLASS\n";
    s2 += "    state: READY\n";
    s2 += "        action: Disable(Device)\n";
    s2 += "            remove &VAL_OF_Device from $FWPART_"+fwFsm_formSetName(obj,"STATES")+"\n";
    s2 += "            remove &VAL_OF_Device from $FWPART_"+fwFsm_formSetName(obj,"ACTIONS")+"\n";
    s2 += "            move_to READY\n";
    s2 += "        action: Enable(Device)\n";
    s2 += "            insert &VAL_OF_Device in $FWPART_"+fwFsm_formSetName(obj,"STATES")+"\n";
    s2 += "            insert &VAL_OF_Device in $FWPART_"+fwFsm_formSetName(obj,"ACTIONS")+"\n";
    s2 += "            move_to READY\n\n";

    s2 += "object: $FWPART_"+obj+"_FWDM is_of_class $FWPART_"+obj+"_FwDevMode_CLASS\n\n";

    s = "class: $FWPART_$TOP$"+obj+"_CLASS/associated\n";
  }
  else
  {
//		s2 = "class: $FWPART_$TOP$"+obj+"_FwDevMode_CLASS\n";
    s2 = "class: $FWPART_"+obj+"_FwDevMode_CLASS\n";
    s2 += "    state: READY\n";
    s2 += "        action: Disable(Device)\n";
    s2 += "            remove &VAL_OF_Device from $FWPART_"+fwFsm_formSetName(obj,"STATES")+"\n";
    s2 += "            remove &VAL_OF_Device from $FWPART_"+fwFsm_formSetName(obj,"ACTIONS")+"\n";
    s2 += "            move_to READY\n";
    s2 += "        action: Enable(Device)\n";
    s2 += "            insert &VAL_OF_Device in $FWPART_"+fwFsm_formSetName(obj,"STATES")+"\n";
    s2 += "            insert &VAL_OF_Device in $FWPART_"+fwFsm_formSetName(obj,"ACTIONS")+"\n";
    s2 += "            move_to READY\n\n";

//		s2 += "object: $FWPART_$TOP$"+obj+"_FWDM is_of_class $FWPART_$TOP$"+obj+"_FwDevMode_CLASS\n\n";
    s2 += "object: $FWPART_"+obj+"_FWDM is_of_class $FWPART_"+obj+"_FwDevMode_CLASS\n\n";
    s = "class: $FWPART_$TOP$"+obj+"_CLASS\n";
  }
  s1 = "class: ASS_"+obj+"_CLASS/associated\n";

  fwUi_getTypeFullPanel(obj, panel);
  s += "!panel: "+panel+"\n";
  s1 += "!panel: "+panel+"\n";

  fwFsm_readObjectStates(obj, states);
  fwFsm_readObjectColors(obj, colors);
//  fwFsm_readObjectFunctions(obj);

  fwFsm_readObjectParameters(obj, par_list);
  tmp = fwFsm_formatParameters(par_list, "    ", "parameters: ", "\n");
  s += tmp;
  s1 += tmp;

  fwFsm_readObjectActions(obj, action_list, 1);
//DebugTN("functions", action_list);
  //		fwFsm_getObjectStateActions(obj,states[i],action_list);

  for(i = 1; i <= dynlen(action_list); i++)
  {
    action = action_list[i];
    fwFsm_readObjectActionParameters(obj,"",action,action_pars, 1);
    s += fwFsm_formatAction(action, action_pars, "    ",  "function: ", "\n", sep);
    if(sep)
      continue;
    fwFsm_readObjectActionText(obj,"", action, action_line, 1);
    action_txt = strsplit(action_line,"\n");
    s += fwFsm_formatActionText(action, action_txt, "        ", flag);
  }

  for(i = 1; i <= dynlen(states); i++)
  {
    tmp = fwFsm_formatState(states[i], colors[i], "    ");
    s += tmp;
    s1 += tmp;
    if(!proxy)
    {
      fwFsm_readObjectWhens(obj,states[i],when_list);
      s += fwFsm_formatWhens(states[i], when_list, "        ", flag);
    }
    fwFsm_getObjectStateActionsV(obj,states[i],action_list, visi_list);
  //		fwFsm_getObjectStateActions(obj,states[i],action_list);

    for(j = 1; j <= dynlen(action_list); j++)
    {
      action = action_list[j];
      fwFsm_readObjectActionParameters(obj,states[i],action,action_pars);
      tmp = fwFsm_formatAction(action, action_pars, "        ",  "action: ",
                                "\t!visible: "+visi_list[j]+"\n", sep);
      s += tmp;
      s1 += tmp;
      if(sep)
      {
        continue;
      }
      fwFsm_readObjectActionText(obj,states[i],action,action_line);
      action_txt = strsplit(action_line,"\n");
      if(!proxy)
      {
        s += fwFsm_formatActionText(action, action_txt, "            ", flag);
      }
      else
      {
        if(dynlen(action_txt) > 1)
        {
          DebugTN("*************** Internal WARNING: Strange code removed", action_txt);
/*
          s += " (";
          s1 += " (";
          for(k = 2; k <= dynlen(action_txt); k++)
          {
            s += action_txt[k];
            s1 += action_txt[k];
            if(k != dynlen(action_txt))
            {
              s += ", ";
              s1 += ", ";
            }
          }
          s += " )";
          s1 += " )";
*/
        }
//        s += "\t!visible: "+visi_list[j]+"\n";
//        s1 += "\t!visible: "+visi_list[j]+"\n";
      }

   }
  }

//DebugN("before",s, flag);
  if(flag)
    strreplace(s,"class: $FWPART_$TOP$"+obj+"_CLASS","class: $FWPART_$ASS_"+obj+"_CLASS\n");
//DebugN("after",s, flag);
//	fwFsm_writeSmiObjectType(obj, s, s1);
//	DebugN(obj, s, s1);
}

fwFsm_writeSmiObjectType(string obj/*, string text, string header*/, string system = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(system);
  dpSetWait(tododp+".params:_original.._value", makeDynString(obj/*, text, header*/), tododp+".action:_original.._value","FwCreateObject");
  delay(0,200);
}

fwFsm_doWriteSmiObjectType(string obj/*, string text, string header*/)
{
  file f;
  string path, backpath, old_path;
  string text, header, enable_obj;

/*
	f = fopen(fwFsm_getProjPath()+"/smi/"+obj+".sml","w");
	fprintf(f,"%s",text);
	fclose(f);
	f = fopen(fwFsm_getProjPath()+"/smi/"+obj+"_include.sml","w");
	fprintf(f,"%s",header);
	fclose(f);
*/
// To remove files from older versions
  path = fwFsm_getProjPath()+"/smi";
  if (access(path,F_OK)!=0) {
    DebugTN("Creating folder",path);
    mkdir(path);
  }
  path = fwFsm_getProjPath()+"/smi_back";
  if (access(path,F_OK)!=0) {
    DebugTN("Creating folder",path);
    mkdir(path);
  }
/*
  path = fwFsm_getProjPath()+"/smi/"+obj+"_include.sml";
  if(!access(path, F_OK))
  {
    system("rm "+path);
    DebugN("Deleted: "+path);
  }
*/
/*
  path = fwFsm_getProjPath()+"/smi/"+obj+".sml";
  if(!access(path, F_OK))
  {
    system("rm "+path);
DebugN("Deleted: "+path);
  }
*/
  fwFsm_doWriteObjectType(obj, text, header, enable_obj);
//DebugN(enable_obj);

  path = fwFsm_getProjPath()+"/smi/"+obj+".fsm";
  backpath = fwFsm_getProjPath()+"/smi_back/"+obj+".fsm";
  if(!access(path, F_OK))
    copyFile(path, backpath);
  f = fopen(path,"w");
  fprintf(f,"%s",text);
  fclose(f);
  path = fwFsm_getProjPath()+"/smi/"+obj+".inc";
  backpath = fwFsm_getProjPath()+"/smi_back/"+obj+".inc";
  if(!access(path, F_OK))
    copyFile(path, backpath);
  f = fopen(path,"w");
  fprintf(f,"%s",header);
  fclose(f);
//	path = fwFsm_getProjPath()+"/smi/"+obj+"_mode.fsm";
//	backpath = fwFsm_getProjPath()+"/smi_back/"+obj+"_mode.fsm";
//	if(!access(path, F_OK))
//		copyFile(path, backpath);
  path = fwFsm_getProjPath()+"/smi/"+obj+".mode_fsm";
  backpath = fwFsm_getProjPath()+"/smi_back/"+obj+".mode_fsm";
  if(!access(path, F_OK))
    copyFile(path, backpath);
/*
  old_path = fwFsm_getProjPath()+"/smi/"+obj+"_mode.fsm";
  if(!access(old_path, F_OK))
  {
    system("rm "+old_path);
DebugN("Deleted old version: "+old_path);
  }
*/
  f = fopen(path,"w");
  fprintf(f,"%s",enable_obj);
  fclose(f);
  if(fwFsm_isProxyType(obj))
  {
    fwFsm_doWriteTypeScripts(obj);
  }
}

fwFsm_doRemoveSmiObject(string obj)
{
// CVV CMS
  return;
/*
  string path;

  path = fwFsm_getProjPath()+"/smi/"+obj+".inc";
  if(!access(path, F_OK))
  {
    system("rm "+path);
DebugN("Deleted: "+path);
  }
  path = fwFsm_getProjPath()+"/smi/"+obj+".fsm";
  if(!access(path, F_OK))
  {
    system("rm "+path);
DebugN("Deleted: "+path);
  }
//	path = fwFsm_getProjPath()+"/smi/"+obj+"_mode.fsm";
  path = fwFsm_getProjPath()+"/smi/"+obj+".mode_fsm";
  if(!access(path, F_OK))
  {
    system("rm "+path);
DebugN("Deleted: "+path);
  }
  if(fwFsm_isProxyType(obj))
  {
    path = fwFsm_getProjPath()+"/scripts/libs/"+obj+".ctl";
    if(!access(path, F_OK))
    {
      system("rm "+path);
DebugN("Deleted: "+path);
    }
  }
*/
}

fwFsm_getObjectsOfType(string type, dyn_string &syss, dyn_string &objs, string from = "*")
{
  dyn_string dps, dps1, syslist, syslist1;
  int i;
  string curr_type, sys;

  dynClear(objs);
  dynClear(syss);
  strreplace(from,":","");
  dps = fwFsm_getDpsSys(from+":*","_FwFsmObject", syslist);
  dps1 = fwFsm_getDpsSys(from+":*","_FwFsmDevice", syslist1);
  dynAppend(dps, dps1);
  dynAppend(syslist, syslist1);
  for(i = 1; i <= dynlen(dps); i++)
  {
    dpGet(syslist[i]+":"+dps[i]+".type:_online.._value",curr_type);
    if(type == curr_type)
    {
      dps[i] = fwFsm_extractSystem(dps[i]);
      dps[i] = fwFsm_convertToAssociated(dps[i]);
      dps[i] = fwFsm_convertToAssociated(dps[i]);
      dps[i] = fwFsm_convertToAssociated(dps[i]);
      dynAppend(syss,syslist[i]);
      dynAppend(objs,dps[i]);
    }
  }
}

fwFsm_getDomainObjectsOfType(string domain, string type, dyn_string & objs)
{
  dyn_string dps, dps1;
  int i;
  string curr_type;

  dps = fwFsm_getDps(domain+fwFsm_separator+"*","_FwFsmObject");
  dps1 = fwFsm_getDps(domain+fwFsm_separator+"*","_FwFsmDevice");
  dynAppend(dps, dps1);
  for(i = 1; i <= dynlen(dps); i++)
  {
    dpGet(dps[i]+".type:_online.._value",curr_type);
    if(type == curr_type)
    {
      dps[i] = fwFsm_extractSystem(dps[i]);
      dps[i] = fwFsm_convertToAssociated(dps[i]);
      dps[i] = fwFsm_convertToAssociated(dps[i]);
      dps[i] = fwFsm_convertToAssociated(dps[i]);
      dps[i] = fwFsm_getAssociatedObj(dps[i]);
      dynAppend(objs,dps[i]);
    }
  }
}

fwFsm_getObjectType(string obj, string &type)
{
  string full_obj, ass_obj, domain, sys;

  type = "";
  if(!fwFsm_isAssociated(obj))
  {
    full_obj = fwFsm_getSmiDomain();
    full_obj += "::" + obj;
  }
  else
    full_obj = obj;
  domain = fwFsm_getAssociatedDomain(full_obj);
  fwUi_getSysPrefix(domain, sys);
  sys = fwFsm_getSystem(sys);
  full_obj = fwFsm_convertAssociated(full_obj);
  full_obj = fwFsm_convertAssociated(full_obj);
  full_obj = fwFsm_convertAssociated(full_obj);
  if(sys != "")
    full_obj = sys+":"+full_obj;
//DebugTN("getObjectType",obj, sys, full_obj);
  if(!dpExists(full_obj))
  {
    ass_obj = fwFsm_getSmiDomain();
    full_obj = ass_obj+ fwFsm_separator + full_obj;
//DebugTN("getObjectType1",obj, sys, full_obj);
  }
  if(dpExists(full_obj))
  {
    dpGet(full_obj+".type:_online.._value",type);
//DebugTN("getObjectType2",obj, sys, full_obj, type);
    type=fwFsm_extractSystem(type);
  }
//DebugTN("getObjectType3",obj, sys, full_obj, type);
}

fwFsm_getObjectCUFlag(string obj, int & cu)
{
  string full_obj;

  if(!fwFsm_isAssociated(obj))
  {
    full_obj = obj+"::" +obj;
  }
  else
    full_obj = obj;
  full_obj = fwFsm_convertAssociated(full_obj);
  full_obj = fwFsm_convertAssociated(full_obj);
  full_obj = fwFsm_convertAssociated(full_obj);
  if(dpExists(full_obj))
    cu = 1;
  else
    cu = 0;
}

fwFsm_setObjectStatesColors(string type, dyn_string states, dyn_string colors)
{
  dyn_string full_states;
  int i, index;
  dyn_string actions;
  dyn_int visis;
  dyn_string new_states;

  fwFsm_createObjectTypeDp(type);
  dynClear(new_states);
  dynClear(actions);
  dynClear(visis);
  fwFsm_readObjectStates(type,full_states);
  for(i = 1; i <= dynlen(full_states); i++)
  {
    if(!dynContains(states, full_states[i]))
    fwFsm_setObjectStateActionsV(type, full_states[i], actions, visis);
  }
  if((index = dynContains(states,"-")))
  {
    dynRemove(states, index);
    dynRemove(colors,index);
  }
  fwFsm_writeObjectStates(type,states);
  if(dynlen(colors) >= 1)
  {
    fwFsm_writeObjectColors(type,colors);
  }
}

fwFsm_setObjectStateActionsV(string type, string state, dyn_string actions, dyn_int visis)
{
  dyn_string full_actions;
  dyn_int full_visis;
  string action;
  int i, pos;

  fwFsm_readObjectActions(type,full_actions);
  fwFsm_readObjectVisis(type, full_visis);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],state+"/") == 0)
    {
      dynRemove(full_actions, i);
      dynRemove(full_visis, i);
      i--;
    }
  }
  for(i = 1; i <= dynlen(actions); i++)
  {
    action = state+"/"+actions[i];
    dynAppend(full_actions, action);
    dynAppend(full_visis, visis[i]);
  }
  fwFsm_writeObjectActions(type,full_actions);
  fwFsm_writeObjectVisis(type, full_visis);
}

fwFsm_getObjectStates(string type, dyn_string & states)
{
  fwFsm_readObjectStates(type,states);
}

fwFsm_getObjectStatesColors(string type, dyn_string & states, dyn_string & colors)
{
  fwFsm_readObjectStates(type,states);
  fwFsm_readObjectColors(type,colors);
// to store functions at index 1
  dynInsertAt(states, "-", 1);
  dynInsertAt(colors, "", 1);
}

fwFsm_getObjectStateColor(string type, string state, string & color)
{
  dyn_string states, colors;
  int index;

  fwFsm_getItemByNameAtPos(type+".states", color, state, 2);
}


fwFsm_getObjectActions(string type, dyn_string & actions)
{
  dyn_string full_actions;
  string action;
  int i, pos;

  dynClear(actions);
  fwFsm_readObjectActions(type, full_actions);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    pos = strpos(full_actions[i],"/");
    action = substr(full_actions[i],pos+1);
//		if((pos = strpos(action,"NV_GOTO")) >= 0)
//			continue;
    if(!dynContains(actions, action))
      dynAppend(actions, action);
  }
}

fwFsm_getObjectStateActions(string type, string state, dyn_string & actions)
{
  dyn_string full_actions;
  string action;
  int i, pos;

  dynClear(actions);
  fwFsm_readObjectActions(type, full_actions);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],state+"/") == 0)
    {
      pos = strpos(full_actions[i],"/");
      action = substr(full_actions[i],pos+1);
      dynAppend(actions, action);
    }
  }
}

fwFsm_getObjectStateActionsV(string type, string state, dyn_string & actions,
	dyn_int & visi)
{
  dyn_string full_actions;
  dyn_int full_visis;
  string action;
  int i, pos;

  dynClear(actions);
  dynClear(visi);
  fwFsm_readObjectActions(type, full_actions);
  fwFsm_readObjectVisis(type, full_visis);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],state+"/") == 0)
    {
      pos = strpos(full_actions[i],"/");
      action = substr(full_actions[i],pos+1);
      dynAppend(actions, action);
      dynAppend(visi,full_visis[i]);
    }
  }
}

fwFsm_getObjectStateFullActionsV(string type, string state, dyn_string & actions,
	dyn_int & visi)
{
  dyn_string full_actions;
  dyn_int full_visis;
  string action;
  int i, pos;

  dynClear(actions);
  dynClear(visi);
  fwFsm_readObjectActions(type, full_actions);
  fwFsm_readObjectVisis(type, full_visis);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],state+"/") == 0)
    {
      dynAppend(actions, full_actions[i]);
      dynAppend(visi,full_visis[i]);
    }
  }
}

fwFsm_getObjectStateVActions(string type, string state, dyn_string & actions)
{
  dyn_string full_actions;
  dyn_int full_visis;
  string action;
  int i, pos;

  dynClear(actions);
  fwFsm_readObjectActions(type, full_actions);
  fwFsm_readObjectVisis(type, full_visis);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],state+"/") == 0)
    {
      pos = strpos(full_actions[i],"/");
      action = substr(full_actions[i],pos+1);
      if(full_visis[i])
        dynAppend(actions, action);
    }
  }
}

fwFsm_getObjectStateVActionsV(string type, string state, dyn_string & actions, dyn_int &visi)
{
  dyn_string full_actions;
  dyn_int full_visis;
  string action;
  int i, pos;

  dynClear(actions);
  fwFsm_readObjectActions(type, full_actions);
  fwFsm_readObjectVisis(type, full_visis);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],state+"/") == 0)
    {
      pos = strpos(full_actions[i],"/");
      action = substr(full_actions[i],pos+1);
      if(full_visis[i])
      {
        dynAppend(actions, action);
        dynAppend(visi, full_visis[i]);
      }
    }
  }
}

fwFsm_getObjectActionVisibility(string type, string action, int & visibility)
{
  dyn_string full_actions;
  dyn_int full_visis;
  int i;

  visibility = 0;
  fwFsm_readObjectActions(type, full_actions);
  fwFsm_readObjectVisis(type, full_visis);
  for(i = 1; i <= dynlen(full_actions); i++)
  {
    if(strpos(full_actions[i],"/"+action) > 0)
    visibility = full_visis[i];
  }
}

fwFsm_setSmiDomain(string domain)
{
  addGlobal("currentSmiDomain",STRING_VAR);
  currentSmiDomain = domain;
}

string fwFsm_getSmiDomain()
{
  if(globalExists("currentSmiDomain"))
    return currentSmiDomain;
  return "";
}

fwFsm_setSmiObject(string obj)
{
  addGlobal("currentSmiObject",STRING_VAR);
  currentSmiObject = obj;
}

string fwFsm_getSmiObject()
{
  return currentSmiObject;
}

fwFsm_generateAll(string system = "")
{
  dyn_string pars;
  string status = "not done";
  string tododp;

  tododp = _fwFsm_getToDoDP(system);
  dpSetWait(tododp+".action:_original.._value","FwFsmGenerateAll");
  while( status != "FwFsmGenerateAll")
  {
    delay(0,200);
    dpGet(tododp+".status:_online.._value",status);
  }
}

fwFsm_writeDomainTypeScripts(string domain, string type, dyn_string objs, string system = "")
{
  dyn_string pars;
  string status = "not done";
  string tododp;

  tododp = _fwFsm_getToDoDP(system);
  dynAppend(pars,domain);
  dynAppend(pars,type);
  dynAppend(pars,objs);
  dpSetWait(tododp+".params:_original.._value",pars, tododp+".action:_original.._value","FwCreateScripts");
  while( status != "FwCreateScripts")
  {
    delay(0,100);
    dpGet(tododp+".status:_online.._value",status);
  }
}

fwFsm_doWriteDomainTypeScripts(string domain, string type, dyn_string objs)
{
  int        i, j, inv_flag, pos;
  string     s, s1, prefix, midfix, domain_name, action_text;
  dyn_string name, dps, aux_dps, dp_types, statedps, states, actiondps, allactions, actions, types;
  dyn_string timeout, obj_names, physobjs, sysprefixes;
  file f;
  string path, domain_file, sys;

  fwFsm_readDeviceStateComps(type, dps, dp_types);
//DebugTN("fwFsm_doWriteDomainTypeScripts", type, dps, dp_types);
  fwFsm_getObjectStates(type, states);
  fwFsm_getObjectActions(type, actions);

  if(dynlen(actions))
  {
    fwFsm_readDeviceActionScript(type, action_text);
    if((pos = strpos(action_text,"{")) >= 0)
    {
      action_text = substr(action_text, pos+1);
      action_text = strltrim(action_text);
      action_text = strrtrim(action_text);
      if(action_text == "}")
        dynClear(actions);
    }
  }

//  prefix = "";
//  midfix = ".fwDeclarations.fwCtrlDev";
//  prefix = "fwDU_";
  prefix = domain+fwFsm_separator;
  midfix = "";
  s1 = "";
  domain_name = domain;
  strreplace(domain_name,fwDev_separator,"_");
  strreplace(domain_name,"-","_");
  obj_names = objs;
  for( i=1; i <= dynlen(objs); i++)
  {
    sys = fwFsm_getSystem(obj_names[i]);
    obj_names[i] = fwFsm_extractSystem(obj_names[i]);
    objs[i] = fwFsm_extractSystem(objs[i]);
    physobjs[i] = fwFsm_getPhysicalDeviceName(obj_names[i]);
    sysprefixes[i] = "";
    if(sys != "")
    {
      physobjs[i] = sys+":"+physobjs[i];
      sysprefixes[i] = sys+":";
    }
//DebugN(obj_names[i], physobjs[i]);
    strreplace(obj_names[i],fwDev_separator,"_");
    strreplace(obj_names[i],"-","_");
  }
  s = "#uses \""+type+".ctl\"\n";
  s1 = s;
  for( i=1; i <= dynlen(objs); i++)
  {
    if(fwFsm_isAssociated(objs[i]))
      continue;
    s = domain_name+"_"+obj_names[i]+"_install()\n{\n";
    s += "   string devdp;\n\n";
    s += "   devdp = \""+sysprefixes[i]+"\"+fwDU_getPhysicalName(\""+objs[i]+"\");\n";
    s += "   if(!globalExists(\""+type+"_CurrDUActions\"))\n   {\n";
    s += "      addGlobal(\""+type+"_CurrDUActions\",DYN_STRING_VAR);\n";
    s += "      fwDU_getAllActions(\""+type+"\","+type+"_CurrDUActions);\n   }\n";
    s += "   "+type+"_initialize(\""+domain+"\", devdp);\n";
    s += "   fwDU_setDefaultParameters(\""+domain+"\", devdp);\n";
    if(dynlen(dps))
    {
      if(dps[1] != "")
      {
        s += "   if(dpConnect(\"cb"+domain_name+"_"+obj_names[i]+"_valueChanged\"";
        aux_dps = dps;
        for( j=1; j <= dynlen(dps); j++)
        {
          inv_flag = 0;
          if((pos = strpos(dps[j],"_invalid")) > 0)
          {
            aux_dps[j] = substr(dps[j],0, pos);
            inv_flag = 1;
          }
          if(dpExists(physobjs[i]+"."+aux_dps[j]))
            statedps[j] = "devdp+\"."+aux_dps[j];
          else
            statedps[j] = "\""+aux_dps[j];
          if(!inv_flag)
          {
            if((pos = strpos(statedps[j],":")) > 0)
            {
              s += ",\n      "+statedps[j]+"\"";
            }
            else
            {
              s += ",\n      "+statedps[j]+":_online.._value\"";
            }
//            s += ",\n      "+statedps[j]+":_online.._value\"";
          }
          else
          {
            s += ",\n      "+statedps[j]+":_online.._bad\"";
//            s += ",\n      "+statedps[j]+":_online.._invalid\"";
          }
        }
        s += "\n     ) == -1 )\n"+"      DebugTN(\"Bad dpConnect state\");\n";
      }
      else
      {
        DebugTN("Warning: empty component list for state determination of "+domain_name+"_"+obj_names[i]+", not generating value callback.");
      }
    }
    if(dynlen(actions))
    {
      s += "   if(dpConnect(\"cb"+domain_name+"_"+obj_names[i]+"_doCommand\",false";
      s += ",\n     \""+prefix+objs[i]+midfix+".fsm.sendCommand:_online.._value\"";
      s += "\n     ) == -1 )\n"+"      DebugTN(\"Bad dpConnect command\");\n";
    }
//    s += "   fwDU_setDefaultParameters(\""+domain+"\", devdp);\n";
//    s += "//   fwFsm_waitDomainEnd(\""+domain+"\");\n";
//    s += "//   "+domain_name+"_"+obj_names[i]+"_uninstall(\"\", 0);\n";
//    s += "//   if(isFunctionDefined(\""+type+"_cleanup\"))\n";
//    s += "//       "+type+"_cleanup(\""+domain+"\", devdp);\n";
    s += "}\n\n";

//DebugN("Installed "+objs[i]);

    s += domain_name+"_"+obj_names[i]+"_uninstall(string dp, int running)\n{\n";
    s += "   string devdp;\n\n";
    s += "DebugTN(\"uninstalling "+domain+" "+objs[i]+"\");\n";
    s += "   if(running) return;\n";
    s += "   devdp = \""+sysprefixes[i]+"\"+fwDU_getPhysicalName(\""+objs[i]+"\");\n";
    if(dynlen(dps))
    {
      if(dps[1] != "")
      {
        s += "   if(dpDisconnect(\"cb"+domain_name+"_"+obj_names[i]+"_valueChanged\"";
        for( j=1; j <= dynlen(dps); j++)
        {
          inv_flag = 0;
          if((pos = strpos(dps[j],"_invalid")) > 0)
          {
            aux_dps[j] = substr(dps[j],0, pos);
            inv_flag = 1;
          }
          if(dpExists(physobjs[i]+"."+aux_dps[j]))
            statedps[j] = "devdp+\"."+aux_dps[j];
          else
            statedps[j] = "\""+aux_dps[j];
          if(!inv_flag)
          {
            if((pos = strpos(statedps[j],":")) > 0)
            {
              s += ",\n      "+statedps[j]+"\"";
            }
            else
            {
              s += ",\n      "+statedps[j]+":_online.._value\"";
            }
//            s += ",\n      "+statedps[j]+":_online.._value\"";
          }
          else
          {
            s += ",\n      "+statedps[j]+":_online.._bad\"";
//            s += ",\n      "+statedps[j]+":_online.._invalid\"";
          }
        }
        s += "\n     ) == -1 )\n"+"      DebugTN(\"Bad dpDisconnect state\");\n";
      }
    }
    if(dynlen(actions))
    {
      s += "   if(dpDisconnect(\"cb"+domain_name+"_"+obj_names[i]+"_doCommand\"";
      s += ",\n     \""+prefix+objs[i]+midfix+".fsm.sendCommand:_online.._value\"";
      s += "\n     ) == -1 )\n"+"      DebugN(\"Bad dpDisconnect command\");\n";
    }
    s += "}\n\n";

//DebugN("Uninstalled "+objs[i]);
    if(dynlen(dps))
    {
      if(dps[1] != "")
      {
        s+="cb"+domain_name+"_"+obj_names[i]+"_valueChanged(\n";
        for( j=1; j <= dynlen(dps); j++)
        {
          s += "      string dp"+j+", "+dp_types[j]+" x"+j;
          if(j != dynlen(dps))
            s += ",\n";
        }
        s += "   )\n{\n";
        s+= "   string state;\n";
//        s+= "   string state, oldstate, busy;\n";
        s+= "   string devdp;\n\n";
        s+= "   devdp = \""+sysprefixes[i]+"\"+fwDU_getPhysicalName(\""+objs[i]+"\");\n";
        s+= "   fwDU_convertValue(\""+domain+"\",\""+objs[i]+"\");\n";
        s+= "   "+type+"_valueChanged(\""+domain+"\", devdp,\n";

        for(j = 1; j <= dynlen(dps); j++)
        {
          s += "      x"+j;
          if(j != dynlen(dps))
            s+= ",\n";
        }
        s += ", state );\n";
//        s+= "   dpGet(\""+prefix+objs[i]+midfix+".fsm.currentState:_online.._value\", oldstate,\n";
//        s+= "         \""+prefix+objs[i]+midfix+".fsm.executingAction:_online.._value\", busy);\n";
//        s+= "   if ((state != oldstate) || (busy != \"\"))\n";
//        s+= "   if (state == \"\") return;\n";
//        s+= "      fwDU_setState(\""+domain+"\", devdp, state);\n";
        s+= "   fwDU_setState(\""+domain+"\", devdp, state);\n";
        s+="}\n\n";
      }
    }
    if(dynlen(actions))
    {
      s+="cb"+domain_name+"_"+obj_names[i]+"_doCommand(string dp, string command)\n";
      s+= "{\n";
      s+= "   string devdp;\n\n";
      s+= "   devdp = \""+sysprefixes[i]+"\"+fwDU_getPhysicalName(\""+objs[i]+"\");\n";
      s+= "   command = fwDU_convertCommand(\""+domain+"\",\""+objs[i]+"\",\""+type+"\", "+type+"_CurrDUActions, command);\n";
//      s+= "   command = fwDU_convertCommand(\""+domain+"\",\""+objs[i]+"\",\""+type+"\", command);\n";
      s+= "   "+type+"_doCommand(\""+domain+"\", devdp, command);\n";
      s+="}\n\n";
    }
    s1 += s;
  }
  domain_file = domain;
  strreplace(domain_file,fwDev_separator,"_");
  strreplace(domain_file,"-","_");
  path = fwFsm_getProjPath()+"/scripts/libs/"+domain_file+"$"+type+"$install";
  f = fopen(path,"w");
  fprintf(f,"%s",s1);
  fclose(f);
}

fwFsm_doWriteDomainScript(string domain, dyn_string types)
{
  int        i;
  string     s, domain_name;
  file f;
  string path;

  domain_name = domain;
  strreplace(domain_name,fwDev_separator,"_");
  strreplace(domain_name,"-","_");
  s = "";
//DebugN(domain, types);
  for(i = 1; i <= dynlen(types); i++)
  {
    s += "#uses \""+domain_name+"$"+types[i]+"$install\"\n";
  }
//   s += "\nmain()\n{\n	fwFsm_startDomainDevicesNew(\""+domain+"\");\n}\n";
  s += "\nstartDomainDevices_"+domain_name+"()\n{\n	fwFsm_startDomainDevicesNew(\""+domain+"\");\n}\n";

  path = fwFsm_getProjPath()+"/scripts/libs/"+domain_name+".ctl";
  f = fopen(path,"w");
  fprintf(f,"%s",s);
  fclose(f);
}

fwFsm_doWriteTypeScripts(string type)
{
  file f;
  dyn_string items;
  string type1, path, backpath;

  type1 = fwFsm_formType(type);
  dpGet(type1+".components:_online.._value", items);

// To remove scripts from older versions
/*
  path = fwFsm_getProjPath()+"/scripts/libs/"+type;
  if(!access(path, F_OK))
  {
    system("rm "+path);
DebugN("Deleted: "+path);
  }
*/
  path = fwFsm_getProjPath()+"/scripts/libs/"+type+".ctl";
  if(!access(path, F_OK))
  {
    backpath = fwFsm_getProjPath()+"/scripts/libs_back/"+type+".ctl";
    copyFile(path, backpath);
  }
  f = fopen(path,"w");
  fprintf(f,"%s\n%s\n%s\n",items[3],items[4], items[5]);
  fclose(f);
}

fwFsm_doRemoveTypeScripts(string domain)
{
//CVV CMS
  return;
/*
  dyn_string files;
  int i, n;
  string domain_file;
  string pDebug;

  domain_file = domain;
  strreplace(domain_file,fwDev_separator,"_");
  strreplace(domain_file,"-","_");
  files = getFileNames(fwFsm_getProjPath()+"/scripts/libs",domain_file+"$*$install");
  if(!access(fwFsm_getProjPath()+"/scripts/libs/"+domain_file+".ctl", F_OK))
    dynAppend(files,domain_file+".ctl");
  for(i = 1; i <= dynlen(files); i++)
  {
    strreplace(files[i], "$", "\\$");
    system("rm "+fwFsm_getProjPath()+"/scripts/libs/"+files[i]);
  }
*/
}


fwFsm_writeDeviceTopScript(string type, dyn_string state_comps, dyn_string action_comps)
{
  string s1, dptype;
  string stateComps, actionComps, actionText;
  dyn_string items;
  int i, typ;
  string type1;

  type1 = fwFsm_formType(type);

  stateComps = "";
  actionComps = "";
  actionText = "";
  for(i = 1; i <= dynlen(state_comps); i++)
  {
    s1 = state_comps[i]+"\n";
    stateComps += s1;
  }

  for(i = 1; i <= dynlen(action_comps); i++)
  {
    s1 = action_comps[i]+"\n";
    actionComps += s1;
  }

//	s1 = type+"_initialize(string device)\n{\n    fwDU_setDefaultParameters(device)\n}\n";
//	actionText += s1;
  dpGet(type1+".components:_online.._value", items);
  items[1] = stateComps;
  items[2] = actionComps;
//	items[3] = actionText;
  dpSet(type1+".components:_original.._value", items);
}

fwFsm_readDeviceStateComps(string type, dyn_string & comps, dyn_string & types)
{
  string s, s1, str;
  int i, end;
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value", items);
  if(!dynlen(items))
    return;
  str = items[1];
  dynClear(comps);
  dynClear(types);
  items = strsplit(str,"\n");
  for(i = 1; i <= dynlen(items); i++)
  {
    sscanf(items[i],"%s%s",s, s1);
    dynAppend(types,s);
    dynAppend(comps,s1);
  }
}

fwFsm_readDeviceActionComps(string type, dyn_string & comps, dyn_string & types)
{
  string s, s1, str;
  int i, end;
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value", items);
  if(dynlen(items) < 2)
    return;
  str = items[2];
  dynClear(comps);
  dynClear(types);
  items = strsplit(str,"\n");
  for(i = 1; i <= dynlen(items); i++)
  {
    sscanf(items[i],"%s%s",s, s1);
    dynAppend(types,s);
    dynAppend(comps,s1);
  }
}

fwFsm_writeDeviceStateScript(string type, string text)
{
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value",items);
  items[4] = text;
  dpSet(type1+".components:_original.._value",items);
}

fwFsm_writeDeviceActionScript(string type, string text)
{
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value",items);
  items[5] = text;
  dpSet(type1+".components:_original.._value",items);
}

fwFsm_readDeviceInitScript(string type, string & text)
{
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value",items);
  if(dynlen(items) < 2)
    return;
  text = items[3];
}

fwFsm_writeDeviceInitScript(string type, string &text)
{
  dyn_string items;
  string type1, s;

  s = type+"_initialize(string domain, string device)\n{\n}\n";
  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value", items);
//	if(text == s)
//		text = s1;
  if(text == "")
    text = s;
  items[3] = text;
  dpSet(type1+".components:_original.._value", items);
}

fwFsm_readDeviceStateScript(string type, string & text)
{
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value",items);
  if(dynlen(items) < 2)
    return;
  text = items[4];
}

fwFsm_readDeviceActionScript(string type, string & text)
{
  dyn_string items;
  string type1;

  type1 = fwFsm_formType(type);

  dpGet(type1+".components:_online.._value",items);
  if(dynlen(items) < 2)
  return;
  text = items[5];
}

int strreplace_once(string &line, string from, string to)
{
  int pos;
  string begin,end;
  int ret = 0;

  if((pos = strpos(line, from)) >= 0)
  {
    begin = substr(line, 0, pos + strlen(from));
    end = substr(line, pos + strlen(from));
//DebugTN("replace_once",line, begin, end, from, to);
    strreplace(begin, from, to);
    line = begin+end;
//DebugTN("replace_once 1",line, begin, end);
    ret = 1;
  }
  return ret;
}

fwFsm_rewriteInstruction(string s, string type, dyn_string objs, dyn_string types, int all_flag, string &out,
			int union_flag = FwFSM_UnionFlag)
{
  string line, obj, start, domain, obj_type, aux_domain, aux_obj, tnode, sys;
  int i, pos;
  int do_union = 0;
  string union_type;

//DebugTN("Rewrite Instruction", s, type, objs, types);
  pos = strpos(s,"do ");
  if(pos == -1)
    pos = strpos(s,"set ");
  if(pos == -1)
    pos = strpos(s,"wait ");
  start = substr(s, 0, pos);
  out = "";
  if((dynlen(types) > 1) && (union_flag))
  {
    do_union = 1;
    union_type = "FwCHILDREN";
  }
  if(type == "FwMode")
  {
    for( i = 1; i <= dynlen(types); i++)
    {
      line = s;
      obj = fwFsm_getAssociatedObj(objs[i]);
      domain = fwFsm_getAssociatedDomain(objs[i]);
      if(i == 1)
      {
        strreplace(line,"$"+type, domain+"::"+obj);
        out += line;
        pos = strpos(obj,"_FW");
        obj = substr(obj,0,pos);
      }
      aux_domain = domain;
      strreplace(aux_domain,":",fwDev_separator);
      aux_obj = obj;
      strreplace(aux_obj,":",fwDev_separator);
      strreplace(aux_obj,"//","::");
//			fwFsm_getObjectType( aux_domain+"::"+aux_obj, obj_type);
      fwFsm_getObjectType( fwFsm_getSmiDomain()+"::"+aux_domain+"::"+aux_obj, obj_type);
//DebugN("rewritingInst",i, types, domain, obj, aux_domain, aux_obj, obj_type);
      if(obj_type == "")
      {
//				fwFsm_getObjectType( fwFsm_getSmiDomain()+"::"+aux_domain+"::"+aux_obj, obj_type);
        fwFsm_getObjectType( aux_domain+"::"+aux_obj, obj_type);
      }
      {
    				string tp;
    				//int pos;

    				tp = obj_type;
    				if((pos = strpos(tp,fwFsm_typeSeparator)) > 0)
    				{
          tp = substr(tp, 0, pos);
          obj_type = tp;
    				}
      }

      if(strpos(s,"Include") >= 0)
      {
        out += start+"insert "+domain+"::"+obj+" in "+
        fwFsm_formSetName(obj_type, "STATES")+"\n";
        out += start+"insert "+domain+"::"+obj+" in "+
        fwFsm_formSetName(obj_type, "ACTIONS")+"\n";
        out += start+"insert "+domain+"::"+obj+"_FWCNM in "+
        fwFsm_formSetName("FwChildrenMode", "STATES")+"\n";
      }
      if(strpos(s,"Take") >= 0)
      {
        out += start+"insert "+domain+"::"+obj+" in "+
        fwFsm_formSetName(obj_type, "STATES")+"\n";
        out += start+"insert "+domain+"::"+obj+" in "+
        fwFsm_formSetName(obj_type, "ACTIONS")+"\n";
        out += start+"insert "+domain+"::"+obj+"_FWCNM in "+
        fwFsm_formSetName("FwChildrenMode", "STATES")+"\n";
      }
      else if(strpos(s,"Exclude") >= 0)
      {
        out += start+"remove "+domain+"::"+obj+" from "+
        fwFsm_formSetName(obj_type, "STATES")+"\n";
        out += start+"remove "+domain+"::"+obj+" from "+
        fwFsm_formSetName(obj_type, "ACTIONS")+"\n";
        out += start+"remove "+domain+"::"+obj+"_FWCNM from "+
        fwFsm_formSetName("FwChildrenMode", "STATES")+"\n";
      }
      else if(strpos(s,"Release") >= 0)
      {
        out += start+"remove "+domain+"::"+obj+" from "+
        fwFsm_formSetName(obj_type, "STATES")+"\n";
        out += start+"remove "+domain+"::"+obj+" from "+
        fwFsm_formSetName(obj_type, "ACTIONS")+"\n";
        out += start+"remove "+domain+"::"+obj+"_FWCNM from "+
        fwFsm_formSetName("FwChildrenMode", "STATES")+"\n";
      }
      else if(strpos(s,"Manual") >= 0)
      {
        out += start+"insert "+domain+"::"+obj+" in "+
        fwFsm_formSetName(obj_type, "STATES")+"\n";
        out += start+"remove "+domain+"::"+obj+" from "+
        fwFsm_formSetName(obj_type, "ACTIONS")+"\n";
      }
      else if(strpos(s,"Ignore") >= 0)
      {
        out += start+"insert "+domain+"::"+obj+" in "+
        fwFsm_formSetName(obj_type, "ACTIONS")+"\n";
        out += start+"remove "+domain+"::"+obj+" from "+
        fwFsm_formSetName(obj_type, "STATES")+"\n";
      }
    }
  }
  else
  {
    int wait_flag = 0;
    string setname = "ACTIONS";
    string prefix, postfix;

    if(strpos(s,"wait ") >= 0)
    {
      wait_flag = 1;
      setname = "STATES";
    }
    if(all_flag)
    {
      if(do_union)
      {
        line = s;
        strreplace_once(line,"$"+type,"all_in "+CurrPart+
        fwFsm_formSetName(union_type, setname));
        out += line;
      }
      else
      {
        if(wait_flag)
        {
          if(!dynlen(types))
          {
            line = s;
            pos = strpos(line,"$"+type);
            prefix = substr(line, 0, pos);
            postfix = substr(line, pos);
//DebugTN("replacing empty",line, prefix, postfix, "$"+type,"");
            strreplace_once(postfix,"$"+type,"");
            postfix = strltrim(postfix," ,\t");
//DebugTN("replaced empty",line, prefix, postfix);
            if((strpos(postfix,"$") == -1))
            {
              prefix = strrtrim(prefix," ,\t");
              prefix += " ";
            }
            out += prefix+postfix;
            if((strpos(out,"all_in") == -1) && (strpos(out,"$") == -1))
              out = "";
//DebugTN("returning out",out, prefix, postfix);
          }
        }
        for( i = 1; i <= dynlen(types); i++)
        {
  //      if(wait_flag)
  //      {
  //        if(i == 1)
  //          line = s;
  //      }
  //      else
          line = s;
          strreplace_once(line,"$"+type,"all_in "+CurrPart+
          fwFsm_formSetName(types[i], setname));
  //      if(wait_flag)
  //      {
  //        if(i == dynlen(types))
  //          out += line;
  //      }
  //      else
          out += line;
        }
      }
    }
    else
    {
      for( i = 1; i <= dynlen(types); i++)
      {
        line = s;
        string aux = line;
        for( i = 1; i <= dynlen(objs); i++)
        {
          if((types[1] == type) || (type == "FwCHILDREN"))
          {
            strreplace_once(line,"$"+type,objs[i]);
            out += line;
            line = aux;
          }
        }
      }
    }
  }
}

int fwFsm_rewriteCondition(string s, string type, dyn_string objs, dyn_string types,
	int all_flag, string &out, int union_flag = FwFSM_UnionFlag)
{
  string in, cond, cont_set, set, line, aux, tmp;
  int i, pos, pos1, pos2, posn, set_empty_if, surround;
  int do_union =0;
  string union_type;

  in = s;
  cont_set = "";
  out = "";

//DebugTN("rewriteCondition", s, type, objs, types, all_flag);
  pos = strpos(s,"$");
  aux = substr(s, pos);
  pos1 = strpos(aux," ");
  pos2 = strpos(aux,")");
  posn = strpos(aux,".");
  if((posn >= 0) && dynlen(objs))
  {
//DebugTN("rewriteCondition", s, type, objs, types, all_flag);
    tmp = s;
    strreplace(tmp,"$"+type,objs[1]);
//DebugTN("rewriteCondition1 ", "$"+type,objs[1], tmp, out);
    out += tmp;
    if(strpos(out,"$") >= 0)
      return 1;
    return 0;
  }
  cond = substr(aux, pos1+1, pos2-pos1-1);
  cond = strrtrim(cond);
  cond = strltrim(cond);

  set_empty_if = 0;
  cont_set = "and";
  surround = dynlen(types);
  if((surround > 1) && (union_flag))
  {
    surround = 1;
    do_union = 1;
    union_type = "FwCHILDREN";
  }

  if(all_flag == 1)
  {
    cont_set = "and";
    set = "all_in";
  }
  else if(all_flag == 2)
  {
    cont_set = "or";
    set = "any_in";
  }
  else
  {
    if(strpos(s,"empty") > 0)
    {
      set_empty_if = 1;
      if(strpos(s,"not_empty") > 0)
        cont_set = "or";
    }
    else
    {
      surround = dynlen(objs);
    }
  }

  if(dynlen(objs))
  {
//		if(all_flag)
    if(surround > 1)
    {
      out += "( ";
    }
    if(!set_empty_if)
    {
      if(all_flag)
      {
        if(do_union)
        {
          line = "( "+set+" "+CurrPart+fwFsm_formSetName(union_type, "STATES")+" "+cond+" )";
          out += line;
        }
        else
        {
          for( i = 1; i <= dynlen(types); i++)
          {
            line = "( "+set+" "+CurrPart+fwFsm_formSetName(types[i], "STATES")+" "+cond+" )";
            out += line;
            if(i != dynlen(types))
            {
              out += " "+cont_set+"\n"+"          ";
            }
          }
        }
      }
      else
      {
        for( i = 1; i <= dynlen(objs); i++)
        {
          line = "( "+objs[i]+" "+cond+" )";
          out += line;
          if(i != dynlen(objs))
          {
            out += " "+cont_set+"\n"+"          ";
          }
        }
      }
    }
    else
    {
      if(do_union)
      {
        line = "( "+CurrPart+fwFsm_formSetName(union_type, "ACTIONS")+" "+cond+" )";
        out += line;
      }
      else
      {
        for( i = 1; i <= dynlen(types); i++)
        {
          line = "( "+CurrPart+fwFsm_formSetName(types[i], "ACTIONS")+" "+cond+" )";
          out += line;
          if(i != dynlen(types))
          {
            out += " "+cont_set+"\n"+"          ";
          }
        }
      }
    }
//		if(all_flag)
    if(surround > 1)
    {
      out += " )";
    }
  }
  return 0;
}

int fwFsm_parseParameters(string &s)
{
  int pos1, ret = 0;
  string aux;

  while( ( (pos1 = strpos(s," = $dp=")) >= 0) || ( (pos1 = strpos(s," = \"$dp=")) >= 0) )
  {
    aux = substr(s, pos1);
    if((pos1 = strpos(aux,")")) >= 0)
      aux = substr(aux, 0, pos1);
    if((pos1 = strpos(aux,",")) >= 0)
      aux = substr(aux, 0, pos1);
    strreplace(s, aux, "");
    ret = 1;
  }
  return ret;
}

int fwFsm_parseFsmLine(string &s, int pos, string &top_type, int &all_flag)
{
  int pos1, ret;
  string aux;

  ret = 0;
  all_flag = 0;

//DebugN("before", s);
  ret = fwFsm_parseParameters(s);
  if(ret)
    return ret;
  if( strpos(s,"$FWPART_") >= 0 )
  {
    strreplace(s,"$FWPART_",CurrPart);
    ret = 1;
    if((pos = strpos(s,"$")) < 1)
      return ret;
  }
//DebugN("after",s);
  if((pos1 = strpos(substr(s, pos),".")) >= 1)
  {
    top_type = substr(s, pos+1, pos1-1);
  }
  else if((pos1 = strpos(substr(s, pos)," ")) >= 1)
  {
    top_type = substr(s, pos+1, pos1-1);
    if((pos1 = strpos(top_type,",")) >= 1)
    {
      top_type = substr(top_type, 0, pos1);
    }
    if((pos1 = strpos(top_type,")")) >= 1)
    {
      top_type = substr(top_type, 0, pos1);
    }
  }
  else if((pos1 = strpos(substr(s, pos),",")) >= 1)
  {
    top_type = substr(s, pos+1, pos1-1);
  }
  else if((pos1 = strpos(substr(s, pos),")")) >= 1)
  {
    top_type = substr(s, pos+1, pos1-1);
  }
  else
  {
    pos1 = strlen(s);
    pos1 -= pos;
    top_type = substr(s, pos+1, pos1-2);
  }
//if(strpos(s,"wait") >= 0)
//DebugN("top_type", s, pos, top_type);
  if( strpos(top_type,"ASS_") == 0 )
  {
//		strreplace(s,"$ASS",curr_obj);
    return 1;
  }
  if( strpos(top_type,"TOP$") == 0 )
  {
    return 1;
  }
  if( strpos(top_type,"ALL$") == 0 )
  {
    top_type = substr(top_type,4);
    strreplace_once(s,"$ALL","");
    all_flag = 1;
  }
  if( strpos(top_type,"ANY$") == 0 )
  {
    top_type = substr(top_type,4);
    strreplace_once(s,"$ANY","");
    all_flag = 2;
  }
  if( strpos(top_type,"ASS$") == 0 )
  {
    top_type = substr(top_type,4);
    strreplace_once(s,"$ASS","");
//		all_flag = 2;
  }
  if( strpos(top_type,"THIS$") == 0 )
  {
    top_type = substr(top_type,5);
    top_type = "_"+top_type;
    strreplace_once(s,"$THIS$","$_");
//		all_flag = 2;
  }
  if( strpos(top_type,"FWPART_") == 0 )
  {
    strreplace_once(s,"$FWPART_",CurrPart);
    return 1;
  }
//if(strpos(s,"wait")>=0)
//DebugN("end", s, ret, top_type);
  return ret;
}

fwFsm_rewriteSimpleCondition(string s, string &out)
{
  int and_flag, not_flag, all_flag, pos, ret, index, index1;
  string top_type;
  dyn_string top_objs, top_types, tmp;
  int again = 1;

  while (again)
  {
  if((pos = strpos(s,"$")) >= 1)
  {
    dynClear(top_objs);
    dynClear(top_types);
    ret = fwFsm_parseFsmLine(s, pos, top_type, all_flag);
    if(ret)
      fputs(s, f);
    if(top_type == "FwCHILDREN")
    {
      top_objs = CurrfwChildrenObjs;
      top_types = CurrfwChildrenTypes;
    }
    else if(top_type == "_FwMode")
    {
      top_objs[1] = CurrObj;
      strreplace(top_objs[1],"_FWCNM","_FWM");
      top_types[1] = top_type;
//DebugTN(s, top_type, CurrPart, CurrObj);
    }
/*
		else if(top_type == "FwMode")
		{
			top_objs = makeDynString(domain+"_FWM");
			top_types = makeDynString("FwMode");
		}
*/
    else
    {
      if(index = dynContains(CurrObjTypes,top_type))
      {
        top_objs = CurrObjsTypes[index];
//DebugTN("Removing cond?", top_type, top_objs, CurrObj, CurrPart, CurrParts, s);
        if(index1 = dynContains(top_objs, CurrObj))
        {
          dynRemove(top_objs,index1);
          RemCurrObj = 1;
        }
        if(dynlen(top_objs))
          dynAppend(top_types, top_type);
      }
    }
//DebugN("rewriteContition", s, top_type, top_objs, top_types, all_flag);
    again = fwFsm_rewriteCondition(s, top_type, top_objs, top_types, all_flag, out);
    tmp = top_objs;
    dynAppend(CurrObjs, top_objs);
    dynAppend(CurrUsedObjs, tmp);
    if(again)
    {
//DebugTN("rewriteCond", s, out);
      s = out;
    }
  }
  else
  {
    out = s;
    again = 0;
  }
  }
}

fwFsm_rewriteFullCondition(string s, string &out)
{
  string in, cond;
  int i, j, index, pos;
  string prev, start;
  dyn_string items;
  int start_flag, n;
  int n_pars;
  dyn_int simpleConds;

  in = s;
  out = "";
  prev = "";
  start = "";
  start_flag = 1;
  n = 0;
  n_pars = 0;

  strreplace(in, "(","|( ");
  strreplace(in, ")"," )|");
//	strreplace(in, "\n"," ");

  items = strsplit(in,"|");
  start = items[1];
  dynClear(CurrObjs);

  for(i = 1; i <= dynlen(items); i++)
  {
    if( (strpos(items[i],"in_state") > 0) || (strpos(items[i],"empty") > 0) ||
        (strpos(items[i],"==") > 0) ||
        (strpos(items[i],"<>") > 0) ||
        (strpos(items[i],">=") > 0) ||
        (strpos(items[i],"<=") > 0) ||
        (strpos(items[i],">") > 0) ||
        (strpos(items[i],"<") > 0) )
    {
      fwFsm_rewriteSimpleCondition(items[i], cond);
      items[i] = cond;
      dynAppend(simpleConds,i);
    }
  }
//DebugTN("rewritefull", s, simpleConds, items);
  for(i = 1; i <= dynlen(simpleConds); i++)
  {
    index = simpleConds[i];
    if(items[index] == "")
    {
      for(j = 1; 1 ; j++)
      {
        if( (strpos(items[index+j],")") >= 0) && (strpos(items[index-j],"(") >= 0) )
        {
          items[index-j] = "";
          items[index+j] = "";
        }
        else
          break;
      }
      if( (strpos(items[index-j],"and") >= 0) || (strpos(items[index-j],"or") >= 0) )
        items[index-j] = "";
      else if( (strpos(items[index+j],"and") >= 0) || (strpos(items[index+j],"or") >= 0) )
        items[index+j] = "";
    }
    else
      n++;
  }
  for(i = 1; i <= dynlen(items); i++)
  {
    out += items[i];
  }
  if(!n)
    out = "";
}

int fwFsm_handleInstruction(file fin, file fout, string s)
{
  int i, j, and_flag, not_flag, all_flag, pos, ret, index, index1;
  string top_type, out, s1;
  dyn_string top_objs, top_types, items;

  s1 = strrtrim(s);
  s1 = strltrim(s1);
  items = strsplit(s1," \t\n");
//DebugN(s, s1, items);
  if((items[1] != "do") && (items[1] != "set") && (items[1] != "wait"))
    return 0;
  if((pos = strpos(s,"$")) >= 1)
  {
    dynClear(top_objs);
    dynClear(top_types);
    ret = fwFsm_parseFsmLine(s, pos, top_type, all_flag);
    if(ret)
      fputs(s, fout);
//DebugN("handleInstruction", s, top_type, CurrObjTypes);
    if(top_type == "FwCHILDREN")
    {
      top_objs = CurrfwChildrenObjs;
      top_types = CurrfwChildrenTypes;
    }
/*
		else if(top_type == "FwMode")
		{
			top_objs = makeDynString(domain+"_FWM");
			top_types = makeDynString("FwMode");
		}
*/
    else if(top_type == "FwMode")
    {
      for(i = 1; i <= dynlen(CurrObjsTypes); i++)
      {
        for(j = 1; j <= dynlen(CurrObjsTypes[i]); j++)
        {
          dynAppend(top_objs,CurrObjsTypes[i][j]);
          dynAppend(top_types,CurrObjTypes[i]);
        }
      }
    }
    else
    {
      if(index = dynContains(CurrObjTypes,top_type))
      {
        top_objs = CurrObjsTypes[index];
//DebugTN("Removing do?", top_type, top_objs, CurrObj, CurrPart, CurrParts, s);
        if(index1 = dynContains(top_objs, CurrObj))
        {
          dynRemove(top_objs,index1);
          RemCurrObj = 1;
        }
        if(dynlen(top_objs))
          dynAppend(top_types, top_type);
      }
    }
//DebugN("rewriteInstruction", CurrObj, s, top_type, top_objs, top_types, all_flag);
    fwFsm_rewriteInstruction(s, top_type, top_objs, top_types, all_flag, out);
    dynAppend(CurrUsedObjs, top_objs);
  }
  else
    out = s;
//DebugN("rewriteInstruction", s, out);
  fputs(out, fout);
  return 1;
}

int fwFsm_handleInstructionWait(file fin, file fout, string s)
{
  int i, j, and_flag, not_flag, all_flag, pos, ret, index, index1;
  string top_type, out, s1, sn;
  dyn_string top_objs, top_types, items;

  s1 = strrtrim(s);
  s1 = strltrim(s1);
  items = strsplit(s1," \t\n");
//DebugN(s, s1, items);
  if(items[1] != "wait")
    return 0;
  if((pos = strpos(s,"$")) >= 1)
  {
    dynClear(top_objs);
    dynClear(top_types);

    ret = fwFsm_parseFsmLine(s, pos, top_type, all_flag);
    if(ret)
      fputs(s, fout);
//DebugN("handleInstruction", s, top_type, CurrObjTypes, all_flag);

    if(top_type == "FwCHILDREN")
    {
      top_objs = CurrfwChildrenObjs;
      top_types = CurrfwChildrenTypes;
    }
    else if(top_type == "FwMode")
    {
      for(i = 1; i <= dynlen(CurrObjsTypes); i++)
      {
        for(j = 1; j <= dynlen(CurrObjsTypes[i]); j++)
        {
          dynAppend(top_objs,CurrObjsTypes[i][j]);
          dynAppend(top_types,CurrObjTypes[i]);
        }
      }
    }
    else
    {
      if(index = dynContains(CurrObjTypes,top_type))
      {
        top_objs = CurrObjsTypes[index];
//DebugTN("Removing wait?", top_type, top_objs, CurrObj, CurrPart, CurrParts, s);
        if(index1 = dynContains(top_objs, CurrObj))
        {
          dynRemove(top_objs,index1);
          RemCurrObj = 1;
        }
        if(dynlen(top_objs))
          dynAppend(top_types, top_type);
      }
    }
//DebugN("rewriteInstruction", CurrObj, s, top_type, top_objs, top_types, all_flag);
    fwFsm_rewriteInstruction(s, top_type, top_objs, top_types, all_flag, out);
    dynAppend(CurrUsedObjs, top_objs);
  }
  else
    out = s;
//DebugN("rewriteInstruction", s, out);
  if((pos = strpos(out,"$")) >= 1)
  {
    fwFsm_handleInstructionWait(fin, fout, out);
  }
  else
  {
//DebugN("writing line", out);
    fputs(out, fout);
  }
  return 1;
}

int fwFsm_handleCondition(file fin, file fout, string s)
{
  int condition, empty_if, if_counter;
  string full_cond_str, cond_str, s1;
  dyn_string items;

  s1 = strrtrim(s);
  s1 = strltrim(s1);
  items = strsplit(s1," \t\n");
  if((items[1] != "if") && (items[1] != "when"))
    return 0;
  full_cond_str = "";
  condition = 1;
  empty_if = 0;
  while(1)
  {
    full_cond_str += s;
    if( (strpos(s,"then") >= 0 ) ||
        (strpos(s,"do ") >= 0 ) ||
        (strpos(s,"move_to") >= 0) ||
        (strpos(s,"continue") >= 0) ||
        (strpos(s,"stay_in_state") >= 0) )
    {
      condition = 0;
      fwFsm_rewriteFullCondition(full_cond_str, cond_str);
//DebugN("Full cond", full_cond_str, cond_str);
      if(dynlen(CurrObjs))
      {
        fputs(cond_str, fout);
      }
      else
      {
        if ((strpos(s,"then") >= 0) && (cond_str == ""))
        {
          empty_if = 1;
        }
      }
    }
    if(condition)
    {
      if(!feof(fin))
      {
        fgets(s,2000,fin);
      }
    }
    else
    {
      if(empty_if)
      {
        if_counter = 1;
        while(!feof(fin))
        {
          fgets(s,2000,fin);
          if(strpos(s,"endif") >= 0)
          {
            if_counter--;
            if(!if_counter)
            {
              empty_if = 0;
              break;
            }
          }
          else if( strpos(s,"then") >= 0 )
          {
            if_counter++;
          }
        }
        if((!empty_if) || (feof(fin)))
          break;
      }
      else
        break;
    }
  }
  return 1;
}

fwFsm_rewriteSmiObject(file f, string type, string domain, string curr_obj, int mode_flag)
{
  file fin;
  int pos, all_flag;
  string s, top_type;
  int ret, index, i, todo_flag = 0;
  string aux_type;

  fwFsm_setSmiDomain(domain);

  if( strpos(type,"TOP_") == 0 )
  {
    if((domain == curr_obj) || (CurrPart == curr_obj))
    {
//			strreplace(type,"TOP_","");
      type = substr(type,4);
    }
  }
//DebugN("rewriteObj",domain, curr_obj, CurrPart, CurrParts, "type", type, mode_flag);
//DebugN("    ",CurrObjTypes, CurrObjs, CurrObjsTypes, CurrUsedObjs);

  index = dynContains(CurrObjTypes, type);
  if(mode_flag)
  {
    if((curr_obj != CurrPart) /*  || (index)*/ )
    {
//DebugTN("Mode rewriten", type, CurrUsedTypes, curr_obj);
      if(!dynContains(CurrUsedTypes, type))
      {
//				fin = fopen(fwFsm_getProjPath()+"/smi/"+type+"_mode.fsm","r");
        if((pos = strpos(type,fwFsm_typeSeparator)) < 0)
        {
          fin = fopen(fwFsm_getProjPath()+"/smi/"+type+".mode_fsm","r");
          fwFsm_doRewriteSmiObject(f, fin, domain, curr_obj);
          fclose(fin);
          dynAppend(CurrUsedTypes, type);
        }
        else
        {
          aux_type = substr(type, 0, pos);
          if(!dynContains(CurrUsedTypes, aux_type))
          {
            fin = fopen(fwFsm_getProjPath()+"/smi/"+aux_type+".mode_fsm","r");
            fwFsm_doRewriteSmiObject(f, fin, domain, curr_obj);
            fclose(fin);
            dynAppend(CurrUsedTypes, aux_type);
          }
        }
      }
    }
  }
  if(!dynContains(CurrParts, curr_obj))
    todo_flag = 1;
  else
  {
    if(index)
    {
      for(i = 1; i <= dynlen(CurrObjsTypes[index]); i++)
      {
        if(!dynContains(CurrParts, CurrObjsTypes[index][i]))
          todo_flag = 1;
      }
    }
  }
  if(todo_flag)
  {
//DebugN("Object class rewriten", type);
    fin = fopen(fwFsm_getProjPath()+"/smi/"+type+".fsm","r");
//DebugN("Object class rewriten", type, fin);
    fwFsm_doRewriteSmiObject(f, fin, domain, curr_obj);
    fclose(fin);
  }
}

fwFsm_doRewriteSmiObject(file f, file fin, string domain, string curr_obj)
{
  int pos, all_flag;
  string s, top_type;
  int ret;

//DebugN("rewriting ",domain, curr_obj);
  while(!feof(fin))
  {
    ret = 0;
    fgets(s,2000,fin);
//DebugN(s);
    if((pos = strpos(s,"$")) >= 1)
    {
//DebugTN("has $", s);
      if( (strpos(s,"if") >= 0 ) || (strpos(s,"when") >= 0 ) )
      {
        ret = fwFsm_handleCondition(fin, f, s);
      }
      if(!ret)
      {
        if( strpos(s, "wait") >= 0 )
        {
          ret = fwFsm_handleInstructionWait(fin, f, s);
        }
      }
      if(!ret)
      {
        if( ( strpos(s, "do") >= 0 ) || ( strpos(s, "set") >= 0 )  || ( strpos(s, "wait") >= 0 ) )
        {
          ret = fwFsm_handleInstruction(fin, f, s);
        }
      }
      if(!ret)
      {
//DebugN("***",s);
        ret = fwFsm_parseFsmLine(s, pos, top_type, all_flag);
//DebugN("***",s,ret, top_type, curr_obj);
        if(ret)
        {
//DebugN("found", s, pos);
          if( strpos(top_type,"ASS_") == 0 )
          {
            strreplace(s,"$ASS",curr_obj);
          }
          if((domain == curr_obj) || (CurrPart == curr_obj))
            strreplace(s,"$TOP$","TOP_");
          else
            strreplace(s,"$TOP$","");
          fputs(s, f);
        }
      }
//DebugN("out of $ line");
    }
    else
    {
      fputs(s, f);
    }
  }
  fprintf(f,"\n");
}


fwFsm_checkSmiObject(string type, int & flag)
{
  file fin;
  int i, pos;
  string s;

  flag = 0;
  fin = fopen(fwFsm_getProjPath()+"/smi/"+type+".fsm","r");
  if(fin == 0)
  {
    DebugN("File not found: "+"smi/"+type+".fsm");
    return;
  }
  while(!feof(fin))
  {
    fgets(s,2000,fin);
    if((pos = strpos(s,"$ASS")) >= 1)
    {
      flag = 1;
    }
  }
  fclose(fin);
}

fwFsm_writeSmiDomain(string domain, string system = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(system);
  dpSetWait(tododp+".params:_original.._value",makeDynString(domain),
            tododp+".action:_original.._value","FwCreateDomain");
  delay(0,200);
}

int fwFsm_checkTransLog(string logfile, string smlfile, string domain)
{
  file flog;
  string logstr, logs, errorstr;
  int size, stopit = 0;

  size = getFileSize(logfile);
  if(size)
  {
    logs = "";
    flog = fopen(logfile,"r");
    while(!feof(flog))
    {
      fgets(logstr,2000,flog);
      logs += logstr;

      if(strpos(logstr,"=== ") == 0)
      {
        if((strpos(logstr,"=== WARNING ===") < 0) && (strpos(logstr,"=== SEVERE WARNING ===") < 0))
          stopit = 1;
      }
    }
    fclose(flog);
    if(stopit)
      DebugN(domain+" - Error(s) Translating SML code in: "+smlfile);
    else
      DebugN(domain+" - Warning(s) Translating SML code in: "+smlfile);
    DebugN(logs);
    if(stopit)
      return 0;
  }
  return 1;
}

int fwFsm_doWriteSmiDomain(string domain)
{
  file fout;
  dyn_string allobjs, logobjs, objs;
  dyn_string fwChildrenAllDUTypes;
  string domain_file, path, backpath, logfile, smlfile, sobjfile;
  int i, j, index;

  dynClear(CurrParts);
  dynClear(CurrUsedObjs);
  dynClear(CurrUsedAllObjs);
  dynClear(CurrUsedAllTypes);
  fwFsm_setSmiDomain(domain);
  domain_file = domain;
  strreplace(domain_file,fwDev_separator,"_");
//	fout = fopen(fwFsm_getProjPath()+"/smi/"+domain_file+"_domain.sml","w");
//To remove old version
/*
  path = fwFsm_getProjPath()+"/smi/"+domain_file+"_domain.sml";
  if(!access(path, F_OK))
  {
    system("rm "+path);
DebugN("Deleted: "+path);
  }
*/
  path = fwFsm_getProjPath()+"/smi/"+domain_file+".sml";
  backpath = fwFsm_getProjPath()+"/smi_back/"+domain_file+".sml";
  if(!access(path, F_OK))
    copyFile(path, backpath);
  fout = fopen(path,"w");

  allobjs = fwFsm_getDomainObjects(domain, 1, 1);
//DebugN("all", allobjs);

  logobjs = fwFsm_getDomainLogicalObjects(domain);
//DebugN("logicals", logobjs);

  fwFsm_writeLogicalObjsrec(fout, domain, domain, allobjs, logobjs, fwChildrenAllDUTypes);

//DebugN("writing rest", domain, "", allobjs);
  fwFsm_doWriteSmiDomainPart(fout, domain, "", allobjs, fwChildrenAllDUTypes);
  fclose(fout);
  fwFsm_setupCUModeBits(domain);

//	system("rm "+fwFsm_getProjPath()+"/tmp1");
//	system("rm "+fwFsm_getProjPath()+"/tmp2");

  if (os=="Linux")
  {
    logfile = fwFsm_getProjPath()+"/smi/"+domain_file+".log";
    smlfile = fwFsm_getProjPath()+"/smi/"+domain_file+".sml";
    sobjfile = fwFsm_getProjPath()+"/smi/"+domain_file+".sobj";
//     DebugTN("File to delete: ", sobjfile);
    //string testt = "pwd; echo " + sobjfile + " >> testt.txt";
    //system(testt);
    system("rm "+sobjfile);
    system(fwFsm_getFsmPath()+"/smiTrans "+smlfile+" "+sobjfile+" > "+logfile);
    if(!fwFsm_checkTransLog(logfile, smlfile, domain))
      return 0;
  }
  else
  {
    logfile = fwFsm_getProjPath()+"\\smi\\"+domain_file+".log";
    smlfile = fwFsm_getProjPath()+"\\smi\\"+domain_file+".sml";
    sobjfile = fwFsm_getProjPath()+"\\smi\\"+domain_file+".sobj";
    system("rm "+sobjfile);
    system("start /b "+fwFsm_getFsmPath()+"\\smiTrans "+smlfile+" "+sobjfile+" > "+logfile);
//DebugTN("start /b "+fwFsm_getFsmPath()+"\\smiTrans "+smlfile+" "+sobjfile+" > "+logfile);
    delay(0,200);
    if(!fwFsm_checkTransLog(logfile, smlfile, domain))
      return 0;
/*
		size = getFileSize(fwFsm_getProjPath()+"/smi/"+domain_file+".log");
		if(size)
		{
			log = "";
			flog = fopen(fwFsm_getProjPath()+"\\smi\\"+domain_file+".log","r");
			while(!feof(flog))
			{
				fgets(logs,2000,flog);
				log += logs;
			}
			fclose(flog);
			DebugN(domain+" - Error Translating SML code in: "+fwFsm_getProjPath()+"\\smi\\"+domain_file+".sml");
			DebugN(log);
//			return 0;
		}
*/
  }
  if(dynlen(fwChildrenAllDUTypes))
    fwFsm_doWriteDomainScript(domain, fwChildrenAllDUTypes);
  return 1;
}

fwFsm_writeLogicalObjsrec(file fout, string domain, string node,
	dyn_string &allobjs, dyn_string &logobjs, dyn_string &fwChildrenAllDUTypes)
{
  dyn_string objs, children;
  dyn_int flags;
  int i, index;

  objs = fwFsm_getObjChildren(domain, node, flags);
//DebugN("in rec", domain, node, objs);

//	if(dynlen(objs))
//		fwFsm_writeLogicalObjsrec(fout, domain, allobjs, logobjs, fwChildrenAllDUTypes);
  for(i = 1; i <= dynlen(objs); i++)
  {
    if(dynContains(logobjs, objs[i]))
    {
      children = fwFsm_getObjChildren(domain, objs[i], flags);
      if(dynlen(children))
        fwFsm_writeLogicalObjsrec(fout, domain, objs[i], allobjs, logobjs, fwChildrenAllDUTypes);
    }
    if(domain != node)
    {
      if(index = dynContains(allobjs, objs[i]))
      {
        dynRemove(allobjs, index);
//DebugN("Removing",objs[i]);
      }
    }
  }
  if((domain != node) && (!fwFsm_isAssociated(node)))
  {
    dynInsertAt(objs, node, 1);
    fwFsm_doWriteSmiDomainPart(fout, domain, node, objs, fwChildrenAllDUTypes);
    dynAppend(CurrParts, node);
  }
}

int fwFsm_doWriteSmiDomainPart(file fout, string domain, string part, dyn_string objs,
	dyn_string &fwChildrenAllDUTypes, int union_flag = FwFSM_UnionFlag)
{
  file fin;
  string s, full_name, aux, aux1, curr_type, obj;
  int i, j, k, pos, index, done = 0, done_ass = 0, done_not_ass = 0, ass = 0, later = 0, dont;
  dyn_string types, names, all_types, top_objs, setobjects;
  dyn_int asss, laters, cus, dus;
  dyn_dyn_int type_obj_index, type_obj_index_more;
  int set_flag, cu, du, lobj;
  string subdomain, subobj, tmp_obj, domain_aux;
  dyn_string fwChildrenObjs, fwChildrenDUObjs;
  dyn_string fwChildrenTypes, fwChildrenDUTypes;
  dyn_dyn_string typeObjs, tmp_objs;
  dyn_string typesTypes, tmp_types, aux_objs, aux_types;
  string path, backpath, logs, log;
  int size, aux_index;
  dyn_string unionsets;
  string union_top_type, curr_type_aux;

//DebugTN("-------- fwFsm_doWriteSmiDomainPart", domain, part, objs);
  dynClear(all_types);
  dynClear(top_objs);
//DebugN("***", domain, part, CurrUsedObjs);
  dynAppend(CurrUsedAllObjs, CurrUsedObjs);
  dynClear(CurrUsedObjs);
//	dynAppend(CurrUsedAllTypes, CurrUsedTypes);
  dynClear(CurrUsedTypes);
  CurrPart = part;
  domain_aux = domain;
  strreplace(domain_aux,fwDev_separator,":");
//DebugTN("before",domain, objs);
  for(i = 1; i <= dynlen(objs); i++)
  {
    fwFsm_getObjectType( domain+"::"+objs[i], types[i]);
    if(types[i] == "")
    {
      dynRemove(objs, i);
      i--;
      continue;
    }
    if((pos = strpos(types[i],fwFsm_typeSeparator)) > 0)
    {
      obj = objs[i];
      dynRemove(objs, i);
      dynInsertAt(objs, obj, 1);
    }
  }
//DebugTN("after",domain, objs);
  for(i = 1; i <= dynlen(objs); i++)
  {
    fwFsm_getObjectType( domain+"::"+objs[i], types[i]);
//DebugN(domain+"::"+objs[i], types[i]);
/*
		if(types[i] == "")
		{
			dynRemove(objs, i);
			i--;
			continue;
		}
*/
    asss[i] = fwFsm_isAssociated(objs[i]);
    cus[i] = fwFsm_isCU(domain, objs[i]);
    if((part != "") && (asss[i]))
      cus[i] = 0;
    dus[i] = fwFsm_isDU(domain, objs[i]);
//DebugTN(domain, part, objs[i], asss[i], cus[i], dus[i]);
    if(i > 1)
    {
      if( types[i] == types[i-1])
        laters[i] = laters[i-1];
      else
        fwFsm_checkSmiObject(types[i], laters[i]);
    }
    else
      fwFsm_checkSmiObject(types[i], laters[i]);
    curr_type = types[i];
    if((objs[i] == domain) || (objs[i] == part))
    {
      string tp;
			//int pos;

      types[i] = "TOP_"+types[i];
      tp = types[i];
      if((pos = strpos(tp,fwFsm_typeSeparator)) > 0)
        tp = substr(tp, 0, pos);
      union_top_type = tp;
    }

    strreplace(objs[i],fwDev_separator,":");


    if((objs[i] != domain_aux) && (objs[i] != part) &&
       (strpos(objs[i],"_FWM") < 0) && (strpos(objs[i],"_FWCNM") < 0) &&
       (strpos(objs[i],"_FWMAJ") < 0) && (strpos(objs[i],"_FWDM") < 0))
    {
      string tp;
			//int pos;
      dynAppend(fwChildrenObjs,objs[i]);

      tp = curr_type;
      if((pos = strpos(tp,fwFsm_typeSeparator)) > 0)
        tp = substr(tp, 0, pos);
      if(!dynContains(fwChildrenTypes,tp))
        dynAppend(fwChildrenTypes,tp);
      if(dus[i])
      {
        dynAppend(fwChildrenDUObjs,objs[i]);
        if(!dynContains(fwChildrenDUTypes,curr_type))
          dynAppend(fwChildrenDUTypes,curr_type);
      }
      dynAppend(aux_objs, objs[i]);
      dynAppend(aux_types, curr_type);
    }
/*
//		if((objs[i] != domain_aux) &&
		if(	(objs[i] != domain_aux+"_FWM") &&
			(objs[i] != domain_aux+"_FWCNM"))
//			(objs[i] != domain_aux+"_FWDM"))
*/
    if(((objs[i] != domain_aux) || (dus[i])) && (objs[i] != part) &&
       (objs[i] != domain_aux+"_FWM") && (objs[i] != domain_aux+"_FWCNM"))
//			(objs[i] != domain_aux+"_FWDM"))
    {
      string tp;
			//int pos;

      tp = curr_type;
      if((pos = strpos(tp,fwFsm_typeSeparator)) > 0)
        tp = substr(tp, 0, pos);
      if(!(index = dynContains(typesTypes,tp)))
        index = dynAppend(typesTypes,tp);
/*
			if(!(index = dynContains(typesTypes,curr_type)))
				index = dynAppend(typesTypes,curr_type);
*/
      dynAppend(typeObjs[index],objs[i]);
      if(dus[i])
      {
        if(!dynContains(fwChildrenAllDUTypes,curr_type))
          dynAppend(fwChildrenAllDUTypes,curr_type);
      }
    }

  }
//DebugN("fwChildren",fwChildrenTypes, fwChildrenObjs);
//DebugN("OtherTypes",typesTypes, typeObjs);

//	domain = domain_aux;
  for(i = 1; i <= dynlen(types); i++)
  {
    string tp;

    tp = types[i];
    if(!(index = dynContains(all_types, tp)))
    {
      index = dynAppend(all_types, tp);
    }
//		index = dynContains(all_types, types[i]);
    dynAppend(type_obj_index[index], i);
  }
//DebugTN("ALL Types", all_types, types, type_obj_index, type_obj_index_more, objs);
  for(i = 1; i <= dynlen(types); i++)
  {
    string tp;
		//int pos;

    if((pos = strpos(types[i],fwFsm_typeSeparator)) > 0)
    {
      tp = substr(types[i],0, pos);
      if(!(index = dynContains(all_types, tp)))
      {
        index = dynAppend(all_types, tp);
        dynAppend(type_obj_index[index], makeDynInt());
      }
//		index = dynContains(all_types, types[i]);
      dynAppend(type_obj_index_more[index], i);
    }
  }
//DebugTN("ALL Types1", all_types, types, type_obj_index, type_obj_index_more, objs);
  for(i = 1; i <= dynlen(all_types); i++)
  {
    done_ass = 0;
    done_not_ass = 0;
    set_flag = 0;
    dynClear(setobjects);
    curr_type = all_types[i];
    curr_type_aux = curr_type;
    if((pos = strpos(curr_type_aux,fwFsm_typeSeparator)) > 0)
      curr_type_aux = substr(curr_type_aux, 0, pos);
    if(pos = strpos(curr_type,"TOP_") == 0)
      strreplace(curr_type,"TOP_","");
//DebugN("**** Type objects", all_types[i], i, j, type_obj_index);
    for(j = 1; j <= dynlen(type_obj_index[i]); j++)
    {
      ass = asss[type_obj_index[i][j]];
      obj = objs[type_obj_index[i][j]];
      cu = cus[type_obj_index[i][j]];
      du = dus[type_obj_index[i][j]];
      lobj = 0;
//DebugN("TYPE", all_types[i], curr_type, fwChildrenTypes, obj, du, cu, types[type_obj_index[i][j]] );
//DebugTN("TYPE", all_types[i], curr_type, curr_type_aux, domain_aux, obj, du, cu, fwChildrenTypes);
      if(((!du) && (!cu)) && dynContains(fwChildrenTypes, curr_type_aux))
        lobj = 1;
      later = laters[type_obj_index[i][j]];

      if((obj == domain_aux) || (obj == part))
      {
        CurrfwChildrenObjs = fwChildrenObjs;
        CurrfwChildrenTypes = fwChildrenTypes;
      }
      else
      {
        if((!du) && (!ass) && (!cu))
        {
          CurrfwChildrenObjs = fwChildrenDUObjs;
          CurrfwChildrenTypes = fwChildrenDUTypes;
        }
      }
/*
			CurrfwChildrenObjs = fwChildrenObjs;
			CurrfwChildrenTypes = fwChildrenTypes;
*//* to be seen */
//DebugN("Curr",obj, CurrfwChildrenTypes, CurrfwChildrenObjs, ass, done_ass, CurrUsedTypes, all_types[i]);
//DebugN("Curr",obj, ass, done_ass, CurrUsedTypes, all_types[i], du, lobj);
      if(ass)
      {
//DebugTN("Doing ass", done_ass, curr_type_aux, CurrUsedTypes, domain, obj);
        if(!done_ass)
        {
//DebugN("rewrite",all_types[i], CurrUsedTypes, domain, part, obj, du, cu, lobj);
/*
					if((!dynContains(CurrUsedTypes, all_types[i])))
					{
//DebugTN("Add ass", obj, all_types[i], du, lobj, cu);
//						if(((pos = strpos(all_types[i],"Fw")) != 0) && (du | lobj))
						if( (du | lobj))
						{
DebugN("rewrite2",all_types[i], CurrUsedTypes, domain, part, obj, du, cu, lobj);
//						fin = fopen(fwFsm_getProjPath()+"/smi/"+all_types[i]+"_mode.fsm","r");
						fin = fopen(fwFsm_getProjPath()+"/smi/"+all_types[i]+".mode_fsm","r");
						fwFsm_doRewriteSmiObject(fout, fin, domain, obj);
						fclose(fin);
						dynAppend(CurrUsedTypes, all_types[i]);
						}
					}
*/
//DebugTN("calling doRewrite mode", curr_type_aux, CurrUsedTypes, domain, obj);
          if(/*(part != "") && */(!dynContains(CurrUsedTypes, curr_type_aux)))
          {
//DebugTN("Add ass", obj, all_types[i], du, lobj, cu);
//						if(((pos = strpos(all_types[i],"Fw")) != 0) && (du | lobj))
            if(/*((pos = strpos(all_types[i],"Fw")) != 0) && */ (du | lobj))
            {
//DebugN("rewrite2",curr_type_aux, CurrUsedTypes, domain, part, obj, du, cu, lobj);
//						fin = fopen(fwFsm_getProjPath()+"/smi/"+all_types[i]+"_mode.fsm","r");
              fin = fopen(fwFsm_getProjPath()+"/smi/"+curr_type_aux+".mode_fsm","r");
              fwFsm_doRewriteSmiObject(fout, fin, domain, obj);
              fclose(fin);
              dynAppend(CurrUsedTypes, curr_type_aux);
            }
          }
          if(!dynContains(CurrUsedAllTypes, "ASS_"+all_types[i]))
          {
//						fin = fopen(fwFsm_getProjPath()+"/smi/"+all_types[i]+"_include.sml","r");
//DebugN("object1 type: "+obj+" is_of_class ASS_"+all_types[i]+"_CLASS", CurrUsedAllTypes);
            fin = fopen(fwFsm_getProjPath()+"/smi/"+all_types[i]+".inc","r");
            if(fin == 0)
            {
              DebugN("File not found: "+"smi/"+all_types[i]+".inc");
            }
            else
            {
              while(!feof(fin))
              {
                fgets(s,2000,fin);
                if((pos = strpos(s,"$")) >= 1)
                {
                  fwFsm_parseParameters(s);
                }
//DebugTN(s);
                fputs(s, fout);
              }
              fprintf(fout,"\n");
              fclose(fin);
            }
            dynAppend(CurrUsedAllTypes, "ASS_"+all_types[i]);
//            done_ass = 1;
          }
          if((dynContains(CurrUsedAllTypes, "ASS_"+all_types[i])) && (dynContains(CurrUsedTypes, curr_type_aux)))
            done_ass = 1;
        }
        if(!dynContains(CurrUsedAllObjs, obj))
        {
//DebugN("object1: "+obj+" is_of_class ASS_"+all_types[i]+"_CLASS", part, CurrUsedAllObjs);
          fprintf(fout,"object: %s is_of_class ASS_%s_CLASS\n\n", obj, all_types[i]);
        }
        if (all_types[i] == "FwChildrenMode")
        {
          dynAppend(setobjects, obj);
        }
        if(!cu)
        {
          if(!dynContains(setobjects, obj))
          {
            dynAppend(setobjects, obj);
          }
        }
        set_flag = 1;
      }
      else
      {
        if(!done_not_ass)
        {
          if(!later)
          {
            CurrObjTypes = typesTypes;
            CurrObjsTypes = typeObjs;
            CurrObj = obj;
            RemCurrObj = 0;
//DebugTN("rewrite-", typesTypes, typeObjs, obj);
//DebugTN("rewrite",all_types[i], domain_aux, CurrPart, obj, du, cu, lobj);
            fwFsm_rewriteSmiObject(fout, all_types[i], domain_aux, obj, (du && !cu) || lobj);
          }
          done_not_ass = 1;
        }
        if(later)
        {
          if((pos = strpos(obj,"_FW")) >= 0)
          {
            dynClear(tmp_types);
            dynClear(tmp_objs);
            aux = substr(obj,0,pos);
            tmp_types[1] = "FwMode";
            tmp_objs[1][1] = aux+"::"+obj;
            aux_index = 2;
/*
						for(k = 1; k < dynlen(aux_objs); k++)
						{
							if(strpos(aux_objs[k],aux+"::") == 0)
							{
								if(aux_objs[k] != aux+"::"+aux)
								{
//DebugN("bug?", aux_objs, k, aux_types, i);
									tmp_types[aux_index] = aux_types[k];
									tmp_objs[aux_index] = makeDynString();
									//dynAppend(tmp_types,aux_types[i]);
									//pos = dynAppend(tmp_objs,makeDynString());
									tmp_objs[aux_index][1] = aux_objs[k];
									aux_index++;
								}
							}
						}
*/
            CurrObjTypes = tmp_types;
            CurrObjsTypes = tmp_objs;
//DebugN("types, objs", CurrObjTypes, CurrObjsTypes);
//DebugN("alltypes,objs",typesTypes, typeObjs);
//DebugN("fwChildren",fwChildrenObjs, fwChildrenTypes);
//DebugN("objs",aux_objs, aux_types);
          }
          RemCurrObj = 0;
//DebugN("rewrite 1",all_types[i], domain_aux, CurrPart, obj, du, cu, lobj);
          fwFsm_rewriteSmiObject(fout, all_types[i], domain_aux
						/*, tmp_objs*/, aux, du || lobj);
          if(!dynContains(CurrParts, obj))
          {
//DebugTN("object: "+obj+" is_of_class "+aux+"_"+all_types[i]+"_CLASS", CurrUsedTypes);
            fprintf(fout,"object: %s is_of_class %s_%s_CLASS\n\n",	obj, aux, all_types[i]);
          }
        }
        else
        {
//DebugN("is_of_class",CurrPart+all_types[i], obj, CurrPart);
          if(!dynContains(CurrParts, obj))
          {
//DebugTN("object2: "+obj+" is_of_class "+CurrPart+all_types[i]+"_CLASS", CurrUsedTypes);
            fprintf(fout,"object: %s is_of_class %s_CLASS\n\n", obj, CurrPart+all_types[i]);
          }
        }
        if (all_types[i] != "FwChildrenMode")
        {
//					if(strpos(all_types[i],"Fw") == 0)
          dynUnique(CurrUsedObjs);
//DebugN("Appending setobjects", all_types[i], obj, RemCurrObj, CurrUsedObjs);
          if((!RemCurrObj) || (dynContains(CurrUsedObjs, obj)))
            dynAppend(setobjects, obj);
        }
      }
    }

    if(i <= dynlen(type_obj_index_more))
    {
      for(j = 1; j <= dynlen(type_obj_index_more[i]); j++)
      {
        ass = asss[type_obj_index_more[i][j]];
        obj = objs[type_obj_index_more[i][j]];
        cu = cus[type_obj_index_more[i][j]];
        du = dus[type_obj_index_more[i][j]];
        lobj = 0;
//DebugN("TYPE", all_types[i], curr_type, domain_aux, obj, du, cu);
        if(((!du) && (!cu)) && dynContains(fwChildrenTypes, curr_type))
          lobj = 1;
//DebugTN("type more", all_types[i], curr_type, fwChildrenTypes, obj, du, cu, lobj, types[type_obj_index_more[i][j]], setobjects );
        if((ass) || (lobj))
        {
          if (all_types[i] == "FwChildrenMode")
          {
            dynAppend(setobjects, obj);
          }
          if(!cu)
          {
            if(!dynContains(setobjects, obj))
            {
              dynAppend(setobjects, obj);
            }
          }
          set_flag = 1;
        }
      }
    }

//DebugN("setobjects",obj, all_types[i], setobjects, CurrObjs);
    if((all_types[i] != "FwMode") && (all_types[i] != "FwChildrenMode"))
    {
      if(obj != CurrPart)
      {
        string tp;
			//int pos;
			//int dont = 0;

        dont = 0;
        tp = all_types[i];
        if((pos = strpos(tp, fwFsm_typeSeparator)) > 0)
        {
          tp = substr(tp, 0, pos);
          if(dynContains(all_types, tp))
            dont = 1;
        }
//DebugTN("setobjects",obj, all_types[i], tp, union_top_type, setobjects, CurrPart, dont);
        if((tp != "FwChildMode") && (tp != "FwDevMode") && (tp != union_top_type))
        {
          if(!dynContains(unionsets, CurrPart+fwFsm_formSetName(tp, "ACTIONS")))
            dynAppend(unionsets, CurrPart+fwFsm_formSetName(tp, "ACTIONS"));
        }
        if(!dont)
        {
//      if(ass)
//			  aux = "objectset: "+CurrPart+fwFsm_formSetName(tp, "STATES")+" is_of_class "+"ASS_"+all_types[i]+"_CLASS";
//      else
//			  aux = "objectset: "+CurrPart+fwFsm_formSetName(tp, "STATES")/*+" is_of_class "+CurrPart+all_types[i]+"_CLASS"*/;
          aux = "objectset: "+CurrPart+fwFsm_formSetName(tp, "STATES")+" is_of_class VOID";
          if(index = dynContains(setobjects,domain_aux))
          {
            dynRemove(setobjects,index);
          }
          if(index = dynContains(setobjects,part))
          {
            dynRemove(setobjects,index);
          }
//DebugN("setobjects 1",obj, setobjects, CurrObjs, aux, all_types[i], set_flag);
          if(dynlen(setobjects))
          {
            aux +=" {";
            for(j = 1; j <= dynlen(setobjects); j++)
            {
              aux += setobjects[j];
              if(j != dynlen(setobjects))
                aux += ",\n\t";
              else
                aux += " }";
            }
            set_flag = 1;
          }
          if(set_flag)
          {
//        if(ass)
//			    aux += "\nobjectset: "+CurrPart+fwFsm_formSetName(tp, "ACTIONS")+" is_of_class "+"ASS_"+all_types[i]+"_CLASS";
//        else
//			  	aux += "\nobjectset: "+CurrPart+fwFsm_formSetName(tp, "ACTIONS")/*+" is_of_class "+CurrPart+all_types[i]+"_CLASS"*/;
            aux += "\nobjectset: "+CurrPart+fwFsm_formSetName(tp, "ACTIONS")+" is_of_class VOID";
            if(dynlen(setobjects))
            {
              aux +=" {";
              for(j = 1; j <= dynlen(setobjects); j++)
              {
                aux += setobjects[j];
                if(j != dynlen(setobjects))
                  aux += ",\n\t";
                else
                  aux += " }";
              }
            }
            fprintf(fout,aux+"\n\n");
          }
        }
      }
    }
    else if ((all_types[i] == "FwChildrenMode") && (dynlen(setobjects)))
    {
//      if(ass)
//			  aux = "objectset: "+fwFsm_formSetName(all_types[i], "STATES")+" is_of_class "+"ASS_"+all_types[i]+"_CLASS";
//      else
//			  aux = "objectset: "+fwFsm_formSetName(all_types[i], "STATES")/*+" is_of_class "+CurrPart+all_types[i]+"_CLASS"*/;
      aux = "objectset: "+fwFsm_formSetName(all_types[i], "STATES")+" is_of_class VOID";
//DebugTN("objectset2",aux);
//DebugN("setobjects 2",obj, setobjects, CurrObjs);
      if(dynlen(setobjects))
      {
/*
				aux +=" {";
 				for(j = 1; j <= dynlen(setobjects); j++)
				{
					aux += setobjects[j];
					if(j != dynlen(setobjects))
						aux += ",\n\t";
					else
						aux += " }";
				}
*/
        fprintf(fout,aux+"\n\n");
      }
    }
  }
//DebugN("object set", CurrPart, all_types, unionsets);
  if(union_flag)
  {

    aux = "\nobjectset: "+CurrPart+fwFsm_formSetName("FwCHILDREN", "ACTIONS");
    if(dynlen(unionsets))
    {
      aux +=" union {";
      for(j = 1; j <= dynlen(unionsets); j++)
      {
        aux += unionsets[j];
        if(j != dynlen(unionsets))
          aux += ",\n\t";
        else
          aux += " }";
      }
    }
    aux += " is_of_class VOID";
    aux += "\nobjectset: "+CurrPart+fwFsm_formSetName("FwCHILDREN", "STATES");
    if(dynlen(unionsets))
    {
      aux +=" union {";
      for(j = 1; j <= dynlen(unionsets); j++)
      {
        strreplace(unionsets[j],"SETACTIONS","SETSTATES");
        aux += unionsets[j];
        if(j != dynlen(unionsets))
          aux += ",\n\t";
        else
          aux += " }";
      }
    }
    aux += " is_of_class VOID";
    fprintf(fout,aux+"\n\n");
  }
}

fwFsm_doRemoveSmiDomain(string domain)
{
//CVV CMS
  return;
/*
  string domain_file, path;

  domain_file = domain;
  strreplace(domain_file,fwDev_separator,"_");

  path = fwFsm_getProjPath()+"/smi/"+domain_file+".sobj";
  if(!access(path, F_OK))
  {
    system("rm "+path);
    DebugN("Deleted: "+path);
  }
  path = fwFsm_getProjPath()+"/smi/"+domain_file+".sml";
  if(!access(path, F_OK))
  {
    system("rm "+path);
    DebugN("Deleted: "+path);
  }
  path = fwFsm_getProjPath()+"/smi/"+domain_file+".log";
  if(!access(path, F_OK))
  {
    system("rm "+path);
    DebugN("Deleted: "+path);
  }
*/
}

fwFsm_restartAllDomains(string system = "")
{
  _fwFsm_commandToAllDomains("FwRestartAllDomains", system);
}

fwFsm_stopAllDomains(string system = "")
{
  _fwFsm_commandToAllDomains("FwStopAllDomains", system);
}

_fwFsm_commandToAllDomains(string command, string system)
{
  string tododp;

  tododp = _fwFsm_getToDoDP(system);
  dpSetWait(tododp+".params:_original.._value", makeDynString(),
            tododp+".action:_original.._value", command);
  delay(0,200);
}

/*
	get todo datapoint name for distributed systems
 */
string _fwFsm_getToDoDP(string system = "")
{
  string dpName = "ToDo";
  if (system != "")
  {
    dpName = system+":"+dpName;
    if (!dpExists(dpName))
    {
      DebugTN("Error: internal FSM tree datapoint not found for system " +system+". Check connection!");
  		}
  }
  return dpName;
}
/*
fwFsm_restartAllDomains()
{

	dpSetWait("ToDo.params:_original.._value",makeDynString(),
		  "ToDo.action:_original.._value","FwRestartAllDomains");
	delay(0,200);
}

fwFsm_stopAllDomains()
{

	dpSetWait("ToDo.params:_original.._value",makeDynString(),
		  "ToDo.action:_original.._value","FwStopAllDomains");
	delay(0,200);
}
*/
fwFsm_restartTreeDomains(string domain, string sys = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(sys);
  dpSetWait(tododp+".params:_original.._value",makeDynString(domain),
            tododp+".action:_original.._value","FwRestartTreeDomains");
  delay(0,200);
}

fwFsm_stopTreeDomains(string domain, string sys = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(sys);
  dpSetWait(tododp+".params:_original.._value",makeDynString(domain),
            tododp+".action:_original.._value","FwStopTreeDomains");
  delay(0,200);
}

fwFsm_restartDomain(string domain, string sys = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(sys);
  dpSetWait(tododp+".params:_original.._value",makeDynString(domain),
            tododp+".action:_original.._value","FwRestartDomain");
  delay(0,200);
}

fwFsm_stopDomain(string domain, string sys = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(sys);
  dpSetWait(tododp+".params:_original.._value",makeDynString(domain),
            tododp+".action:_original.._value","FwStopDomain");
  delay(0,200);
}

fwFsm_restartDomainDevices(string domain, string sys = "")
{
  string action;
  string tododp;

  tododp = _fwFsm_getToDoDP(sys);
  while(1)
  {
    dpGet(tododp+".status", action);
    if(action != "busyDevices")
    {
      dpSetWait(tododp+".status:_original.._value","busyDevices");
      dpSetWait(tododp+".params:_original.._value",makeDynString(domain),
                tododp+".action:_original.._value","FwRestartDomainDevices");
      delay(0,200);
      break;
    }
    else
    {
      delay(1);
    }
  }
}

fwFsm_restartPVSS00smi(string sys = "")
{
  string tododp;

  tododp = _fwFsm_getToDoDP(sys);
  dpSetWait(tododp+".action:_original.._value","FwRestartPVSS00smi");
  delay(0,200);
}

fwFsm_restartPVSS00ctrl(string sys = "", string domain = "")
{
  string tododp;
  dyn_string params;

  tododp = _fwFsm_getToDoDP(sys);
  if(domain != "")
    dynAppend(params, domain);
	 dpSetWait(tododp+".params:_original.._value",params,
		          tododp+".action:_original.._value","FwRestartPVSS00ctrl");
  delay(0,200);
}

fwFsm_sendSmiCommand(string domain, string obj, string cmnd)
{
//DebugN("-------- smiSendCommand ", domain, obj, cmnd);
  dpSetWait("ToDo.params:_original.._value",makeDynString(domain, obj, cmnd),
            "ToDo.action:_original.._value","FwSendSmiCommand");
  delay(0,200);
}

fwFsm_cleanupObjectType(string obj)
{
  dpSetWait("ToDo.params:_original.._value",makeDynString(obj),
            "ToDo.action:_original.._value","FwDeleteObject");
  delay(0,200);
}

fwFsm_cleanupDomainScripts(string domain)
{
  string status = "not_done";

  dpSetWait("ToDo.params:_original.._value",makeDynString(domain),
            "ToDo.action:_original.._value","FwDeleteScripts");
  while( status != "FwDeleteScripts")
  {
    delay(0,100);
    dpGet("ToDo.status:_online.._value",status);
  }
}

fwFsm_cleanupDomain(string domain)
{
  dpSetWait("ToDo.params:_original.._value",makeDynString(domain),
            "ToDo.action:_original.._value","FwDeleteDomain");
  delay(0,200);
}

fwFsm_readObjectStates(string type, dyn_string &states)
{
  fwFsm_getItemsAtPos(type+".states",states,1);
}

fwFsm_writeObjectStates(string type, dyn_string states)
{
  fwFsm_insertItemsPos1(type+".states",states);
}

fwFsm_readObjectColors(string type, dyn_string &colors)
{
  fwFsm_getItemsAtPos(type+".states",colors,2);
}

fwFsm_writeObjectColors(string type, dyn_string colors)
{
  fwFsm_insertItemsAtPos(type+".states",colors, 2);
}

fwFsm_readObjectActions(string type, dyn_string &actions, int funct = 0)
{
  string dpe;

  dpe = ".actions";
  if(funct)
    dpe = ".functions";
  fwFsm_getItemsAtPos(type+dpe,actions,1);
}

fwFsm_writeObjectActions(string type, dyn_string actions, int funct = 0)
{
  string dpe;

  dpe = ".actions";
  if(funct)
    dpe = ".functions";
  fwFsm_insertItemsPos1(type+dpe,actions);
}

fwFsm_readObjectVisis(string type, dyn_int &visis)
{
  int pos;
  if(FwFsmObjectNItems == 3)
    pos = 2;
  else
    pos = 3;
  fwFsm_getItemsAtPos(type+".actions",visis,pos);
}

fwFsm_writeObjectVisis(string type, dyn_int visis)
{
  int pos;
  if(FwFsmObjectNItems == 3)
    pos = 2;
  else
    pos = 3;
  fwFsm_insertItemsAtPos(type+".actions",visis, pos);
}

fwFsm_writeObjectAction(string obj, string state, string action, dyn_string text, int funct = 0)
{
  string str, find, dpe;
  int i;
  int pos;

  if(FwFsmObjectNItems == 3)
    pos = 3;
  else
    pos = 4;

  str = "";
  for(i = 1; i <= dynlen(text); i++)
  {
    str += text[i] +"\n";
  }
  if(funct)
  {
    dpe = ".functions";
    pos = 3;
  }
  else
  {
    dpe = ".actions";
    find = state+"/";
  }
  fwFsm_insertItemByNameAtPos(obj+dpe,str, find+action, pos);
}

fwFsm_readObjectAction(string obj, string state, string action, dyn_string & text, int funct = 0)
{
  string str, find, dpe;
  int pos;

  if(FwFsmObjectNItems == 3)
    pos = 3;
  else
    pos = 4;

  if(funct)
  {
    dpe = ".functions";
    pos = 3;
  }
  else
  {
    dpe = ".actions";
    find = state+"/";
  }
  fwFsm_getItemByNameAtPos(obj+dpe,str, find+action, pos);
  text = strsplit(str,"\n");
}

fwFsm_writeObjectActionText(string obj, string state, string action, string text, int funct = 0)
{
  string str, find, dpe;
  int i;
  int pos;

  if(FwFsmObjectNItems == 3)
    pos = 3;
  else
    pos = 4;

  if(funct)
  {
    dpe = ".functions";
    pos = 3;
  }
  else
  {
    dpe = ".actions";
    find = state+"/";
  }
  fwFsm_insertItemByNameAtPos(obj+dpe,text, find+action, pos);
}

fwFsm_readObjectActionText(string obj, string state, string action, string & text, int funct = 0)
{
  string str, find, dpe;
  int pos;

  if(FwFsmObjectNItems == 3)
    pos = 3;
  else
    pos = 4;

  if(funct)
  {
    dpe = ".functions";
    pos = 3;
  }
  else
  {
    dpe = ".actions";
    find = state+"/";
  }
  fwFsm_getItemByNameAtPos(obj+dpe,text, find+action, pos);
}

fwFsm_writeObjectActionTime(string obj, string state, string action, int act_time)
{
  string str;
  int i;
  int pos;

  if(FwFsmObjectNItems == 3)
    return;
  else
    pos = 5;

  fwFsm_insertItemByNameAtPos(obj+".actions",act_time, state+"/"+action, pos);
}

fwFsm_readObjectActionTime(string obj, string state, string action, int & act_time)
{
  string str;
  int pos;

  if(FwFsmObjectNItems == 3)
    return;
  else
    pos = 5;

  fwFsm_getItemByNameAtPos(obj+".actions",act_time, state+"/"+action, pos);
}

fwFsm_writeObjectWhens(string obj, string state, dyn_string text)
{
  string str;
  int i;

  str = "";
  for(i = 1; i <= dynlen(text); i++)
  {
    str += text[i] +"|";
  }
  fwFsm_insertItemByNameAtPos(obj+".states",str, state, 3);
}

fwFsm_readObjectWhens(string obj, string state, dyn_string & text)
{
  dyn_string whens;
  int i;
  string s, str;

  fwFsm_getItemByNameAtPos(obj+".states",str, state, 3);
  text = strsplit(str,"|");
}

fwFsm_readObjectActionParameters(string obj, string state, string action, dyn_string &pars, int funct = 0)
{
  string str, find, dpe;

  if((funct) || (state == "-"))
  {
    dpe = ".functions";
  }
  else
  {
    dpe = ".actions";
    find = state+"/";
  }
  fwFsm_getItemByNameAtPos(obj+dpe,str, find+action, 2);
  pars = strsplit(str,"\n");
}

fwFsm_writeObjectActionParameters(string obj, string state, string action, dyn_string pars, int funct = 0)
{
  string str, find, dpe;
  int i;

  str = "";
  for(i = 1; i <= dynlen(pars); i++)
  {
    str += pars[i] +"\n";
  }
  if(funct)
  {
    dpe = ".functions";
  }
  else
  {
    dpe = ".actions";
    find = state+"/";
  }
  fwFsm_insertItemByNameAtPos(obj+dpe,str, find+action, 2);
}

fwFsm_readObjectParameters(string obj, dyn_string &pars)
{
  string type1;

  type1 = fwFsm_formType(obj);

  if(dpExists(type1))
    dpGet(type1+".parameters:_online.._value", pars);
}

fwFsm_writeObjectParameters(string obj, dyn_string pars)
{
  string type1;

  type1 = fwFsm_formType(obj);

  if(dpExists(type1))
    dpSet(type1+".parameters:_original.._value", pars);
}

int fwFsm_getOwnPid()
{
  return fwUiGetOwnPid();
}

string fwFsm_formType(string dp)
{
  string dp1, sys;

  dp1 = "";
  sys = fwFsm_getSystem(dp);
  dp = fwFsm_extractSystem(dp);
  if(sys != "")
    dp1 = sys+":";
  dp1 += "fwOT_"+dp;
  return dp1;
}

fwFsm_createObjectTypeDp(string type, int dev=0)
{
  string type1;

  type1 = fwFsm_formType(type);

  if(!dpExists(type1))
  {
    dpCreate(type1,"_FwFsmObjectType");
    if(dev)
    {
//      dpSetWait(type1+".components",makeDynString("something"));
      dpSetWait(type1+".components",makeDynString("anytype"));
    }
  }
}

fwFsm_deleteObjectTypeDp(string type)
{
  string type1;

  type1 = fwFsm_formType(type);

  if(dpExists(type1))
  {
    dpDelete(type1);
  }
}

string fwFsm_unformType(string dp)
{
  string dp1;

  dp1 = substr(dp,5);
  return dp1;
}

fwFsm_getObjectTypeDps(dyn_string &types)
{
  int i;

  types = fwFsm_getDps("*","_FwFsmObjectType");
  for(i = 1; i <= dynlen(types); i++)
  {
    types[i] = substr(types[i],5);
  }
}

fwFsm_insertItemsPos1(string dp, dyn_string itemList)
{
  dyn_string oldValues, newValues;
  int i, j, index;
  string dp1;

  dynClear(newValues);
  dp1 = fwFsm_formType(dp);
  dpGet(dp1+":_online.._value",oldValues);
  for(i = 1; i <= dynlen(itemList); i++)
  {
    dynAppend(newValues,itemList[i]);
    if(index = dynContains(oldValues,itemList[i]))
    {
      for(j = 1; j < FwFsmObjectNItems; j++)
      {
        if(dynlen(oldValues) >= index+j)
          dynAppend(newValues,oldValues[index+j]);
        else
          dynAppend(newValues,"");
      }
    }
    else
    {
      for(j = 1; j < FwFsmObjectNItems; j++)
        dynAppend(newValues,"");
    }
  }
  dpSet(dp1+":_original.._value",newValues);
}

fwFsm_insertItemsAtPos(string dp, dyn_string itemList, int pos)
{
  dyn_string values;
  int i, index;
  string dp1;

  dp1 = fwFsm_formType(dp);
  dpGet(dp1+":_online.._value",values);
  index = pos;
  for(i = 1; i <= dynlen(itemList); i++)
  {
    values[index] = itemList[i];
    index += FwFsmObjectNItems;
  }
  dpSet(dp1+":_original.._value",values);
}

fwFsm_insertItemByNameAtPos(string dp, string item, string name, int pos)
{
  dyn_string values;
  int i, index;
  string dp1;

  dp1 = fwFsm_formType(dp);

  dpGet(dp1+":_online.._value",values);
  if(index = dynContains(values,name))
  {
    values[index+pos-1] = item;
  }
  dpSet(dp1+":_original.._value",values);
}

fwFsm_getItemsAtPos(string dp, dyn_string &itemList, int pos)
{
  dyn_string values;
  int i;
  string dp1;

  dp1 = fwFsm_formType(dp);

  dynClear(itemList);
  if(dpExists(dp1))
  {
    dpGet(dp1+":_online.._value",values);
    i = pos;
    while(i <= dynlen(values))
    {
      dynAppend(itemList,values[i]);
      i += FwFsmObjectNItems;
    }
  }
}

fwFsm_getItemByNameAtPos(string dp, string &item, string name, int pos)
{
  dyn_string values;
  int i, index;
  string dp1;

  dp1 = fwFsm_formType(dp);

  item = "";
  dpGet(dp1+":_online.._value",values);
  if(index = dynContains(values,name))
  {
    item = values[index+pos-1];
  }
}

fwFsm_addClipboard()
{
  dyn_string exInfo;

  fwTree_addNode("FSM","---ClipboardFSM---", exInfo);
}

int fwFsm_initialize(int report = 1, int upgrade = 0)
{
  int version;
  int currentVersion;
  int new_version = 0;

  if(globalExists("FwFsm_initialized"))
  {
//		delay(1);
    while(!FwFsm_initialized)
      delay(0,50);
    return(0);
  }
  addGlobal("FwFsm_initialized", INT_VAR);
  FwFsm_initialized = 0;
  currentVersion = 3424;

  fwFsm_startShowFwObjects();
  fwFsm_setDeviceBaseTypes();
  fwFsm_addClipboard();
  addGlobal("os",STRING_VAR);
/*
	os = getenv("OSTYPE");
	if(strpos(os,"linux") >= 0)
		os = "Linux";
*/
  if(_UNIX)
    os = "Linux";
  addGlobal("FwFsmVersion",INT_VAR);
  addGlobal("FwFsmObjectNItems",INT_VAR);
  FwFsmObjectNItems = 5;
//	fwFsm_lock("fwFsmVersion.version");
  if(upgrade)
  {
    dpGet("fwFsmVersion.version",version);
    FwFsmVersion = version;
    if(version < currentVersion)
    {
      fwFsm_upgradeVersion(version, currentVersion);
      new_version = 1;
    }
  }
//	fwFsm_unlock("fwFsmVersion.version");
  FwFsmVersion = currentVersion;
  if(report)
  DebugTN("System Name: "+getSystemName()+" System Number: "+getSystemId()+" - FwFsm: version is "+FwFsmVersion);
  addGlobal("FwFSMHierarchy",INT_VAR);
  FwFSMHierarchy = 1;
  FwFsm_initialized = 1;
  return new_version;
}

fwFsm_upgradeReferences()
{
  dyn_string nodes, refnode, exInfo;
  int i;
  int num;
  string refstr, refnum, newref;

  DebugN("Converting Reference Format to version 23");
  fwTree_getAllNodes(nodes, exInfo);
  for(i = 1; i <= dynlen(nodes); i++)
  {
    if(fwFsm_isObjectReference(nodes[i]))
    {
      if(patternMatch("&[0123456789]*", nodes[i]))
      {
        if(!patternMatch("&[0123456789][0123456789]*", nodes[i]))
        {
          refstr = substr(nodes[i], 1, 1);
          refnode = substr(nodes[i], 2);
          num = (int) refstr;
          newref = fwTree_makeNodeNumber(num, refnode);
          DebugN("renaming "+nodes[i]+" to "+newref);
          fwTree_renameNode(nodes[i], newref, exInfo);
        }
      }
    }
  }
}

fwFsm_upgradeTree()
{
  dyn_string nodes, exInfo;
  int i, cu;

  fwTree_getRootNodes(nodes, exInfo);
  for(i = 1; i <= dynlen(nodes); i++)
  {
    fwTree_getNodeCU(nodes[i], cu, exInfo);
    if(cu)
    {
      DebugN("Converting "+nodes[i]+" to version 22");
      fwTree_addNode("FSM",nodes[i], exInfo);
    }
  }
  fwTree_getChildren("---Clipboard---", nodes, exInfo);
  if(dynlen(nodes))
  {
    DebugN("Converting Clipboard to version 22");
    for(i = 1; i <= dynlen(nodes); i++)
    {
      fwTree_cutNode("---Clipboard---",nodes[i], exInfo);
    }
  }
  fwTree_removeNode("FSM","---Clipboard---", exInfo);
}

fwFsm_upgradeForLUs()
{
  dyn_string dps, types, panels, exInfo;
  string type, panel;
  int i;

  DebugN("Converting Tree to version 24");
  dps = fwFsm_getAllObjectDps();
  for(i = 1; i <= dynlen(dps); i++)
  {
    dpSet(dps[i]+".mode.enabled",1);
  }
//	types = fwFsm_getAllObjectTypes();
  types = fwFsm_getAllObjectTypes();
  for(i = 1; i <= dynlen(types); i++)
  {
    type = fwFsm_getDeviceBaseTypeOld(types[i]);
    if(type != "")
    {
      fwUi_setTypePanelBaseType(types[i], type);
    }
  }
  fwTree_getNodeUserData("FSM", panels, exInfo);
  if(dynlen(panels))
    panel = panels[dynlen(panels)];
  else
    panel = fwFsm_getDefaultMainPanel();
  fwTree_setNodeUserData("FSM", makeDynString(panel), exInfo);
}

fwFsm_upgradeBaseTypes()
{
  dyn_string types, items;
  int i;
  string type, panel, type_dp;

  DebugN("Converting Base Type Storage");
  types = fwFsm_getAllObjectTypes();
  for(i = 1; i <= dynlen(types); i++)
  {
    type = fwFsm_getDeviceBaseTypeOld(types[i]);
    if(type != "")
    {
      type_dp = fwFsm_formType(types[i]);
      if(dpExists(type_dp))
      {
        dpGet(type_dp+".panel:_online.._value",panel);
        items = strsplit(panel,"/");
        if(dynlen(items) > 1)
        {
//					if(strpos(types[i], items[1]) == 0)
          if(items[1] == type)
          {
            strreplace(panel,items[1]+"/",items[1]+"|");
            dpSetWait(type+".panel:_original.._value",panel);
          }
        }
        else
          fwUi_setTypePanelBaseType(types[i], type);
      }
    }
  }
/*
	types = fwFsm_getDeviceTypes();
	for(i = 1; i <= dynlen(types); i++)
	{

		type = fwFsm_formType(types[i]);

		if(dpExists(type))
		{
			dpGet(type+".panel:_online.._value",panel);
			items = strsplit(panel,"/");
			if(dynlen(items) > 1)
			{
				if(strpos(types[i], items[1]) == 0)
				{
					strreplace(panel,items[1]+"/",items[1]+"|");
					dpSetWait(type+".panel:_original.._value",panel);
				}
			}
		}
	}
*/
}

fwFsm_upgradeEnable()
{
  dyn_string dps;
  int i;

  DebugN("Converting Enable Flags");
  dps = fwFsm_getAllObjectDps();
  for(i = 1; i <= dynlen(dps); i++)
  {
    dpSet(dps[i]+".mode.enabled",1);
  }
}

fwFsm_upgradeLockedOut()
{
  dyn_string dps;
  int i;
  int enabled;
  string dp;

  DebugN("Converting LockedOut Flags");
  dps = fwFsm_getAllObjectDps();
  for(i = 1; i <= dynlen(dps); i++)
  {
    if(strpos(dps[i],"_FWM") >= 0)
    {
      dpGet(dps[i]+".mode.enabled",enabled);
      if(enabled <= 0)
      {
        DebugTN("Converting LockedOut for "+dps[i]);
        dp = dps[i];
        strreplace(dp,"_FWM","");
        dpSet(dp+".mode.enabled",enabled);
        dpSet(dps[i]+".mode.enabled",1);
      }
    }
  }
}
/*
fwFsm_deupgradeLockedOut()
{
	dyn_string dps;
	int i;
  int enabled;
  string dp;

DebugN("Converting LockedOut Flags");
	dps = fwFsm_getAllObjectDps();
	for(i = 1; i <= dynlen(dps); i++)
	{
    if(strpos(dps[i],"_FWM") < 0)
    {
      if(dpExists(dps[i]+"_FWM"))
      {
DebugTN("Converting",dps[i]);

		    dpGet(dps[i]+".mode.enabled",enabled);
        if(enabled <= 0)
        {
          DebugTN("Converting LockedOut for "+dps[i]);
          dp = dps[i];
          dp = dps[i]+"_FWM";
		      dpSet(dp+".mode.enabled",enabled);
		      dpSet(dps[i]+".mode.enabled",1);
        }
      }
    }
	}
}
*/
fwFsm_upgradeVersion(int version, int newversion)
{
  dyn_string nodes, exInfo;
  int i, cu;
  int base_done = 0;

  if(version < 2200)
  {
    fwFsm_upgradeTree();
  }
  if(version < 2300)
  {
    fwFsm_upgradeReferences();
  }
  if(version < 2400)
  {
    fwFsm_upgradeForLUs();
  }
  if(version < 2406)
  {
    fwFsm_upgradeBaseTypes();
    base_done = 1;
  }
  if(version < 2408)
  {
    if(!base_done)
      fwFsm_upgradeBaseTypes();
    fwFsm_setMainPanel("");
  }
  if(version < 2410)
  {
    fwFsm_upgradeEnable();
  }
  if(version < 3002)
  {
    fwFsm_upgradeLockedOut();
  }
  dpSet("fwFsmVersion.version",newversion);
}

fwFsm_createLocalObject(string type)
{
  addGlobal("ObjStateNames",DYN_STRING_VAR);
  addGlobal("ObjStateColors",DYN_STRING_VAR);
  addGlobal("ObjStateIndex",INT_VAR);
  addGlobal("ObjStateCurrentIndex",INT_VAR);
  ObjStateIndex = 0;
  ObjStateCurrentIndex = 0;
  dynClear(ObjStateNames);
  addGlobal("ObjActionNames",DYN_DYN_STRING_VAR);
//	addGlobal("ObjActionNVisible",DYN_DYN_INT_VAR);
  addGlobal("ObjActionVisible",DYN_DYN_INT_VAR);
  addGlobal("ObjActionTime",DYN_DYN_INT_VAR);
  addGlobal("ObjActionIndex",DYN_INT_VAR);
//  addGlobal("ObjActionState",DYN_STRING_VAR);
  addGlobal("ObjActionText",DYN_DYN_STRING_VAR);
  addGlobal("ObjActionPars",DYN_DYN_STRING_VAR);
  addGlobal("ObjWhens",DYN_DYN_STRING_VAR);
  addGlobal("ObjWhenIndex",DYN_INT_VAR);
//  addGlobal("ObjWhenState",DYN_STRING_VAR);
  addGlobal("ObjActionCurrentIndex",INT_VAR);
  ObjActionCurrentIndex = 0;
//  dynClear(ObjActionState);

  addGlobal("ObjStateComps",DYN_STRING_VAR);
  addGlobal("ObjActionComps",DYN_STRING_VAR);
  addGlobal("ObjStateCompTypes",DYN_STRING_VAR);
  addGlobal("ObjActionCompTypes",DYN_STRING_VAR);
  addGlobal("ObjInitScript",STRING_VAR);
  addGlobal("ObjStateScript",STRING_VAR);
  addGlobal("ObjActionScript",STRING_VAR);

 // The global variables relating to the functions/macro-instructions
  addGlobal("ObjFunctions", DYN_DYN_STRING_VAR);
  addGlobal("ObjFunctionNames", DYN_STRING_VAR);

  ObjFunctions = makeDynString();
  ObjFunctionNames = makeDynString();
//  dynClear("ObjFunctions");

//  DebugTN("Created objects.");

  if(!dpExists(fwFsm_formType(type)))
  {
    return;
  }
  fwFsm_readLocalObject(type);
}

fwFsm_deleteLocalObject()
{
  removeGlobal("ObjStateNames");
  removeGlobal("ObjStateColors");
  removeGlobal("ObjStateIndex");
  removeGlobal("ObjStateCurrentIndex");
  removeGlobal("ObjActionNames");
//	removeGlobal("ObjActionNVisible");
  removeGlobal("ObjActionVisible");
  removeGlobal("ObjActionTime");
  removeGlobal("ObjActionIndex");
//  removeGlobal("ObjActionState");
  removeGlobal("ObjActionText");
  removeGlobal("ObjActionPars");
  removeGlobal("ObjActionCurrentIndex");
  removeGlobal("ObjWhens");
  removeGlobal("ObjWhenIndex");
//  removeGlobal("ObjWhenState");
  removeGlobal("ObjStateComps");
  removeGlobal("ObjActionComps");
  removeGlobal("ObjStateCompTypes");
  removeGlobal("ObjActionCompTypes");
  removeGlobal("ObjInitScript");
  removeGlobal("ObjStateScript");
  removeGlobal("ObjActionScript");

  // The global variables relating to the functions/macro-instructions
  removeGlobal("ObjFunctions");
  removeGlobal("ObjFunctionNames");
}

fwFsm_readLocalObject(string type)
{
  fwFsm_getObjectStatesColors(type,ObjStateNames, ObjStateColors);
  ObjStateIndex = dynlen(ObjStateNames);
  _fwFsm_readActions(type, ObjStateNames);
  _fwFsm_readWhens(type, ObjStateNames);

 // Now we read the object functions
  fwFsm_readObjectFunctions(type);
//  _fwFsm_readFunctions(type, ObjStateNames);

  if(fwFsm_isProxyType(type))
  _fwFsm_readScripts(type);
//DebugTN("Loaded actions are", ObjStateNames, ObjActionNames, ObjActionText, ObjActionPars);
}

_fwFsm_readActions(string type, dyn_string states)
{
  dyn_string action_dps, pars;
  dyn_int visis;
  string action, par_text;
  int i, j, k;

  for(i = 1; i <= dynlen(states); i++)
  {
    ObjActionIndex[i] = 0;
//		  ObjActionState[i] = states[i];
		  ObjActionNames[i] = makeDynString();
		  fwFsm_getObjectStateActionsV(type, states[i], action_dps, visis);
		  for(j = 1; j <= dynlen(action_dps); j++)
		  {
      ObjActionIndex[i]++;
      action = action_dps[j];
      ObjActionNames[i][j] = action;
//			ObjActionNVisible[i][j] = !visis[j];
      ObjActionVisible[i][j] = visis[j];
      fwFsm_readObjectActionText(type, states[i], action, ObjActionText[i][j]);
      fwFsm_readObjectActionParameters(type, states[i], action, pars);
      fwFsm_setLocalActionParsIndexed(i, j, pars);
      fwFsm_readObjectActionTime(type, states[i], action, ObjActionTime[i][j]);
    }
  }
}

_fwFsm_readWhens(string type, dyn_string states)
{
  dyn_string whens;
  int i, j;

  for(i = 1; i <= dynlen(states); i++)
  {
    ObjWhenIndex[i] = 0;
//    ObjWhenState[i] = states[i];
    ObjWhens[i] = makeDynString();
    fwFsm_readObjectWhens(type, states[i], whens);
    for(j = 1; j <= dynlen(whens); j++)
    {
      ObjWhenIndex[i]++;
      ObjWhens[i][j] = whens[j];
    }
  }
}

_fwFsm_readScripts(string type)
{
  dyn_string scripts;
  int i, j;

  fwFsm_readDeviceStateComps(type, ObjStateComps, ObjStateCompTypes);
  fwFsm_readDeviceActionComps(type, ObjActionComps, ObjActionCompTypes);
  fwFsm_readDeviceInitScript(type, ObjInitScript);
  fwFsm_readDeviceStateScript(type, ObjStateScript);
  fwFsm_readDeviceActionScript(type, ObjActionScript);
}

fwFsm_writeLocalObject(string type, dyn_string states)
{
  int fIndex, i, j;
  dyn_string colors, state_list, action_list;
  string panel;
  dyn_int indexes;

  fIndex = dynContains(states,"-");
//  if(fIndex)
//    dynRemove(states, fIndex);
  for(i = 1; i <= dynlen(states); i++)
  {
    for(j = 1; j <= dynlen(ObjStateNames); j++)
    {
      if(states[i] == ObjStateNames[j])
      {
        colors[i] = ObjStateColors[j];
        dynAppend(indexes, j);
      }
    }
  }
  fwFsm_setObjectStatesColors(type, states, colors);
  for(i = 1; i <= dynlen(indexes); i++)
  {
//    for(j = 1; j <= dynlen(ObjActionState); j++)
//    {
//      if(states[i] == ObjActionState[j])
//        _fwFsm_writeActionsWhens(type, states[i], j);
//    }
      _fwFsm_writeActionsWhens(type, ObjStateNames[indexes[i]], indexes[i]);
  }
  if(fwFsm_isProxyType(type))
  {
    for(i = 1; i <= dynlen(ObjStateComps); i++)
    {
      dynAppend(state_list,ObjStateCompTypes[i]+" "+ObjStateComps[i]);
    }
  		for(i = 1; i <= dynlen(ObjActionComps); i++)
  		{
      dynAppend(action_list,ObjActionCompTypes[i]+" "+ObjActionComps[i]);
  		}
  		fwFsm_writeDeviceTopScript(type,state_list, action_list);
  		fwFsm_writeDeviceInitScript(type,ObjInitScript);
  		fwFsm_writeDeviceStateScript(type, ObjStateScript);
  		fwFsm_writeDeviceActionScript(type, ObjActionScript);
  //		_fwFsm_writeDefaultParameters(type);

  }

  // Now write the function/macro-instructions to the datapoint.
  fwFsm_writeObjectFunctions(type);
  fwFsm_writeSmiObjectType(type);

// DebugTN("Finished writing the local object to a datapoint.");
}

string fwFsm_formParam(string type, string name, string value)
{
  string param;

  param = type+" "+name;
  if(type == "string")
  {
    if(strpos(value,"\"") < 0)
      value = "\""+value+"\"";
  }
  else
  {
    if(value == "")
      value = "0";
    if(type == "float")
    {
      if(strpos(value,".") < 0)
        value += ".0";
    }
  }
  param += " = "+value;
  return param;
}
/*
_fwFsm_writeDefaultParameters(string type)
{
dyn_string pars;
string par1, par2;

	par1 = fwFsm_formParam("int","StateTimeout","0");
	par2 = fwFsm_formParam("int","ActionTimeout","0");
	fwFsm_readObjectParameters(type, pars);
	if(!dynContains(pars, par1))
		dynAppend(pars, par1);
	if(!dynContains(pars, par2))
		dynAppend(pars, par2);
	fwFsm_writeObjectParameters(type, pars);
}
*/
_fwFsm_writeActionsWhens(string type, string state, int state_index)
{
  dyn_string all_actions, state_list, action_list, when_list;
  int i, j, found, pos, index;
  dyn_string action_dps, action_text, action_pars, pars;
  dyn_int visi, action_times;
  string action;

//DebugTN("writing", state_index, ObjActionNames, ObjActionText);
  for(i = 1; i <= ObjActionIndex[state_index]; i++)
  {
//		if((strpos(ObjActionNames[state_index][i],"NV_GOTO_")) == -1 )
//		{
//			if(ObjActionNVisible[state_index][i] != -1)
    if(ObjActionVisible[state_index][i] != -1)
    {
      dynAppend(action_list,ObjActionNames[state_index][i]);
      dynAppend(action_text,ObjActionText[state_index][i]);
      dynAppend(action_pars,ObjActionPars[state_index][i]);
//				dynAppend(visi,!ObjActionNVisible[state_index][i]);
      dynAppend(visi,ObjActionVisible[state_index][i]);
      dynAppend(action_times,ObjActionTime[state_index][i]);
    }
//		}
  }
  fwFsm_setObjectStateActionsV(type, state, action_list, visi);
  for(i = 1; i <= dynlen(action_list); i++)
  {
    fwFsm_writeObjectActionText(type, state, action_list[i], action_text[i]);
    fwFsm_writeObjectActionTime(type, state, action_list[i], action_times[i]);
    pars = strsplit(action_pars[i],",");
    fwFsm_writeObjectActionParameters(type, state, action_list[i], pars);
  }
//	if(!fwFsm_isProxyType(type))
//	{
  fwFsm_writeObjectWhens(type, state, ObjWhens[state_index]);
//	}
}


fwFsm_getLocalStates(dyn_string &states)
{
  int index;

  states = ObjStateNames;
  if(index = dynContains(states,"-"))
    dynRemove(states,index);
  if(index = dynContains(states,""))
    dynRemove(states,index);
}

fwFsm_setLocalState(string state)
{
  int index;

  if(index = dynContains(ObjStateNames, state))
    ObjStateCurrentIndex = index;
}

fwFsm_getLocalState(string &state)
{
  state = ObjStateNames[ObjStateCurrentIndex];
}

fwFsm_getLocalColor(string &color)
{
  color = ObjStateColors[ObjStateCurrentIndex];
}

fwFsm_getLocalStateColor(string state, string &color)
{
  int index;

  if(index = dynContains(ObjStateNames, state))
    color = ObjStateColors[index];
}

fwFsm_getLocalActions(dyn_string &actions)
{
  int i;
  string action;

  dynClear(actions);
  for(i = 1; i <= ObjActionIndex[ObjStateCurrentIndex]; i++)
  {
//		if(ObjActionNVisible[ObjStateCurrentIndex][i] != -1)
    if(ObjActionVisible[ObjStateCurrentIndex][i] != -1)
    {
      action = ObjActionNames[ObjStateCurrentIndex][i];
//			if(strpos(action,"NV_GOTO_") < 0 )
      dynAppend(actions,action);
    }
  }
}

fwFsm_getLocalFunctions(dyn_string &actions)
{
  int i, index;
  string action;

  dynClear(actions);
  if(index = dynContains(ObjStateNames,"-"))
  {
    for(i = 1; i <= ObjActionIndex[index]; i++)
    {
//		if(ObjActionNVisible[ObjStateCurrentIndex][i] != -1)
      if(ObjActionVisible[index][i] != -1)
      {
        action = ObjActionNames[index][i];
//			if(strpos(action,"NV_GOTO_") < 0 )
        dynAppend(actions,action);
      }
    }
  }
}

fwFsm_getLocalAllActions(dyn_string &actions)
{
  int i, j, k;

  for(i = 1; i <= dynlen(ObjStateNames); i++)
  {
    if(ObjStateNames[i] == "-")
      continue;
/*
    for(j = 1; j <= dynlen(ObjActionNames); j++)
    {
      if(ObjStateNames[i] == ObjActionState[j])
      {
        for(k = 1; k <= ObjActionIndex[j]; k++)
        {
//					if(ObjActionNVisible[j][k] != -1)
          if(ObjActionVisible[j][k] != -1)
          {
//						if(strpos(ObjActionNames[j][k],"NV_GOTO_") < 0 )
//						{
            if(!dynContains(actions,ObjActionNames[j][k]))
              dynAppend(actions,ObjActionNames[j][k]);
//						}
          }
        }
      }
    }
*/
    for(j = 1; j <= ObjActionIndex[i]; j++)
    {
      if(ObjActionVisible[i][j] != -1)
      {
        if(!dynContains(actions,ObjActionNames[i][j]))
          dynAppend(actions,ObjActionNames[i][j]);
      }
    }
  }
}

fwFsm_setLocalAction(string action)
{
  int index;

  if(index = dynContains(ObjActionNames[ObjStateCurrentIndex], action))
    ObjActionCurrentIndex = index;
}

fwFsm_getLocalAction(string &action)
{
  if(ObjActionCurrentIndex)
    action = ObjActionNames[ObjStateCurrentIndex][ObjActionCurrentIndex];
}
/*
fwFsm_getLocalNV(int &nv)
{
	nv = ObjActionNVisible[ObjStateCurrentIndex][ObjActionCurrentIndex];
}
*/

fwFsm_getLocalVisi(int &visi)
{
  visi = ObjActionVisible[ObjStateCurrentIndex][ObjActionCurrentIndex];
}

fwFsm_getLocalActionText(string &text)
{
  text = ObjActionText[ObjStateCurrentIndex][ObjActionCurrentIndex];
}

fwFsm_setLocalActionText(string text)
{
  ObjActionText[ObjStateCurrentIndex][ObjActionCurrentIndex] = text;
}

fwFsm_getLocalActionPars(dyn_string &pars)
{
  string par_text;
  par_text = ObjActionPars[ObjStateCurrentIndex][ObjActionCurrentIndex];
  pars = strsplit(par_text,",");
}
/*
dyn_string fwFsm_convertLocalActionPars(string par_text)
{
	dyn_string pars;
}
*/
fwFsm_setLocalActionPars(dyn_string pars)
{
  string par_text;
  int i;

  for(i = 1; i <= dynlen(pars); i++)
  {
    par_text += pars[i];
    if(i != dynlen(pars))
      par_text += ",";
  }
  ObjActionPars[ObjStateCurrentIndex][ObjActionCurrentIndex] = par_text;
}

fwFsm_setLocalActionParsIndexed(int stateIndex, int actionIndex, dyn_string pars)
{
  string par_text;
  int i;

  for(i = 1; i <= dynlen(pars); i++)
  {
    par_text += pars[i];
    if(i != dynlen(pars))
      par_text += ",";
  }
  ObjActionPars[stateIndex][actionIndex] = par_text;
}

fwFsm_getLocalActionTime(int &act_time)
{
  act_time = ObjActionTime[ObjStateCurrentIndex][ObjActionCurrentIndex];
}

fwFsm_setLocalActionTime(int act_time)
{
  ObjActionTime[ObjStateCurrentIndex][ObjActionCurrentIndex] = act_time;
}

fwFsm_getLocalWhens(dyn_string &whens)
{
  whens = ObjWhens[ObjStateCurrentIndex];
}

fwFsm_addLocalState(string state, string color)
{
  int index;

  if(index = dynContains(ObjStateNames, state))
  {
    if(color == "")
      color = ObjStateColors[index];
    else
      ObjStateColors[index] = color;
  }
  else
  {
    ObjStateIndex++;
    ObjStateNames[ObjStateIndex] = state;
    ObjStateColors[ObjStateIndex] = color;
    ObjActionIndex[ObjStateIndex] = 0;
//    ObjActionState[ObjStateIndex] = state;
    ObjActionNames[ObjStateIndex] = makeDynString();
    ObjWhenIndex[ObjStateIndex] = 0;
//    ObjWhenState[ObjStateIndex] = state;
    ObjWhens[ObjStateIndex] = makeDynString();
  }
}

fwFsm_removeLocalState(string state)
{
  int index;

  if(index = dynContains(ObjStateNames, state))
  {
    ObjStateNames[index] = "";
  }
}
/*
fwFsm_addLocalAction(string action, int nv, int act_time)
{
	int index;

	if(index = dynContains(ObjActionNames[ObjStateCurrentIndex], action))
	{
		ObjActionNVisible[ObjStateCurrentIndex][index] = nv;
		ObjActionTime[ObjStateCurrentIndex][index] = act_time;
	}
	else
	{
		ObjActionIndex[ObjStateCurrentIndex]++;
		ObjActionNames[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = action;
		ObjActionNVisible[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = nv;
		ObjActionTime[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = act_time;
		ObjActionText[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = "";
		ObjActionPars[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = "";
	}
}
*/

fwFsm_addLocalAction(string action, int visi, int act_time, int sep = 0)
{
  int index;

  if((index = dynContains(ObjActionNames[ObjStateCurrentIndex], action)) && (!sep))
  {
    ObjActionVisible[ObjStateCurrentIndex][index] = visi;
    ObjActionTime[ObjStateCurrentIndex][index] = act_time;
  }
  else
  {
    ObjActionIndex[ObjStateCurrentIndex]++;
    ObjActionNames[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = action;
    ObjActionVisible[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = visi;
    ObjActionTime[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = act_time;
    ObjActionText[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = "";
    ObjActionPars[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = "";
  }
}

fwFsm_removeLocalAction(string action, int sep = 0)
{
  int index, to_remove = 0;

  if((index = dynContains(ObjActionNames[ObjStateCurrentIndex], action)) && (!sep))
  {
//		ObjActionNVisible[ObjStateCurrentIndex][index] = -1;
    ObjActionVisible[ObjStateCurrentIndex][index] = -1;
    to_remove = index;
  }
  else if (sep)
  {
//DebugTN(ObjActionNames[ObjStateCurrentIndex], sep);
    if(ObjActionNames[ObjStateCurrentIndex][sep] == fwFsm_actionSeparator)
    {
		    ObjActionVisible[ObjStateCurrentIndex][sep] = -1;
      to_remove = sep;
    }
  }
  if(to_remove)
  {
    dynRemove(ObjActionNames[ObjStateCurrentIndex],to_remove);
    dynRemove(ObjActionVisible[ObjStateCurrentIndex],to_remove);
    dynRemove(ObjActionTime[ObjStateCurrentIndex],to_remove);
    dynRemove(ObjActionText[ObjStateCurrentIndex],to_remove);
    dynRemove(ObjActionPars[ObjStateCurrentIndex],to_remove);
    ObjActionIndex[ObjStateCurrentIndex]--;
  }
}

fwFsm_replaceLocalWhen(string when, string when1)
{
  int index;

  if(index = dynContains(ObjWhens[ObjStateCurrentIndex],when))
  {
    ObjWhens[ObjStateCurrentIndex][index] = when1;
  }
}

fwFsm_replaceLocalWhenAtPos(int index, string when)
{
  if(dynlen(ObjWhens[ObjStateCurrentIndex]) >= index)
    ObjWhens[ObjStateCurrentIndex][index] = when;
}

fwFsm_exchangeLocalWhen(string when1, string when2)
{
  int index1, index2;

  index1 = dynContains(ObjWhens[ObjStateCurrentIndex],when1);
  index2 = dynContains(ObjWhens[ObjStateCurrentIndex],when2);
  ObjWhens[ObjStateCurrentIndex][index2] = when1;
  ObjWhens[ObjStateCurrentIndex][index1] = when2;
}

fwFsm_exchangeLocalWhenAtPos(int index1, int index2)
{
  string when1, when2;

  when1 = ObjWhens[ObjStateCurrentIndex][index1];
  when2 = ObjWhens[ObjStateCurrentIndex][index2];
  ObjWhens[ObjStateCurrentIndex][index2] = when1;
  ObjWhens[ObjStateCurrentIndex][index1] = when2;
}

fwFsm_addLocalWhen(string when)
{
  int index, pos;
  string action;

  ObjWhenIndex[ObjStateCurrentIndex]++;
  ObjWhens[ObjStateCurrentIndex][ObjWhenIndex[ObjStateCurrentIndex]] = when;
/*
	if((pos = strpos(when,"NV_GOTO_")) >= 0)
	{
		action = substr(when,pos);
		action = strrtrim(action);
		if(!(index = dynContains(ObjActionNames[ObjStateCurrentIndex],action)))
		{
			ObjActionIndex[ObjStateCurrentIndex]++;
			ObjActionNames[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = action;
			ObjActionNVisible[ObjStateCurrentIndex][ObjActionIndex[ObjStateCurrentIndex]] = 1;
		}
		else
			ObjActionNVisible[ObjStateCurrentIndex][index] = 1;
	}
*/
}

fwFsm_removeLocalWhen(string when)
{
  int index;

  if(index = dynContains(ObjWhens[ObjStateCurrentIndex],when))
  {
    dynRemove(ObjWhens[ObjStateCurrentIndex], index);
    ObjWhenIndex[ObjStateCurrentIndex]--;
  }
/*
	if((pos = strpos(when,"NV_GOTO_")) >= 0)
	{
		action = substr(when,pos);
		action = strrtrim(action);
		for(i = 1; i <= dynlen(ObjWhens[ObjStateCurrentIndex]); i++)
		{
			if( strpos(ObjWhens[ObjStateCurrentIndex][i],action) >= 0)
				found = 1;
		}
		if(! found)
		{
			if(index = dynContains(ObjActionNames[ObjStateCurrentIndex],action))
			{
				ObjActionNVisible[ObjStateCurrentIndex][index] = -1;
			}
		}
	}
*/
}

fwFsm_removeLocalWhenAtPos(int index)
{
  if(dynlen(ObjWhens[ObjStateCurrentIndex]) >= index)
    dynRemove(ObjWhens[ObjStateCurrentIndex], index);
}

fwFsm_getLocalWhenAtPos(int index, string &when)
{
  if(dynlen(ObjWhens[ObjStateCurrentIndex]) >= index)
    when = ObjWhens[ObjStateCurrentIndex][index];
}

fwFsm_getLocalStateComps(dyn_string &comps, dyn_string &types)
{
  comps = ObjStateComps;
  types = ObjStateCompTypes;
}

fwFsm_setLocalStateComps(dyn_string comps, dyn_string types)
{
  int i;

  dynClear(ObjStateComps);
  dynClear(ObjStateCompTypes);
  for(i = 1; i <= dynlen(comps); i++)
  {
    if(!dynContains(ObjStateComps,comps[i]))
    {
      dynAppend(ObjStateComps,comps[i]);
      dynAppend(ObjStateCompTypes,types[i]);
    }
  }
}

fwFsm_getLocalStateScript(string &text)
{
  text = ObjStateScript;
}

fwFsm_setLocalStateScript(string text)
{
  ObjStateScript = text;
}

fwFsm_getLocalInitScript(string &text)
{
  text = ObjInitScript;
}

fwFsm_setLocalInitScript(string text)
{
  ObjInitScript = text;
}
fwFsm_getLocalActionComps(dyn_string &comps, dyn_string &types)
{
  comps = ObjActionComps;
  types = ObjActionCompTypes;
}

fwFsm_setLocalActionComps(dyn_string comps, dyn_string types)
{
  int i;

  dynClear(ObjActionComps);
  dynClear(ObjActionCompTypes);
  for(i = 1; i <= dynlen(comps); i++)
  {
    if(!dynContains(ObjActionComps,comps[i]))
    {
      dynAppend(ObjActionComps,comps[i]);
      dynAppend(ObjActionCompTypes,types[i]);
    }
  }
}

fwFsm_getLocalActionScript(string &text)
{
  text = ObjActionScript;
}

fwFsm_setLocalActionScript(string text)
{
  ObjActionScript = text;
}

fwFsm_setAlarm(string device)
{
  string dpe;
  int type;
  string text;

  dpe = device+".status";

  dpGet( dpe + ":_alert_hdl.._type",type);

  if(type != DPCONFIG_NONE)
  {
    dpSetWait( dpe + ":_alert_hdl.._active", 0, dpe + ":_alert_hdl.._ack", 1 );
    dpSetWait( dpe + ":_alert_hdl.._type", DPCONFIG_NONE);
  }
  dpSetWait( dpe + ":_alert_hdl.._type", DPCONFIG_ALERT_NONBINARYSIGNAL,
             dpe + ":_alert_hdl.1._type", 4,
             dpe + ":_alert_hdl.2._type", 4,

//             dpe + ":_alert_hdl.1._hyst_type", 0,
//             dpe + ":_alert_hdl.2._hyst_type", 0,

             dpe + ":_alert_hdl.1._u_limit", 0.0,
             dpe + ":_alert_hdl.2._l_limit", 0.0,

             dpe + ":_alert_hdl.1._text", "Channel(s) Tripped",
             dpe + ":_alert_hdl.2._text", "",
             dpe + ":_alert_hdl.1._class", "VoltageDevice.",
             dpe + ":_alert_hdl.2._class", "",

             dpe + ":_alert_hdl.1._u_incl", 0,
             dpe + ":_alert_hdl.1._l_incl", 1,
             dpe + ":_alert_hdl.2._u_incl", 1,
             dpe + ":_alert_hdl.2._l_incl", 1,

//             dpe + ":_alert_hdl.1._u_hyst_limit", 0.0,
//             dpe + ":_alert_hdl.2._l_hyst_limit", 0.0,

//             dpe + ":_alert_hdl.._min_prio",    1,
//             dpe + ":_alert_hdl.._panel",       "",
//             dpe + ":_alert_hdl.._panel_param", makeDynString(),
//             dpe + ":_alert_hdl.._help",        "",

             dpe + ":_alert_hdl.._orig_hdl", 1);

            dpSetWait( dpe + ":_alert_hdl.._active", 1);
 }
/*
fwFsm_getDeviceAlarmLimits(string device, string item, dyn_float &limits)
{
float upper, old;
bool exists;

	old = 0;
	dpGet(device+"."+item+":_alert_hdl.1._u_incl", exists);
	dpGet(device+"."+item+":_alert_hdl.1._u_limit", upper);
DebugN("getLimits", device+"."+item+":_alert_hdl.1._u_limit", upper, exists);
//	if(old == upper)
//		return;
	if(!exists)
		return;
	old = upper;
	dpGet(device+"."+item+":_alert_hdl.2._u_limit", upper);
	if(old == upper)
		return;
	dynAppend(limits, old);
	old = upper;
	dpGet(device+"."+item+":_alert_hdl.3._u_limit", upper);
	if(old == upper)
		return;
	dynAppend(limits, old);
	old = upper;
	dpGet(device+"."+item+":_alert_hdl.4._u_limit", upper);
	if(old == upper)
		return;
	dynAppend(limits, old);
	old = upper;
	dpGet(device+"."+item+":_alert_hdl.5._u_limit", upper);
	if(old == upper)
		return;
	dynAppend(limits, old);
	old = upper;
}
*/

fwFsm_getDeviceAlarmLimits(string device, string item, dyn_float &limits)
{
  float upper;
  unsigned num;
  int i;

  dynClear(limits);
  dpGet(device+"."+item+":_alert_hdl.._num_ranges", num);
  for(i = 1; i < num; i++)
  {
    dpGet(device+"."+item+":_alert_hdl."+i+"._u_limit", upper);
    dynAppend(limits, upper);
  }
}

fwFsm_setDeviceBaseTypes()
{
  dyn_string base_types, types;
  string base_type;
  int i, set_flag = 0;

  dpGet("ToDo.baseTypes",base_types);
  if(!dynContains(base_types,"FwNode"))
  {
    dynAppend(base_types, "FwNode");
    dynAppend(base_types, "FwAi");
    dynAppend(base_types, "FwAo");
    dynAppend(base_types, "FwDi");
    dynAppend(base_types, "FwDo");
    dynAppend(base_types, "FwAio");
    dynAppend(base_types, "FwDio");
    set_flag = 1;
  }
  if(!dynContains(base_types,"FwAio"))
  {
    dynAppend(base_types, "FwAio");
    dynAppend(base_types, "FwDio");
    set_flag = 1;
  }
  types = fwFsm_getDeviceTypes();
  for(i = 1; i <= dynlen(types); i++)
  {
    fwUi_getTypePanelBaseType(types[i], base_type);
    if(base_type != "")
    {
      if(!dynContains(base_types, base_type))
      {
        dynAppend(base_types, base_type);
        set_flag = 1;
      }
    }
  }
  if(set_flag)
    dpSet("ToDo.baseTypes",base_types);
}


dyn_string fwFsm_getDeviceBaseTypes(string sys = "")
{
  dyn_string types;

/*
	dynAppend(types, "FwNode");
	dynAppend(types, "FwAi");
	dynAppend(types, "FwAo");
	dynAppend(types, "FwDi");
	dynAppend(types, "FwDo");
*/
  if(sys == "")
    dpGet("ToDo.baseTypes",types);
  else
    dpGet(sys+":"+"ToDo.baseTypes",types);
  return types;
}

int fwFsm_isDeviceBaseType(string type, string sys="")
{
  dyn_string types;

  if(sys == "")
    types = fwFsm_getDeviceBaseTypes();
  else
    types = fwFsm_getDeviceBaseTypes(sys);
  return dynContains(types, type);
}

fwFsm_setDeviceBaseType(string type)
{
  dyn_string types;

  dpGet("ToDo.baseTypes",types);
  if(!dynContains(types,type))
  {
    dynAppend(types, type);
    dpSet("ToDo.baseTypes",types);
  }
}

fwFsm_resetDeviceBaseType(string type)
{
  dyn_string types;
  int index;

  dpGet("ToDo.baseTypes",types);
  if(index = dynContains(types,type))
  {
    dynRemove(types, index);
    dpSet("ToDo.baseTypes",types);
  }
}

string fwFsm_getDeviceBaseTypeOld(string type)
{
  dyn_string types;
  int i, found, len;
  string basetype;

  found = 0;
  len = 0;
  types = fwFsm_getDeviceBaseTypes();
  for(i = 1; i <= dynlen(types); i++)
  {
    if(types[i] != type)
    {
      if(strpos(type,types[i]) == 0)
      {
        if(strlen(types[i]) > len)
        {
          basetype = types[i];
          len = strlen(types[i]);
          found = 1;
        }
      }
    }
  }
  if(found)
    return basetype;
  return "";
}

string fwFsm_getDeviceBaseType(string type)
{
  string basetype;

  fwUi_getTypePanelBaseType(type, basetype);
  return basetype;
}

int fwFsm_isDeviceCompositType(string type, string sys="")
{
  string type1, basetype;

  if(sys == "")
    type1 = type;
  else
    type1 = sys+":"+type;
  fwUi_getTypePanelBaseType(type1, basetype);
  if(basetype == "")
    return 0;
  return 1;
}

string fwFsm_getDeviceCompositBaseType(string type, string sys="")
{
  string type1, basetype;

  if(sys == "")
    type1 = type;
  else
    type1 = sys+":"+type;
  fwUi_getTypePanelBaseType(type1, basetype);
  if(basetype == "")
    return type;
  else
    return basetype;
}

dyn_string fwFsm_getCompositDevicesOfBaseType(string basetype)
{
  dyn_string types;
  int i;
  string base;
  dyn_string list;


  types = fwFsm_getDeviceTypes();
  for(i = 1; i <= dynlen(types); i++)
  {
    fwUi_getTypePanelBaseType(types[i], base);
    if(base == basetype)
      dynAppend(list, types[i]);
  }
  return list;
}

fwFsm_generateDeviceTypes()
{
  dyn_string objs, states;
  int i;

  fwFsm_showFwObjects(1);
  objs = fwFsm_getDeviceTypes();
  for(i = 1; i <= dynlen(objs); i++)
  {
    fwFsm_createLocalObject(objs[i]);
    fwFsm_getLocalStates(states);
    if(dynlen(states))
    {
      fwFsm_writeLocalObject(objs[i], states);
    }
    fwFsm_deleteLocalObject();
  }
  fwFsm_showFwObjects(0);
}

fwFsm_generateObjectTypes()
{
  dyn_string objs, states;
  int i;

  fwFsm_showFwObjects(1);
  objs = fwFsm_getObjectTypes();
  for(i = 1; i <= dynlen(objs); i++)
  {
    fwFsm_createLocalObject(objs[i]);
    fwFsm_getLocalStates(states);
    if(dynlen(states))
    {
      fwFsm_writeLocalObject(objs[i], states);
    }
    fwFsm_deleteLocalObject();
  }
  fwFsm_showFwObjects(0);
}

/* Note: it only regenerates an existing trees, does not create new nodes for example.
   Can be used when only an object type changed for example
*/

fwFsm_regenerateObjectTypes(string sys = "")
{
  int i;
  string thesys;
  dyn_string types;

  if(sys == "")
    thesys = "";
  else
    thesys = sys+":";
  DebugN("regenerate", sys, thesys);
//	dps = dpNames(search,type);
//	for(i = 1; i <= dynlen(dps) ; i++)
//	{
//		dps[i] = fwFsm_extractSystem(dps[i]);
//	}
  types = fwFsm_getDps(thesys+"*","_FwFsmObjectType");
  DebugN(thesys,types);
  for(i = 1; i <= dynlen(types); i++)
  {
    types[i] = substr(types[i],5);
    DebugTN("Generating Object Type "+types[i]+" on system "+sys);
    fwFsm_writeSmiObjectType(types[i],sys);
  }
}

fwFsm_regenerateAll(string sys = "")
{
  dyn_string nodes, exInfo;
  int i, cu;
  string thesys;

  if(sys == "")
    thesys = "";
  else
    thesys = sys+":";
  fwTree_getChildren(thesys+"FSM", nodes, exInfo);
  for(i = 1; i <= dynlen(nodes); i++)
  {
    fwTree_getNodeCU(thesys+nodes[i],cu, exInfo);
    if(cu)
    {
      fwFsm_regenerateTreeNode(sys, nodes[i]);
    }
  }
}

fwFsm_regenerateTreeNode(string sys, string node, int recurse = 1, string parent_node = "")
{
  string child_sys, obj, type;
  dyn_string children, exInfo;
  int i, cu;

  DebugTN("Generating node "+node+" on system "+sys);
  fwTree_getNodeCU(sys+":"+node, cu, exInfo);
  if(!cu)
    return;
  fwTree_getChildren(sys+":"+node, children, exInfo);
  for(i = 1; i <= dynlen(children); i++)
  {
    fwTree_getNodeCU(sys+":"+children[i], cu, exInfo);
    if(cu)
    {
      fwTree_getNodeDevice(sys+":"+children[i], obj, type, exInfo);
      child_sys = fwFsm_getSystem(obj);
      if(recurse)
      {
        if((child_sys == sys) && (!fwFsm_isObjectReference(children[i])))
          fwFsm_regenerateTreeNode(sys, children[i]);
      }
    }
  }
  fwTree_getNodeDevice(sys+":"+node, obj, type, exInfo);
  child_sys = fwFsm_getSystem(obj);
  if((child_sys == sys) && (!fwFsm_isObjectReference(node)))
  {
    fwFsm_writeSmiDomain(node, sys);
  }
}


/*
fwFsm_getObjectReferenceType(string node, string &type)
{
string dev;
dyn_string exInfo;

	if(node == "")
		type = "";
	else
	{
		fwTree_getNodeDevice(node, dev, type, exInfo);
	}
}

fwFsm_getObjectReferenceCU(string node, int &cu)
{
dyn_string exInfo;


	fwTree_getNodeCU(node, cu, exInfo);
}
*/

fwFsm_createTmpDeviceType(string type)
{
  dpCreate("_smiDeviceDummy",type);
}

fwFsm_deleteTmpDeviceType()
{
  dpDelete("_smiDeviceDummy");
}

dyn_string fwFsm_getDeviceTypeItems(string type)
{
  dyn_string dps, items;
  int i, typ, pos;
  string item;

  dps = fwFsm_getDps("_smiDeviceDummy.**",type);
  for(i = 1; i <= dynlen(dps); i++)
  {
    typ = dpElementType(dps[i]);
    if(typ != 1)
    {
      pos = strpos(dps[i],".");
      item = substr(dps[i],pos+1);
      dynAppend(items,item);
    }
  }
  return items;
}

string fwFsm_getDeviceTypeItemType(string item)
{
  int typ;
  string type;

  if(dpExists("_smiDeviceDummy."+item))
  {
    typ = dpAttributeType("_smiDeviceDummy."+item+":_online.._value");
  }
  else if(dpExists(item))
  {
    typ = dpAttributeType(item+":_online.._value");
  }
  type = _const2str(typ);
  return type;
}

fwFsm_copyDevObjType(string from_sys, string type)
{
  dyn_string items;
  int i;
  dyn_anytype values;
  string type1;

  type1 = fwFsm_formType(type);
  if(!dpExists(type1))
    dpCreate(type1,"_FwFsmObjectType");
  items = fwFsm_getDps(type1+".*","_FwFsmObjectType");
  for(i = 1; i <= dynlen(items); i++)
  {
//		items[i] = fwFsm_extractSystem(items[i]);
    dpGet(from_sys+":"+items[i],values[i]);
    dpSet(items[i],values[i]);
  }
}

string fwFsm_getDimDnsNode()
{
  string dns_node;
  dpGet("ToDo.dim_dns_node",dns_node);
  if(dns_node == "")
  {
    dns_node = getenv("DIM_DNS_NODE");
  }
  return dns_node;
}

string FwFSM_NextDimDnsNode;

fwFsm_setDimDnsNode(string dns_node)
{
  string status;

  FwFSM_NextDimDnsNode = dns_node;
  fwFsm_stopAllDomains();
  delay(0,200);
  dpGet("ToDo.status", status);
  if(status == "idle")
    dpSet("ToDo.dim_dns_node",dns_node);
  else
    dpConnect("fwFsm_doSetDimDnsNode","ToDo.status");
}

fwFsm_doSetDimDnsNode(string dp, string status)
{
  if(status == "FwStopAllDomains")
  {
    dpDisconnect("fwFsm_doSetDimDnsNode","ToDo.status");
    dpSet("ToDo.dim_dns_node",FwFSM_NextDimDnsNode);
  }
}

fwFsm_setupCUModeBits(string domain)
{
  dyn_string params;
  int ret;

//DebugN("Setting up CU dp_fct for",domain);
  dynAppend(params,"fwCU_"+domain+".mode.exclusivity:_online.._value");
  dynAppend(params,"fwCU_"+domain+".mode.owner:_online.._value");

  dynAppend(params,domain+fwFsm_separator+domain+"_FWM.fsm.currentState:_online.._value");
  dynAppend(params,domain+fwFsm_separator+domain+"_FWCNM.fsm.currentState:_online.._value");

  ret = dpSetWait("fwCU_"+domain+".mode.modeBits:_dp_fct.._type", 60,
                  "fwCU_"+domain+".mode.modeBits:_dp_fct.._param", params,
                  "fwCU_"+domain+".mode.modeBits:_dp_fct.._fct",
                  "fwFsmEvent_computeCUModeBits(p1, p2, p3, p4)");

//DebugN("Connected","fwCU_"+domain+".mode.modeBits:_dp_fct.._type");
//DebugN("dp_fct returned",ret);
}

fwFsm_setupDUModeBits(string domain, string obj, string lu = "")
{
  dyn_string params;
  string func_call;
  int ret;

  dynAppend(params,"fwCU_"+domain+".mode.exclusivity:_online.._value");
  dynAppend(params,"fwCU_"+domain+".mode.owner:_online.._value");
  dynAppend(params,domain+fwFsm_separator+obj+".mode.enabled:_online.._value");
  func_call = "fwFsmEvent_computeDUModeBits(p1, p2, p3";
//DebugN("Setting up DU dp_fct for",domain, obj);
  if(lu != "")
  {
    dynAppend(params,domain+fwFsm_separator+lu+".mode.modeBits:_online.._value");
    func_call += ", p4";
  }
  func_call += ")";

  ret = dpSetWait(domain+fwFsm_separator+obj+".mode.modeBits:_dp_fct.._type", 60,
                  domain+fwFsm_separator+obj+".mode.modeBits:_dp_fct.._param", params,
                  domain+fwFsm_separator+obj+".mode.modeBits:_dp_fct.._fct", func_call);
}

fwFsm_setupLobjModeBits(string domain, string obj, string lu = "")
{
  dyn_string params;
  string func_call;
  int ret;

  dynAppend(params,"fwCU_"+domain+".mode.exclusivity:_online.._value");
  dynAppend(params,"fwCU_"+domain+".mode.owner:_online.._value");
  dynAppend(params,domain+fwFsm_separator+obj+".mode.enabled:_online.._value");
  dynAppend(params,domain+fwFsm_separator+domain+"/"+obj+"_FWDM.fsm.currentState:_online.._value");
  func_call = "fwFsmEvent_computeLobjModeBits(p1, p2, p3, p4";
//DebugN("Setting up LU dp_fct for",domain, obj);
  if(lu != "")
  {
    dynAppend(params,domain+fwFsm_separator+lu+".mode.modeBits:_online.._value");
    func_call += ", p5";
  }
  func_call += ")";

  ret = dpSetWait(domain+fwFsm_separator+obj+".mode.modeBits:_dp_fct.._type", 60,
                  domain+fwFsm_separator+obj+".mode.modeBits:_dp_fct.._param", params,
                  domain+fwFsm_separator+obj+".mode.modeBits:_dp_fct.._fct", func_call);
}

/*
bit32 fwFsm_computeCUModeBits(bool exclusive, string owner,
	string mode, string comp)
{
	bit32 statusBits;
	int enabled, is_free, is_owner, incomplete;

	enabled = fwUi_checkOwnershipMode(owner);
	is_free = (enabled == 1);
	is_owner = (enabled == 2);

	setBit(statusBits,FwFreeBit,is_free);
	setBit(statusBits,FwOwnerBit,is_owner);
	setBit(statusBits,FwExclusiveBit,exclusive);
//	incomplete = 0;
	if(comp == "COMPLETE")
	{
		setBit(statusBits,FwIncompleteBit,0);
		setBit(statusBits,FwIncompleteDevBit,0);
	}
  	else if(comp == "INCOMPLETE")
	{
		setBit(statusBits,FwIncompleteBit,1);
		setBit(statusBits,FwIncompleteDevBit,0);
	}
   	else if (comp == "INCOMPLETEDEV")
	{
		setBit(statusBits,FwIncompleteBit,0);
		setBit(statusBits,FwIncompleteDevBit,1);
	}
	if(mode == "EXCLUDED")
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	else if( (mode == "INCLUDED") || (mode == "INLOCAL") )
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	else if((mode == "MANUAL") || (mode == "INMANUAL"))
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	else if(mode == "IGNORED")
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	return statusBits;
}

bit32 fwFsm_computeDUModeBits(bool exclusive, string owner, bool mode)
{
	bit32 statusBits;
	int enabled, is_free, is_owner, complete;

	enabled = fwUi_checkOwnershipMode(owner);
	is_free = (enabled == 1);
	is_owner = (enabled == 2);

	setBit(statusBits,FwFreeBit,is_free);
	setBit(statusBits,FwOwnerBit,is_owner);
	setBit(statusBits,FwExclusiveBit,exclusive);
	if(mode == 1)
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	else
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	return statusBits;
}
*/

/*
fwFsm_startDomainScripts(string domain)
{
	string dp;

	fwUi_getDomainPrefix(domain, dp);
	dpConnect("fwFsm_domainRunningCb", 0, dp+".running");
}

fwFsm_domainRunningCb(string dp, int running)
{
	string domain;
	dyn_string items;
	int index;
	int n_domains, manId;

	items = strsplit(dp,":.");
	domain = items[2];
	strreplace(domain,"fwCU_","");
	if(!running)
	{
		if((index = dynContains(DomainsOn,domain)))
		{
			dynRemove(DomainsOn, index);
			DomainsDone--;
		}
		return;
	}
	if(!dynContains(DomainsOn,domain))
		dynAppend(DomainsOn, domain);
	n_domains = dynlen(DomainsOn);
	fwFsm_startDomainDevices(domain);
	delay(5);
	if(n_domains != dynlen(DomainsOn))
	{
		return;
	}
	if(DomainsDone == dynlen(DomainsOn))
	{
//DebugN("last installed domain",domain, DomainsDone, NInstalled);
		manId = myManNum();
	 	dpSetWait("ToDo.ctrlPid:_original.._value", manId);
	}
}

fwFsm_startDomainDevices(string domain)
{
	int i, id, pos;
	dyn_string devices, domain_types;
	int ndevs;

	devices = fwFsm_getDomainDevices(domain);
	NDevices += dynlen(devices);
	ndevs = NDevices;
	for(i = 1; i <= dynlen(devices); i++)
	{
		id = startThread("fwFsm_installDevice", domain, devices[i]);
//		dynAppend(Thread_ids,id);
	}

	while(NInstalled < ndevs)
	{
		delay(0,500);
	}
	DomainsDone++;
}

fwFsm_doInstallDevice(string line, string domain, string device)
{
	execScript("main(string line) { "+
			line+"(); fwFsm_waitDUEnd($domain, $device);}",
		makeDynString("$domain:"+domain, "$device:"+device));

}


fwFsm_installDevice(string domain, string device)
{
string domain_name, device_name;
int id;

	domain_name = domain;
	device_name = device;
	strreplace(domain_name,fwDev_separator,"_");
	strreplace(device_name,fwDev_separator,"_");
	strreplace(domain_name,"-","_");
	strreplace(device_name,"-","_");
	fwFsm_doInstallDevice(domain_name+"_"+device_name+"_install", domain, device);
}

fwFsm_waitDUEnd()
{
string domain = $domain;
string device = $device;
string dp;
int running;
string domain_name = domain;
string device_name = device;

	fwUi_getDomainPrefix(domain, dp);
	strreplace(domain_name,fwDev_separator,"_");
	strreplace(device_name,fwDev_separator,"_");
	strreplace(domain_name,"-","_");
	strreplace(device_name,"-","_");
	dpConnect(domain_name+"_"+device_name+"_uninstall", dp+".running");
	NInstalled++;
	fwFsm_waitForDp(dp+".running", 0, 0);
//DebugTN("Exiting thread", domain, device);
	NDevices--;
	NInstalled--;
}
*/

int fwFsm_waitForDp(string dp, anytype value, time t, int no_cond = 0)
{
  string dpe = dp+":_original.._value";
  dyn_anytype conditions, results;
  int status, cond;
  bool end;

  if(!no_cond)
    dynAppend(conditions, value);
  end = false;
  dpWaitForValue( makeDynString(dpe), conditions, makeDynString(dpe), results, t, end);
  return end;
}

/*
fwFsm_startDomainDevicesNew(string domain)
{
	int i, id;
	dyn_string devices;
	string sys, domain_name;

	fwFsm_initialize();
	fwUi_getDomainSys(domain, sys);
	strreplace(sys,":","");
	domain_name = domain;
	strreplace(domain_name,fwDev_separator,"_");
	devices = fwFsm_getDomainDevices(domain);
	for(i = 1; i <= dynlen(devices); i++)
	{
		strreplace(devices[i],fwDev_separator,"_");
		id = startThread(domain_name+"_"+devices[i]+"_install");
	}
	dpSetWait("fwCU_"+domain+".running", myManNum());
}
*/

fwFsm_startDomainDevicesNew(string domain)
{
  int i, id;
  dyn_string devices, refs;
  string sys, domain_name;
  int refAutoEnable = 0;

//	fwFsm_initialize();
//	fwUi_getDomainSys(domain, sys);
//	strreplace(sys,":","");
  domain_name = domain;
  strreplace(domain_name,fwDev_separator,"_");
  strreplace(domain_name,"-","_");
  devices = fwFsm_getDomainDevices(domain);
  if(dpExists("ToDo.refAutoEnable"))
    dpGet("ToDo.refAutoEnable", refAutoEnable);
  if(refAutoEnable)
    refs = fwFsm_getDomainDeviceReferences(domain);
//DebugTN("StartDomainDevices", domain, devices, refs);
// CVV
  for(i = 1; i <= dynlen(devices); i++)
  {
    if(strpos(devices[i],"_FWDM") > 0)
    {
      fwDevModeDU_externalInitialize(domain, devices[i]);
    }
  }

  for(i = 1; i <= dynlen(devices); i++)
  {
    strreplace(devices[i],fwDev_separator,"_");
    strreplace(devices[i],"-","_");
    fwFsm_doStartDevice(domain_name, devices[i], domain);
//		id = startThread(domain_name+"_"+devices[i]+"_install");
  }

  for(i = 1; i <= dynlen(refs); i++)
  {
//		strreplace(refs[i],fwDev_separator,"_");
//		strreplace(refs[i],"-","_");
    fwFsm_doStartDeviceReference(domain_name, refs[i], domain);
//		id = startThread(domain_name+"_"+devices[i]+"_install");
  }

//	dpSetWait("fwCU_"+domain+".running", myManNum());

//	dpSetWait("fwCU_"+domain+".running", 1);
//	DebugN("Starting devices for ",domain);
}

int fwFsm_getCUCtrlFlag(string domain)
{
  int flag;

  dpGet("fwCU_"+domain+".ctrlDUFlag", flag);
  return flag;
}

fwFsm_setCUCtrlFlag(string domain, int flag = 0)
{
  dpSet("fwCU_"+domain+".ctrlDUFlag", flag);
}

fwFsm_doStartDevice(string domain, string device, string cu)
{
  int id;
  int ctrlDUFlag;

//	id = startThread(domain+"_"+device+"_install");

  ctrlDUFlag = fwFsm_getCUCtrlFlag(cu);
  if(ctrlDUFlag == 2)
    fwFsm_startProcess(domain, device);
  else
    id = startThread(domain+"_"+device+"_install");
//		id = startThread("fwFsm_doStartExec", domain, device);
}

fwFsm_doStartDeviceReference(string domain, string obj, string cu)
{
  int id;

  id = startThread("fwFsm_connectReference", cu, obj);
}

string FwFSM_CurrentReferenceDomain;

//mapping FwFSM_CurrentReferences;

fwFsm_connectReference(string domain, string obj)
{
  string subdomain, subobj;

  FwFSM_CurrentReferenceDomain = domain;
  subdomain = fwFsm_getAssociatedDomain(obj);
  subobj = fwFsm_getAssociatedObj(obj);
//DebugTN("**** Connecting Reference", domain, obj);
  fwUi_connectEnabled("fwFsm_referenceCallback",subdomain, subobj);
  fwFsm_localWaitDomainEnd(domain);
  fwUi_disconnectEnabled("fwFsm_referenceCallback",subdomain, subobj);
}

fwFsm_referenceCallback(string dp, int enabled)
{
  dyn_string items;
  string subdomain, subobj, parent;

  items = strsplit(dp,":|.");
  subdomain = items[2];
  subobj = items[3];
  parent = FwFSM_CurrentReferenceDomain;
  if(enabled)
  {
//    fwCU_enableObj(pars[i],subdomain+"::"+subobj);
    fwUi_enableDevice(parent, subdomain+"::"+subobj);
  }
  else
  {
//    fwCU_disableObj(pars[i],subdomain+"::"+subobj);
    fwUi_disableDevice(parent, subdomain+"::"+subobj);
  }
}

fwFsm_doStartExec(string domain, string device)
{
  execScript("#uses \""+domain+".ctl\"\n main() {	"+
  domain+"_"+device+"_install(); fwFsm_localWaitDomainEnd(\""+domain+"\"); "+
		domain+"_"+device+"_uninstall(\"\", 0); }",
		makeDynString());
}

fwFsm_startProcess(string domain, string device)
{
  string domain_name;
  string str, fname;
  file f;

//	domain_name = domain;
//	strreplace(domain_name,fwDev_separator,"_");

  str = "#uses \""+domain+
        ".ctl\"\n main() \n{\n	int id; "+
        "fwFsm_initialize(0); "+domain+
        "_"+device+"_install(); fwFsm_localWaitDomainEnd(\""+
        domain+"\", 1); "+ domain+"_"+device+"_uninstall(\"\", 0); "+
        "id = convManIdToInt(CTRL_MAN, myManNum()); dpSetWait(\"_Managers.Exit:_original.._value\",id); }";

  fname = getPath(SCRIPTS_REL_PATH)+"/fsm/"+domain+"_"+device+"_DevHandler.ctl";
  f = fopen(fname, "w");
  fputs(str, f);
  fclose(f);

  if (os=="Linux")
  {
    system(fwFsm_getPvssPath()+"/bin/WCCOActrl fsm/"+ domain+"_"+device+"_DevHandler.ctl&");
  }
  else
  {
    system("start /B "+fwFsm_getPvssPath()+"/bin/WCCOActrl fsm/"+ domain+"_"+device+"_DevHandler.ctl");
  }
}

int fwFsm_getFreeCtrlNum()
{
  dyn_int busy_nums;
  int i;
  int num, start;

  start = 1;

  num = -1;
  dpGet("_Connections.Ctrl.ManNums",busy_nums);
  for(i = start; i <= 255; i++)
  {
// PVSS feature
    if(i == 110)
      i = 120;
    if(!dynContains(busy_nums,i))
    {
      num = i;
      break;
    }
  }
  return num;
}

int fwFsm_startCUProcess(string domain)
{
  string domain_name;
  string str, fname;
  file f;
  int num;

  domain_name = domain;
  strreplace(domain_name,fwDev_separator,"_");
  strreplace(domain_name,"-","_");
/*
	str = "#uses \""+domain+".ctl\"\n main() \n{\n	int id; "+
		"fwFsm_initialize(0); "+domain+"_"+device+"_install(); fwFsm_localWaitDomainEnd(\""+domain+"\"); "+
		domain+"_"+device+"_uninstall(\"\", 0); "+
		"id = convManIdToInt(CTRL_MAN, myManNum()); dpSetWait(\"_Managers.Exit:_original.._value\",id); }";
*/
  str = "#uses \""+domain_name+
        ".ctl\"\n main() \n{\n int id; DebugTN(\"Starting devices for: "+domain+
        "\"); fwFsm_initialize(0); startDomainDevices_"+domain_name+
        "(); fwFsm_localWaitDomainEnd(\""+domain+
        "\"); DebugTN(\"Stopping devices for: "+domain+
        "\"); "+
        "id = convManIdToInt(CTRL_MAN, myManNum()); dpSetWait(\"_Managers.Exit:_original.._value\",id); }";

  fname = getPath(SCRIPTS_REL_PATH)+"/fsm/"+domain+"_CUHandler.ctl";
  f = fopen(fname, "w");
  fputs(str, f);
  fclose(f);
//  num = fwFsm_getFreeCtrlNum();
  if (os=="Linux")
  {
//		system(fwFsm_getPvssPath()+"/bin/PVSS00ctrl -num "+num+" fsm/"+ domain+"_CUHandler.ctl&");
    system(fwFsm_getPvssPath()+"/bin/WCCOActrl fsm/"+ domain+"_CUHandler.ctl&");
  }
  else
  {
//		system("start /B "+fwFsm_getPvssPath()+"/bin/WCCOActrl -num "+num+" fsm/"+ domain+"_CUHandler.ctl");
    system("start /B "+fwFsm_getPvssPath()+"/bin/WCCOActrl fsm/"+ domain+"_CUHandler.ctl");
  }
  return num;
}

fwFsm_stopDomainDevicesNew(string domain)
{
  int i, id;
  dyn_string devices;
  string sys, domain_name;

//	fwFsm_initialize();
//	fwUi_getDomainSys(domain, sys);
//	strreplace(sys,":","");
//	domain_name = domain;
//	strreplace(domain_name,fwDev_separator,"_");
//	strreplace(domain_name,"-","_");
  devices = fwFsm_getDomainDevices(domain);
  for(i = 1; i <= dynlen(devices); i++)
  {
    dpSet(domain+"|"+devices[i]+".fsm.currentState","DEAD");
  }
}

/*
fwFsm_stopDomainDevicesNewNew(string domain)
{
//	DebugN("Stoping devices for ",domain);
}
*/

fwFsm_waitDomainEnd(string domain)
{
  int index, recalc;

  index = dynContains(FwFsmDomains, domain);

  while(1)
  {
    delay(0, 500);
    recalc = 0;
    if(index > dynlen(FwFsmDomains))
    {
      recalc = 1;
    }
    else
    {
      if(FwFsmDomains[index] != domain)
      recalc = 1;
    }
    if(recalc)
      index = dynContains(FwFsmDomains, domain);
    if(!index)
      break;
    if(FwFsmDomainsOn[index] == 0)
    {
//DebugTN("Found Domain not Running",domain);
      break;
    }
  }
}

int FwFSM_LocalDomainOn;
int FwFSM_LocalDomainDUMode = 1;

fwFsm_localDomainChange(string dp, int value)
{
  FwFSM_LocalDomainOn = value;
}

fwFsm_localDomainChangeDUMode(string dp, int value)
{
  if(value != 2)
    FwFSM_LocalDomainDUMode = 0;
  else
    FwFSM_LocalDomainDUMode = 1;
}

fwFsm_localWaitDomainEnd(string domain, int connectDUMode = 0)
{
  int index;
  string dp;

  fwUi_getDomainPrefix(domain, dp);
  if(dpExists(dp))
  {
    dpConnect("fwFsm_localDomainChange",dp+".running");
    if(connectDUMode)
    {
      if(dpExists(dp+".ctrlDUFlag"))
        dpConnect("fwFsm_localDomainChangeDUMode",dp+".ctrlDUFlag");
    }
  }

  while(1)
  {
    delay(0, 500);
    if((FwFSM_LocalDomainOn <= 0) || (FwFSM_LocalDomainDUMode == 0))
    {
      dpDisconnect("fwFsm_localDomainChange",dp+".running");
      if(connectDUMode)
        dpDisconnect("fwFsm_localDomainChangeDUMode",dp+".ctrlDUFlag");
      break;
    }
  }
}

int FwFSM_SummaryAlarms = -1;

int fwFsm_summaryAlarmsEnabled()
{
//	if(!globalExists("FwFSM_SummaryAlarms"))
  if(isATLAS())
    return 0;
  if(FwFSM_SummaryAlarms == -1)
  {
//		addGlobal("FwFSM_SummaryAlarms",INT_VAR);

    dpGet("ToDo.noSummaryAlarms",FwFSM_SummaryAlarms);
    FwFSM_SummaryAlarms = !FwFSM_SummaryAlarms;
    dpConnect("_fwFsm_summaryAlarms", "ToDo.noSummaryAlarms");
  }
//DebugN("Summary_alarms", FwFSM_SummaryAlarms);
  return FwFSM_SummaryAlarms;
}

_fwFsm_summaryAlarms(string dp, int value)
{
  FwFSM_SummaryAlarms = !value;
//DebugN("SummaryAlarms changed", FwFSM_SummaryAlarms);
}

fwFsm_setupSummaryAlarms(string node, string lunit = "")
{
  dyn_string children, al_dps, al_list;
  string dp, domain, obj, local_dp, rem_local_dp, type;
  dyn_int children_types;
  int i, n;

  if(lunit == "")
    lunit = node;
  fwUi_getObjDp(node, lunit, local_dp);
  local_dp += ".";
  if(!fwFsm_summaryAlarmsEnabled())
  {
    dpGet(local_dp+":_alert_hdl.._type", type);
    if(type == DPCONFIG_NONE)
    {
      return;
    }
  }
  children = fwFsm_getObjChildren(node, lunit, children_types);
//DebugN("SUMMARY", node, lunit, children, children_types);
  for (i = 1; i <= dynlen(children); i++)
  {
    if(fwFsm_isAssociated(children[i]))
    {
      domain = fwFsm_getAssociatedDomain(children[i]);
      obj = fwFsm_getAssociatedObj(children[i]);
    }
    else
    {
      domain = node;
      obj = children[i];
    }
    fwUi_getObjDp(domain, obj, dp);
    dp += ".";
    if(dpExists(dp))
    {
      if(children_types[i] == 1) 	// CU
      {
//				dynAppend(al_list, dp);
// Hack due tu summary alarms not working across distributed systems
        rem_local_dp = fwFsm_setupRemoteSummaryAlarm(node, lunit, domain, obj, local_dp, dp);
        dynAppend(al_list, rem_local_dp);
      }
      else if(children_types[i] == 2) // DU
      {
//				al_dps = fwFsm_getDeviceAlarms(dp);
//				dynAppend(al_list, al_dps);
        n = fwFsm_setDeviceSummaryAlarm(dp);
//				if(n)
        dynAppend(al_list, dp);
//DebugN("DU alarms",aldps);
      }
      else				// Obj
      {
        rem_local_dp = fwFsm_setupRemoteSummaryAlarm(node, lunit, domain, obj, local_dp, dp);
//				dynAppend(al_list, dp);
//				dynAppend(al_list, rem_local_dp);
        if(!fwFsm_isAssociated(children[i]))
        {
          fwFsm_setupSummaryAlarms(node, children[i]);
          dynAppend(al_list, rem_local_dp);
        }
      }
    }
  }
//DebugN("CUS",cus,"DUS",dus,"LUS",lus);
//DebugN("Setting",node, lunit, local_dp, al_list);
//	if(dynlen(al_list))
  fwFsm_setSummaryAlarm(local_dp, al_list, 0);
//	else
//		fwFsm_removeSummaryAlarm(local_dp);
//DebugN("Setup Summary Alarm", node, lunit, local_dp, al_list);
}

string fwFsm_setupRemoteSummaryAlarm(string node, string lunit, string domain, string obj, string local_dp, string dp)
{
  string sys, local_sys, rem_local_dp, extra_dp;

  rem_local_dp = dp;
  sys = fwFsm_getSystem(dp);
  local_sys = fwFsm_getSystem(local_dp);
  if(sys != local_sys)
  {
    fwUi_getObjDp(node, domain+"::"+obj, rem_local_dp);
    rem_local_dp += ".";
    extra_dp = rem_local_dp+"hasAlarms";
    fwFsm_setLocalRemoteAlarm(extra_dp);
    fwFsm_setSummaryAlarm(rem_local_dp, makeDynString(extra_dp));
  }
  return rem_local_dp;
}

string fwFsm_getRemoteSummaryAlarmDp(string node, string lunit, string domain, string obj, string local_dp, string dp)
{
  string sys, local_sys, rem_local_dp, extra_dp;

  rem_local_dp = dp;
  sys = fwFsm_getSystem(dp);
  local_sys = fwFsm_getSystem(local_dp);
  if(sys != local_sys)
  {
    fwUi_getObjDp(node, domain+"::"+obj, rem_local_dp);
    rem_local_dp += ".";
  }
  return rem_local_dp;
}

fwFsm_actOnSummaryAlarm(int action, string obj, string node, string lunit = "")
{
  string domain, local_dp, dp, rem_local_dp;

  if(!fwFsm_summaryAlarmsEnabled())
    return;
  strreplace(obj,"|","::");
//DebugN("ActOnSummary", action, node, lunit, obj);
  if(lunit == "")
    lunit = node;
  fwUi_getObjDp(node, lunit, local_dp);
  local_dp += ".";

  domain = node;
  if(fwFsm_isAssociated(obj))
  {
    domain = fwFsm_getAssociatedDomain(obj);
    obj = fwFsm_getAssociatedObj(obj);
  }
  fwUi_getObjDp(domain, obj, dp);
  dp += ".";
  rem_local_dp = fwFsm_getRemoteSummaryAlarmDp(node, lunit, domain, obj, local_dp, dp);
//DebugTN("ActOnSummary1",local_dp, dp, rem_local_dp);
  if(local_dp == dp)
    return;
  if(action == 1)
    fwFsm_addAlarmToSummary(local_dp, rem_local_dp);
  else
    fwFsm_removeAlarmFromSummary(local_dp, rem_local_dp);
//DebugTN("out");
}

fwFsm_addAlarmToSummary(string dpe, string al_dp)
{
  dyn_string dp_list;
  int type;
  bool val;

  if(!dpExists(al_dp))
    return;

  dpGet(dpe+":_alert_hdl.._type", type);

  if(type != DPCONFIG_NONE)
  {
    val = false;
    dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
    dpGet(dpe+":_alert_hdl.._dp_list",dp_list);
  }
//DebugTN(type, dp_list);
  if(!dynContains(dp_list, al_dp))
  {
    dynAppend(dp_list, al_dp);
    if(type != DPCONFIG_NONE)
    {
//DebugTN("dpSetWait", dpe+":_alert_hdl.._dp_list",dp_list);
      dpSetTimedWait(0,dpe+":_alert_hdl.._dp_list",dp_list);
    }
    else
    {
//DebugTN("setSummaryAlert",dpe, dp_list);
      fwFsm_setSummaryAlarm(dpe, dp_list);
    }
  }
//DebugN("Adding", dpe, dp_list);
//	if(fwFsm_summaryAlarmsEnabled())
//	{
  val = 1;
  dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
//	}
}

fwFsm_removeAlarmFromSummary(string dpe, string al_dp)
{
  dyn_string dp_list;
  int index;
  int type;
  bool val;

  dpGet(dpe+":_alert_hdl.._type", type);

  if(type != DPCONFIG_NONE)
  {
    val = false;
    dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
    dpGet(dpe+":_alert_hdl.._dp_list",dp_list);
  }

  if(index = dynContains(dp_list, al_dp))
  {
    dynRemove(dp_list, index);
    dpSetTimedWait(0,dpe+":_alert_hdl.._dp_list",dp_list);
  }
//DebugN("Removing", dpe, dp_list);
//	if(fwFsm_summaryAlarmsEnabled())
//	{
  if(dynlen(dp_list))
  {
    val = 1;
    dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
  }
//	}
//	else
//		fwFsm_removeSummaryAlarm(dpe);

}

fwFsm_setSummaryAlarm(string dpe, dyn_string dp_list, int activate = 1)
{
  int type;
  string text;
  bool val;

//DebugTN("Setting summ alarm", dpe, dp_list);

  val = false;
  dpSetTimedWait(0, dpe+":_alert_hdl.._active",val);

  if(!fwFsm_summaryAlarmsEnabled())
  {
    fwFsm_removeSummaryAlarm(dpe);
    return;
  }
  dpGet(dpe+":_alert_hdl.._type", type, dpe+":_alert_hdl.._text1", text);

  if((type == DPCONFIG_SUM_ALERT) && (text == "FSM Summary"))
  {
    dpSetTimed(0, dpe+":_alert_hdl.._dp_list",dp_list);
    dpSetTimedWait(0, dpe+":_alert_hdl.._filter_threshold",0);
  }
  else
  {
    dpSetTimedWait(0,dpe+":_alert_hdl.._type", DPCONFIG_SUM_ALERT);

// For some reason this is MUCH faster
    dpSetTimed(0,dpe+":_alert_hdl.._text1","FSM Summary");
    dpSetTimed(0,dpe+":_alert_hdl.._text0","");
    dpSetTimed(0,dpe+":_alert_hdl.._class","");
    dpSetTimed(0,dpe+":_alert_hdl.._dp_list",dp_list);
    dpSetTimed(0,dpe+":_alert_hdl.._filter_threshold",0);
    dpSetTimedWait(0, dpe+":_alert_hdl.._dp_pattern","");
  }
/* Than this...
	dpSetWait(dpe+":_alert_hdl.._text1","FSM Summary",
              dpe+":_alert_hdl.._text0","",
              dpe+":_alert_hdl.._class","",
//              dpe+":_alert_hdl.._ack_has_prio",q-1,
//              dpe+":_alert_hdl.._order",r-1,
              dpe+":_alert_hdl.._dp_list",dp_list,
              dpe+":_alert_hdl.._dp_pattern",""
//              dpe+":_alert_hdl.._prio_pattern",pr,
//              dpe+":_alert_hdl.._abbr_pattern",ku,
//              dpe+":_alert_hdl.._ack_deletes",ql,
//              dpe+":_alert_hdl.._non_ack",nq,
//              dpe+":_alert_hdl.._came_ack",kq,
//              dpe+":_alert_hdl.._pair_ack",pq,
//              dpe+":_alert_hdl.._both_ack",bq,
//              dpe+":_alert_hdl.._panel",panel,
//              dpe+":_alert_hdl.._panel_param",param,
//              dpe+":_alert_hdl.._help",ls_lt
	);
*/
  if((fwFsm_summaryAlarmsEnabled()) && activate)
  {
//DebugN("Setting sum alarm", dpe, dp_list);
    if(dynlen(dp_list))
    {
      val = 1;
      dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
    }
  }
//DebugTN("done");
}

fwFsm_setLocalRemoteAlarm(string dpe)
{
  int type;
  string text;
  bool val;

  val = false;
  dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);

  if(!fwFsm_summaryAlarmsEnabled())
  {
    fwFsm_removeSummaryAlarm(dpe);
    return;
  }
  dpGet(dpe+":_alert_hdl.._type", type, dpe+":_alert_hdl.._text1", text);

  if((type != DPCONFIG_ALERT_BINARYSIGNAL) || (text != "FSM Remote Alarm"))
  {
    dpSetTimedWait(0, dpe + ":_alert_hdl.._type", DPCONFIG_ALERT_BINARYSIGNAL);
    dpSetTimedWait(0, dpe+":_alert_hdl.._ok_range", 0,
                   dpe+":_alert_hdl.._text1","FSM Remote Alarm",
                   dpe+":_alert_hdl.._text0","",
                   dpe+":_alert_hdl.._class","_fwWarningNack.",
                   dpe+":_alert_hdl.._orig_hdl", 1);
  }
//DebugN("Setting Local Remote", dpe);

//	if(fwFsm_summaryAlarmsEnabled())
//	{
  val = 1;
		dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
//	}
}

fwFsm_setLocalRemoteAlarmClass(string dpe, int prio)
{
  int type;
  string text, aClass, old_class;
  bool val;

  if(!fwFsm_summaryAlarmsEnabled())
    return;
  val = false;
  dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);

  dpGet(dpe+":_alert_hdl.._type", type, dpe+":_alert_hdl.._text1", text, dpe+":_alert_hdl.._class", old_class);

  if(prio >= 80)
    aClass = "_fwFatalNack.";
  else if(prio >= 60)
    aClass = "_fwErrorNack.";
  else if(prio >= 40)
    aClass = "_fwWarningNack.";
  if((type == DPCONFIG_ALERT_BINARYSIGNAL) && (text == "FSM Remote Alarm") && (getSystemName()+aClass != old_class))
  {
    dpSetTimedWait(0,dpe+":_alert_hdl.._class", aClass);
  }
//DebugN("Setting Local Remote Class", dpe, getSystemName()+aClass, old_class);

//	if(fwFsm_summaryAlarmsEnabled())
//	{
  val = 1;
  dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);
//	}
}

/*
fwFsm_setLocalRemoteAlarm(string dpe)
{
int type;
string text;

	dpSetWait(dpe+":_alert_hdl.._active",0);

	dpGet(dpe+":_alert_hdl.._type", type, dpe+":_alert_hdl.._text1", text);

	if((type != DPCONFIG_ALERT_NONBINARYSIGNAL) || (text != "FSM Remote Alarm"))
	{
		dpSetWait( dpe + ":_alert_hdl.._type", DPCONFIG_ALERT_NONBINARYSIGNAL);

		dpSetWait(
//			dpe+":_alert_hdl.._min_prio", 0,
			dpe+":_alert_hdl.1._type", 4,
			dpe+":_alert_hdl.2._type", 4,
			dpe+":_alert_hdl.3._type", 4,
			dpe+":_alert_hdl.4._type", 4,
			dpe+":_alert_hdl.1._u_limit", 1,
			dpe+":_alert_hdl.2._l_limit", 1,
			dpe+":_alert_hdl.2._u_limit", 2,
			dpe+":_alert_hdl.3._l_limit", 2,
			dpe+":_alert_hdl.3._u_limit", 3,
			dpe+":_alert_hdl.4._l_limit", 3,
			dpe+":_alert_hdl.4._u_limit", 4,
			dpe+":_alert_hdl.1._text", "",
			dpe+":_alert_hdl.2._text", "FSM Remote Alarm",
			dpe+":_alert_hdl.3._text", "FSM Remote Alarm",
			dpe+":_alert_hdl.4._text", "FSM Remote Alarm",
			dpe+":_alert_hdl.1._class","",
			dpe+":_alert_hdl.2._class","_fwWarningNack.",
			dpe+":_alert_hdl.3._class","_fwErrorNack.",
			dpe+":_alert_hdl.4._class","_fwFatalNack.",
			dpe+":_alert_hdl.._orig_hdl", 1
		);
	}
//DebugN("Setting Local Remote", dpe);

	if(fwFsm_summaryAlarmsEnabled())
		dpSetWait(dpe+":_alert_hdl.._active",1);
}
*/
fwFsm_removeSummaryAlarm(string dpe)
{
  bool val;

  val = false;
//DebugTN("removeSummaryAlarm",dpe, getStackTrace());
  dpSetTimedWait(0,dpe+":_alert_hdl.._active",val);

  dpSetTimedWait(0,dpe+":_alert_hdl.._type", DPCONFIG_NONE);
}

int fwFsm_setDeviceSummaryAlarm(string dp)
{
  int i, type, n;
  dyn_string alarms, dps, types;
  string aldp, text;

  n = 0;
  dpGet(dp+":_alert_hdl.._type", type, dp+":_alert_hdl.._text1", text);
  if(!fwFsm_summaryAlarmsEnabled())
  {
    if((type != DPCONFIG_NONE) && (text == "FSM Summary"))
      fwFsm_removeSummaryAlarm(dp);
    return 0;
  }
  if((type == DPCONFIG_NONE) || (text == "FSM Summary"))
  {
    alarms = dpNames(dp+"**:_alert_hdl.._type");
    dpGet(alarms, types);
    for(i = 1; i <= dynlen(alarms); i++)
    {
//			dpGet(alarms[i], type);
      if(types[i] != DPCONFIG_NONE)
      {
        aldp = dpSubStr (alarms[i], DPSUB_SYS_DP_EL);
        if(aldp != dp)
        {
          dynAppend(dps, aldp);
          n++;
        }
      }
    }
//		if(n)
    fwFsm_setSummaryAlarm(dp, dps);
//		else
//			fwFsm_removeSummaryAlarm(dp);
  }
  else
  {
    n = 1;
  }
  return n;
}

int fwFsm_getLocked(string dpe)
{
  int locked, manNum, manType, manId;

  dpGet(dpe+":_lock._original._locked", locked,
			dpe+":_lock._original._man_nr", manNum,
			dpe+":_lock._original._man_type", manType);

  if(locked)
  {
    manId = convManIdToInt(manType, manNum);
    return manId;
  }
  return 0;
}

fwFsm_lock(string dpe)
{
  int manLocked, manId;

  while(1)
  {
    manLocked = fwFsm_getLocked(dpe);
    if(!manLocked)
    {
      dpSetWait(dpe+":_lock._original._locked", 1);
      manLocked = fwFsm_getLocked(dpe);
      manId = convManIdToInt(myManType(), myManNum());
      if(manId == manLocked)
        break;
    }
    delay(0, 100);
  }
}

fwFsm_unlock(string dpe)
{
  dpSetWait(dpe+":_lock._original._locked", 0);
}

int fwFsm_openColorSel(string &color)
{
  dyn_string colors;
  dyn_float res;
  string panel;
  string path;

  panel = "/fwFSMuser/myColorSel";
  path = getPath(PANELS_REL_PATH,panel);
  if(path == "")
  {
    panel = "/fwFSMuser/myColorSel.pnl";
    path = getPath(PANELS_REL_PATH,panel);
  }
  if(path == "")
    panel = "fwFSM/fsm/myColorSel.pnl";

  ChildPanelOnReturn(panel,"ColorSelection",makeDynString(""),0,0,res, colors);
  color = colors[1];
  return res[1];
}

// Added to read functions/macro-instructions

/**
  Read the datapoint associated with the functions/macro-instructions of each object into a local data structure.

  @param type is the name of the FSM object type, as defined in FSMConfig.pnl
*/
/*
_fwFsm_readFunctions(string type, dyn_string states)
{
  dyn_string action_dps, pars;
  dyn_int visis;
  string action, par_text;
  int i, j, k;
  dyn_string fNames, fParams, fText;
  int nFunctions = dynlen(ObjFunctions);

  for (i = 1; i <= nFunctions; i++)
  {
    dynAppend(fNames, ObjFunctions[i][1]);
    dynAppend(fParams, ObjFunctions[i][2]);
    dynAppend(fText, ObjFunctions[i][3]);
  }

  i = dynContains(states,"-");
  ObjActionIndex[i] = 0;
  ObjActionState[i] = states[i];
	ObjActionNames[i] = makeDynString();
	for(j = 1; j <= dynlen(fNames); j++)
	{
    ObjActionIndex[i]++;
    action = fNames[j];
    ObjActionNames[i][j] = action;
//			ObjActionNVisible[i][j] = !visis[j];
    ObjActionVisible[i][j] = 0;
    ObjActionText[i][j] = fText[j];
    ObjActionPars[i][j] = fParams[j];
    ObjActionTime[i][j] = 0;
  }
}
*/
fwFsm_readObjectFunctions(string type)
{
  int i, j;
  dyn_string actions, pars, names, params, fText;
  string action;

   // Delete everything in the data structure before we start
//    dynClear(ObjFunctions);
//    dynClear(ObjFunctionNames);
/*
  ObjFunctions = makeDynString();
  ObjFunctionNames = makeDynString();

  fwFsm_getItemsAtPos(type+".functions", names, 1);
	 fwFsm_getItemsAtPos(type+".functions", params, 2);
  fwFsm_getItemsAtPos(type+".functions", fText, 3);

  for (i=1; i<=dynlen(names); i++)
  {
     ObjFunctions[i]=makeDynString();
     dynAppend(ObjFunctions[i], names[i]);
     dynAppend(ObjFunctionNames, names[i]);
     dynAppend(ObjFunctions[i], params[i]);
     dynAppend(ObjFunctions[i], fText[i]);
     // Currently unused, writing a blank
//      dynAppend(functions[i], "");
//      dynAppend(functions[i], "");
  }
*/
  fwFsm_readObjectActions(type, actions, 1);
  i = dynContains(ObjStateNames,"-");
  ObjActionIndex[i] = 0;
//  ObjActionState[i] = ObjStateNames[i];
	ObjActionNames[i] = makeDynString();
  for(j = 1; j <= dynlen(actions); j++)
  {
    ObjActionIndex[i]++;
    action = actions[j];
    ObjActionNames[i][j] = action;
    ObjActionVisible[i][j] = 0;
    ObjActionTime[i][j] = 0;
    fwFsm_readObjectActionText(type, "", action, ObjActionText[i][j], 1);
    fwFsm_readObjectActionParameters(type, "", action, pars, 1);
    fwFsm_setLocalActionParsIndexed(i, j, pars);
  }
}

/**
  Write the local data structure associated with functions/macro-instructions of each object into the corresponding datapoint.

  @param type is the name of the FSM object type, as defined in FSMConfig.pnl
*/

fwFsm_writeObjectFunctions(string type)
{
  int i, j, state_index;
  dyn_string pars, s, fNames, fParams, fText;
  string action;

  i = dynContains(ObjStateNames,"-");
  fwFsm_writeObjectActions(type, ObjActionNames[i], i);
  for(j = 1; j <= ObjActionIndex[i]; j++)
  {
    action = ObjActionNames[i][j];
    fwFsm_writeObjectActionText(type, "", action, ObjActionText[i][j], 1);
    pars = strsplit(ObjActionPars[i][j],",");
    fwFsm_writeObjectActionParameters(type, "", action, pars, 1);
  }
/*
  for (i = 1; j <= ObjActionIndex[i]; j++)
  {
    dynAppend(s,"");
    dynAppend(fNames, ObjActionNames[state_index][i]);
    dynAppend(fParams, ObjActionPars[state_index][i]);
    dynAppend(fText, ObjActionText[state_index][i]);
  }

   // This line effectively clears the datapoint
  dpSet(fwFsm_formType(type)+".functions:_original.._value", s);

   // Insert the headers, parameters and code for the functions/macro-instructions
  fwFsm_insertItemsAtPos(type+".functions", fNames, 1);
  fwFsm_insertItemsAtPos(type+".functions", fParams, 2);
  fwFsm_insertItemsAtPos(type+".functions", fText, 3);
*/
// DebugTN("Wrote the ObjFunctions data structure to the corresponding datapoint.");
}


/**
  Retrieve the value of a function/macro-instruction.

  @param header is the header/name of the function - should be a single word
  @param params are the arguments to that function, in a single string separated by commas
  @param functionText is the actual code of the function, in a single string
  @return the function returns 0 if function; -1 otherwise
*/
int fwFsm_getObjectFunctions(string header, string &params, string &functionText)
{
  int i, j;
  string fHeader, fParams, fText;
  for (i=1; i<=dynlen(ObjFunctions); i++)
  {

    if (ObjFunctions[i][1] == header)
    {
      params = ObjFunctions[i][2];
      functionText = ObjFunctions[i][3];
// DebugTN("Found this function.", functionText, params);
      return 0;
    }
  }
  return -1;
}

/**
  Set the parameters and code of an existing function/macro-instruction.

  @param header is the header/name of the function - should be a single word
  @param params are the arguments to that function, in a single string separated by commas
  @param functionText is the actual code of the function, in a single string
  @return the function returns 0 if function and properties set; -1 otherwise
*/
int fwFsm_setObjectFunctions(string header, string params, string fText)
{
  int i;

  for (i=1; i<=dynlen(ObjFunctions); i++)
  {
    if (ObjFunctions[i][1] == header)
    {
      ObjFunctions[i][2] = params;
      ObjFunctions[i][3] = fText;
      return 0;
    }
  }
  return -1;
}


/**
  Append a new function/macro-instruction.

  @param header is the header/name of the function - should be a single word
  @param params are the arguments to that function, in a single string separated by commas
  @param functionText is the actual code of the function, in a single string
*/
fwFsm_addObjectFunction(string header, string params, string fText)
{
  int i;
  dyn_string s;

  dynAppend(ObjFunctions, makeDynString(header, params, fText));
  dynAppend(ObjFunctionNames, header);
}

/**
  Delete a function/macro-instruction.

  @param header is the header/name of the function to be removed - should be a single word
  @return the function returns 0 if function found and subsequently removed; -1 otherwise
*/
int fwFsm_removeObjectFunction(string header)
{
  int i;

  for (i=1; i<=dynlen(ObjFunctions); i++)
  {
    if (ObjFunctions[i][1] == header)
    {
      dynRemove(ObjFunctions, i);
      dynRemove(ObjFunctionNames, i);
      return 0;
    }
  }
  return -1;
}

/**
  Directly access the datapoint looking for a particular function.

  @param type is the name of the FSM object type, as defined in FSMConfig.pnl
  @param header is the header/name of the function - should be a single word
  @param params are the arguments to that function, in a single string separated by commas
  @param functionText is the actual code of the function, in a single string
  @return the function returns 0 if function found; -1 otherwise
*/
int fwFsm_extFindFunctionByHeader(string type, string header, string &params, string &text)
{
  int i, j;
  dyn_string names, par, txt;

  fwFsm_getItemsAtPos(type+".functions", names, 1);
  fwFsm_getItemsAtPos(type+".functions", par, 2);
  fwFsm_getItemsAtPos(type+".functions", txt, 3);

  for (i=1; i<=dynlen(names); i++)
  {
    if (names[i] == header)
    {
       params=par[i];
       text=txt[i];
       return 0;
    }
  }
  return -1;
}

/**
  Split the "params" string into type and variable names. "parsed" will contain only the names separated by commas.

  @param params are the arguments (type + argument name) to a function, in a single string separated by commas
  @param types is the array which will contain the types of the arguments
  @param varsis the array which will contain the names of the arguments
  @parsed is the string with only argument names separated by commas.
*/

parseSplitParams(string params, dyn_string &types, dyn_string &vars, string &parsed)
{
   dyn_string s1, s2;

   types = makeDynString();
   vars = makeDynString();

   parsed = "";

   s1 = strsplit(params, ",");
   if(dynlen(s1)>=1)
   {
//       DebugTN("There are params");
      for (int i=1; i<=dynlen(s1); i++)
      {
         s2 = strsplit(s1[i], " ");
         dynAppend(types, s2[1]);
         dynAppend(vars, s2[2]);
         parsed += s2[2];

         // If not the last one, add a comma
         if(i!=dynlen(s1))
         {
            parsed += ", ";
         }
      }
   }
//    DebugTN(types, vars);
}
