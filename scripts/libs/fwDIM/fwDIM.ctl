#uses "fwDIM/fwDimCacheHash.ctl"

//int FwDimSubscribeBusy = 0;

/**@name LIBRARY: fwDim:

library of functions to add/remove DIM Services/Commands/RPCs

modifications: none

Note: For all functions in the library
      if no config is given (empty string) the default Config "fwDimDefaultConfig" will be used.
      PVSS00dim will use the default config if it doesn't receive one as a parameter ( in -dim_config_dp)

WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions
                in a working function called by a PVSS (dpConnect) or in a calling function

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@version creation: 27/07/2001
@author C. Gaspar



*/
//@{
//--------------------------------------------------------------------------------
//fwDim_createConfig:
/**  Create a configuration DP for publishing or subscribing (DIM Services or Commands).


Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param dp : data point name for this config to be given to PVSS00dim at startup
*/

fwDim_createConfig(string &dp)
{
	string config;
	dyn_string pars, parsold;

	if(!globalExists("FwDimSubscribeBusy"))
	{
		addGlobal("FwDimSubscribeBusy", INT_VAR);
		FwDimSubscribeBusy = 0;
	}
	if(dp == "")
		config = "fwDimDefaultConfig";
	else
		config = dp;
	if(!dpExists(config))
	{
		dpCreate(config,"_FwDimConfig");
		pars[1] = config+".ApiInfo.manNum:_online.._value";
		pars[2] = "_Connections.Device.ManNums:_online.._value";
		dpSet(config+".ApiInfo.manState:_dp_fct.._type", DPCONFIG_DP_FUNCTION,
		      config+".ApiInfo.manState:_dp_fct.._global",makeDynString(),
		      config+".ApiInfo.manState:_dp_fct.._param",pars,
		      config+".ApiInfo.manState:_dp_fct.._fct","dynContains(p2, p1)");
	}
/*
	else
	{
		pars[1] = config+".ApiInfo.manNum:_online.._value";
		pars[2] = "_Connections.Device.ManNums:_online.._value";
		dpSet(config+".ApiInfo.manState:_dp_fct.._param",pars);
	}
*/
	dp = config;
}

//fwDim_deleteConfig:
/**  Delete a configuration DP.


Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param dp : data point name of this config
*/

fwDim_deleteConfig(string dp)
{
	string config;
	dyn_string pars;

	if(dp == "")
		config = "fwDimDefaultConfig";
	else
		config = dp;
	if(dpExists(config))
	{
		dpSetWait(config+".ApiInfo.manState:_dp_fct.._type", DPCONFIG_NONE);
		dpDelete(config);
	}
}

//fwDim_copyConfig:
/**  Copy a configuration DP.


Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param fromdp : data point name of the config to be copied
      @param todp : data point name of new config
*/

fwDim_copyConfig(string fromdp, string todp)
{
	string fromconf, toconf;
	dyn_string services;
	int rate, error;

	if(fromdp == "")
		fromconf = "fwDimDefaultConfig";
	else
		fromconf = fromdp;
	fwDim_createConfig(todp);
	toconf = todp;
	dpCopyOriginal(fromconf, toconf, error);
/*
	dpGet(fromconf+".clientServices:_online.._value", services);
	dpSet(toconf+".clientServices:_original.._value", services);
	dpGet(fromconf+".clientCommands:_online.._value", services);
	dpSet(toconf+".clientCommands:_original.._value", services);
	dpGet(fromconf+".serverServices:_online.._value", services);
	dpSet(toconf+".serverServices:_original.._value", services);
	dpGet(fromconf+".serverCommands:_online.._value", services);
	dpSet(toconf+".serverCommands:_original.._value", services);
	dpGet(fromconf+".ApiParams.dispatchRate:_online.._value", rate);
	dpSet(toconf+".ApiParams.dispatchRate:_original.._value", rate);
	dpGet(fromconf+".ApiParams.aliveRate:_online.._value", rate);
	dpSet(toconf+".ApiParams.aliveRate:_original.._value", rate);
	dpGet(fromconf+".ApiParams.dimDnsNode:_online.._value", rate);
	dpSet(toconf+".ApiParams.dimDnsNode:_original.._value", rate);
	dpGet(fromconf+".ApiInfo.manNum:_online.._value", rate);
	dpSet(toconf+".ApiInfo.manNum:_original.._value", rate);
*/
}

int fwDim_subscribeAny(string config, string type, dyn_string dps, dyn_string new_lines, int save_now, int secs = 1)
{
string conf;
int i;
dyn_string lines_to_add;
int cacheId;

//	dyn_string dp_configs, dp_configs1;
//	dyn_anytype dp_config_values, dp_config_values1;

	conf = config;
	fwDim_createConfig(conf);

	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;
//DebugTN("Creating cache");
	cacheId = fwDim_cacheCreate(conf, type, 1);
	for(i = 1; i <= dynlen(new_lines); i++)
	{
		if(dps[i] == "")
			continue;
		if(!fwDim_cacheFind(cacheId, dps[i], new_lines[i]))
		{
			dynAppend(lines_to_add, new_lines[i]);
//			_fwDim_prepDpConfig(dp_names[i], conf, dp_configs, dp_config_values,
//				dp_configs1, dp_config_values1);
		}
	}
//DebugTN("Cache add & save");
	if(dynlen(lines_to_add))
	{
		fwDim_cacheAdd(cacheId, lines_to_add);
//		fwDim_cacheSave(cacheId, save_now, secs);
	}
	fwDim_cacheSave(cacheId, save_now, secs);
//	if(dynlen(dp_configs))
//	{
//time t1;
//t1 = getCurrentTime();
//DebugN(formatTime("%c",t1)+" - Setting "+dynlen(dp_configs)+" items");
//		dpSetWait(dp_configs, dp_config_values);
//		dpSetWait(dp_configs1, dp_config_values1);
//	}
	FwDimSubscribeBusy = 0;
	return(dynlen(lines_to_add));
}

