#uses "fwGeneral/fwGeneral.ctl"
#uses "fwTree/fwTreeUtil.ctl"
#uses "fwTree/fwTree.ctl"
// No need to include the whole FwFsm.ctl here

/** Cuts-out the system name from passed dp name

  Note: this function has a special behaviour when
  it detects a string with double colon characters,
  such as "W1::W1"; in such case it does not consider
  this to be a system name plus another string, but
  rather returns the complete string unchanged.
  As such it differs in functionality from the @ref fwNoSysName
  provided by the fwCore

 */
string fwFsm_extractSystem(string dp)
{

int pos;
string res, aux;

    if((pos = strpos(dp,":")) >= 0)
    {
        res = substr(dp,pos+1);
        aux = substr(dp,pos+1);
        if(strpos(aux,":") == 0)
            res = dp;
    }
    else
        res = dp;

    return res;
}

/** returns the system name for the passed sp name

  Note: this function has a special behaviour when
  it detects a string with double colon characters,
  such as "W1::W1"; in such case it does not consider
  this to be a system name plus another string,
  and hence it returns an empty string. 
  As such it differs in functionality from the @ref fwSysName
  provided by the fwCore

  @sa see also fwFSM_extractSystem

*/
string fwFsm_getSystem(string dp)
{
int pos;
string res, aux;

    if((pos = strpos(dp,":")) >= 0)
    {
        res = substr(dp,0,pos);
        aux = substr(dp,pos+1);
        if(strpos(aux,":") == 0)
            res = "";
    }
    else
        res = "";

    return res;
}

string fwFsm_getSystemName()
{
int pos;
string res;

    res = getSystemName();
    if((pos = strpos(res,":")) >= 0)
    {
        res = substr(res,0,pos);
    }
    return res;
}

string fwFsm_getLogicalDeviceName(string pdev)
{
string ldev, pdev1;

	if(strpos(pdev,".") >= 0)
		pdev1 = pdev;
	else
		pdev1 = pdev+".";
	ldev = dpGetAlias(pdev1);
//DebugN("getLogical",pdev, pdev1, ldev);
	pdev = fwNoSysName(pdev);
	if(ldev == "")
		ldev = pdev;
	return ldev; 
}

string fwFsm_getPhysicalDeviceName(string ldev)
{
string pdev, pdev1;
int pos;

	pdev = dpAliasToName(ldev);
	ldev = fwNoSysName(ldev);
	if(pdev == "")
		pdev = ldev;
	else
		pdev = fwNoSysName(pdev);
//	pdev1 = dpSubStr(pdev, DPSUB_DP_EL);
	pdev1 = strrtrim(pdev,".");
//DebugN("getPhysicalDevName",ldev, pdev, pdev1);
	if(pdev1 != "")
		pdev = pdev1;
	return pdev;
}

int fwFsm_isLogicalDeviceName(string ldev)
{
string pdev, pdev1;


	pdev = dpAliasToName(ldev);
	ldev = fwNoSysName(ldev);
	if(pdev != "")
	{
		pdev1 = dpSubStr(pdev, DPSUB_DP);
		if((pdev1 != "") && (pdev1 != ldev))
			return 1;
	}
	return 0;
}

string fwFsm_getProjPath()
{
	return (makeNativePath(strrtrim(PROJ_PATH,"/\\")));
}

string fwFsm_getPvssPath()
{
	return (makeNativePath(strrtrim(PVSS_PATH,"/\\")));
}

string fwFsm_getProjVersion()
{
	return VERSION_DISP;
}

string fwFsm_getApiPath()
{
string path, bin_path, ext;
int pos;

	if (_UNIX)
		ext = "";
	else
		ext = ".exe";
	bin_path = getPath(BIN_REL_PATH, "WCCOAsmi"+ext);
// Fix for getPath bug, returns "//cern.ch/dfs..." instead of "\\cern.ch\dfs..."
	if(strpos(bin_path,"//") == 0)
		strreplace(bin_path,"//","\\\\");
	pos = strpos(bin_path,"/bin/WCCOAsmi"+ext);
	path = substr(bin_path, 0, pos);
	return path;
}

string fwFsm_getFsmPath()
{
string path, bin_path, ext;
int pos;

	if (_UNIX)
		ext = "";
	else
		ext = ".exe";
	bin_path = getPath(BIN_REL_PATH, "fwFSM/smiTrans"+ext);
// Fix for getPath bug, returns "//cern.ch/dfs..." instead of "\\cern.ch\dfs..."
	if(strpos(bin_path,"//") == 0)
		strreplace(bin_path,"//","\\\\");
	pos = strpos(bin_path,"smiTrans"+ext);
	path = substr(bin_path, 0, pos);
	return path;
}


dyn_string fwFsm_getDps(string search, string type)
{
int i;
dyn_string dps;

	dps = dpNames(search,type);
	for(i = 1; i <= dynlen(dps) ; i++)
	{
		dps[i] = fwNoSysName(dps[i]);
	}
	return(dps);
}

