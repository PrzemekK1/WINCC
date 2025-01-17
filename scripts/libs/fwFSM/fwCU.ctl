/**@name LIBRARY: fwCU:

Library of functions to get information or to operate Framework Control Units (and their objects/devices),
these functions can be used in User Interfaces or Ctrl Scripts

modifications:
    05/08/05: New functions added
                    Note: Some functions have changed (details)

    20/12/05: Several changes (details)

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@version creation: 08/05/2003
@author C. Gaspar



*/

#uses "fwFSM/fwFsm.ctl" // assure all dependencies resolved

//@{
//--------------------------------------------------------------------------------
//fwCU_view:
/**  Open the operation panel for a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param x: (Optional) The x coordinate when to display the panel
      @param y: (Optional) The y coordinate when to display the panel
*/
fwCU_view(string node, int x = -1, int y = -1)
{
string obj;

	fwFsm_initialize(0);
	if(obj == "")
	{
		obj = _fwCU_getNodeObj(node);
	}
	else
	{
		DebugN("fwCU_view - The 2nd parameter (obj) is obsolete, please consult the documentation");
		if(obj != node)
		{
			if(dpExists(obj))
				fwCU_getObjName(node, obj, obj);
		}
		fwUi_getCUNodeNames(node, obj);
	}
	fwFsmUi_view(node, obj, x, y);
//	fwUi_showFsmObject(node, obj, "", x, y);
}

string _fwCU_getNodeObj(string &node)
{
string obj, parent, child;


	if(fwFsm_isAssociated(node))
	{
		obj = fwFsm_getAssociatedObj(node);
		node = fwFsm_getAssociatedDomain(node);
		if(fwFsm_isAssociated(obj))
		{
			parent = fwFsm_getAssociatedDomain(obj);
			child = fwFsm_getAssociatedObj(obj);
			if((parent == child) || (parent == node))
				obj = child;
		}
		if(obj != node)
		{
			if(dpExists(obj))
				fwCU_getDevName(node, obj, obj);
		}
	}
	else
		obj = node;
	fwUi_getCUNodeNames(node, obj);
	return obj;
}

_fwCU_getNodeNode(string &node)
{
string obj;

	if(fwFsm_isAssociated(node))
	{
		node = fwFsm_getAssociatedDomain(node);
	}
}

//fwCU_getState:
/**  Get the state of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param state: the current state
*/
fwCU_getState(string node, string &state)
{

	string obj;

	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	fwUi_getCurrentState(node, obj, state);
}

fwCU_getObjState(string node, string obj, string &state)
{
	DebugN("fwCU_getObjState - This function is obsolete, replaced by fwCU_getState, please consult the documentation");
	fwUi_getCUNodeNames(node, obj);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	fwUi_getCurrentState(node, obj, state);
}

//dyn_string FwCUCallbacks;
//dyn_string FwCUObjects;

//fwCU_connectState:
/**  Connect to state changes of a Control Unit, Logical Unit, Device Unit or Internal Object.
The Callback function will be called with two parameters:
yourCallbackName(string node, string state), where <node> is the node passed to this function and
<state> is the current state of the CU/LU/DU or Obj

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param callback: The routine to be called when the state changes
      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @return 1:OK, 0:node not found or not connected

*/
int fwCU_connectState(string callback, string node, int wait_up = 0)
{
	string obj;
	string userNode;
	int ret;

	userNode = node;
	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	fwUi_registerObjCallback(callback, node, obj, "STATE", userNode);
	ret = fwUi_connectCurrentState("_fwCU_stateCallback", node, obj);
	if(wait_up)
	{
		while(!ret)
		{
			delay(1);
			ret = fwUi_connectCurrentState("_fwCU_stateCallback", node, obj);
		}
	}
	return ret;
}

_fwCU_stateCallback(string dp, string state)
{
string node, obj, userNode;
dyn_string callbacks;
int i;

	if(fwUi_getObjCallbacks(dp, callbacks, node, obj, userNode))
	{
		for(i = 1; i <= dynlen(callbacks); i++)
		{
			startThread(callbacks[i], userNode, state);
		}
	}
}

_fwCU_objStateCallback(string dp, string state)
{
string node, obj, userNode;
dyn_string callbacks;
int i;

	if(fwUi_getObjCallbacks(dp, callbacks, node, obj, userNode))
	{
		for(i = 1; i <= dynlen(callbacks); i++)
		{
			if(node == obj)
				startThread(callbacks[i], node, state);
			else
				startThread(callbacks[i], node, obj, state);
		}
	}
}

