#uses "fwFSM/fwFsm.ctl" // assure all dependencies resolved

string fwDU_getFsmPrefix()
{
//	return "";
	return "fwDU_";
}

string fwDU_getFsmMidfix()
{
//	return ".fwDeclarations.fwCtrlDev.fsm";
	return ".fsm";
}

string fwDU_extractFsmPrefix(string dp)
{
string dev;

	if(strpos(dp,"fwDU_") == 0)
		dev = substr(dp,5);
	else
		dev = dp;
	return dev;
}

string fwDU_getLogicalName(string dev)
{
	string log;

	log = fwFsm_getLogicalDeviceName(dev);
	return log;
}

string fwDU_getPhysicalName(string log)
{
	string dev;

	dev = fwFsm_getPhysicalDeviceName(log);
	return dev;
}

string fwDU_checkLogicalName(string domain, string device)
{
	string logdev, dp, sys;

//DebugN("checkLogical", domain, device);
	sys = fwFsm_getSystem(device);
	if(sys != "")
		sys +=":";
	logdev = fwDU_getLogicalName(device);
	dp = sys+domain+fwFsm_separator+logdev;
	if(dpExists(dp))
		return logdev;
	device = fwFsm_extractSystem(device);
	return device;
}

dyn_int FwDU_timersOn;
dyn_string FwDU_timersName;
dyn_string FwDU_callbacks;
mapping FwDU_ExecutingAction, FwDU_Command/*, FwDU_IsBusy*/;

/**@name LIBRARY: fwDU:

Library of functions to get/set information for Framework Device Units,
these functions can be used inside the Device Type Scripts

modifications: none

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@version creation: 08/05/2003
@author C. Gaspar



*/
//@{
//--------------------------------------------------------------------------------
//fwDU_startTimeout:
/**  Start a timer to send the device to a given state, for example "ERROR", if
the device doesn't change state (or doesn't go to a specific state) within that time.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param secs: The number of seconds for the Timeout
      @param domain: The domain name (control unit name) of the device
      @param device: The device name received by the xxx_doCommand() script
      @param timeout_state: The state to go to if the timeout fires
      @param desired_state: (Optional) The state the device is expected to go into
      @param callback: (Optional) The name of a function to be called when the timeout occurs
*/
fwDU_startTimeout(int secs, string domain, string device, string timeout_state, string desired_state = "",
	string callback = "")
{
int id, index;
string dev, dp;

//	device = fwDU_getLogicalName(device);
	dev = fwDU_checkLogicalName(domain, device);
	dp = domain+fwFsm_separator+dev+fwDU_getFsmMidfix()+".currentState";
	if(!(index = dynContains(FwDU_timersName, dp)))
	{
		index = dynAppend(FwDU_timersName, dp);
	}
	else
	{
		if(FwDU_timersOn[index] == 1)
		{
			fwDU_stopTimeout(domain, device);
DebugTN("Warning: previous Timeout for Device "+domain+"::"+device+" was still running, it has been stopped!");
		}
   else if(FwDU_timersOn[index] == -3)
		{
			fwDU_stopTimeout(domain, device);
DebugTN("Warning: previous Timeout for Device "+domain+"::"+device+" was still stopping!");
		}

	}
	FwDU_timersOn[index] = -1;
//DebugTN("Info: Starting Timeout for Device "+domain+"::"+device, index, FwDU_timersOn[index]);
//	FwDU_callbacks[index] = callback;
	id = startThread("fwDU_stateTimeout", secs, domain, device, index, desired_state, timeout_state, callback);
	while(FwDU_timersOn[index] == -1)
		delay(0,50);
//DebugTN("Info: Started Timeout for Device "+domain+"::"+device, index, FwDU_timersOn[index]);
}