fwDim_unSubscribeAny(string config, string type, int itemIndex, string pattern, int save_now, int secs = 1)
{
dyn_dyn_string all_items;
string conf;
int i, n_lines;
int cacheId;
dyn_int indexList;
dyn_bool res;

	conf = config;
	fwDim_createConfig(conf);

	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	cacheId = fwDim_cacheCreate(conf, type, 0);

	fwDim_cacheGetItems(cacheId, all_items);
/*
	for(i = 1; i <= dynlen(all_items[itemIndex]); i++)
	{
		if(patternMatch(pattern, all_items[itemIndex][i]))
		{
			dynAppend(indexList, i);
//			fwDim_cacheRemove(cacheId, i);
//			_fwDim_unSetDpConfig(items[1]);
		}
	}
*/
	res = patternMatch(pattern, all_items[itemIndex]);
	for(i = 1; i <= dynlen(res); i++)
	{
		if(res[i])
			dynAppend(indexList, i);
	}
	fwDim_cacheRemoveMany(cacheId, indexList);
//DebugTN("cacheSave", pattern, save_now, secs, dynlen(all_items[itemIndex]));
	fwDim_cacheSave(cacheId, save_now, secs);

	FwDimSubscribeBusy = 0;
}

fwDim_unSubscribeAnyNoWild(string config, string type, int itemIndex, dyn_string dps, int save_now, int secs = 1)
{
dyn_dyn_string all_items;
string conf;
int i, n_lines;
int cacheId;
dyn_int indexList;
dyn_bool res;
int index1;
int ret;
dyn_string lines;

	conf = config;
	fwDim_createConfig(conf);

	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

//DebugTN("Unsubscribe", config, type);
	cacheId = fwDim_cacheCreate(conf, type, 1);

	for(i = 1; i <= dynlen(dps); i++)
	{
		ret = fwDim_cacheFind(cacheId, dps[i], lines[i]);
		if(ret)
			dynAppend(indexList, ret);
	}
	fwDim_cacheRemoveMany(cacheId, indexList);

//DebugTN("cacheSave", dps, save_now, secs, dynlen(all_items[itemIndex]));
	fwDim_cacheSave(cacheId, save_now, secs);

	FwDimSubscribeBusy = 0;
}

fwDim_getSubscribedAny(string config, string type, dyn_dyn_string &all_items)
{
dyn_string lines, items;
int i, j, hashIndex;
string conf;
int cacheId;

	conf = config;
	fwDim_createConfig(conf);

	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	cacheId = fwDim_cacheCreate(conf, type, 0);
	fwDim_cacheGetItems(cacheId, all_items);
	FwDimSubscribeBusy = 0;
}

fwDim_getSubscribedAnyParameter(string config, string type, string service, int servIndex, string &par)
{
dyn_dyn_string all_items;
int i, j, hashIndex;
string conf;
int cacheId;
dyn_dyn_string res;
int index;

	par = "";
	conf = config;
	fwDim_createConfig(conf);

	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	cacheId = fwDim_cacheCreate(conf, type, 0);
	fwDim_cacheGetItems(cacheId, all_items);
	if(dynlen(all_items[servIndex+1]))
	{
		for(i = 1; i <= dynlen(all_items[servIndex]); i++)
		{
			if((index = dynContains(all_items[servIndex], service)))
			par = all_items[servIndex+1][index];
		}
	}

	FwDimSubscribeBusy = 0;
}