//fwCU_disconnectState:
/**  Disconnect from state changes of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @return 1:OK, 0:node not found or not connected
*/
int fwCU_disconnectState(string node)
{
	string obj;
	int ret;

	obj = _fwCU_getNodeObj(node);

//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	ret = fwUi_disconnectCurrentState("_fwCU_stateCallback", node, obj);
	fwUi_unRegisterObjCallback(node, obj, "STATE");
	return ret;
}

fwCU_connectObjState(string callback, string node, string obj)
{
//	int index;

	DebugN("fwCU_connectObjState - This function is obsolete, replaced by fwCU_connectState, please consult the documentation");
	fwUi_getCUNodeNames(node, obj);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
/*
	if(!(index = dynContains(FwCUObjects,node+"/"+obj)))
	{
		index = dynAppend(FwCUObjects,node+"/"+obj);
	}
	FwCUCallbacks[index] = callback;
*/
	fwUi_registerObjCallback(callback, node, obj, "STATE");
	fwUi_connectCurrentState("_fwCU_objStateCallback", node, obj);
}

fwCU_disconnectObjState(string node, string obj)
{
//	int index;

	DebugN("fwCU_disconnectObjState - This function is obsolete, replaced by fwCU_disconnectState, please consult the documentation");
	fwUi_getCUNodeNames(node, obj);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	fwUi_disconnectCurrentState("_fwCU_stateCallback", node, obj);
	fwUi_unRegisterObjCallback(node, obj);
/*
	if(index = dynContains(FwCUObjects,node+"/"+obj))
	{
		dynRemove(FwCUObjects, index);
		dynRemove(FwCUCallbacks, index);
	}
*/
}

//fwCU_getParameter:
/**  Get the value of a parameter defined for a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param param: The name of the parameter
      @param value: The value of the parameter as a string
*/

fwCU_getParameter(string node, string param, string &value)
{
	string obj;

	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	fwUi_getCurrentParameter(node, obj, param, value);
}

fwCU_getObjParameter(string node, string obj, string param, string &value)
{
	DebugN("fwCU_getObjParameter - This function is obsolete, replaced by fwCU_getParameter, please consult the documentation");
	fwUi_getCUNodeNames(node, obj);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	fwUi_getCurrentParameter(node, obj, param, value);
}

//fwCU_getStateColor:
/**  Get the color of a state defined for a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param state: The state
      @param color: Returns the state color
*/

fwCU_getStateColor(string node, string state, string &color)
{
	string obj;

	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	fwUi_getObjStateColor(node, obj, state, color);
}