//fwDU_stopTimeout:
/**  Stop the timer for the device. In general this function is not necessary, the timer is stopped either by a
state change or by the Timeout.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name received by the xxx_doCommand() script
*/
fwDU_stopTimeout(string domain, string device)
{

	string dev, dp;
	int index, i;

	dev = fwDU_checkLogicalName(domain, device);
	dp = domain+fwFsm_separator+dev+fwDU_getFsmMidfix()+".currentState";
//	_fwDU_stopIt(dp, "");
	if((index = dynContains(FwDU_timersName, dp)))
	{
    if(FwDU_timersOn[index] == 1)
    {
      FwDU_timersOn[index] = -2;
    }
    for(i = 1; i <= 3; i++)
    {
      if(FwDU_timersOn[index] == 0)
        break;
      else
        delay(0,50);
    }
    if(FwDU_timersOn[index] != 0)
      FwDU_timersOn[index] = 0;
	}
}

void fwDU_stateTimeout(int secs, string domain, string device, int index, string state, string timeout_state, string callback = "")
{
int i;
string curr_state;

//DebugTN("Starting Timeout Thread",index, secs, domain, device);
	fwDU_connectState("_fwDU_stopIt", 1, domain, device);
	while(FwDU_timersOn[index] == -1)
		delay(0,50);
	for(i = 0; i <= secs*10; i++)
	{
		if(FwDU_timersOn[index] == 1)
			delay(0,100);
		else if(FwDU_timersOn[index] == -2)
			break;
		else
		{
			if(state != "")
			{
				fwDU_getState(domain, device, curr_state);
				if(curr_state == state)
					break;
				else
					FwDU_timersOn[index] = 1;
			}
			else
				break;
		}
	}
//DebugTN("Stopping Timeout Thread", index, secs, domain, device);
//DebugTN("Info: Stopping Timeout Thread for Device "+domain+"::"+device, index, FwDU_timersOn[index]);
	fwDU_disconnectState("_fwDU_stopIt", domain, device);
	if(FwDU_timersOn[index] == 1)
	{
DebugTN("Timeout: Device "+domain+"::"+device+" Set to "+timeout_state+ " after "+secs+" seconds");
/*
		if(FwDU_callbacks[index] != "")
		{
//			if(functionDefined(FwDU_callbacks[index]))
//			{
				startThread(FwDU_callbacks[index], domain, device);
//			}
		}
*/
		if(callback != "")
		{
			startThread(callback, domain, device);
		}
		fwDU_setState(domain, device, timeout_state);
	}
	FwDU_timersOn[index] = 0;
//DebugTN("Info: Stopped Timeout Thread for Device "+domain+"::"+device, index, FwDU_timersOn[index]);
//	FwDU_callbacks[index] = "";
//DebugTN("Stopped Timeout Thread",index, secs, domain, device);
}

_fwDU_stopIt(string dp, string state)
{
int index;

//DebugTN("Info: Got StateChange dpConnect", dp, state);
	dp = dpSubStr(dp,DPSUB_DP_EL);
	if((index = dynContains(FwDU_timersName, dp)))
	{
    if(FwDU_timersOn[index] == -1)
    {
      FwDU_timersOn[index] = 1;
      return;
    }
//DebugTN("Do Stop Timeout Thread index", dp, state, index);
//		FwDU_timersOn[index] = 0;
//DebugTN("Info: Got StateChange for Device ", dp, index, FwDU_timersOn[index]);
    FwDU_timersOn[index] = -3;
	}
}

//fwDU_getState:
/**  Get the state of this device.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the state or action scripts
      @param state: current state
*/
fwDU_getState(string domain, string device, string &state)
{
	device = fwDU_checkLogicalName(domain, device);
	fwUi_getCurrentState(domain, device, state);
}