//fwDim_subscribeService:
/**  Subscribe to a new DIM Service.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this service be added
      @param service_name : DIM Service Name
      @param dp_name : Data point (or DP element) that receives the DIM service contents
      @param default_value (optional): The default value if the service is not available or empty string (default)
      @param timeout (optional): The time interval in seconds for periodic reception - 0 for on change (default)
      @param flag (optional): quality and time-stamp flag - 1 for quality (default), 2 for time-stamp, 3 for both
      @param immediate_update (optional): 1 means update value when first connected (default)
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeService(string config, string service_name, string dp_name,
string defaultv, int timeout = 0, int flag = 1, int immediate_update = 1, int save_now = 0)
{
	string new_line;

	new_line = dp_name+", "+service_name+", "+defaultv+", "+timeout+", "+flag+", "+immediate_update;
	return fwDim_subscribeAny(config,"clientServices", makeDynString(dp_name), makeDynString(new_line), save_now);
}


//fwDim_subscribeServices:
/**  Subscribe to several new DIM Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should these services be added
      @param service_names : List of DIM Service Names
      @param dp_names : Data points (or DP elements) that receives the DIM service contents
      @param default_values (optional): The default values if the service is not available or empty string (default)
      @param timeouts (optional): The time intervals in seconds for periodic reception - 0 for on change (default)
      @param flags (optional): quality and time-stamp flags - 1 for quality (default), 2 for time-stamp, 3 for both
      @param immediate_updates (optional): 1 means update value when first connected (default)
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeServices(string config, dyn_string service_names, dyn_string dp_names,
	dyn_string defaults = makeDynString(),
	dyn_int timeouts= makeDynInt(), dyn_int flags = makeDynInt(),
	dyn_int immediate_updates = makeDynInt(),
	int save_now = 0, int secs = 1)
{
	dyn_string new_lines;
	int i;
	string defaultv;
	int timeout, flag, update;
	string new_line;

	for(i = 1; i <= dynlen(service_names); i++)
	{
		if(!dynlen(defaults))
			defaultv = "";
		else
			defaultv = defaults[i];
		if(!dynlen(timeouts))
			timeout = 0;
		else
			timeout = timeouts[i];
		if(!dynlen(flags))
			flag = 1;
		else
			flag = flags[i];
		if(!dynlen(immediate_updates))
			update = 1;
		else
			update = immediate_updates[i];

		new_line = dp_names[i]+", "+service_names[i]+", "+
			defaultv+", "+timeout+", "+flag+", "+update;

		dynAppend(new_lines, new_line);
	}
	return fwDim_subscribeAny(config,"clientServices", dp_names, new_lines, save_now, secs);
}


//fwDim_subscribeCommand:
/**  Subscribe to a new DIM Command.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this command be added
      @param service_name : DIM Command Name
      @param dp_name : Data point (or DP element) that sends the DIM command when modified
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeCommand(string config, string service_name, string dp_name, int save_now = 0,
	string format = "")
{
	string new_line;

	new_line = dp_name+", "+service_name;
	if(format != "")
		new_line += ", 0, "+format;
	return fwDim_subscribeAny(config,"clientCommands", makeDynString(dp_name), makeDynString(new_line), save_now);
}


//fwDim_subscribeCommands:
/**  Subscribe to several new DIM Commands.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should these services be added
      @param service_names : List of DIM Command Names
      @param dp_names : Data points (or DP elements) that send the DIM commands when modified
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeCommands(string config, dyn_string service_names, dyn_string dp_names, int save_now = 0,
	dyn_string formats = makeDynString(), int secs = 1)
{
	dyn_string new_lines;
	int i;

	for(i = 1; i <= dynlen(service_names); i++)
	{
		new_lines[i] = dp_names[i]+", "+service_names[i];
		if(dynlen(formats) >= i)
			new_lines[i] += ", 0, "+formats[i];
	}
	return fwDim_subscribeAny(config,"clientCommands", dp_names, new_lines, save_now, secs);
}


//fwDim_subscribeMultiplexedCommand:
/**  Subscribe to a new DIM Command: Instead of sending the whole structure, each item is
     sent as an ascii string containing the DP item name and the new value.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this command be added
      @param service_name : DIM Command Name
      @param dp_name : Data point (or DP element) that sends the DIM command when modified
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeMultiplexedCommand(string config, string service_name, string dp_name, int save_now = 0)
{
	string new_line;

	new_line = dp_name+", "+service_name+", 1";
	return fwDim_subscribeAny(config,"clientCommands", makeDynString(dp_name), makeDynString(new_line), save_now);
}


//fwDim_subscribeMultiplexedCommands:
/**  Subscribe to several new DIM Commands. For each command, instead of sending the whole structure,
     each item is sent as an ascii string containing the DP item name and the new value.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should these services be added
      @param service_names : List of DIM Command Names
      @param dp_names : Data points (or DP elements) that send the DIM commands when modified
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeMultiplexedCommands(string config, dyn_string service_names, dyn_string dp_names, int save_now = 0)
{
	dyn_string new_lines;
	int i;

	for(i = 1; i <= dynlen(service_names); i++)
	{
		new_lines[i] = dp_names[i]+", "+service_names[i]+", 1";
	}
	return fwDim_subscribeAny(config,"clientCommands", dp_names, new_lines, save_now);
}

//fwDim_subscribeFileCommand:
/**  Subscribe to a new DIM Command: The last (or only) "string" element of a structure must be a file
name. At run time the file will be read and its contents sent in the DIM command (instead of the file name)

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this command be added
      @param service_name : DIM Command Name
      @param dp_name : Data point (or DP element) that sends the DIM command when modified
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeFileCommand(string config, string service_name, string dp_name, int save_now = 0)
{
	string new_line;

	new_line = dp_name+", "+service_name+", -1";
	return fwDim_subscribeAny(config,"clientCommands", makeDynString(dp_name), makeDynString(new_line), save_now);
}

//fwDim_subscribeRPC:
/**  Subscribe to a new DIM RPC.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this command be added
      @param service_name : DIM RPC Service Name
      @param dp_name_out : Data point (or DP element) that sends the DIM command part of the RPC when modified
      @param dp_name_in : Data point (or DP element) that receives the DIM service contents part of the RPC
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_subscribeRPC(string config, string service_name, string dp_name_out, string dp_name_in, int save_now = 0)
{
	string new_line;

	new_line = dp_name_out+", "+dp_name_in+", "+service_name;
	return fwDim_subscribeAny(config,"clientRPCs", makeDynString(dp_name_out), makeDynString(new_line), save_now);
}

//fwDim_publishService:
/**  Publish a new DIM Service.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this service be added
      @param service_name : DIM Service Name
      @param dp_name : Data point (or DP element) that contains the DIM service contents
      @param format : (Optional) A DIM Format string for the Service
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishService(string config, string service_name, string dp_name, string format = "", int save_now = 0)
{
	string new_line;

	if(format != "")
		new_line = dp_name+", "+service_name+", "+format;
	else
		new_line = dp_name+", "+service_name;
	return fwDim_subscribeAny(config,"serverServices", makeDynString(dp_name), makeDynString(new_line), save_now);
}

//fwDim_publishServices:
/**  Publish several new DIM Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should these services be added
      @param service_names : List of DIM Service Names
      @param dp_names : Data points (or DP elements) that contain the DIM service contents
      @param formats : (Optional) A list of DIM Format strings for the Services
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishServices(string config, dyn_string service_names, dyn_string dp_names,
	dyn_string formats = makeDynString(), int save_now = 0)
{
	dyn_string new_lines;
	int i;

	for(i = 1; i <= dynlen(service_names); i++)
	{
		new_lines[i] = dp_names[i]+", "+service_names[i];
		if(dynlen(formats))
		{
			if(formats[i] != "")
				new_lines[i] += ", "+formats[i];
		}
	}
	return fwDim_subscribeAny(config,"serverServices", dp_names, new_lines, save_now);
}

//fwDim_publishAlarmService:
/**  Publish a new DIM Service containing the alarm state of a datapoint element.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this service be added
      @param service_name : DIM Service Name ("/ALARM_STATE" will be appended)
      @param dp_name : DP element for which to send the alarm information
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishAlarmService(string config, string service_name, string dp_name, int save_now = 0)
{
	string new_line;
	string new_service, new_dp;
	string format;
	int type;

	dpGet(dp_name+":_alert_hdl.._type", type);
	if(type == DPCONFIG_NONE)
	{
		DebugN(dp_name+" does not have an alert config, discarding...");
		return 0;
	}
	new_service = service_name+"/ALARM_INFO";
	new_dp = dp_name+":_alert_hdl.._active;"+
		 dp_name+":_alert_hdl.._act_state;"+
		 dp_name+":_alert_hdl.._act_prior;"+
		 dp_name+":_alert_hdl.._act_text";
	format = "C:1;I:1;C:1;C";

	new_line = new_dp+", "+new_service+", "+format;

	return fwDim_subscribeAny(config,"serverServices", makeDynString(new_dp), makeDynString(new_line), save_now);
}

//fwDim_publishAlarmServices:
/**  Publish several new DIM Services containing the alarm states of datapoint elements.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should these services be added
      @param service_names : List of DIM Service Names ("/ALARM_STATE" will be appended)
      @param dp_names : DP elements for which to send alarm information
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishAlarmServices(string config, dyn_string service_names, dyn_string dp_names, int save_now = 0)
{
	dyn_string new_lines, new_dps;
	int i, type;
	string new_service, new_dp, format, new_line;

	format = "C:1;I:1;C:1;C";

	for(i = 1; i <= dynlen(service_names); i++)
	{
		dpGet(dp_names[i]+":_alert_hdl.._type", type);
		if(type == DPCONFIG_NONE)
		{
			DebugN(dp_names[i]+" does not have an alert config, discarding...");
		}
		else
		{
			new_service = service_names[i]+"/ALARM_INFO";
			new_dp = dp_names[i]+":_alert_hdl.._active;"+
				 dp_names[i]+":_alert_hdl.._act_state;"+
				 dp_names[i]+":_alert_hdl.._act_prior;"+
				 dp_names[i]+":_alert_hdl.._act_text";
			new_line = new_dp+", "+new_service+", "+format;
			dynAppend(new_dps, new_dp);
			dynAppend(new_lines, new_line);
		}
	}
	return fwDim_subscribeAny(config,"serverServices", new_dps, new_lines, save_now);

}

//fwDim_publishCommand:
/**  Publish a new DIM Command.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this command be added
      @param service_name : DIM Command Name
      @param dp_name : Data point (or DP element) that receives the DIM command
      @param format : (Optional) A DIM Format string for the Command
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishCommand(string config, string service_name, string dp_name, string format = "", int save_now = 0)
{
	string new_line;

	if(format != "")
		new_line = dp_name+", "+service_name+", "+format;
	else
		new_line = dp_name+", "+service_name;
	return fwDim_subscribeAny(config,"serverCommands", makeDynString(dp_name), makeDynString(new_line), save_now);
}


//fwDim_publishCommands:
/**  Publish several new DIM Commands.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should these services be added
      @param service_names : List of DIM Command Names
      @param dp_names : Data points (or DP elements) that receive the DIM commands
      @param formats : (Optional) A list of DIM Format strings for the Commands
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishCommands(string config, dyn_string service_names, dyn_string dp_names,
	dyn_string formats = makeDynString(), int save_now = 0)
{
	dyn_string new_lines;
	int i;

	for(i = 1; i <= dynlen(service_names); i++)
	{
		new_lines[i] = dp_names[i]+", "+service_names[i];
		if(dynlen(formats))
		{
			if(formats[i] != "")
				new_lines[i] += ", "+formats[i];
		}
	}
	return fwDim_subscribeAny(config,"serverCommands", dp_names, new_lines, save_now);
}


//fwDim_publishRPC:
/**  Publish a new DIM RPC.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should this command be added
      @param service_name : DIM RPC Service Name
      @param dp_name_in : Data point (or DP element) that receives the DIM command part of the RPC
      @param dp_name_out : Data point (or DP element) that updates the DIM service part of the RPC
      @param format : (Optional) DIM Format strings for the input and output data, separated by "|"
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

int fwDim_publishRPC(string config, string service_name, string dp_name_in, string dp_name_out,
	string format = "", int save_now = 0)
{
	string new_line;

	new_line = dp_name_in+", "+dp_name_out+", "+service_name;
	if(format!= "")
		new_line += ", "+format;
	return fwDim_subscribeAny(config,"serverRPCs", makeDynString(dp_name_in), makeDynString(new_line), save_now);
}

//fwDim_getSubscribedServices:
/**  find subscribed DIM Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should be used
      @param service_names : List of DIM Service Names
      @param dp_names : Data points (or DP elements) that receives the DIM service contents
      @param defaults : The default values if the service is not available (empty string for no default)
      @param timeouts : The time intervals in seconds for periodic reception ( 0 for on change only)
      @param flags : quality and time-stamp flags (0 for no quality and no time-stamp)
      @param immediate_updates : 1 means update value when first connected
*/


