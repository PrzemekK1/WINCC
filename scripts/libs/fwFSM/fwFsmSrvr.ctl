#uses "fwFSM/fwFsm.ctl"

int first_time;
dyn_string DomainsOn;
dyn_int DomainsRunning;
dyn_string DomainsConnected;
mapping DomainsStates;
mapping RemoteDomainsStates;

//For Redundant Systems
bool isActive;		//Peer status
bool dpConnStarted;	//Used to know when dpDisconnect cb
string reduManagerDp;

main()
{

DebugTN("fwFsmSrv: Starting up");

	if(!isRedundant())
	{
		isActive = true;
		standardMain();
	}
 	else
	{
		first_time = 1; //Anticipate the initialization of it, safe since never used before next init
		if(myReduHostNum() > 1)
      reduManagerDp="_ReduManager"+ "_" + myReduHostNum()+".EvStatus";
		else
      reduManagerDp="_ReduManager.EvStatus";
    dpConnect("handleSwap",reduManagerDp);
	}

}



bool isAPIConnected(int num,string which="my") {
   dyn_int busy_nums;
  	if((myReduHostNum() > 1)) {
      if (which=="my") dpGet("_Connections_2.Device.ManNums",busy_nums);
      else dpGet("_Connections.Device.ManNums",busy_nums);
     }
    else{
      if (which=="my") dpGet("_Connections.Device.ManNums",busy_nums);
      else dpGet("_Connections_2.Device.ManNums",busy_nums);
    }
   if(!dynContains(busy_nums,num)) return FALSE;
   else return TRUE;

}

void handleSwap(string dpe, bool value)
{
 DebugTN("fwFsmSrv: handleSwap() Entering handleSwap with value " + value);

	isActive = value;

 if(value)
	{
   if (!isCMS()) {
     int pid,timeElapsed;
     int timeout=50;
   		do
  	 	{
  		 	delay(2);
  			 timeElapsed++;
   			dpGet("ToDo.apiPid",pid);
   		}while((pid!=0)&&(timeElapsed<timeout)&&(!first_time)) ;  //TO BE EQUIVALENT TO FORMER VERSIONS IN NON-CMS REDUNDANT SYSTEMS
   }


	  if(!dpConnStarted) dpConnStarted = true;
	  standardMain();

 	}

 	else
	  passivePeer();
}

void passivePeer()
{

//Stop/Kill the api manager
int new_version = fwFsm_initialize(1, 1);
int ret;

	if(dpConnStarted)
	{
  DebugTN("fwFsmSrv: passivePeer() trying to stop API");
		ret = stop_api_man();
		if(!ret)
		{
			ret = stop_api_man();
			if(!ret)
			{
				ret = kill_api_man();
			}
		}

  DebugTN("fwFsmSrv: passivePeer() trying to stop Device Handler");
  stop_device_handler();
  stop_connections();
  dynClear(DomainsOn);
  dynClear(DomainsRunning);

  DebugTN("fwFsmSrv: passivePeer() dpDisconnecting cbDowork");
  dpDisconnect("cbDoWork","ToDo.action:_online.._value", "ToDo.params:_online.._value");
		dpConnStarted = false;
	}

 if(first_time)
	first_time = 0;

 DebugTN("fwFsmSrv: passivePeer() finished.");
}


standardMain()
{
	int done, new_version, autoStart, all_running;
	string status, action;
	int tmout = 60;
 dyn_string fsmObjects;

	if(_WIN32)
	{
		dyn_string fnames;
		int i;
		fnames = getFileNames(PROJ_PATH+"log","*.std*");

		for(i = 1; i <= dynlen(fnames); i++)
		{
   DebugTN("Cleaning up "+PROJ_PATH+"log/"+fnames[i]);
			remove(PROJ_PATH+"log/"+fnames[i]);
		}
	}
	while(tmout)
	{
		dpGet("ToDo.action", action, "ToDo.status", status);
		if((action != "Installing") && (status != "Installing"))
			break;
		delay(1);
		tmout--;
	}

//	fwFsm_startShowFwObjects();
	new_version = fwFsm_initialize(1, 1);
	dpGet("ToDo.autoStart", autoStart);
  fsmObjects = dpNames("*","_FwFsmObject");
//DebugTN("Auto start", autoStart);
// if(autoStart)
  if(dynlen(fsmObjects))
	  start_api_man(done,TRUE);
	if(new_version)
	{
    dpConnect("cbDoWork",FALSE,"ToDo.action:_online.._value","ToDo.params:_online.._value");
    fwUi_connectManagerIds();
    DebugTN("fwFsmSrvr: detected new FSM version - Generating ALL");
    startThread("do_generate_all", action, 1);
//		fwFsmTree_generateAll();
	}
  else
  {
	  all_running = check_all_domains();
	  if(autoStart)
	  {
      		if(!all_running) {
//              DebugTN("Starting FSM from fwFsmSrv after check_all_domains");
            		restart_all_fsms("FwRestartAllDomains");

          }
	  }
    dpConnect("cbDoWork",FALSE,"ToDo.action:_online.._value","ToDo.params:_online.._value");
    fwUi_connectManagerIds();
  }
}