//fwDU_setState:
/**  Set the state of this device.
Can be used outside the Device Type scripts, if an empty script is given as Device State Script.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name
      @param state: new state
*/
fwDU_setState(string domain, string device, string state)
{
  string dp, oldstate, busy;
  int manid;
  int manType, manNum;

  if (state == "")
    return;
  device = fwDU_checkLogicalName(domain, device);
  dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
  dpGet(dp+".currentState:_online.._value", oldstate,
        dp+".executingAction:_online.._value", busy,
        dp+".executingAction:_online.._manager", manid);
  state = fwFsm_capitalize(state);
//  busy = FwDU_IsBusy[domain+device];
  getManIdFromInt(manid, manType, manNum);
//DebugTN("fwDU_setState", domain, device, busy, manid, manType, manNum);
  if ((state != oldstate) || ((busy != "") && (manType != DEVICE_MAN)))
  {
    dpSetWait(dp+".currentState", state,
              dp+".executingAction", "");
  }
}

//fwDU_connectCommand:
/**  Connect to the reception of a command for this device.
Can be used outside the Device Type scripts, if an empty script is given as Device Action Script.
The Callback function will be called with three parameters:
yourCallbackName(string domain, string device, string command), where <domain> and <device> are the ones passed to this function and
<command> is the command received.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param callback: The routine to be called when the command arrives
      @param domain: The domain name (control unit name) of the device
      @param device: The device name

*/
fwDU_connectCommand(string callback, string domain, string device)
{
	fwUi_registerObjCallback(callback, domain, device, "COMMAND");
	fwUi_connectExecutingAction("_fwDU_commandCallback", domain, device, 0);
}

_fwDU_commandCallback(string dp, string command)
{
string node, obj, userNode, action;
dyn_string callbacks, pars;
int i;

	if(command == "")
		return;
	action = command;
	pars = strsplit(command,"/");
	if(dynlen(pars))
		action = pars[1];
	if(fwUi_getObjCallbacks(dp, callbacks, node, obj, userNode))
	{
		for(i = 1; i <= dynlen(callbacks); i++)
		{
			startThread(callbacks[i], node, obj, action);
		}
	}
}

fwDU_getAllActions(string type, dyn_string &allActions)
{
	int i;
	string capaction;
	dyn_string actions;
	int doit = 0;

	fwFsm_getObjectActions(type, actions);
	for(i = 1; i <= dynlen(actions); i++)
	{
		capaction = fwFsm_capitalize(actions[i]);
		if(capaction != actions[i])
		{
			doit = 1;
			break;
		}
	}
	if(doit)
	{
		dynAppend(allActions, actions);
	}
//DebugN(type,"actions",allActions);
}

int fwDU_convertValue(string domain, string device)
{
/*
	string dp, busy;

  device = fwDU_checkLogicalName(domain, device);
  dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
  dpGet(dp+".executingAction:_online.._value", busy);
  FwDU_IsBusy[domain+device] = busy;
*/
	return 1;
}

string fwDU_convertCommand(string domain, string device, string type, dyn_string actions, string command)
{
	int i;
	string capaction;
  string executing;
  string dp, ret;

//DebugN(domain, device, command, actions);
//	fwFsm_getObjectActions(type, actions);
	device = fwDU_checkLogicalName(domain, device);
  dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
  fwUi_getExecutingAction(domain, device, executing);
  if(executing == "")
  {
    delay(0, 100);
    fwUi_getExecutingAction(domain, device, executing);
  }
  FwDU_ExecutingAction[domain+device] = executing;
  ret = command;
 	for(i = 1; i <= dynlen(actions); i++)
	{
		capaction = fwFsm_capitalize(actions[i]);
		if(capaction == command)
    {
			ret = actions[i];
      break;
    }
	}
  FwDU_Command[domain+device] = ret;
  dpSetWait(dp+".executingAction:_original.._value", executing);
	return ret;
}

fwDU_connectState(string rout, int flag, string domain, string device)
{
	string dp;

//	dp = fwDU_getFsmPrefix()+device+fwDU_getFsmMidfix()+".currentState:_original.._value";
//	device = fwDU_getLogicalName(device);
	device = fwDU_checkLogicalName(domain, device);
	dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix()+".currentState:_original.._value";
	dpConnect(rout, flag, dp);
}