fwDim_getSubscribedServices(string config, dyn_string &service_names, dyn_string &dp_names, dyn_string &defaults,
	dyn_int &timeouts, dyn_int &flags, dyn_int &immediate_updates)
{
dyn_dyn_string all_items;
int i;

	fwDim_getSubscribedAny(config, "clientServices", all_items);
	dp_names =  all_items[1];
	service_names = all_items[2];
	defaults = all_items[3];
	timeouts = all_items[4];
	flags = all_items[5];
	if(dynlen(all_items[6]))
	{
		immediate_updates = all_items[6];
	}
	else
	{
		dynClear(immediate_updates);
		for(i = 1; i <= dynlen(dp_names); i++)
		{
			immediate_updates[i] = 1;
		}
	}
}


//fwDim_getSubscribedCommands:
/**  find subscribed DIM Commands.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should be used
      @param service_names : List of DIM Command Names
      @param dp_names : Data points (or DP elements) that send the DIM Commands
      @param flags: Multiplexed flags for each command
*/

fwDim_getSubscribedCommands(string config, dyn_string &service_names, dyn_string &dp_names, dyn_int &flags)
{
dyn_dyn_string all_items;
int i;

	fwDim_getSubscribedAny(config, "clientCommands", all_items);
	dp_names = all_items[1];
	service_names = all_items[2];
	if(dynlen(all_items[3]))
	{
		flags = all_items[3];
	}
	else
	{
		dynClear(flags);
		for(i = 1; i <= dynlen(dp_names); i++)
		{
			flags[i] = 0;
		}
	}
}

//fwDim_getSubscribedRPCs:
/**  find subscribed DIM RPCs.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should be used
      @param service_names : List of DIM RPC Names
      @param dp_names_out : Data points (or DP elements) that send the DIM Commands associated to the RPC
      @param dp_names_in : Data points (or DP elements) that receive the DIM Services associated to the RPC
*/

fwDim_getSubscribedRPCs(string config, dyn_string &service_names, dyn_string &dp_names_out,
	dyn_string &dp_names_in)
{
dyn_dyn_string all_items;
int i;

	fwDim_getSubscribedAny(config, "clientRPCs", all_items);
	dp_names_out = all_items[1];
	dp_names_in = all_items[2];
	service_names = all_items[3];
}