dyn_string fwFsm_getDpsSys(string search, string type, dyn_string &systems)
{
int i;
dyn_string dps;

	dynClear(systems);
	dps = dpNames(search,type);
	for(i = 1; i <= dynlen(dps) ; i++)
	{
		systems[i] = fwSysName(dps[i]); 
		dps[i] = fwNoSysName(dps[i]);
	}
	return(dps);
}

fwFsm_deleteDps(string search, string type)
{
int i;
dyn_string dps;

	dps = dpNames(search,type);
	for(i = 1; i <= dynlen(dps) ; i++)
		dpDelete(dps[i]);
}

int fwFsm_isObjectReference(string obj)
{ 
	return fwTreeUtil_isObjectReference(obj);
}

int fwFsm_isObjectReferenceCU(string obj, int &isCu)
{
	string obj_name;
	dyn_string children, exInfo;
	string parent, sys, dev, type;
	int cu;
	obj_name = fwTree_getNodeDisplayName(obj, exInfo);
	if(obj_name == obj)
		return 0;
	sys = fwTree_getNodeSys(obj, exInfo);
	if(strpos(obj, sys+":") == 0)
	{
		fwTree_getNodeCUDevice(obj, cu, dev, type, exInfo);
//		fwTree_getNodeDevice(obj, dev, type, exInfo);
	}
	else
	{
		fwTree_getNodeCUDevice(sys+":"+obj, cu, dev, type, exInfo);
//		fwTree_getNodeDevice(sys+":"+obj, dev, type, exInfo);
	}
//	if(cu)
//	{
//		fwTree_getChildren(obj, children, exInfo);
//		if(!dynlen(children))
//			return 1;
//	}
	isCu = cu;
	if((cu) || (strpos(dev,"::") >= 0))
		return 1;
	return(0);
}


fwFsm_getObjectReferences(string obj, dyn_string &refs, dyn_string &syss)
{
string ref, sys, parent, local_dev, local_type, local_sys, dev, type, obj_name;
int i, index, cu;
dyn_string nodes, exInfo;

	dynClear(refs);

	sys = fwTree_getNodeSys(obj, exInfo);
	fwTree_getCUName(sys+":"+obj, parent, exInfo);
	fwTree_getNodeDevice(sys+":"+obj, local_dev, local_type, exInfo);
	local_sys = fwSysName(local_dev);
	local_dev = fwNoSysName(local_dev);

	nodes = fwTree_getNamedNodes(obj, exInfo);
//DebugN("In Get refs", obj, nodes, parent, exInfo);
	if((index = dynContains(nodes, obj)))
	{
		dynRemove(nodes, index);
	}
	for(i = 1; i <= dynlen(nodes); i++)
	{
		if(fwFsm_isObjectReference(nodes[i]))
		{
//DebugN(nodes[i], "is ref");
		ref = nodes[i];
		if((sys = fwTree_getNodeSys(ref, exInfo)) != "")
		{
//DebugN(ref, "sys", sys);
			fwTree_getNodeCU(sys+":"+ref, cu, exInfo);
			if(cu)
			{
				if(local_dev != "")
				{
					fwTree_getNodeDevice(sys+":"+ref, dev, type, exInfo);
					if(dev == local_sys+":"+local_dev)
					{
						dynAppend(refs, ref);
						dynAppend(syss, sys);
					}
				}
				else
				{
					dynAppend(refs, ref);
					dynAppend(syss, sys);
				}
			}
			else
			{
				fwTree_getNodeDevice(sys+":"+ref, dev, type, exInfo);
//DebugN(dev, local_sys+":"+parent+"::"+local_dev);
				if(dev == local_sys+":"+parent+"::"+local_dev)
				{
					dynAppend(refs, ref);
					dynAppend(syss, sys);
				}
			}
		}
		}
	}
}


fwFsm_getObjectReferenceSystem(string node, string &sys)
{
string dev, type;
dyn_string exInfo;
	
	if(node == "")
		sys = fwFsm_getSystemName();
	else
	{
		fwTree_getNodeDevice(node, dev, type,exInfo);
 		sys = fwSysName(dev);
	}
}

string fwFsm_getReferencedObjectDevice(string ref)
{
string dev, type, sys, mysys;
dyn_string exInfo;


	mysys = fwFsm_getSystemName();
	fwTree_getNodeDevice(ref, dev, type, exInfo);
 	sys = fwSysName(dev);
	if(sys == mysys)
		dev = fwNoSysName(dev);
	return dev;
}

fwUi_askUserInputScalar(string question, int x, int y, int all, int &answer, string addText = "")
{
	dyn_string ret;
	dyn_float res;
	string middle;

	answer = 0;
	if(all)
		middle = "Yes to all";
	else
		middle = "";
	ChildPanelOnReturn("fwTreeDisplay/myMessageInputCount.pnl","confirm",
		makeDynString(
		question,
		"Yes","No", middle, addText),
		x,y, res, ret);
		if(res[1])
		{
			answer = (int) ret[1];
		}
}