fwDU_disconnectState(string rout, string domain, string device)
{
	string dp;

//	dp = fwDU_getFsmPrefix()+device+fwDU_getFsmMidfix()+".currentState:_original.._value";
//	device = fwDU_getLogicalName(device);
	device = fwDU_checkLogicalName(domain, device);
	dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix()+".currentState:_original.._value";
	dpDisconnect(rout, dp);
}
/*
fwDU_getParameters(string domain, string device, dyn_string &params)
{
string dp;
dyn_string pars;

//	dp = fwDU_getFsmPrefix()+device+fwDU_getFsmMidfix();
	dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
	dpGet(dp+".currentParameters:_online.._value",pars);

	fwUi_getCurrentParameters(domain, device, params);
}
*/

//fwDU_getParameter:
/**  Get the value of a parameter defined for this device.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the state or action scripts
      @param param: The name of the parameter
      @param value: The value of the parameter as a string
*/

fwDU_getParameter(string domain, string device, string param, string &value)
{
/*
string dp;
dyn_string pars, items;
int i;

//	dp = fwDU_getFsmPrefix()+device+fwDU_getFsmMidfix();
	dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
	dpGet(dp+".currentParameters:_online.._value",pars);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i]," ");
		if(items[2] == param)
		{
			value = items[4];
		}
	}
*/
//	device = fwDU_getLogicalName(device);
	device = fwDU_checkLogicalName(domain, device);
	fwUi_getCurrentParameter(domain, device, param, value);
}

//fwDU_setParameter:
/**  Set the value of a parameter defined for this device.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the state or action scripts
      @param param: The name of the parameter
      @param value: The new value of the parameter as a string
*/

fwDU_setParameter(string domain, string device, string param, string value)
{
/*
string dp;
dyn_string pars, items;
int i;

	dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
//	dp = fwDU_getFsmPrefix()+device+fwDU_getFsmMidfix();
	dpGet(dp+".currentParameters:_online.._value",pars);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i]," ");
		if(items[2] == param)
		{
			pars[i] = items[1] +" "+items[2] +" = "+ value;
		}
	}
	dpSetWait(dp+".currentParameters:_original.._value",pars);
*/
//	device = fwDU_getLogicalName(device);
	device = fwDU_checkLogicalName(domain, device);
	fwUi_setCurrentParameter(domain, device, param, value);
}

fwDU_setDefaultParameters(string domain, string device)
{
string dp, type;
dyn_string type_pars;

//	device = fwDU_getLogicalName(device);
	device = fwDU_checkLogicalName(domain, device);
//	type = dpTypeName(device);
	fwFsm_getObjectType(domain+"::"+device,type);
	fwFsm_readObjectParameters(type, type_pars);
	dp = domain+fwFsm_separator+device+fwDU_getFsmMidfix();
//	dp = fwDU_getFsmPrefix()+device+fwDU_getFsmMidfix();
	dpSetWait(dp+".currentParameters:_original.._value",type_pars);
}

//fwDU_getCommandParameter:
/**  Get A parameter of the device's last received command.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the state or action scripts
      @param parameter: The name of the parameter
      @param value: The value of the parameter
*/

fwDU_getCommandParameter(string domain, string device, string par, string &value, int unescape = 1)
{
	int ret;
  string executing, action;
  dyn_string items;
  int i;
//	device = fwDU_getLogicalName(device);
	device = fwDU_checkLogicalName(domain, device);
  if(FwDU_ExecutingAction[domain+device] == "")
  {
    fwUi_getExecutingAction(domain, device, executing);
    if(executing == "")
      executing = FwDU_Command[domain+device];
    FwDU_ExecutingAction[domain+device] = executing;
  }
  ret = fwUi_parseExecutingActionParameter(FwDU_ExecutingAction[domain+device], par, value, unescape);
//DebugTN("FSM Parsing Action", domain, device, FwDU_ExecutingAction[domain+device], par, value, ret);
//	ret = fwUi_getExecutingActionParameter(domain, device, par, value, unescape);
	if(ret <= 0)
  {
    items = strsplit(FwDU_ExecutingAction[domain+device],"/");
    if(dynlen(items))
    {
      items[1] = FwDU_Command[domain+device];
      action += items[1];
      for(i = 2; i <= dynlen(items); i++)
      {
        action += "/";
        action += items[i];
      }
    }
		fwUi_parseExecutingActionDefaultParameter(action, domain, device, par, value);
//DebugTN("FSM Parsing Action (default)", domain, device, action, items, par, value, ret);
  }
//		fwUi_getExecutingActionDefaultParameter(domain, device, par, value);
}