//fwDim_getPublishedServices:
/**  find published DIM Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should be used
      @param service_names : List of DIM Service Names
      @param dp_names : Data points (or DP elements) that contain the DIM service contents
*/

fwDim_getPublishedServices(string config, dyn_string &service_names, dyn_string &dp_names)
{
dyn_dyn_string all_items;
int i;

	fwDim_getSubscribedAny(config, "serverServices", all_items);
	dp_names = all_items[1];
	service_names = all_items[2];
}

//fwDim_getPublishedServiceFormat:
/**  get the format of a published DIM Service.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param service_name : DIM Service Name
      @param format : DIM format string
*/

fwDim_getPublishedServiceFormat(string config, string service_name, string &format)
{
	fwDim_getSubscribedAnyParameter(config, "serverServices", service_name, 2, format);
}

//fwDim_getPublishedCommands:
/**  find published DIM Commands.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param service_names : List of DIM Command Names
      @param dp_names : Data points (or DP elements) that receive the DIM Commands
*/

fwDim_getPublishedCommands(string config, dyn_string &service_names, dyn_string &dp_names)
{
dyn_dyn_string all_items;
int i;

	fwDim_getSubscribedAny(config, "serverCommands", all_items);
	dp_names = all_items[1];
	service_names = all_items[2];
}

//fwDim_getPublishedCommandFormat:
/**  get the format of a published DIM Command.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param service_name : DIM Command Name
      @param format : DIM format string
*/

fwDim_getPublishedCommandFormat(string config, string service_name, string &format)
{
	fwDim_getSubscribedAnyParameter(config, "serverCommands", service_name, 2, format);
}

//fwDim_getPublishedRPCs:
/**  find published DIM RPCs.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : To which config should be used
      @param service_names : List of DIM RPC Names
      @param dp_names_in : Data points (or DP elements) that receive the DIM Commands associated to the RPC
      @param dp_names_ont : Data points (or DP elements) that update the DIM Services associated to the RPC
*/

fwDim_getPublishedRPCs(string config, dyn_string &service_names, dyn_string &dp_names_in,
	dyn_string &dp_names_out)
{
dyn_dyn_string all_items;
int i;

	fwDim_getSubscribedAny(config, "serverRPCs", all_items);
	dp_names_in = all_items[1];
	dp_names_out = all_items[2];
	service_names = all_items[3];
}

//fwDim_getPublishedRPCFormat:
/**  get the format of a published DIM RPC.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param service_name : DIM Command Name
      @param format : DIM format string
*/
fwDim_getPublishedRPCFormat(string config, string service_name, string &format)
{
	fwDim_getSubscribedAnyParameter(config, "serverRPCs", service_name, 3, format);
}


int DnsReceived;

receive_it(string dp, dyn_string list)
{
	DnsReceived = 1;
}

//fwDim_findServices:
/**  wildcard find existing services (available in DNS).

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param search_string : wildcard search string
      @param service_names : List of DIM Services
      @param formats : List of DIM format strings
*/
int fwDim_findServices(string config, string search_string, dyn_string &service_names, dyn_string &formats)
{
	dyn_string services;
	dyn_string items;
	int i, timeout;
	string conf;
  bool state;

	conf = config;
	fwDim_createConfig(conf);

  dpGet(conf+".ApiInfo.manState", state);
  if(!state)
    return 0;
	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	DnsReceived = 0;
	fwDim_lock(conf+".DnsInfo.searchString");

	dpSetWait(conf+".DnsInfo.serviceList:_original.._value",
		services);
	dpConnect("receive_it",0,conf+".DnsInfo.serviceList:_online.._value");
	dpSetWait(conf+".DnsInfo.searchString:_original.._value",
		search_string);
	timeout = 200;
	while(!DnsReceived)
	{
		delay(0,100);
		timeout--;
		if(!timeout)
			break;
	}
  if(!timeout)
  {
	  dpDisconnect("receive_it",conf+".DnsInfo.serviceList:_online.._value");
	  fwDim_unlock(conf+".DnsInfo.searchString");
	  FwDimSubscribeBusy = 0;
    return 0;
  }
	dynClear(service_names);
	dynClear(formats);

	dpGet(conf+".DnsInfo.serviceList:_online.._value",
		services);
	for(i = 1; i <= dynlen(services); i++)
	{
		items = strsplit(services[i],"|");
		if(dynlen(items) < 3)
		{
			dynAppend(service_names,items[1]);
			dynAppend(formats,items[2]);
		}
	}
	dpDisconnect("receive_it",conf+".DnsInfo.serviceList:_online.._value");

	fwDim_unlock(conf+".DnsInfo.searchString");

	FwDimSubscribeBusy = 0;
  return 1;
}

//fwDim_findCommands:
/**  wildcard find existing commands (available in DNS).

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param search_string : wildcard search string
      @param service_names : List of DIM Commands
      @param formats : List of DIM format strings
*/


int fwDim_findCommands(string config, string search_string, dyn_string &service_names, dyn_string &formats)
{
	dyn_string services;
	dyn_string items;
	int i, timeout;
	string conf;
  bool state;

	conf = config;
	fwDim_createConfig(conf);

  dpGet(conf+".ApiInfo.manState", state);
  if(!state)
    return 0;

	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	DnsReceived = 0;
	fwDim_lock(conf+".DnsInfo.searchString");

	dpSetWait(conf+".DnsInfo.serviceList:_original.._value",
		services);
	dpConnect("receive_it",0,conf+".DnsInfo.serviceList:_online.._value");
	dpSetWait(conf+".DnsInfo.searchString:_original.._value",
		search_string);
	timeout = 200;
	while(!DnsReceived)
	{
		delay(0,100);
		timeout--;
		if(!timeout)
			break;
	}
  if(!timeout)
    return 0;
	dpGet(conf+".DnsInfo.serviceList:_online.._value",
		services);
	dynClear(service_names);
	dynClear(formats);

	for(i = 1; i <= dynlen(services); i++)
	{
		items = strsplit(services[i],"|");
		if(dynlen(items) == 3)
		{
			if(items[3] == "CMD")
			{
				dynAppend(service_names,items[1]);
				dynAppend(formats,items[2]);
			}
		}
	}
	dpDisconnect("receive_it",conf+".DnsInfo.serviceList:_online.._value");

	fwDim_unlock(conf+".DnsInfo.searchString");

	FwDimSubscribeBusy = 0;
  return 1;
}