cbDoWork(string dp, string action, string dp1, dyn_string params)
{
	dyn_string domains, parents, children, objs;
	string domain, obj, type, text, cmnd;
	int pid, ret, pos, api_started;

	if(!isActive)
	{
		//Stop the cb execution, waiting the disconnect from passivePeer funct
		return;
	}

//	if(first_time)
//	{
//		first_time = 0;
//		return;
//	}

 dpSetWait("ToDo.status:_original.._value", "working");
	if(action == "FwFsmGenerateAll")
	{
		print_msg("fwFSMSrvr executing "+action, 1);
    startThread("do_generate_all", action, 0);
	}
	else if(action == "FwCreateObject")
	{
		obj = params[1];
		print_msg("fwFSMSrvr executing "+action+" - "+obj, 1);
		fwFsm_doWriteSmiObjectType(obj);
		print_msg(obj+" - Object Type Created");
		dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwCreateScripts")
	{
		domain = params[1];
		print_msg("fwFSMSrvr executing "+action+" - "+domain, 1);
		type = params[2];
		objs = params;
		dynRemove(objs,1);
		dynRemove(objs,1);
		fwFsm_doWriteDomainTypeScripts(domain, type, objs);
		print_msg(domain+" - Object Scripts for Type "+type+" Created");
		dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwDeleteScripts")
	{
		domain = params[1];
		print_msg("fwFSMSrvr executing "+action+" - "+domain, 1);
		fwFsm_doRemoveTypeScripts(domain);
		print_msg(domain+" - Object Scripts deleted");
		dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwCreateDomain")
	{
		domain = params[1];
		print_msg("fwFSMSrvr executing "+action+" - "+domain, 1);
		ret = fwFsm_doWriteSmiDomain(domain);
		if(ret)
		{
			print_msg(domain+" - Domain Created");
			dpSetWait("ToDo.status:_original.._value", action);
		}
		else
		{
			print_msg(domain+" - Domain Not Created");
			dpSetWait("ToDo.status:_original.._value",
			"error/"+domain+": Error Translating SML code, please check the log");
		}
	}
	else if(action == "FwDeleteObject")
	{
		obj = params[1];
		print_msg("fwFSMSrvr executing "+action+" - "+obj, 1);
		fwFsm_doRemoveSmiObject(obj);
		print_msg(obj+" - Object Type Deleted");
		dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwDeleteDomain")
	{
		domain = params[1];
		print_msg("fwFSMSrvr executing "+action+" - "+domain, 1);
		fwFsm_doRemoveSmiDomain(domain);
		print_msg(domain+" - Domain Deleted");
		dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwRestartAllDomains")
	{
		restart_all_fsms(action);
	}
	else if(action == "FwStopAllDomains")
	{
		stop_all_fsms(action);
	}
	else if(action == "FwRestartTreeDomains")
	{
		restart_fsms(action, params[1], 1);
	}
	else if(action == "FwStopTreeDomains")
	{
		stop_fsms(action, params[1], 1);
	}
	else if(action == "FwRestartDomain")
	{
		restart_fsms(action, params[1], 0);
	}
	else if(action == "FwStopDomain")
	{
		stop_fsms(action, params[1], 0);
	}
	else if(action == "FwRestartDomainDevices")
	{
//  		dpGet("ToDo.params:_online.._value", params);
		print_msg("fwFSMSrvr executing "+action+" - "+params[1], 1);
		stop_domain_devices_new(params[1], -1);
		delay(5);
		start_domain_devices_new(params[1]);
		delay(5);
 	dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwRestartPVSS00smi")
	{
//		int api_started, ret; //FVR commented out given that this variables are defined in line 136

//  		dpGet("ToDo.params:_online.._value", params);
		print_msg("fwFSMSrvr executing "+action, 1);
		ret = kill_api_man();
		delay(2);
		start_api_man(api_started);
 	dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwRestartPVSS00ctrl")
	{

//  		dpGet("ToDo.params:_online.._value", params);
    if(!dynlen(params))
    {
	  	print_msg("fwFSMSrvr executing "+action, 1);
	  	stop_device_handler();
	  	delay(5);
	  	start_device_handler();
	  	delay(5);
    }
    else
    {
		  print_msg("fwFSMSrvr executing "+action+" - "+params[1], 1);
	  	stop_device_handler(params[1]);
	  	delay(5);
    }
 	  dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "FwSendSmiCommand")
	{
//  		dpGet("ToDo.params:_online.._value", params);
		domain = params[1];
		obj = params[2];
		cmnd = params[3];
//		print_msg("fwFSMSrvr executing "+action+" - "+domain+"::"+obj+" "+cmnd, 1);
		fwUi_sendDirectSmiCommand(domain, obj,cmnd);
 	dpSetWait("ToDo.status:_original.._value", action);
	}
	else if(action == "Installing")
	{
		print_msg("fwFSMSrvr Ignoring action: "+action);
	}
	else
	{
		print_msg("fwFSMSrvr executing Unknown "+action, 1);
		dpSetWait("ToDo.status:_original.._value", action);
	}
}

do_generate_all(string action, int do_exit = 0)
{
  string status;

  fwFsmTree_generateAll();
  while(1)
  {
    dpGet("ToDo.status", status);
    if(status != "working")
      break;
    delay(0,100);
  }
	print_msg("fwFsmSrvr - Generate ALL done!");
  dpSetWait("ToDo.status:_original.._value", action);
  if(do_exit)
    exit(0);
}

print_msg(string msg, int print_user = 0)
{
	time t1;
	int manId, num, type, sysNum;
	string sys, id, infoDp, user;

	t1 = getCurrentTime();
//DebugTN("In print_msg", msg, print_user, t1);
	if(!print_user)
	{
		DebugN(formatTime("%c",t1)+" "+msg);
		return;
	}
	dpGet("ToDo.action:_online.._manager", manId);
	getManIdFromInt(manId, type, num, sysNum);
//DebugN("manager", manId, type, num, sysNum);
	if(type == UI_MAN)
	{
		if(sysNum == 0)
			sys = getSystemName();
		else
			sys = getSystemName(sysNum);
		id = sys+"Manager"+num;
		user = fwUi_getManagerIdInfo(id);
		DebugN(formatTime("%c",t1)+" "+msg+" From: "+id+"("+user+")");
	}
	else
	{
		DebugN(formatTime("%c",t1)+" "+msg);
	}
//DebugN("user", id, user);
}



stop_all_fsms(string action)
{
  int api_started, ret;

  start_api_man(api_started);
  print_msg("fwFSMSrvr executing "+action, 1);
  stop_device_handler();
  stop_all_domains();
//  delay(2);
  ret = stop_api_man();
  if(!ret)
  {
    ret = stop_api_man();
    if(!ret)
    {
      ret = kill_api_man();

    }

  }
  stop_connections();

  dpSetWait("ToDo.status:_original.._value", action);
}

dyn_string ReIncludesToDo;
int ReIncludesDone = 1;

restart_all_fsms(string action)
{
  int api_started, tmout = 2;

  print_msg("fwFSMSrvr executing "+action, 1);
  start_device_handler();
  start_api_man(api_started);
//  if(!api_started)
//    signal_api_man();
  if (dynlen(DomainsOn)) stop_all_domains();
  if(!api_started)
    signal_api_man();
//  else
//  {
//      if(isATLAS())
//         tmout = tmout*5;
//         delay(tmout);
//  }
//  delay(2);
  ReIncludesDone = 0;
  dynClear(ReIncludesToDo);
  start_all_domains();
  if(wait_running())
    do_reincludes();
  ReIncludesDone = 1;
  dpSetWait("ToDo.status:_original.._value", action);
}

restart_fsms(string action, string domain, int recurse)
{
  int api_started, tmout = 2;

  start_device_handler();
  start_api_man(api_started);
  print_msg("fwFSMSrvr executing "+action+" - "+domain, 1);
//  if(!api_started)
//    signal_api_man();
  do_stop_domain(domain, recurse);
  wait_stopped();
  if(!api_started)
    signal_api_man();
//  else
//  {
//      if(isATLAS())
//         tmout = tmout*5;
//         delay(tmout);
//  }
//  delay(2);
  ReIncludesDone = 0;
  dynClear(ReIncludesToDo);
  do_start_domain(domain, recurse);
  if(wait_running())
    do_reincludes();
  ReIncludesDone = 1;
  dpSetWait("ToDo.status:_original.._value", action);
}

stop_fsms(string action, string domain, int recurse)
{
  int api_started;

  start_api_man(api_started);
  print_msg("fwFSMSrvr executing "+action+" - "+domain, 1);
//  if(!api_started)
//    signal_api_man();
  do_stop_domain(domain, recurse);
  wait_stopped();
  if(!api_started)
    signal_api_man();
  dpSetWait("ToDo.status:_original.._value", action);
}

get_all_domain_children(string domain, dyn_string &children, dyn_int &cus)
{

	dyn_string part_children, exInfo;
	dyn_int part_cus;
	int cu, i;

	fwTree_getChildren(domain, part_children, exInfo);
	for(i = 1; i <= dynlen(part_children); i++)
	{
		fwTree_getNodeCU(part_children[i], cu, exInfo);
		dynAppend(part_cus, cu);
		if ((!cu) && (!(strpos(part_children[i],"&")==0))) //Linked nodes don't have children, much less operations on FSMs with lot of LUs
		{
			get_all_domain_children(part_children[i], children, cus);
		}
	}
	dynAppend(children, part_children);
	dynAppend(cus, part_cus);
//DebugN("get_all_children", domain, children, cus);
}


do_start_domain (string domain, int recurse){

	dyn_string children, exInfo;
	dyn_int cus;
	int i, pos, cu;
	string sys, obj, type, child, local_dp, rem_dp;

//	fwTree_getChildren(domain,children, exInfo);


	get_all_domain_children(domain, children, cus);

	for(i = 1; i <= dynlen(children); i++)
	{
// DebugTN("do_start_domain,check remote alarm on domain, children[i] ",domain,children[i]);
		if(check_remote_alarm(domain, children[i], local_dp, rem_dp))
		{
    //  DebugTN("connect remote alarm ",local_dp,rem_dp);
			fwUi_connectRemoteSummaryAlarm(local_dp, rem_dp);
		}
//		fwTree_getNodeCU(children[i],cu, exInfo);
		if(cus[i])
		{
			child = fwTree_getNodeDisplayName(children[i], exInfo);
			if(!dynContains(DomainsConnected,domain+"|"+child+"::"+child+"_FWM"))
			{
DebugTN("Start Domain - Connecting child state", domain, child+"::"+child+"_FWM");
              if(fwTree_isNode(child, exInfo) == 2)
              {
                RemoteDomainsStates[child+"::"+child] = "";
                fwUi_connectCurrentState("checkRemoteRunning", child, child+"_FWM");
              }
							fwUi_connectCurrentState("checkSummaryAlert", domain, child+"::"+child+"_FWM");

//DebugTN("Connecting","ExecutingAction set_owner_new",domain, /*child+"::"+*/child+"_FWM");
				fwUi_connectExecutingAction("set_owner_new",domain, /*child+"::"+*/child+"_FWM");
				dynAppend(DomainsConnected,domain+"|"+child+"::"+child+"_FWM");
			}
			if(recurse)
			{
				fwTree_getNodeDevice(children[i], obj, type, exInfo);
				sys = fwFsm_getSystem(obj);
   	    if((sys == fwFsm_getSystemName()) && (!fwFsm_isObjectReference(children[i]))) {
//          DebugTN("Calling do start domain recursively on",children[i]);
					do_start_domain(children[i], recurse);
			}
		}
	}
  }
	start_domain(domain);

}


int check_remote_alarm(string domain, string child, string &local_dp, string &rem_dp)
{
	dyn_string exInfo, items;
	string obj, type;
	string sys;

	if(fwFsm_isObjectReference(child))
	{
		fwTree_getNodeDevice(child, obj, type, exInfo);
		sys = fwFsm_getSystem(obj);
		if(sys != fwFsm_getSystemName())
		{
			strreplace(obj,"::","|");
			items = strsplit(obj,":|");
			if(dynlen(items) < 3)
			{
				dynAppend(items, items[2]);
				obj += "|"+items[2];
			}
			local_dp = domain+"|"+items[2]+"|"+items[3]+".";
			rem_dp = obj+".";
			return 1;
		}
	}
	return 0;
}

do_stop_domain(string domain, int recurse)
{
	dyn_string children, exInfo;
	dyn_int cus;
	int i, pos, cu, enabled, done = 0;
	string sys, obj, type, id, child, local_dp, rem_dp, owner;
  dyn_string excludedChildren;

//DebugTN("Do_Stop_Domain", domain);
	if(dynContains(DomainsOn, domain))
	{
		fwUi_getOwnership(domain, id);
//		if(!recurse)
//		{
//			fwUi_getChildren(domain, children);
//			fwUi_excludeTree(domain, domain, id);
//			done = fwUi_excludeChildren(domain, domain, id, 1);
//		}
//		else
//		{
//DebugN("************ Releasing ",domain);
//			fwUi_releaseTreeAll(domain, domain, id);
//		}
//DebugTN("Starting delay for domain, DONE = ", done);
//			if(done)
//			{
//				delay(0,500);
//			}
//		}
	}
//	fwTree_getChildren(domain,children, exInfo);
	get_all_domain_children(domain, children, cus);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(dynContains(DomainsOn, domain))
		{
			if(check_remote_alarm(domain, children[i], local_dp, rem_dp))
				fwUi_disconnectRemoteSummaryAlarm(local_dp, rem_dp);
		}
//		fwTree_getNodeCU(children[i],cu, exInfo);
		if(cus[i])
		{
			child = fwTree_getNodeDisplayName(children[i], exInfo);
			if(recurse)
			{
				fwTree_getNodeDevice(children[i],obj,type, exInfo);
				sys = fwFsm_getSystem(obj);
				if((sys == fwFsm_getSystemName()) && (!fwFsm_isObjectReference(children[i])))
				{
					do_stop_domain(children[i], recurse);
				}
				else
				{
					if(dynContains(DomainsOn, domain))
					{
//DebugN("Excluding1", DomainsOn, domain, child, id);
						fwUi_checkOwnership(child, enabled, owner, id);
						if(enabled == 2)
						{
  			  fwUi_excludeTree(domain, child, id);
       dynAppend(excludedChildren, child);
							done++;
						}
					}
				}
			}
			else
			{
				if(dynContains(DomainsOn, domain))
				{
//DebugN("Excluding2", DomainsOn, domain, child, id);
					fwUi_checkOwnership(child, enabled, owner, id);
					if(enabled == 2)
					{
						fwUi_excludeTree(domain, child, id);
      dynAppend(excludedChildren, child);
						done++;
					}
				}
			}
//			if(dynContains(DomainsOn, domain))
//			{
//DebugTN("Disconnecting","checkSummaryAlert",domain, child+"::"+child+"_FWM");
//				fwUi_disconnectCurrentState("checkSummaryAlert",domain, child+"::"+child+"_FWM");
//				fwUi_disconnectExecutingAction("set_owner_new",domain, child+"::"+child+"_FWM");
//			}
		}
	}
/*
	if(done)
		delay(0, 500);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(cus[i])
		{
			if(dynContains(DomainsOn, domain))
			{
//DebugTN("Disconnecting","checkSummaryAlert",domain, child+"::"+child+"_FWM");
				fwUi_disconnectCurrentState("checkSummaryAlert",domain, child+"::"+child+"_FWM");
				fwUi_disconnectExecutingAction("set_owner_new",domain, child+"::"+child+"_FWM");
			}
		}
	}
*/
 fwUi_waitExcluded(domain, excludedChildren);
	if(dynContains(DomainsOn, domain))
	{
		int secs, millis;


	//	millis = 200;
//		secs = millis / 1000;
	//	millis = millis % 1000;

//DebugN("************** Excluding", done, secs, millis);
//			delay(0, 200);
		stop_domain(domain);
	}
}

copy_log(string log_file, int n_copies, int n = 0)
{
  string curr_log, next_log;

  curr_log = log_file+".bak";
  if(n)
    curr_log += "-"+n;
  n++;
  next_log = log_file+".bak"+"-"+n;
  if(n < n_copies)
    copy_log(log_file, n_copies, n);
	 if(isfile(curr_log))
  {
   DebugTN("Copying "+curr_log+" to "+next_log);
	 	copyFile(curr_log, next_log, 1);
  }
}

 void systemFunctionHack(string dns_node, string domain_name, string domain_file, string logfile) {

  int ret = 1, retry = 10;

//		env = "SET DIM_DNS_NODE="+dns_node;
//		system("start /B "+env+"&"+fwFsm_getFsmPath()+"/bin/smiSM "+domain_name+" "+fwFsm_getProjPath()+"/smi/"+domain_file+" &");
//		system("start /B "+fwFsm_getFsmPath()+"/bin/smiSM "+domain_name+" "+fwFsm_getProjPath()+"/smi/"+domain_file+" &");
////		system("start /B cmd /c \""+env+"&&"+fwFsm_getFsmPath()+"/bin/smiSM "+domain_name+" "+fwFsm_getProjPath()+"/smi/"+domain_file+"\"");
//DebugTN("Spawning", domain);
		while(ret && (retry > 0))
		{
			if(retry != 10)
			{
//    DebugTN("Retry",domain_name);
    send_dim_command(domain_name+"_SMI/EXIT", 1);
				delay(0,200);
			}

//   DebugTN("Starting start function from fwFsmSrv",domain_name);
			ret = system("start /B "+fwFsm_getFsmPath()+"\\smiSM -u -t -d 1 "+"-dns "+dns_node+" "+
			domain_name+" "+fwFsm_getProjPath()+"\\smi\\"+domain_file+
			" > " + getPath(LOG_REL_PATH) + "\\smiSM_" + logfile + " 2>&1");
			retry--;
//DebugTN("start /B "+fwFsm_getFsmPath()+"\\smiSM -u -t -d 1 "+"-dns "+dns_node+" "+
//			domain_name+" "+fwFsm_getProjPath()+"\\smi\\"+domain_file+
//			" > " + getPath(LOG_REL_PATH) + "\\smiSM_" + logfile + " 2>&1");
//      DebugTN("Finished start function from fwFsmSrv",domain_name);
		}
//DebugTN("Started", domain, "**************************************************", ret, retry);
//		if(ret)
//		{
////DebugTN("DisConnecting start","check_running",domain, domain+"_FWM");
//			fwUi_disconnectCurrentState("check_running",domain, domain+"_FWM");
//		}


 }

start_domain(string domain)
{
 string dp, domain_file, domain_name, dns_node, env, log_file;
 int index;
 string logfile;

 //DebugTN("start domain on", domain);

	fwUi_getDomainPrefix(domain, dp);
	start_domain_devices_new(domain);
//	delay(0,200);

	domain_file = domain;
	domain_name = domain;
	strreplace(domain_file,fwDev_separator,"_");
	strreplace(domain_name,fwDev_separator,":");
//DebugTN("Starting", domain, domain_file, domain_name);
	dns_node = fwFsm_getDimDnsNode();
	log_file = getPath(LOG_REL_PATH) + "/smiSM_" + domain_file + ".log";
	if(isfile(log_file))
  {
  copy_log(log_file, 5);
  DebugTN("Copying "+log_file+" to "+log_file+".bak");
		copyFile(log_file, log_file+".bak");
  }
	if(!(index = dynContains(DomainsOn,domain)))
		index = dynAppend(DomainsOn, domain);
	DomainsRunning[index] = 0;
  DomainsStates[domain] = "";
	dpSet(dp+".mode.owner","");
	if(!dynContains(DomainsConnected,domain+"|"+domain+"_FWM"))
	{
//DebugTN("Connecting","ExecutingAction set_owner",domain, domain+"_FWM");
    fwUi_connectExecutingAction("set_owner",domain,domain+"_FWM");

//DebugTN("Connecting","CurrentState check_running",domain, domain+"_FWM");
    fwUi_connectCurrentState("check_running",domain, domain+"_FWM");
    dynAppend(DomainsConnected,domain+"|"+domain+"_FWM");
	}
//DebugTN("Connecting","check_running",domain, domain+"_FWM");
//	fwUi_connectCurrentState("check_running",domain, domain+"_FWM", 0);
 logfile = domain_file;
 if(!isATLAS())
    logfile += ".log";
	if (os=="Linux")
	{
		system(
			"export LD_LIBRARY_PATH="+fwFsm_getFsmPath()+":"
			+"${LD_LIBRARY_PATH};"
//			+"export DIM_DNS_NODE="+dns_node+";"
			+fwFsm_getFsmPath()+"/smiSM -u -t -d 1 "+"-dns "+dns_node+" "+
				domain_name+" "+fwFsm_getProjPath()+"/smi/"+domain_file+
				" 1>" + getPath(LOG_REL_PATH) + "/smiSM_" + logfile + " 2>&1 &");
	}
	else
	{
		 startThread("systemFunctionHack",dns_node,domain_name,domain_file,logfile);

	}
/*
	if(!(index = dynContains(DomainsOn,domain)))
		index = dynAppend(DomainsOn, domain);
	DomainsRunning[index] = 0;
	dpSet(dp+".mode.owner","");
	if(!dynContains(DomainsConnected,domain+"|"+domain+"_FWM"))
	{
//DebugTN("Connecting","ExecutingAction set_owner",domain, domain+"_FWM");
		fwUi_connectExecutingAction("set_owner",domain,domain+"_FWM");
		dynAppend(DomainsConnected,domain+"|"+domain+"_FWM");
	}
*/
}

stop_domain(string domain)
{
	string domain1;
	int index;

//DebugTN("************ Stopping ",domain);
	if((index = dynContains(DomainsOn,domain)))
	{
//		fwUi_disconnectExecutingAction("set_owner",domain,domain+"_FWM");
//		dynRemove(DomainsOn, index);
//		dynRemove(DomainsRunning, index);
    if(DomainsRunning[index])
      DomainsRunning[index] = -1;
	}
//	domain1 = strtoupper(domain);
//	strreplace(domain1,fwDev_separator,":");
//	send_dim_command(domain1+"_SMI/EXIT", 1);
//	delay(0,200);
//DebugTN("************ Stopping 1",domain);
	stop_domain_devices_new(domain);
//	delay(0,50);
}

do_exclude(string domain, string object)
{
string dp;

	fwUi_sendDirectSmiCommand(domain, object+"_FWM","EXCLUDE");
	fwUi_getDomainPrefix(object, dp);
	dpSet(dp+".mode.owner","");
}

stop_all_domains()
{
  dyn_string domains, exInfo;
  string domain;
  int i, pos, cu;

  fwTree_getChildren("FSM", domains, exInfo);
  for(i = 1; i <= dynlen(domains); i++)
  {
//  if(domains[i] != fwFsm_clipboardNodeName)
//  {
    fwTree_getNodeCU(domains[i], cu, exInfo);
    if(cu)
    {
      do_stop_domain(domains[i], 1);
    }
//  }
  }
  if(!wait_stopped())
  {
    for(i = 1; i <= dynlen(DomainsOn); i++)
    {
      if(DomainsRunning[i])
      {
        domain = strtoupper(DomainsOn[i]);
        strreplace(domain,fwDev_separator,":");
        send_dim_command(domain+"_SMI/EXIT", 1);
        delay(0,200);
      }
    }
    dynClear(DomainsOn);
    dynClear(DomainsRunning);
  }
}

/*
stop_all_domains()
{
	int i;

	for(i = 1; i <= dynlen(DomainsOn); i++)
	{
		stop_domain(DomainsOn[i]);
	}
	dynClear(DomainsOn);
}
*/

int deleteDomain()
{
}

int check_all_domains()
{
	dyn_string dps, domains;
	string dp, child, local_dp, rem_dp, state;
	int i, j, index, id;
	dyn_string children, exInfo;
	dyn_int cus;
	int cu, all_running;

// DebugTN("fwFsmSrv: check_all_domains execution");
	all_running = 1;
	dps = fwFsm_getDps("*","_FwCtrlUnit");
	for(i = 1; i <= dynlen(dps) ; i++)
		domains[i] = substr(dps[i],5);
	for(i = 1; i <= dynlen(domains); i++)
	{
	 	fwUi_getDomainPrefix(domains[i], dp);
	 	dpGet(dp+".running", id);
 		if(id != 0)
	 	{
			fwUi_getCurrentState(domains[i],domains[i], state);
			if(state == "DEAD")
			{
				stop_domain_devices_new(domains[i]);
				id = 0;
			}
		}
		if(id != 0)
		{
			if(!(index = dynContains(DomainsOn,domains[i])))
			{
				dynAppend(DomainsOn, domains[i]);
				dynAppend(DomainsRunning, 1);
				if(!dynContains(DomainsConnected,domains[i]+"|"+domains[i]+"_FWM"))
				{
//DebugTN("Connecting1","ExecutingAction set_owner",domains[i], domains[i]+"_FWM");
          fwUi_connectExecutingAction("set_owner",domains[i],domains[i]+"_FWM");
          DomainsStates[domains[i]] = "";
          fwUi_connectCurrentState("check_running",domains[i], domains[i]+"_FWM");
          dynAppend(DomainsConnected,domains[i]+"|"+domains[i]+"_FWM");
				}
//				fwTree_getChildren(domains[i],children, exInfo);
				dynClear(children);
				dynClear(cus);
				get_all_domain_children(domains[i], children, cus);
				for(j = 1; j <= dynlen(children); j++)
				{
					if(check_remote_alarm(domains[i], children[j], local_dp, rem_dp))
					{
						fwUi_connectRemoteSummaryAlarm(local_dp, rem_dp);
					}
//					fwTree_getNodeCU(children[j], cu, exInfo);
					if(cus[j])
					{
						child = fwTree_getNodeDisplayName(children[j], exInfo);
						if(!dynContains(DomainsConnected,domains[i]+"|"+child+"::"+child+"_FWM"))
						{
DebugTN("Check All Domains - Connecting child state", domains[i], child+"::"+child+"_FWM");
              if(fwTree_isNode(child, exInfo) == 2)
              {
                RemoteDomainsStates[child+"::"+child] = "";
		            fwUi_connectCurrentState("checkRemoteRunning", child, child+"_FWM");
              }
							fwUi_connectCurrentState("checkSummaryAlert", domains[i], child+"::"+child+"_FWM");
//DebugTN("Connecting1","ExecutingAction set_owner_new",domains[i], /*child+"::"+*/child+"_FWM");
							fwUi_connectExecutingAction("set_owner_new",domains[i], /*child+"::"+*/child+"_FWM");
							dynAppend(DomainsConnected,domains[i]+"|"+child+"::"+child+"_FWM");
						}
					}
				}
//DebugN("DomainsConnected",DomainsConnected);
			}
		}
		else
			all_running = 0;
	}
	return all_running;
}

int check_all_domains_time(time origin, dyn_string &done_domains)
{
	dyn_string dps, domains;
	string dp, child, local_dp, rem_dp, stime;
	int i, j, index, id;
	dyn_string children, exInfo;
	dyn_int cus;
	int cu, all_running;

// DebugTN("fwFsmSrv: check_all_domains execution");
//	all_running = 1;
	dps = fwFsm_getDps("*","_FwCtrlUnit");
	for(i = 1; i <= dynlen(dps) ; i++)
		domains[i] = substr(dps[i],5);
	for(i = 1; i <= dynlen(domains); i++)
	{
    if(dynContains(done_domains, domains[i]))
      continue;
	 	fwUi_getDomainPrefix(domains[i], dp);
	 	dpGet(dp+".running", id);
 		if(id != 0)
	 	{
			fwUi_getCurrentStateTime(domains[i],domains[i], stime);
//DebugTN("ChekingTime",domains[i], domains[i], stime);
			if(stime < origin)
			{
				return 0;
			}
		}
		if(id != 0)
		{
        fwUi_getCurrentStateTime(domains[i], domains[i]+"_FWM", stime);
//DebugTN("ChekingTime1",domains[i], domains[i]+"_FWM", stime);
			  if(stime < origin)
			  {
				  return 0;
			  }
				dynClear(children);
				dynClear(cus);
				get_all_domain_children(domains[i], children, cus);
				for(j = 1; j <= dynlen(children); j++)
				{
					if(cus[j])
					{
						child = fwTree_getNodeDisplayName(children[j], exInfo);
						fwUi_getCurrentStateTime(domains[i], child+"::"+child+"_FWM", stime);
//DebugTN("CheckingTime2",domains[i], child+"::"+child+"_FWM", stime);
			      if(stime < origin)
			      {
				      return 0;
			      }
					}
				}
//DebugN("DomainsConnected",DomainsConnected);
        dynAppend(done_domains, domains[i]);
		}
//		else
//			all_running = 0;
	}
	return 1;
}

stop_connections()
{
int i;
dyn_string items, exInfo;
dyn_string aux_items;
string child;

	for(i = 1; i <= dynlen(DomainsConnected); i++)
	{
		items = strsplit(DomainsConnected[i],"|");
		if(strpos(items[2],"::") > 0)
		{
			aux_items = strsplit(items[2],":");
			child = aux_items[1];
			fwUi_disconnectCurrentState("checkSummaryAlert",items[1], items[2]);
      if(fwTree_isNode(child, exInfo) == 2)
			  fwUi_disconnectCurrentState("checkRemoteRunning", child, child+"_FWM");
			fwUi_disconnectExecutingAction("set_owner_new",items[1], child+"_FWM");
		}
		else
		{
//DebugTN("DisConnecting","ExecutingAction set_owner",items[1],items[2]);
			fwUi_disconnectExecutingAction("set_owner",items[1],items[2]);
	    fwUi_disconnectCurrentState("check_running",items[1], items[2]);
		}
	}
  mappingClear(DomainsStates);
  mappingClear(RemoteDomainsStates);
  dynClear(DomainsConnected);
}

start_all_domains()
{
	dyn_string domains, exInfo;
	int i, pos, cu;

	fwTree_getChildren("FSM", domains, exInfo);
	for(i = 1; i <= dynlen(domains); i++)
	{
//    DebugTN("start_all_domains loop on ",domains[i]);
//		if(domains[i] != fwFsm_clipboardNodeName)
//		{
			fwTree_getNodeCU(domains[i], cu, exInfo);
   			if(cu) {
        //DebugTN("calling do_start_domain on",domains[i]);
			   	do_start_domain(domains[i], 1);
      }
//		}
	}
}

get_api_num(int &num)
{
	dyn_int busy_nums;
	int i;
	int start;

	start = 10;

	num = -1;
//here code redundant-compatible
	if(isRedundant() && (myReduHostNum() > 1))
    		dpGet("_Connections"+ "_" + myReduHostNum()+".Device.ManNums",busy_nums);
	else
	    	dpGet("_Connections.Device.ManNums",busy_nums);
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
}


void waitAPIReady(time origin) {

 string dp;
 bool id;
 string state;
 dyn_string domains;
 int tout = 30;
 dyn_string done_domains;

 while(1)
 {
    if(check_all_domains_time(origin, done_domains))
      break;
    delay(1);
    tout--;
    if(isRedundant())
    {
      bool realIsActive;
      dpGet(reduManagerDp,realIsActive); //can be lost... if during delay turns passive won't be written, will stay here forever, even if going active again... NEEDS TIMEOUT //
      if (!realIsActive) return;
    }
    if(tout <= 0)
    {
      DebugTN("FwFsmSrvr: Api FSM States not written in 30s. Keep going.");
      break;
    }
 }
 if(tout > 0)
 {
   DebugTN("FwFsmSrvr: Api FSM States written.");
 }
/*
 dyn_string dps = fwFsm_getDps("*","_FwCtrlUnit");
	for(int i = 1; i <= dynlen(dps) ; i++)
		domains[i] = substr(dps[i],5);
	for(int i = 1; i <= dynlen(domains); i++)
	{
		fwUi_getDomainPrefix(domains[i], dp);
	  dpGet(dp+".running", id);
		if(id != 0)
		{
			fwUi_getCurrentState(domains[i],domains[i], state);
			if(state == "DEAD")
			{
//				stop_domain_devices_new(domains[i]);
				id = 0;

			}
    }
		if(id != 0) {
          dp="ToDo.dim_dns_up:_original.._stime";
          time t ;
          bool realIsActive;
          int tout=60;
          do {
            delay(0,500);
            dpGet(dp,t);
            if(isRedundant())
            {
              dpGet(reduManagerDp,realIsActive); //can be lost... if during delay turns passive won't be written, will stay here forever, even if going active again... NEEDS TIMEOUT //
              if (!realIsActive) return;
            }
            tout--; //needs timeout as could go P,A during delay and eventually could get stuck here on A-P-A-P changes
          }
          while ((period(t)<period(origin)) && (tout>=0)); //If API is going to be questioned for DEAD domains, wait till dim_dns_up.
          if (tout<0)
            DebugTN("FwFsmSrvr: ToDo.dim_dns_up not wrriten in 30s. Keep going.");
          else
            DebugTN("FwFsmSrvr: ToDo.dim_dns_up has been written, now waiting 5s more for DPs to be written. THIS DELAY HAS BEEN EXPERIMENTALLY STABLISHED for CMS. MIGHT BE ADJUSTED FOR OTHER EXPERIMENTS.");
          delay(5); //And then wait for DPs to be written .  THIS DELAY HAS BEEN EXPERIMENTALLY STABLISHED for CMS. MIGHT BE ADJUSTED FOR OTHER EXPERIMENTS
          i=dynlen(domains)+1; //to break for loop
    }
  } // if no dp.running=1 just dont wait.
*/
  return;
}


global int ApiManNum = 0;

start_api_man(int &done,bool waitAPI=FALSE)
{
	int num, tout, ret;
	dyn_int busy_nums;
	string dns_node;

	done = 0;
/**/
	dpGet("ToDo.apiPid", num);
	if(num != 0)
	{
    if(isAPIConnected(num))
		{
			if(!ApiManNum)
			{
				ApiManNum = num;

				if(isRedundant() && (myReduHostNum() > 1))
					dpConnect("check_api_man","_Connections"+ "_" + myReduHostNum()+".Device.ManNums");
				else
					dpConnect("check_api_man","_Connections.Device.ManNums");
			}
			return;
		}
		else
		{

//      DebugTN("API id detected !=0 on start_api_man, but application not connected, just resetting ToDo.apiPid DP");
      dpSetWait("ToDo.apiPid",0);


      /*
DebugTN("Wrong API ID, stopping PVSS00smi");
			ret = stop_api_man();
			if(!ret)
			{
				ret = stop_api_man();
				if(!ret)
				{
					ret = kill_api_man();
				}
			}*/
		}
	}

	get_api_num(num);
	dns_node = fwFsm_getDimDnsNode();
	if(dns_node == "")
	{
		print_msg("fwFSMSrvr: DIM_DNS_NODE not defined -> WCCOAsmi not started!");
		return;
	}
	print_msg("DIM_DNS_NODE = "+dns_node);

	if (os=="Linux")
	{
		system(
			"export LD_LIBRARY_PATH="+fwFsm_getFsmPath()+":"
			+"${LD_LIBRARY_PATH};"
			+fwFsm_getApiPath()+"/bin/WCCOAsmi -proj "+PROJ+" -own_system_only -dim_dns_node "
			+dns_node+" -num "+num+"&");
	}
	else
	{
		system("start /B /ABOVENORMAL "+fwFsm_getApiPath()+"\\bin\\WCCOAsmi -proj "+PROJ+" -own_system_only -dim_dns_node "+dns_node+" -num "+num);
DebugTN("start /B /ABOVENORMAL "+fwFsm_getApiPath()+"\\bin\\WCCOAsmi -proj "+PROJ+" -own_system_only -dim_dns_node "+dns_node+" -num "+num);
	}
  time origin=getCurrentTime();

	done = 1;
	dpSetWait("ToDo.apiPid",num);
	tout = 40;
	while(1)
	{
		if(isAPIConnected(num))
		{
      DebugTN("WCCOAsmi started");
			if(!ApiManNum)
			{
				ApiManNum = num;

				if(isRedundant() && (myReduHostNum() > 1))
					dpConnect("check_api_man","_Connections"+ "_" + myReduHostNum()+".Device.ManNums");
				else
					dpConnect("check_api_man","_Connections.Device.ManNums");
			}
			break;
		}
		delay(0,500);
		tout--;
    if (tout==0)
    {
      DebugTN("WCCOAsmi launched but taking more than 20s+ to connect");
      tout=40;
    }
	}
/**/
//	else
//	{
//		print_msg("fwFSMSrvr: manager number "+num+" already in use -> WCCOAsmi not started!");
//	}
  if (waitAPI) waitAPIReady(origin); //ONLY from standardmain so as smiSM processes not running are actually written DEAD before proceeding, not in restart_all_fsms or anywhere else because there we delay without a need, cause at that point if API is relaunched we should have arrived with a STOP FSM and FWM DPs should have been properly written.

}

check_api_man(string dp, dyn_int nums)
{
	int done;
//DebugN("Checking APi Man", dp, nums, ApiManNum);
	if(ApiManNum != 0)
	{
		if(dynContains(nums, ApiManNum))
		  return;
    DebugTN("WCCOAsmi re-started");
		start_api_man(done);
	}
}

signal_api_man()
{
	string name;

	name = "PVSSSys"+getSystemId()+":SMIHandler/COMMANDS";
	send_dim_command(name,"CheckSmiObjects");
}

int stop_api_man()
{
	string name;
	int num, tout;
	dyn_int busy_nums;
/**/
	if(ApiManNum)
	{
		ApiManNum = 0;
		if(isRedundant() && (myReduHostNum() > 1))
			dpDisconnect("check_api_man","_Connections"+ "_" + myReduHostNum()+".Device.ManNums");
		else
			dpDisconnect("check_api_man","_Connections.Device.ManNums");
	}
	name = "PVSSSys"+getSystemId()+":SMIHandler/EXIT";
	send_dim_command(name,1);
//DebugTN("Sending", name,1);
	delay(2);
	dpGet("ToDo.apiPid",num);
	tout = 100;
	while(tout)
	{
  if (!isAPIConnected(num))
		{
        DebugTN("WCCOAsmi stopped");
     			break;
  }
		delay(0,100);
		tout--;
	}
	if(!tout)
		  DebugTN("Timeout stopping WCCOAsmi via DIM");
	else {
  		dpSetWait("ToDo.apiPid",0);
//    DebugTN("stop_api_man ToDo.apiPid = 0");
  }
//DebugN("Stopped, Setting Todo.apiPid", 0);
	return tout;
/**/
//  return 1;
}

int kill_api_man()
{
	int id;
	int num, tout;
	dyn_int busy_nums;

 DebugTN("Trying to stop WCCOAsmi via PVSS");
	if(ApiManNum)
	{
		ApiManNum = 0;
		if(isRedundant() && (myReduHostNum() > 1))
			dpDisconnect("check_api_man","_Connections"+ "_" + myReduHostNum()+".Device.ManNums");
		else
			dpDisconnect("check_api_man","_Connections.Device.ManNums");
	}
	dpGet("ToDo.apiPid",num);
	if(num == 0)
	{
 DebugTN("WCCOAsmi already stopped");
		return 1;
	}
	id = convManIdToInt(DEVICE_MAN, num, getSystemId());

	if(isRedundant() && (myReduHostNum() > 1))
        	dpSetWait("_Managers"+ "_" + myReduHostNum()+".Exit:_original.._value",id);
	else
       		dpSetWait("_Managers.Exit:_original.._value",id);

 tout = 100;
	while(tout)
	{
		if (!isAPIConnected(num))
		{
   DebugTN("WCCOAsmi stopped");
			break;
		}
		delay(0,100);
		tout--;
 }
	if(!tout)
		DebugTN("Timeout stopping WCCOAsmi via PVSS");
	else {
  dpSetWait("ToDo.apiPid",0);
//  DebugTN("kill_api_man ToDo.apiPid = 0");
 }
//DebugN("Stopped, Setting Todo.apiPid", 0);
	return tout;
}

set_owner(string dp, string command)
{
	string action, owner, domain, exclusive, parent;
	int exc_flag;


//DebugTN("************** set_owner", dp, command);
	if(command == "")
		return;
//DebugTN("************** set_owner", dp, command);
	exc_flag = -1;
	parent = "";
	fwDU_getAction(command, action);
//	if((action != "TAKE") && (action != "RELEASE") && (action != "RELEASEALL")&& (action != "SETMODE"))
//		return;
//	if((action == "INCLUDE") || (action == "EXCLUDE") || (action == "FREE"))
//		return;
	fwDU_getActionParameter(command,"OWNER", owner);
	fwDU_getActionParameter(command,"EXCLUSIVE", exclusive);
//	fwDU_getActionParameter(command,"PARENT", parent);
	if(exclusive != "")
	{
		if((exclusive == "yes") || (exclusive == "YES"))
			exc_flag = 1;
		else
			exc_flag = 0;
	}
//	if(owner != "")
//	{
		dp = fwFsm_extractSystem(dp);
		dp = fwFsm_convertToAssociated(dp);
		domain = fwFsm_getAssociatedDomain(dp);
		if(parent == "")
			parent = domain;
//DebugTN("Doing externalTreeOwnership",action, parent, domain, owner, exc_flag);
		fwUi_externalTreeOwnership(action, parent, domain, owner, exc_flag);
//	}

}

set_owner_new(string dp, string command)
{
	string action, owner, domain, exclusive, parent, obj;
	int exc_flag;
	dyn_string items;


	if(command == "")
		return;

//DebugN("************** set_owner_new", dp, command);
	exc_flag = -1;
	parent = "";
	fwDU_getAction(command, action);
//	if(action == "SETMODE")
//		return;
	fwDU_getActionParameter(command,"OWNER", owner);
	fwDU_getActionParameter(command,"EXCLUSIVE", exclusive);
//	fwDU_getActionParameter(command,"PARENT", parent);
	if(exclusive != "")
	{
		if((exclusive == "yes") || (exclusive == "YES"))
			exc_flag = 1;
		else
			exc_flag = 0;
	}
//	if(owner != "")
//	{
		items = strsplit(dp,":|.");
		parent = items[2];
		domain = items[3];
		strreplace(domain,"_FWM","");
/*
		dp = fwFsm_extractSystem(dp);
		dp = fwFsm_convertToAssociated(dp);
		domain = fwFsm_getAssociatedDomain(dp);
*/
		if(parent == "")
			parent = domain;
//DebugTN("Doing new externalTreeOwnership",action, parent, domain, owner, exc_flag);
		fwUi_externalTreeOwnership(action, parent, domain, owner, exc_flag);
//	}

}

checkRemoteRunning(string dp, string state)
{
	string domain;
	int index;
	dyn_string devices;
	int t = 0;

  dp = fwFsm_extractSystem(dp);
  dp = fwFsm_convertToAssociated(dp);
  domain = fwFsm_getAssociatedDomain(dp);

  if (state != RemoteDomainsStates[domain+"::"+domain])
  {
    RemoteDomainsStates[domain+"::"+domain] = state;
DebugTN("Remote Child State", domain, RemoteDomainsStates[domain+"::"+domain]);
  }
}

checkSummaryAlert(string dp, string state)
{
dyn_string dpitems, items;
string domain, obj;
int lockedOut, allDone;

//DebugTN("************** CheckCurrentState", dp, state);
	if(state == "DEAD")
	{
		dpitems = strsplit(dp,":.");
		items = strsplit(dpitems[2],fwFsm_separator);

		domain = items[1];
		obj = items[2];
		strreplace(obj,"_FWM","");
		fwFsm_actOnSummaryAlarm(0, obj+"::"+obj, domain);
//		do_exclude(domain, obj);
/*
		fwUi_getLockedOut(domain, obj+"::"+obj, lockedOut);
		if(lockedOut)
		{
//DebugTN("++++++++++++++++++ Locking OUT "+domain+"::"+obj);
			fwUi_lockOutTree(domain, obj+"::"+obj);
		  if(lockedOut == 2)
		  {
//DebugTN("++++++++++++++++++ Locking OUT "+domain+"::"+obj);
		  	fwUi_lockOutTreePerm(domain, obj+"::"+obj);
		  }
		}
*/
	}
	else /*if((state == "EXCLUDED") || (state == "INLOCAL"))*/
	{
		dpitems = strsplit(dp,":.");
		items = strsplit(dpitems[2],fwFsm_separator);

		domain = items[1];
		obj = items[2];
		strreplace(obj,"_FWM","");
/*
		fwUi_getLockedOut(domain, obj+"::"+obj, lockedOut);
		if(lockedOut)
		{
//DebugTN("++++++++++++++++++ Locking OUT1 "+domain+"::"+obj);
			fwUi_lockOutTree(domain, obj+"::"+obj);
			if(lockedOut == 2)
			{
//DebugTN("++++++++++++++++++ Locking OUT1 "+domain+"::"+obj);
		  		fwUi_lockOutTreePerm(domain, obj+"::"+obj);
			}
		}
*/
//DebugN("checkSummaryAlarm", dp, state);
		if(state == "EXCLUDED")
		{
			string dp1, state1, owner;
			int enabled;

			dp1 = dp;
			strreplace(dp1,"|"+obj+"_FWM","_FWM");
			dpGet(dp1, state1);
			if(state1 == "MANUAL")
			{
        int tries = 100;
        delay(2);
        while(tries > 0)
        {
				  fwUi_checkOwnership(domain, enabled, owner);
          if(owner != "")
            break;
          delay(0, 100);
          tries--;
        }
        DebugTN("++++++++++++++++++ Queuing Re-Including", domain, obj+"::"+obj, enabled, owner);
	//			synchronized(ReIncludesToDo)
				{
  					if(owner != "")
  					{
  						dynAppend(ReIncludesToDo,"1 "+domain+" "+obj+"::"+obj+" "+owner);
//  						fwUi_includeTree(domain, obj+"::"+obj, owner);
  					}
  					else
  					{
  						dynAppend(ReIncludesToDo,"0 "+domain+" "+obj+"::"+obj);
//  						fwUi_excludeTree(domain, obj+"::"+obj);
	  				}
				}
				if(ReIncludesDone)
        do {
					allDone = do_reincludes();
          if (!allDone)
          {
            delay(2);
            dpGet(dp, state, dp1, state1);
          }
        } while ((!allDone) && (state == "EXCLUDED") && (state1 == "MANUAL"));
			}
		}
	}
}

synchronized int do_reincludes()
{
int i;
dyn_string items;
int noAutoInclude = 0;

	if(dpExists("ToDo.noAutoInclude"))
		dpGet("ToDo.noAutoInclude", noAutoInclude);
	if(noAutoInclude)
		return 1;
	for(i = 1; i <= dynlen(ReIncludesToDo); i++)
	{
    if(ReIncludesToDo[i] == "")
     continue;
		items = strsplit(ReIncludesToDo[i]," ");
//  DebugTN("++++++++++++++++++ Re-Including?", items[1], items[2], items[3], RemoteDomainsStates );
		if(items[1] == "1")
		{
      if(mappingHasKey(RemoteDomainsStates,items[3]))
      {
        if(RemoteDomainsStates[items[3]] == "DEAD")
          continue;
      }
  DebugTN("++++++++++++++++++ Re-Including", items[2], items[3]);
			fwUi_includeTree(items[2], items[3], items[4]);
		}
		else
		{
  DebugTN("++++++++++++++++++ Re-Excluding", items[2], items[3]);
			fwUi_excludeTree(items[2], items[3]);
		}
		ReIncludesToDo[i] = "";
	}
//	synchronized(ReIncludesToDo)
	{
		for(i = 1; i <= dynlen(ReIncludesToDo); i++)
		{
			if(ReIncludesToDo[i] == "")
			{
				dynRemove(ReIncludesToDo,i);
				i--;
			}
		}
	}
	//ReIncludesDone = 1;
  if(dynlen(ReIncludesToDo))
    return 0;
  return 1;
}


send_dim_command(string cmnd, string value)
{
	string dns_node, env;
	string str;

	dns_node = fwFsm_getDimDnsNode();
	str = "\""+cmnd+"\" \""+value+"\" -dns "+dns_node+" -s";
//print_msg("dim_send_command "+str);
	if (os=="Linux")
	{
		env = "export LD_LIBRARY_PATH="+fwFsm_getFsmPath()+":"
			+"${LD_LIBRARY_PATH};";
//			+"export DIM_DNS_NODE="+dns_node+";";
		system(env+fwFsm_getFsmPath()+"/dim_send_command "+str);
	}
	else
	{
//		env = "SET DIM_DNS_NODE="+dns_node+"&&";
//		system("start /B cmd /c \""+env+fwFsm_getFsmPath()+"/bin/dim_send_command "+str);
		system("start /B "+fwFsm_getFsmPath()+"\\dim_send_command "+str);
	}
}

start_domain_devices_new(string domain)
{
dyn_string devices;
int num;
string domain_file, namedbg, dp;

//	domain_file = domain;
//	strreplace(domain_file,fwDev_separator,"_");
//	devices = fwFsm_getDomainDevices(domain);
//	if(!dynlen(devices))
//	{
		fwUi_getDomainPrefix(domain, dp);
//DebugTN("Setting ",dp+".running", 1);
		dpSetWait(dp+".running", 1);
//		return;
//	}
//	get_ctrl_num(num);
//	namedbg = "_CtrlDebug_CTRL_"+num;
//	if(!dpExists(namedbg))
//	{
//		dpCreate(namedbg,"_CtrlDebug");
//	}
//	if (os=="Linux")
//	{
//		system(fwFsm_getPvssPath()+"/bin/PVSS00ctrl libs/"+domain_file+".ctl &");
//	}
//	else
//	{
//		system("start /B "+fwFsm_getPvssPath()+"/bin/PVSS00ctrl libs/"+domain_file+".ctl");
//	}
}

stop_domain_devices_new(string domain, int flag = 0)
{
string dp;
int id, manId, myId;
dyn_int busy_nums;
dyn_string devices;

	fwUi_getDomainPrefix(domain, dp);
//DebugTN("*************************************************** ReSetting ",dp+".running", flag);
	if(flag == -1)
		dpSetWait(dp+".running", flag);
	else
		dpSetWait(dp+".running", flag,
	           dp+".mode.owner","");
	fwFsm_stopDomainDevicesNew(domain);
}


int get_ctrl_num_clean(int &num)
{
	dyn_int busy_nums;
	int i, manId;
	int start;

	start = 50;

	num = -1;
	if(isRedundant() && (myReduHostNum() > 1))
		dpGet("_Connections"+ "_" + myReduHostNum()+".Ctrl.ManNums",busy_nums);
	else
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
	dpGet("ToDo.ctrlPid", manId);
	if(manId != 0)
	{
		if(dynContains(busy_nums, manId))
			return 0;
		else
    {
	  	dpSetWait("ToDo.ctrlPid", 0);
      if(dpExists("ToDo.moreCtrlPids"))
      {
      	dpSetWait("ToDo.moreCtrlPids", makeDynString());
    	}
    }
	}
	return 1;
}

start_device_handler()
{
int num, manId;
string namedbg;

	if(!get_ctrl_num_clean(num))
		return;
	namedbg = "_CtrlDebug_CTRL_"+num;
	if(!dpExists(namedbg))
	{
		dpCreate(namedbg,"_CtrlDebug");
	}
	if (os=="Linux")
	{
		system(fwFsm_getPvssPath()+"/bin/WCCOActrl -proj "+PROJ+" -num "+num+" fwFSM/fwFsmDeviceHandler.ctl &");
	}
	else
	{
		system("start /B "+fwFsm_getPvssPath()+"/bin/WCCOActrl -proj "+PROJ+" -num "+num+" fwFSM/fwFsmDeviceHandler.ctl");
	}
}

stop_device_handler(string domain = "")
{
int id, manId, myId, tout = 20;
dyn_int busy_nums, manIds;
dyn_string ctrlPids, items;
int i;

  if(dpExists("ToDo.moreCtrlPids"))
  {
  	dpGet("ToDo.moreCtrlPids", ctrlPids);
    for(i = 1; i <= dynlen(ctrlPids); i++)
    {
      items = strsplit(ctrlPids[i]," ");
      if(domain == "")
      {
        dynAppend(manIds, (int)items[2]);
      }
      else
      {
        if(items[1] == domain)
        {
          dynAppend(manIds, (int)items[2]);
          ctrlPids[i] = domain+" "+0;
        }
      }
    }
  }
  if(domain == "")
  {
  	dpGet("ToDo.ctrlPid", manId);
    dynAppend(manIds, manId);
  }
	if(isRedundant() && (myReduHostNum() > 1))
		dpGet("_Connections"+ "_" + myReduHostNum()+".Ctrl.ManNums",busy_nums);
	else
		dpGet("_Connections.Ctrl.ManNums",busy_nums);
  for(i = 1; i <= dynlen(manIds); i++)
  {
    manId = manIds[i];
	  if(manId != 0)
	  {
  		if(dynContains(busy_nums,manId))
  		{
  			myId = myManNum();
  			if(myId != manId)
  			{
  				id = convManIdToInt(CTRL_MAN, manId, getSystemId());
  				if(isRedundant() && (myReduHostNum() > 1))
  					dpSetWait("_Managers"+ "_" + myReduHostNum()+".Exit:_original.._value",id);
  				else
  					dpSetWait("_Managers.Exit:_original.._value",id);

  				while(tout > 0)
  				{
  		  	 		if(isRedundant() && (myReduHostNum() > 1))
  						dpGet("_Connections"+ "_" + myReduHostNum()+".Ctrl.ManNums",busy_nums);
  					else
  						dpGet("_Connections.Ctrl.ManNums",busy_nums);
  					if(!dynContains(busy_nums, manId))
  						break;
  					delay(1);
  					tout--;
  				}
  			}
  		}
    }
  }
  if(domain == "")
  {
   	dpSetWait("ToDo.ctrlPid", 0);
    if(dpExists("ToDo.moreCtrlPids"))
    {
    	dpSet("ToDo.moreCtrlPids", makeDynString());
  	}
  }
  else
  {
    if(dpExists("ToDo.moreCtrlPids"))
    {
    	dpSetWait("ToDo.moreCtrlPids", ctrlPids);
  	}
  }
}

check_running(string dp, string state)
{
	string domain;
	int index;
	dyn_string devices;
	int t = 0;

  dp = fwFsm_extractSystem(dp);
  dp = fwFsm_convertToAssociated(dp);
  domain = fwFsm_getAssociatedDomain(dp);

//DebugTN("check_running", dp, state, domain, DomainsStates[domain]);
  if(state != DomainsStates[domain])
  {
    DomainsStates[domain] = state;
    if(state != "DEAD")
    {

      if((index = dynContains(DomainsOn, domain)))
      {
        if(DomainsRunning[index])
          return;
    		}
    		else
    			return;
/*
      devices = fwFsm_getDomainObjects(domain, 1, 1);
      t = dynlen(devices) / 50;
      if(t)
        delay(t);
//DebugTN("DisConnecting not DEAD","check_running",domain, domain+"_FWM", state, index);
//		fwUi_disconnectCurrentState("check_running",domain, domain+"_FWM");
DebugTN("************ Domain Running", domain, state);
      fwUi_setDomainObjectsEnabled(domain);
//		if((index = dynContains(DomainsOn, domain)))
*/
DebugTN("************ Domain Running", domain, state);
      DomainsRunning[index] = t+1;
    }
    else
    {
      if((index = dynContains(DomainsOn, domain)))
      {
DebugTN("************ Domain Stopped", domain, state);
        DomainsRunning[index] = 0;
      }
    }
  }
}

int wait_running()
{
  int i;
  int n, tout = 60;

  if(isATLAS())
    tout = tout*5;
  while(1)
  {
    n = 0;
    for(i = 1; i <= dynlen(DomainsOn); i++)
    {
      if(!DomainsRunning[i])
        n++;
    }
    if(!n)
    {
//DebugTN("++++++++++++++++ Wait_running Returned OK, tout", tout);
      return 1;
    }
    delay(1);
    tout--;
    if(!tout)
    {
DebugTN("++++++++++++++++ Wait_running Returned TIMEOUT");
      for(i = 1; i <= dynlen(DomainsOn); i++)
      {
        if(!DomainsRunning[i])
          DebugTN("Not Running", DomainsOn[i]);
      }
      return 0;
    }
  }
}

int wait_stopped()
{
  int i;
  int n, tout = 60;
  int ret;

  if(isATLAS())
    tout = tout*5;
  while(1)
  {
    n = 0;
    for(i = 1; i <= dynlen(DomainsOn); i++)
    {
      if(DomainsRunning[i] == -1)
					n++;
    }
    if(!n)
    {
//DebugTN("++++++++++++++++ Wait_stopped Returned OK, tout", tout);
      ret = 1;
      break;
    }
    delay(1);
    tout--;
    if(!tout)
    {
DebugTN("++++++++++++++++ Wait_stopped Returned TIMEOUT");
      for(i = 1; i <= dynlen(DomainsOn); i++)
      {
        if(DomainsRunning[i] == -1)
          DebugTN("Still Running", DomainsOn[i]);
      }
      ret = 0;
      break;
    }
  }
  for(i = 1; i <= dynlen(DomainsOn); i++)
  {
    if(DomainsRunning[i] == 0)
    {
      dynRemove(DomainsOn,i);
      dynRemove(DomainsRunning,i);
      i--;
    }
  }
//DebugTN("Domains left",DomainsOn,DomainsRunning);
  return ret;
}