//fwCU_getOperationMode:
/**  Get the operational mode of a Control Unit, Logical Unit, Device Unit or Internal Object.
(I.e. can the current user send commands to it).

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @return 1 = yes, it can be operated. 0 = No, not owner
*/
int fwCU_getOperationMode(string node, int notOwner = 0, int childrenMode = 0)
{
bit32 bits;
int operate, localOperateable = 1;
string obj;

	obj = _fwCU_getNodeObj(node);
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;

	bits = fwUi_getModeBits(node, obj);
	if(notOwner)
	{
		operate = (
//			(getBit(bits, FwOwnerBit) || (!getBit(bits, FwExclusiveBit))) &&
			(!getBit(bits, FwFreeBit)) &&
			(getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&
			localOperateable);
	}
  else
  {
	  operate = (
	  	(getBit(bits, FwOwnerBit) || (!getBit(bits, FwExclusiveBit))) &&
	  	(getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&
	  	localOperateable);
  }
  if(operate && childrenMode)
  {
    if( getBit(bits, FwIncompleteBit) || getBit(bits, FwIncompleteDevBit) ||
        getBit(bits, FwIncompleteDeadBit))
      operate = 2;
  }
	return operate;
}

int fwCU_getOperationOwner(string node)
{
bit32 bits;
int operate, localOperateable = 1;
string obj;

	obj = _fwCU_getNodeObj(node);
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;

	bits = fwUi_getModeBits(node, obj);
	operate = (
		(getBit(bits, FwOwnerBit) || (!getBit(bits, FwExclusiveBit))) &&
		(getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&
		localOperateable);

	return operate;
}

dyn_int FwCU_CurrentOperationModes;
dyn_int FwCU_CurrentOperationModes_notOwner;
dyn_int FwCU_CurrentOperationModes_childrenMode;


//fwCU_connectOperationMode:
/**  Connect to the operational mode of a Control Unit, Logical Unit, Device Unit or Internal Object.
The Callback function will be called with two parameters:
yourCallbackName(string node, int operate_flag), where <node> is the node passed to this function and
<operate_flag> can be 1 = yes, it can be operated; 0 = No, not owner.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param callback: The routine to be called when the operation mode changes
      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
*/
int fwCU_connectOperationMode(string user_callback, string node, int notOwner = 0, int childrenMode = 0)
{
string obj;
int index;
string userNode;
int ret;

	userNode = node;
	obj = _fwCU_getNodeObj(node);
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	index = fwUi_registerObjCallback(user_callback, node, obj, "MODE", userNode);
//DebugN("fwCU connect", node, obj, index);
	ret = fwFsmUi_connectModeBits("operate_mode", node, obj, 0);
	FwCU_CurrentOperationModes[index] = -1;
	FwCU_CurrentOperationModes_notOwner[index] = notOwner;
	FwCU_CurrentOperationModes_childrenMode[index] = childrenMode;
	return ret;
}

synchronized int checkOperationModeChange(int index, int operate)
{
	int ret = 0;

	if(operate != FwCU_CurrentOperationModes[index])
	{
		FwCU_CurrentOperationModes[index] = operate;
		ret = 1;
	}
	return ret;
}

operate_mode(string dp)
{
	bit32 bits;
	int operate, free, included;
	int localOperateable = 1;
	string node, obj, userNode;
	dyn_string callbacks;
	int i, index;

	index = fwUi_getObjCallbacks(dp, callbacks, node, obj, userNode);
	bits = fwFsmUi_getModeBits(node, obj);
	if(FwCU_CurrentOperationModes_notOwner[index])
	{
		operate = (
//			(getBit(bits, FwOwnerBit) || (!getBit(bits, FwExclusiveBit))) &&
			(!getBit(bits, FwFreeBit)) &&
			(getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&
			localOperateable);
	}
	else
	{
		operate = (
			(!getBit(bits, FwFreeBit)) &&
			(getBit(bits, FwOwnerBit) || (!getBit(bits, FwExclusiveBit))) &&
			(getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&
			localOperateable);
//DebugTN("operate_mode", dp, operate, "owner", getBit(bits, FwOwnerBit), "exclusive", getBit(bits, FwExclusiveBit),
//        "free", getBit(bits, FwFreeBit));
	}
	if(operate && FwCU_CurrentOperationModes_childrenMode[index])
  {
    if( getBit(bits, FwIncompleteBit) || getBit(bits, FwIncompleteDevBit) ||
        getBit(bits, FwIncompleteDeadBit))
      operate = 2;
  }
//DebugN("******** Callback", dp, node, obj, index, bits, operate);
	if(!dynlen(callbacks))
	{
		node = FwUiDomain;
		if(index = dynContains(FwUiObjects,node+"/"+obj+"/MODE"))
		{
			callbacks = FwUiCallbacks[index];
			userNode = FwUiUserObjects[index];
		}
	}
//	if(operate != FwCU_CurrentOperationModes[index])
//	{
//		FwCU_CurrentOperationModes[index] = operate;
//DebugN("******** Callbacks", callbacks, operate, FwCU_CurrentOperationModes[index], userNode);
	if(checkOperationModeChange(index, operate))
	{
		for(i = 1; i <= dynlen(callbacks); i++)
		{
			startThread(callbacks[i], userNode, operate);
//			if(node == obj)
//				startThread(callbacks[i], node, operate, free);
//			else
//				startThread(callbacks[i], node+"::"+obj, operate, free);
		}
	}
}

//fwCU_disconnectOperationMode:
/**  Disconnect from the operational mode of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
*/
fwCU_disconnectOperationMode(string node)
{
//	int index;
	string obj;

	obj = _fwCU_getNodeObj(node);
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;

	fwFsmUi_disconnectModeBits(node, obj);
	fwUi_unRegisterObjCallback(node, obj, "MODE");
}

dyn_string FwCU_CurrentAlarmStates;

//fwCU_getAlarmState:
/**  Get the alarm state of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @return 1 = yes, there are alarms. 0 = No, no alarms

*/
int fwCU_getAlarmState(string node)
{
string obj;

	obj = _fwCU_getNodeObj(node);
	if(fwFsm_isCU(node, obj))
		node = obj;
	return fwUi_getSummaryAlarm(node, obj);
}

//fwCU_connectAlarmState:
/**  Connect to alarm state changes of a Control Unit, Logical Unit, Device Unit or Internal Object.
The Callback function will be called with two parameters:
yourCallbackName(string node, int alarm_state), where <node> is the node passed to this function and
<alarm_state> is the current alarm state of the CU/LU/DU or Obj.
<alarm_state> can be 1 = yes, there are alarms; 0 = No, no alarms.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param callback: The routine to be called when the alarm state changes
      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device

*/
int fwCU_connectAlarmState(string user_callback, string node)
{
string obj;
string userNode;
int index;

	userNode = node;
	obj = _fwCU_getNodeObj(node);
	if(fwFsm_isCU(node, obj))
		node = obj;
	index = fwUi_registerObjCallback(user_callback, node, obj, "ALARM", userNode);
	FwCU_CurrentAlarmStates[index] = -1;
	fwFsmUi_connectSummaryAlarm("change_alarm_state", node, obj);

}

change_alarm_state(int state, string dp)
{
	string node, obj, userNode;
	dyn_string callbacks;
	int i, index;

	index = fwUi_getObjCallbacks(dp, callbacks, node, obj, userNode);

	for(i = 1; i <= dynlen(callbacks); i++)
	{
		if(FwCU_CurrentAlarmStates[index] != state)
		{
			FwCU_CurrentAlarmStates[index] = state;
			startThread(callbacks[i], userNode, state);
		}
	}
}


//fwCU_disconnectAlarmState:
/**  Disconnect from alarm state changes of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
*/
fwCU_disconnectAlarmState(string node)
{
	string obj;

	obj = _fwCU_getNodeObj(node);

//	fwFsmUi_disconnectSummaryAlert(node, obj); //FVR commented out. This function does not seem to exist.
	fwUi_unRegisterObjCallback(node, obj, "ALARM");
}

//fwCU_sendCommand:
/**  Send a command (optionally with parameters) to a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param cmnd: The command
      @param params: (Optional) The parameter names
      @param values: (Optional) The parameter values
      @return 1:OK, 0:node not found or not connected
*/
int fwCU_sendCommand(string node, string cmnd,
	dyn_string params = makeDynString(), dyn_anytype values = makeDynAnytype())
{
string obj;
dyn_string par_names, par_types, par_values;
int i, index;
string cmd;

	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	cmd = cmnd;
	if(dynlen(params))
	{
		_fwCU_getParametersTypes(node, obj, cmnd, par_names, par_types, par_values);
		for(i = 1; i <= dynlen(params); i++)
		{
			index = dynContains(par_names, params[i]);
			if(index)
			{
				fwFsmUi_addParameter(cmd, params[i], par_types[index], values[i]);
//				cmd += "/"+params[i];
//				cmd += par_types[index];
//				cmd += "="+values[i];
			}
		}
	}
	return fwUi_sendCommand(node, obj, cmd);
}

fwCU_sendCommandParameters(string node, string cmnd, dyn_string params, dyn_anytype values)
{
dyn_string par_names, par_types, par_values;
int i, index;
string cmd;
	string obj;

	DebugN("fwCU_sendCommandParameters - This function is obsolete, replaced by fwCU_sendCommand, please consult the documentation");
	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;

	_fwCU_getParametersTypes(node, obj, cmnd, par_names, par_types, par_values);
	cmd = cmnd;
	for(i = 1; i <= dynlen(params); i++)
	{
		index = dynContains(par_names, params[i]);
		if(index)
		{
			fwFsmUi_addParameter(cmd, params[i], par_types[index], values[i]);
//			cmd += "/"+params[i];
//			cmd += par_types[index];
//			cmd += "="+values[i];
		}
	}
//DebugN(node, cmnd, params, values, cmd);
	fwUi_sendCommand(node, obj, cmd);
}

fwCU_sendObjCommand(string node, string obj, string cmnd)
{
	DebugN("fwCU_sendObjCommand - This function is obsolete, replaced by fwCU_sendCommand, please consult the documentation");
	fwUi_getCUNodeNames(node, obj);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	fwUi_sendCommand(node, obj, cmnd);
}

fwCU_sendObjCommandParameters(string node, string obj, string cmnd, dyn_string params, dyn_anytype values)
{
dyn_string par_names, par_types, par_values;
int i, index;
string cmd;

	DebugN("fwCU_sendObjCommandParameters - This function is obsolete, replaced by fwCU_sendCommandParameters, please consult the documentation");
	fwUi_getCUNodeNames(node, obj);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	_fwCU_getParametersTypes(node, obj, cmnd, par_names, par_types);
	cmd = cmnd;
	for(i = 1; i <= dynlen(params); i++)
	{
		index = dynContains(par_names, params[i]);
		if(index)
		{
			fwFsmUi_addParameter(cmd, params[i], par_types[index], values[i]);
//			cmd += "/"+params[i];
//			cmd += par_types[index];
//			cmd += "="+values[i];
		}
	}
	fwUi_sendCommand(node, obj, cmd);
}

_fwCU_getParametersTypes(string node, string obj, string cmnd,
			dyn_string &par_names, dyn_string &par_types)
{
string type, state, sys;
dyn_string pars, items;
int i;

	dynClear(par_names);
	dynClear(par_types);
	fwFsm_getObjectType(node+"::"+obj, type);
	fwUi_getCurrentState(node, obj, state);
	fwUi_getDomainSys(node, sys);
	fwFsm_readObjectActionParameters(sys+type, state, cmnd, pars);
	for(i = 1; i <= dynlen(pars); i++)
	{
		items = strsplit(pars[i]," ");
		dynAppend(par_names, items[2]);
		dynAppend(par_types, items[1]);
/*
		switch(items[1])
		{
			case "string":
				dynAppend(par_types,"(S)");
				break;
			case "int":
				dynAppend(par_types,"(I)");
				break;
			case "float":
				dynAppend(par_types,"(F)");
				break;
		}
*/
	}
}

//fwCU_enableObj:
/**  Enable an object or device in a Control Unit/Logical Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (CU/LU name)
      @param obj: The object or device name
*/

fwCU_enableObj(string node, string obj)
{
//DebugN("************ Enable",  node, obj);
	_fwCU_getNodeNode(node);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
//DebugN("GetCUNodeNames", node, obj);
	fwUi_getCUNodeNames(node, obj);
//DebugN("Trying to enable", node, obj);
	fwUi_enableDevice(node, obj);
}

//fwCU_disableObj:
/**  Disable an object or device in a Control Unit/Logical Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (CU/LU name)
      @param obj: The object or device name
      @param permanent: (Optional) The device should be permanently disabled
*/

fwCU_disableObj(string node, string obj, int permanent = 0)
{
	_fwCU_getNodeNode(node);
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	fwUi_getCUNodeNames(node, obj);
	if(permanent)
		permanent = -1;
	fwUi_disableDevice(node, obj, permanent);
}

//fwCU_takeTree:
/**  Take control of a subtree starting from a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_takeTree(string node, string owner = "")
{
	fwUi_takeTree(node, node, owner);
}

//fwCU_releaseTree:
/**  Release control of a subtree starting from a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_releaseTree(string node, string owner = "")
{
	fwUi_releaseTree(node, node, owner);
}

fwCU_returnTree(string node, string owner = "")
{
	fwUi_releaseTree(node, node, owner);
}

//fwCU_releaseFullTree:
/**  Release control of a subtree recursively starting from a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_releaseFullTree(string node, string owner = "")
{
	fwUi_releaseTreeAll(node, node, owner);
}

//fwCU_shareTree:
/**  Set a subtree starting from a certain Control Unit into shared mode.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_shareTree(string node, string owner = "")
{
	fwUi_shareTree(node, node, owner);
}

//fwCU_exclusiveTree:
/**  Set a subtree starting from a certain Control Unit into exclusive mode.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_exclusiveTree(string node, string owner = "")
{
	fwUi_exclusiveTree(node, node, owner);
}

//fwCU_excludeTree:
/**  Exclude a subtree from a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param obj: The top object of the subtree to exclude
      @param id: optionally The owner, otherwise the Manager id is used
      @param lockOut: optionally A LockOut flag (default = exclude only)
*/

fwCU_excludeTree(string node, string obj, string owner = "", int lockOut = 0)
{
	string obj1;

	if(!fwFsm_isAssociated(obj))
		obj1 = obj+"::"+obj;
	fwUi_excludeTree(node, obj1, owner, 1, lockOut);
}

fwCU_excludeTreePerm(string node, string obj, string owner = "", int lockOut = 0)
{
	string obj1;

	if(!fwFsm_isAssociated(obj))
		obj1 = obj+"::"+obj;
	fwUi_excludeTreePerm(node, obj1, owner, 1, lockOut);
}

//fwCU_excludeFullTree:
/**  Exclude a subtree recursively from a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param obj: The top object of the subtree to exclude
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_excludeFullTree(string node, string obj, string owner = "")
{
	string obj1;

	if(!fwFsm_isAssociated(obj))
		obj1 = obj+"::"+obj;
	fwUi_excludeTreeAll(node, obj1, owner);
}

//fwCU_includeTree:
/**  Include a subtree into a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param obj: The top object of the subtree to include
      @param id: optionally The owner, otherwise the Manager id is used
      @param unlockOut: optionally A UnlockOut flag (default = don't unlockOut)
*/

fwCU_includeTree(string node, string obj, string owner = "", int unlockOut = 0)
{
	string obj1;

	if(!fwFsm_isAssociated(obj))
		obj1 = obj+"::"+obj;
	fwUi_includeTree(node, obj1, owner, 1, 1, unlockOut);
}

//fwCU_delegateTree:
/**  Set a subtree of a certain Control Unit in Manual mode (no commands sent).

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param obj: The top object of the subtree to set to manual
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_delegateTree(string node, string obj, string owner = "")
{
	string obj1;

	if(!fwFsm_isAssociated(obj))
		obj1 = obj+"::"+obj;
	fwUi_delegateTree(node, obj1, owner);
}

//fwCU_ignoreTree:
/**  Ignore the states of a subtree of a certain Control Unit.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param obj: The top object of the subtree to ignore
      @param id: optionally The owner, otherwise the Manager id is used
*/

fwCU_ignoreTree(string node, string obj, string owner = "")
{
	string obj1;

	if(!fwFsm_isAssociated(obj))
		obj1 = obj+"::"+obj;
	fwUi_ignoreTree(node, obj1, owner);
}

//fwCU_getChildren:
/**  Get the list of children of this Control Unit or Logical Unit.
Returns the list of children and their node types for a given node in the FSM hierarchy.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param children_types: Returns the type of each child: 1 = CU, 2 = DU, 0 = LU/Obj
      @param node: The node name. Can be <CU_name> or <LU_name> or <CU_name>::<LU_name> (in case of ambiguity)
      @return The list of children
*/
dyn_string fwCU_getChildren(dyn_int &children_types, string node, string lunit = "")
{
dyn_string children;
string domain, obj;
int i;

	if(lunit == "")
	{
		lunit = _fwCU_getNodeObj(node);
	}
	else
	{
		DebugN("fwCU_getChildren - The 3rd parameter (lunit) is obsolete, please consult the documentation");
		fwUi_getCUNodeNames(node, lunit);
	}
	children = fwFsm_getObjChildren(node, lunit, children_types);
 	for (i = 1; i <= dynlen(children); i++)
	{
		if(fwFsm_isAssociated(children[i]))
		{
			domain = fwFsm_getAssociatedDomain(children[i]);
			obj = fwFsm_getAssociatedObj(children[i]);
			if(domain == obj)
 				children[i] = domain;
		}
	}
	return children;
}

//fwCU_getParent:
/**  Get the Parent of this Control Unit, Logical Unit Object or Device Unit.
Returns the Parent and its node types for a given node in the FSM hierarchy.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param type: Returns the type of the parent: 1 = CU, 0 = LU
      @param node: The node name. Can be <CU_name> or <LU_name> or <CU_name>::<LU_name> or <CU_name>::<DU_name>
      @return The Parent or an empty string if no parent (top level node)
*/
string fwCU_getParent(int &type, string node)
{

	string obj, parent;

	obj = _fwCU_getNodeObj(node);
//	if((node != obj) && (fwFsm_isCU(node, obj)))
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	fwUi_getNodeParent(node, obj, parent, type);
	return parent;
}

//fwCU_getIncludedChildren:
/**  Get the list of Included/Enabled children of this Control Unit or Logical Unit.
Returns the list of Included/Enabled children and their node types for a given node in the FSM hierarchy.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param children_types: Returns the type of each child: 1 = CU, 2 = DU, 0 = LU/Obj
      @param node: The node name. Can be <CU_name> or <LU_name> or <CU_name>::<LU_name> (in case of ambiguity)
      @return The list of Included/Enabled children
*/
dyn_string fwCU_getIncludedChildren(dyn_int &children_types, string node, string lunit = "")
{
dyn_string children;
string domain, obj;
int i;

	if(lunit == "")
	{
		lunit = _fwCU_getNodeObj(node);
	}
	else
	{
		DebugN("fwCU_getChildren - The 3rd parameter (lunit) is obsolete, please consult the documentation");
		fwUi_getCUNodeNames(node, lunit);
	}
	children_types = fwUi_getIncludedChildren(node, lunit, children);
	return children;
}

//fwCU_getIncludedTreeDevices:
/**  Get the list of included and enabled devices in a subtree.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit/logical unit name, top of subtree)
*/

dyn_string fwCU_getIncludedTreeDevices(string node, string lunit = "")
{
	dyn_string devs;

	if(lunit == "")
	{
		lunit = _fwCU_getNodeObj(node);
	}
	else
	{
		DebugN("fwCU_getIncludedTreeDevices - The 2nd parameter (lunit) is obsolete, please consult the documentation");
		fwUi_getCUNodeNames(node, lunit);
	}
	devs = fwUi_getIncludedTreeDevices(node, lunit);
	return devs;
}

//fwCU_getType:
/**  Get the FSM Type of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param type: returns the type of the Control Unit
*/
fwCU_getType(string node, string &type)
{
	string obj;

	obj = _fwCU_getNodeObj(node);
	if((node != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	fwFsm_getObjectType(node+"::"+obj, type);
}


fwCU_getObjType(string node, string obj, string &type)
{

	DebugN("fwCU_getObjType - This function is obsolete, replaced by fwCU_getType, please consult the documentation");
	if(dpExists(obj))
		fwCU_getDevName(node, obj, obj);
	fwUi_getCUNodeNames(node, obj);
	fwFsm_getObjectType(node+"::"+obj, type);
}

//fwCU_getDp:
/**  Get the FSM internal datapoint name of a Control Unit, Logical Unit, Device Unit or Internal Object.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name optionally followed by "::" + the name of the Object/Device
      @param dp: returns the internal CU/LU/object/device data point name
      @param item: (optional) an FSM property. Can be: "STATE","COMMAND" or "EXECUTING"
*/
fwCU_getDp(string node, string &dp, string item = "")
{
	string obj;
  string ref, node1, local_sys, sys;
  dyn_string refs, syss;
  int index;

//DebugTN("fwCU_getDp",node);
  node1 = node;
	obj = _fwCU_getNodeObj(node);
  if((node != obj) && (fwFsm_isDomain(obj)))
  	obj = obj+"::"+obj;
	fwUi_getObjFSMDp(node, obj, dp);
//DebugTN("fwCU_getDp1",node, obj, dp);

	if(item == "STATE")
		dp += ".fsm.currentState";
	else if(item == "COMMAND")
		dp += ".fsm.sendCommand";
	else if(item == "EXECUTING")
		dp += ".fsm.executingAction";
}

//fwCU_getDevDp:
/**  Get the Datapoint name of a Device Unit from its Object name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The CU/LU node name followed by "::" + the name of the Device
      @param dp: returns the Device Datapoint name
*/
fwCU_getDevDp(string node, string &dp)
{
	string obj;

	obj = _fwCU_getNodeObj(node);
	fwUi_getObjDp(node, obj, dp);
}

fwCU_getObjDp(string node, string obj, string &devdp)
{
	string sys;

	DebugN("fwCU_getObjDp - This function is obsolete, replaced by fwCU_getDevDp, please consult the documentation");
	fwUi_getDomainSys(node, sys);
	devdp = fwFsm_getPhysicalDeviceName(sys+obj);
	devdp = sys+devdp;
}

//fwCU_getDevName:
/**  Get the name of a Device Unit (from its Datapoint name) inside a Control Unit .

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (control unit name)
      @param devdp: The device data point name
      @param obj: returns the obj name (possibly logical name)
*/
fwCU_getDevName(string node, string devdp, string &obj)
{
	obj = fwDU_checkLogicalName(node, devdp);
}

fwCU_getObjName(string node, string devdp, string &obj)
{
	DebugN("fwCU_getObjName - This function is obsolete, replaced by fwCU_getDevName, please consult the documentation");
	obj = fwDU_checkLogicalName(node, devdp);
}