//fwDim_findRPCs:
/**  wildcard find existing RPCs (available in DNS).

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param search_string : wildcard search string
      @param service_names : List of DIM RPCs
      @param formats : List of DIM format strings
*/


int fwDim_findRPCs(string config, string search_string, dyn_string &service_names, dyn_string &formats)
{
	dyn_string services;
	dyn_string items;
	int i, timeout;
	string conf;
  bool state;

	conf = config;
	fwDim_createConfig(conf);

  dpGet(conf+".ApiInfo.manState", state);
  if(!state)
    return 0;
	while(FwDimSubscribeBusy)
		delay(0, 100);
	FwDimSubscribeBusy = 1;

	DnsReceived = 0;
	fwDim_lock(conf+".DnsInfo.searchString");

	dpSetWait(conf+".DnsInfo.serviceList:_original.._value",
		services);
	dpConnect("receive_it",0,conf+".DnsInfo.serviceList:_online.._value");
	dpSetWait(conf+".DnsInfo.searchString:_original.._value",
		search_string);
	timeout = 200;
	while(!DnsReceived)
	{
		delay(0,100);
		timeout--;
		if(!timeout)
			break;
	}
  if(!timeout)
    return 0;
	dpGet(conf+".DnsInfo.serviceList:_online.._value",
		services);
	dynClear(service_names);
	dynClear(formats);

	for(i = 1; i <= dynlen(services); i++)
	{
		items = strsplit(services[i],"|");
		if(dynlen(items) == 3)
		{
			if(items[3] == "RPC")
			{
				dynAppend(service_names,items[1]);
				dynAppend(formats,items[2]);
			}
		}
	}
	dpDisconnect("receive_it",conf+".DnsInfo.serviceList:_online.._value");

	fwDim_unlock(conf+".DnsInfo.searchString");

	FwDimSubscribeBusy = 0;
  return 1;
}

//fwDim_unSubscribeServices:
/**  unSubscribe from one or more DIM Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM Service Name, can contain wilddcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unSubscribeServices(string config, string service_name, int save_now = 0, int secs = 1)
{

	fwDim_unSubscribeAny(config, "clientServices", 2, service_name, save_now, secs);
}

//fwDim_unSubscribeCommands:
/**  unSubscribe from one or more DIM Commands.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM Command Name, can contain wildcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unSubscribeCommands(string config, string service_name, int save_now = 0, int secs = 1)
{

	fwDim_unSubscribeAny(config, "clientCommands", 2, service_name, save_now, secs);
}

//fwDim_unSubscribeRPCs:
/**  unSubscribe from one or more DIM RPCs.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM RPC Service Name, can contain wilddcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unSubscribeRPCs(string config, string service_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "clientRPCs", 3, service_name, save_now);
}

//fwDim_unSubscribeServicesByDp:
/**  unSubscribe from one or more DIM Services by DP name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param dp_name : DataPoint Name, can contain wildcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unSubscribeServicesByDp(string config, string dp_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "clientServices", 1, dp_name, save_now);
}

fwDim_unSubscribeServicesNoWild(string config, dyn_string dp_names, int save_now = 0, int secs = 1)
{

	fwDim_unSubscribeAnyNoWild(config, "clientServices", 1, dp_names, save_now, secs);
}

//fwDim_unSubscribeCommandsByDp:
/**  unSubscribe from one or more DIM Commands By DP name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param dp_name : Datapoint Name, can contain wildcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unSubscribeCommandsByDp(string config, string dp_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "clientCommands", 1, dp_name, save_now);
}

fwDim_unSubscribeCommandsNoWild(string config, dyn_string dp_names, int save_now = 0, int secs = 1)
{

	fwDim_unSubscribeAnyNoWild(config, "clientCommands", 1, dp_names, save_now, secs);
}

//fwDim_unPublishServices:
/**  stop publishing one or more DIM Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM Service Name, can contain wilddcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unPublishServices(string config, string service_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "serverServices", 2, service_name, save_now);
}

fwDim_unPublishServicesNoWild(string config, dyn_string dp_names, int save_now = 0)
{

	fwDim_unSubscribeAnyNoWild(config, "serverServices", 2, dp_names, save_now);
}

//fwDim_unPublishAlarmServices:
/**  Stop publishing one or more DIM Services providing DP alarms.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM Service Name, can contain wilddcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unPublishAlarmServices(string config, string service_name, int save_now = 0)
{
string new_service;


	new_service = service_name+"/ALARM_INFO";
	fwDim_unSubscribeAny(config, "serverServices", 2, new_service, save_now);
}

//fwDim_unPublishCommands:
/**  stop publishing one or more DIM Commands.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM Command Name, can contain wildcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unPublishCommands(string config, string service_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "serverCommands", 2, service_name, save_now);
}

//fwDim_unPublishRPCs:
/**  stop publishing one or more DIM RPC Services.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param service_name : DIM RPC Service Name, can contain wilddcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unPublishRPCs(string config, string service_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "serverRPCs", 3, service_name, save_now);
}

//fwDim_unPublishServicesByDp:
/**  stop publishing one or more DIM Services by DP name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param dp_name : DataPoint Name, can contain wildcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unPublishServicesByDp(string config, string dp_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "serverServices", 1, dp_name, save_now);
}

//fwDim_unPublishCommandsByDp:
/**  stop publishing one or more DIM Commands By DP name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : From which config should this service be removed
      @param dp_name : Datapoint Name, can contain wildcards
      @param save_now (optional): 1 means save DimConfig immediately, 0 means optimize, i.e. wait to see if more changes comming (default)
*/

fwDim_unPublishCommandsByDp(string config, string dp_name, int save_now = 0)
{

	fwDim_unSubscribeAny(config, "serverCommands", 1, dp_name, save_now);
}