fwDU_getAction(string command, string &action)
{
	dyn_string pars;

	action = command;
	pars = strsplit(command,"/");
	if(dynlen(pars))
		action = pars[1];
}


fwDU_getActionParameter(string command, string par, string &value)
{
	dyn_string pars, items;
	int i, pos;

	value = "";
	pars = strsplit(command,"/");
	if(!dynlen(pars))
		return;
	dynRemove(pars,1);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i],"()=");
		if(items[1] == par)
		{
			if( (items[2] != "S")&&(items[2] != "I")&&(items[2] != "F") )
				value = items[2];
			else
				value = items[4];
		}
	}
	if((pos = strpos(value,"\"")) == 0)
	{
		value = substr(value,1,strlen(value)-2);
	}
}


fwDU_getStateTime(string device, string state, int &timeout)
{
string type;
dyn_string items;

	type = dpTypeName(device);
	fwFsm_readObjectWhens(type, state, items);
	if(!dynlen(items))
		timeout = 0;
	else
		timeout = (int) items[1];
}

fwDU_getActionTime(string device, string state, string action, int &timeout)
{
string type;

	type = dpTypeName(device);
	fwFsm_readObjectActionTime(type, state, action, timeout);
}

//fwDU_getAlarmLimits:
/**  Get the alarm limits defined for a device, if any.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param device: The device name available in the state or action scripts
      @param elem: The datapoint element within the device datapoint
      @param limits: The list of limits defined by the alert_hdl config
*/

fwDU_getAlarmLimits(string device, string elem, dyn_float &limits)
{
	fwFsm_getDeviceAlarmLimits(device, elem, limits);
}

//fwDU_getDeviceFsmName:
/**  Get the device name used inside the SMI domain.
For example to send as a parameter to an object, in order to send a selective action

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the state or action scripts
*/

string fwDU_getDeviceFsmName(string domain, string device)
{
	string du;

	du = fwDU_checkLogicalName(domain, device);
	du = fwFsm_capitalize(du);
	strreplace(du, fwDev_separator, ":");
	return du;
}

dyn_string CU_DUNameIndexes;

//fwDU_createGlobalIndex:
/**  Create a DU index to be used in different DUs of the same type.
Variables defined outside the "main" in the initialise script of a DU type are common to all
DUs in the same CU. But the user can create dyn variables and use the index returned by:
fwDU_createGlobalIndex()/fwDU_getGlobalIndex() to distiguish between the various DUs

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the initialize, state or action scripts
      @return An index to be used with dyn variables for each DU
*/
int fwDU_createGlobalIndex(string domain, string device)
{
int index;

	if(!(index = dynContains(CU_DUNameIndexes, domain+"||"+device)))
	{
		index = dynAppend(CU_DUNameIndexes, domain+"||"+device);
	}
	return index;
}

//fwDU_getGlobalIndex:
/**  Get the DU index to be used for different DUs of the same type.
If the user called fwDU_createGlobalIndex() in the initialize script, he/she can then call
fwDU_getGlobalIndex() in the state or action scripts to index the dyn variables.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The domain name (control unit name) of the device
      @param device: The device name available in the initialize, state or action scripts
      @return The DU index to be used with dyn variables for the current DU
*/
int fwDU_getGlobalIndex(string domain, string device)
{
int index;

	index = dynContains(CU_DUNameIndexes, domain+"||"+device);
	return index;
}