fwUi_askUser(string question, int x, int y, int all, int &answer, string addText = "")
{
	dyn_string ret;
	dyn_float res;
	string middle;

	answer = 0;
	if(all)
		middle = "Yes to all";
	else
		middle = "";
	ChildPanelOnReturn("fwTreeDisplay/myMessageQuestion.pnl","confirm",
		makeDynString(
		question,
		"Yes","No", middle, addText),
		x,y, res, ret);
		if(res[1])
		{
			answer = (int) res[1];
		}
}

int fwUi_askUserInput(string question, int x, int y, string input, string &answer)
{
	dyn_string ret;
	dyn_float res;
	string middle;

	answer = "";
	ChildPanelOnReturn("fwTreeDisplay/myMessageInput.pnl","UserInput",
		makeDynString(
		question,
		input),
		x,y, res, ret);
		if(res[1])
		{
			answer = ret[1];
		}
	return res[1];
}

fwUi_informUser(string msg, int x, int y, string ok="", string addText = "", string moreText = "")
{
	ChildPanelOn("fwTreeDisplay/myMessageInfo.pnl","Info",
		makeDynString(msg, ok, addText, moreText),x,y);
}

fwUi_uninformUser()
{
	if(isPanelOpen("Info"))
		PanelOffPanel("Info");	
}

int WarnConnected = 0;
fwUi_informUserProgress(string msg, int x, int y, string ok="")
{
//	if(!isFunctionDefined("ChildPanelOn"))
	if(myManType() != UI_MAN)
		return;
	if(dpExists("ToDo.status"))
	{
		dpSetWait("ToDo.status","idle");
	}
	ChildPanelOn("fwTreeDisplay/myMessageInfoProgress.pnl","InfoProgress",
		makeDynString(msg, ok),x,y);
	if(dpExists("ToDo.status"))
	{
		if(!WarnConnected)
		{
			WarnConnected = 1;
			dpConnect("_do_warn","ToDo.status");
		}
	}
	delay(0,200);
}

int UninformWaiting;
fwUi_uninformUserProgress(int wait)
{
int n = 10;
string state;

//	if(!isFunctionDefined("ChildPanelOn"))
	if(myManType() != UI_MAN)
		return;
	if(wait)
	{
		delay(2);
		UninformWaiting = 1;
		dpConnect("_do_uninform","ToDo.status");
		while(UninformWaiting)
		{
			delay(0,100);
			n--;
			if(n <= 0)
			{
				dpGet("ToDo.status", state);
				_do_uninform("ToDo.status", state);
				n = 10;
			}
		}
	}
	else
	{
		if(isPanelOpen("InfoProgress"))
			PanelOffPanel("InfoProgress");
		if(WarnConnected)
		{
			WarnConnected = 0;
			dpDisconnect("_do_warn","ToDo.status");
		}
	}
}

_do_warn(string dp, string state)
{
	dyn_string items;

	items = strsplit(state,"/");
	if(dynlen(items))
	{
		if(items[1] == "error")
			fwUi_warnUser(items[2], 100, 60);
	}
}

_do_uninform(string dp, string state)
{
	dyn_string items;

	if(state != "working")
	{
		if(isPanelOpen("InfoProgress"))
		{
			PanelOffPanel("InfoProgress");
		}
		if(UninformWaiting)
		{
			dpDisconnect("_do_uninform","ToDo.status");
			UninformWaiting = 0;
		}
		if(WarnConnected)
		{
			WarnConnected = 0;
			dpDisconnect("_do_warn","ToDo.status");
		}
	}	
}

fwUi_warnUser(string msg, int x, int y)
{
	ChildPanelOn("fwTreeDisplay/myMessageWarning.pnl","Warning",
		makeDynString(msg),x,y);
}

fwUi_askUserReferences(string question, int x, int y, int all, int &answer)
{
	dyn_string ret;
	dyn_float res;
	string middle;

	answer = 0;
	if(all)
		middle = "Yes to all";
	else
		middle = "";
	ChildPanelOnReturn("fwTreeDisplay/myMessageQuestionReferences.pnl","confirm",
		makeDynString(
		question,
		"Yes","No", middle),
		x,y, res, ret);
		if(res[1])
		{
			answer = (int) res[1];
		}
}

fwUi_warnUserReferences(string msg, int x, int y)
{
	dyn_string ret;
	dyn_float res;

	ChildPanelOnReturn("fwTreeDisplay/myMessageWarningReferences.pnl","Warning",
		makeDynString(msg),x,y, res, ret);
}

fwUi_warnUserTypeInUse(string msg, int x, int y)
{
	dyn_string ret;
	dyn_float res;

	ChildPanelOnReturn("fwTreeDisplay/myMessageWarningTypeInUse.pnl","Warning",
		makeDynString(msg),x,y, res, ret);
}