// fwDim_getPollingRate:
/**  Get PVSS00dim dispatch rate.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param rate : The current polling rate in miliseconds
*/
fwDim_getPollingRate(string config, int &rate)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpGet(conf+".ApiParams.dispatchRate:_online.._value", rate);
	if(rate == 0)
		rate = 100;
}

// fwDim_setPollingRate:
/**  Set PVSS00dim dispatch rate.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param rate : The new polling rate in miliseconds
*/
fwDim_setPollingRate(string config, int rate)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpSet(conf+".ApiParams.dispatchRate:_original.._value", rate);
}

// fwDim_getAliveRate:
/**  Get PVSS00dim watchdog rate.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param rate : The current alive message rate in seconds
*/
fwDim_getAliveRate(string config, int &rate)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpGet(conf+".ApiParams.aliveRate:_online.._value", rate);
	if(rate == 0)
		rate = 10;
}

// fwDim_setAliveRate:
/**  Set PVSS00dim watchdog rate.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param rate : The new alive message rate in seconds
*/
fwDim_setAliveRate(string config, int rate)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpSet(conf+".ApiParams.aliveRate:_original.._value", rate);
}

// fwDim_getDimDnsNode:
/**  Get PVSS00dim's DNS Node name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param node : The DIM_DNS_NODE setup for this config
*/
fwDim_getDimDnsNode(string config, string &node)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpGet(conf+".ApiParams.dimDnsNode:_online.._value", node);
	if(node == "")
	{
		node = getenv("DIM_DNS_NODE");
	}
}

// fwDim_setDimDnsNode:
/**  Set PVSS00dim's DNS Node name.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param node : The DIM_DNS_NODE to setup for this config
*/
fwDim_setDimDnsNode(string config, string node)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpSet(conf+".ApiParams.dimDnsNode:_original.._value", node);
}

// fwDim_getLastUpdateTime:
/**  Get PVSS00dim watchdog.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param last: last update time
*/
fwDim_getLastUpdateTime(string config, time &last)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpGet(conf+".ApiInfo.lastUpdate:_online.._value", last);
}

// fwDim_connectLastUpdateTime:
/**  Connect to PVSS00dim watchdog.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param callback : Callback to be called when watchdog received
*/
fwDim_connectLastUpdateTime(string config, string callback)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	if(callback != "")
	{
		dpConnect(callback,conf+".ApiInfo.lastUpdate:_online.._value");
	}
}

// fwDim_disconnectLastUpdateTime:
/**  Disconnect to PVSS00dim watchdog.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param callback : Callback to be called when watchdog received
*/
fwDim_disconnectLastUpdateTime(string config, string callback)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpDisconnect(callback,conf+".ApiInfo.lastUpdate:_online.._value");
}

// fwDim_getState:
/**  Get PVSS00dim State.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param state: state ( 1 = running, 0 = stopped)
*/
fwDim_getState(string config, int &state)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpGet(conf+".ApiInfo.manState:_online.._value", state);
}

// fwDim_connectState:
/**  Connect PVSS00dim State.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param callback : Callback to be called when state changes
*/
fwDim_connectState(string config, string callback)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	if(callback != "")
	{
		dpConnect(callback,conf+".ApiInfo.manState:_online.._value");
	}
}

// fwDim_disconnectState:
/**  Disconnect PVSS00dim State.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param callback : Callback to be called when state changes
*/
fwDim_disconnectState(string config, string callback)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpDisconnect(callback, conf+".ApiInfo.manState:_online.._value");
}

int fwDim_getFreeNum()
{
dyn_int used;
int i, MAX = 256;

	dpGet("_Connections.Device.ManNums", used);
	for(i = 2; i <= MAX; i++)
	{
		if(!dynContains(used, i))
			return i;
	}
	return 0;
}

// fwDim_getManNum:
/**  Get PVSS00dim Manager Number.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param number: manager number
*/
fwDim_getManNum(string config, int &number)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpGet(conf+".ApiInfo.manNum:_online.._value", number);
}

// fwDim_setManNum:
/**  Set PVSS00dim Manager Number.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param number: manager number
*/
fwDim_setManNum(string config, int number)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpSetWait(conf+".ApiInfo.manNum:_original.._value", number);
}

// fwDim_kill:
/**  Kill PVSS00dim.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
*/
fwDim_kill(string config)
{

	string conf;

	conf = config;
	fwDim_createConfig(conf);
	dpSetWait(conf+".ApiParams.exit:_original.._value", 1);
}

// fwDim_start:
/**  Start PVSS00dim.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param config : Which config should be used
      @param manNum : Which Manager Number
      @param dimDnsNode : Optional: The Node where DIM_DNS is running
*/
fwDim_start(string config, int manNum, string dimDnsNode = "")
{

	string conf, os, path;
/*
	os=getenv("OS");
*/
	if(_UNIX)
		os = "Linux";
	conf = config;
	fwDim_createConfig(conf);
	if (os=="Linux")
		path = getPath(BIN_REL_PATH, "WCCOAdim");
	else
		path = getPath(BIN_REL_PATH, "WCCOAdim.exe");
	if(dimDnsNode == "")
	{
		if (os=="Linux")
			system(path+" -num "+manNum+" -dim_dp_config "+conf+"&");
		else
			system("start /B "+path+" -num "+manNum+" -dim_dp_config "+conf);
	}
	else
	{
		if (os=="Linux")
			system(path+" -num "+manNum+
				" -dim_dp_config "+conf+
				" -dim_dns_node "+dimDnsNode+ "&");
		else
			system("start /B "+path+" -num "+manNum+
				" -dim_dp_config "+conf+
				" -dim_dns_node "+dimDnsNode);
	}
}

_fwDim_setDpConfig(string dp, string config)
{
dyn_string dpes;
int i;

	_fwDim_getDpes(dp, dpes);
	if(!dynlen(dpes))
		dynAppend(dpes,dp);
	for(i = 1; i <= dynlen(dpes); i++)
	{
		dpSet(dpes[i]+":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
		      dpes[i]+":_address.._drv_ident","DIM/"+config);
	}
}


_fwDim_prepDpConfig(string dp, string config, dyn_string &dp_configs, dyn_anytype &dp_config_values,
	dyn_string &dp_configs1, dyn_anytype &dp_config_values1)
{
dyn_string dpes;
int i;

	_fwDim_getDpes(dp, dpes);
	if(!dynlen(dpes))
		dynAppend(dpes,dp);
	for(i = 1; i <= dynlen(dpes); i++)
	{
		dynAppend(dp_configs, dpes[i]+":_distrib.._type");
		dynAppend(dp_config_values, DPCONFIG_DISTRIBUTION_INFO);
		dynAppend(dp_configs, dpes[i]+":_distrib.._driver");
		dynAppend(dp_config_values, 1);

		dynAppend(dp_configs1, dpes[i]+":_address.._type");
		dynAppend(dp_config_values1, DPCONFIG_PERIPH_ADDR_MAIN);
		dynAppend(dp_configs1, dpes[i]+":_address.._drv_ident");
		dynAppend(dp_config_values1, "DIM/"+config);

	}
	if(dynlen(dp_configs) >= 1000)
	{
time t1;
t1 = getCurrentTime();
DebugN(formatTime("%c",t1)+" - Setting "+dynlen(dp_configs)+" items");
		dpSetWait(dp_configs, dp_config_values);
		dynClear(dp_configs);
		dynClear(dp_config_values);
		dpSetWait(dp_configs1, dp_config_values1);
		dynClear(dp_configs1);
		dynClear(dp_config_values1);
	}
}


_fwDim_unSetDpConfig(string dp)
{
dyn_string dpes;
int i;

	_fwDim_getDpes(dp, dpes);
	if(!dynlen(dpes))
		dynAppend(dpes,dp);
	for(i = 1; i <= dynlen(dpes); i++)
	{
		dpSet(dpes[i]+":_address.._type", DPCONFIG_NONE);
//		      dpes[i]+":_address.._drv_ident","");
	}
}


_fwDim_unPrepDpConfig(string dp, dyn_string &dp_configs, dyn_anytype &dp_config_values)
{
dyn_string dpes;
int i;

	_fwDim_getDpes(dp, dpes);
	if(!dynlen(dpes))
		dynAppend(dpes,dp);
	for(i = 1; i <= dynlen(dpes); i++)
	{
		dynAppend(dp_configs, dpes[i]+":_distrib.._type");
		dynAppend(dp_config_values, DPCONFIG_NONE);
		dynAppend(dp_configs, dpes[i]+":_address.._type");
		dynAppend(dp_config_values, DPCONFIG_NONE);
	}
	if(dynlen(dp_configs) >= 1000)
	{
time t1;
t1 = getCurrentTime();
DebugN(formatTime("%c",t1)+" - Setting "+dynlen(dp_configs)+" items");
		dpSetWait(dp_configs, dp_config_values);
		dynClear(dp_configs);
		dynClear(dp_config_values);
	}
}

int _fwDim_getDpes(string dp, dyn_string &dpes)
{
	dyn_string res;
	int i, n, n1, index;

	res = dpNames(dp+".*");
	n = dynlen(res);
	if(n)
	{
		for(i = 1; i <= n; i++)
		{
			n1 = _fwDim_getDpes(res[i], dpes);
			if(!n1)
			{
				dynAppend(dpes, res[i]);
			}
		}
	}
	return n;
}

int fwDim_getLocked(string dpe)
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

fwDim_lock(string dpe)
{
int manLocked, manId;

	while(1)
	{
		manLocked = fwDim_getLocked(dpe);
		if(!manLocked)
		{
			dpSetWait(dpe+":_lock._original._locked", 1);
			manLocked = fwDim_getLocked(dpe);
			manId = convManIdToInt(myManType(), myManNum());
			if(manId == manLocked)
			{
				break;
			}
		}
		delay(0, 100);
	}
}

fwDim_unlock(string dpe)
{
	dpSetWait(dpe+":_lock._original._locked", 0);
}

dyn_string FwDIM_waitDps;
dyn_int FwDIM_waitDpsState;
dyn_int FwDIM_waitDpsN;

fwDim_dpWaitClear(string dp)
{
int index, i;

	dp = dpSubStr(dp, DPSUB_ALL);
	if(index = dynContains(FwDIM_waitDps, ""))
	{
		FwDIM_waitDps[index] = dp;
		FwDIM_waitDpsState[index] = 0;
		FwDIM_waitDpsN[index] = 1;
		dpConnect("_fwDim_dpWaitCallback", 0, dp);
	}
	else if(!(index = dynContains(FwDIM_waitDps, dp)))
	{
		index = dynAppend(FwDIM_waitDps, dp);
		dynAppend(FwDIM_waitDpsState, 0);
		FwDIM_waitDpsN[index] = 1;
		dpConnect("_fwDim_dpWaitCallback", 0, dp);
	}
	else
	{
		FwDIM_waitDpsState[index] = 0;
		FwDIM_waitDpsN[index]++;
	}
}

int fwDim_dpWait(string dp, int tout)
{
int index, n;

//	n = tout*10;
	n = tout*50;
	dp = dpSubStr(dp, DPSUB_ALL);
	if(index = dynContains(FwDIM_waitDps, dp))
	{
		while(1)
		{
			if(FwDIM_waitDpsState[index] == 1)
			{
				FwDIM_waitDpsN[index]--;
				if(FwDIM_waitDpsN[index] == 0)
				{
					FwDIM_waitDps[index] = "";
					FwDIM_waitDpsState[index] = 0;
				}
				return(1);
			}
//			delay(0,100);
			delay(0,20);
			n--;
			if(n <= 0)
			{
				FwDIM_waitDpsN[index]--;
				if(FwDIM_waitDpsN[index] == 0)
				{
					dpDisconnect("_fwDim_dpWaitCallback", dp);
					FwDIM_waitDps[index] = "";
					FwDIM_waitDpsState[index] = 0;
				}
				return(0);
			}
		}
	}
	return(-1);
}

_fwDim_dpWaitCallback(string dp, anytype value)
{
int index;

	dpDisconnect("_fwDim_dpWaitCallback", dp);
	if(index = dynContains(FwDIM_waitDps, dp))
	{
		FwDIM_waitDpsState[index] = 1;
	}
}
