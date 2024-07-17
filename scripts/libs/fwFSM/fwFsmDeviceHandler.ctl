#uses "fwFSM/fwFsm.ctl"

domain_change(string dp, int value)
{
	dyn_string items;
	string domain;
	int index;

//  if(value == -2)
//    return;
	items = strsplit(dp,":.");
	domain = items[2];
	strreplace(domain, "fwCU_","");
	if(index = dynContains(FwFsmDomains, domain))
	{
//		if(value == -1)
//			value = 0;
//DebugTN("Domain Running changed", value, FwFsmDomains[index], FwFsmDomainsOn[index], FwFsmDevicesOn[index]);
    if(value < 0)
    {
      if(value == -2)
        return;
      if(FwFsmDevicesOn[index])
      {
	      FwFsmDevicesOn[index] = 0;
	      FwFsmDomainsOn[index] = 0;
        return;
      }
    }
	  FwFsmDomainsOn[index] = value;
//		if((FwFsmDomainsOn[index]) && (!FwFsmDevicesOn[index]))
//      check_domains_flag++;

	  if(FwFsmDomainsOn[index] != FwFsmDevicesOn[index])
	  {
			  if((!FwFsmDomainsOn[index]) && (FwFsmDevicesOn[index]))
			  {
			    	FwFsmDevicesOn[index] = 0;
			  }
			  else
				  check_domains_flag++;
    }
	}
}

do_start_domain(string domain)
{
	string domain_name, dp;
	int ctrlDUFlag, num;

//DebugTN("do_start_domain", domain);
/*
	ctrlDUFlag = fwFsm_getCUCtrlFlag(domain);

	if(ctrlDUFlag == 1)
	{
	  fwUi_getDomainPrefix(domain, dp);
	  if(dpExists(dp))
    {
DebugTN("Stopping Old CU Handler", domain);
		 			dpSetWait(dp+".running", -2);
       delay(1);
DebugTN("Starting New CU Handler", domain);
		 			dpSetWait(dp+".running", 1);
    }
		num = fwFsm_startCUProcess(domain);
//DebugTN("Started CTRL", num, domain);
	}
	else
	{
*/
		domain_name = domain;
		strreplace(domain_name,fwDev_separator,"_");
		strreplace(domain_name,"-","_");

		execScript("#uses \""+domain_name+".ctl\"\n main() {	DebugTN(\"Starting devices for: "+
			domain+"\"); startDomainDevices_"+
			domain_name+"(); fwFsm_waitDomainEnd(\""+domain+"\"); DebugTN(\"Stopping devices for: "+
			domain+"\"); }",
			makeDynString());
/*
	}
*/
}

/*
do_start_domain(string domain)
{
	string domain_name;

	domain_name = domain;
	strreplace(domain_name,fwDev_separator,"_");
DebugN("#uses \""+domain_name+".ctl\"\n main() {	DebugN(\"Starting devices for: "+
		domain+"\"); startDomainDevices_"+
		domain_name+"(); fwFsm_waitDomainEnd(\""+domain+"\"); stopDomainDevices_"+
		domain_name+"(); DebugN(\"Stopping devices for: "+
		domain+"\"); }");

	execScript("#uses \""+domain_name+".ctl\"\n main() {	DebugN(\"Starting devices for: "+
		domain+"\"); startDomainDevices_"+
		domain_name+"(); fwFsm_waitDomainEnd(\""+domain+"\"); stopDomainDevices_"+
		domain_name+"(); DebugN(\"Stopping devices for: "+
		domain+"\"); }",
		makeDynString());
}
*/

dyn_string old_domains;
int check_domains_flag;
int TopLevel;
string TopDomain = "";

dyn_string get_selected_domains(dyn_string domains, dyn_string &special)
{
  int i, duflag;
  string dp;
  dyn_string duflagdps, selDomains, domainsToRemove, children;
  dyn_int duflags;

  for(i = 1; i <= dynlen(domains); i++)
  {
	  fwUi_getDomainPrefix(domains[i], dp);
		if(dpExists(dp))
		{
      dynAppend(duflagdps, dp+".ctrlDUFlag");
    }
    else
    {
      dynRemove(domains, i);
      i--;
    }
  }
  if(dynlen(duflagdps))
    dpGet(duflagdps, duflags);
  for(i = 1; i <= dynlen(duflags); i++)
  {
    if((duflags[i] == 3) || (duflags[i] == 1))
    {
      dynAppend(special, domains[i]);
      dynAppend(domainsToRemove, domains[i]);
      if(duflags[i] == 3)
      {
        get_children_rec(domains[i], children);
        dynAppend(domainsToRemove, children);
      }
    }
  }
  for(i = 1; i <= dynlen(domains); i++)
  {
    if(!dynContains(domainsToRemove, domains[i]))
      dynAppend(selDomains, domains[i]);
  }
//DebugTN("getSelectedDomains", domains, selDomains, special);
  return selDomains;
}

int get_domains()
{
dyn_string domains, dps, duflagdps, ctrlPids, special, children, ctrlDomains, newDomains;
string dp;
int i, duflag, index;
dyn_int duflags;

//DebugTN("get_domains", TopLevel, TopDomain, old_domains);
  if(!TopLevel)
  {
    if(TopDomain == "")
      TopDomain = findMyDomain();
// get CU Tree
    dynAppend(domains, TopDomain);
    if(TopDomain != "")
    {
	    fwUi_getDomainPrefix(TopDomain, dp);
      if(dpExists(dp))
	    {
        dpGet(dp+".ctrlDUFlag", duflag);
        if(duflag == 3)
        {
          get_children_rec(TopDomain, children);
          dynAppend(domains, get_selected_domains(children, special));
        }
        if((duflag != 1) && (duflag != 3))
        {
          clearCtrlDomain(TopDomain);
          dynClear(domains);
        }
      }
    }
//DebugTN("Child Ctrl Man", TopDomain, children, domains);
  	if(old_domains != domains)
  	{
//DebugTN("get_domains", TopLevel, TopDomain, old_domains, domains);
      for(i = 1; i <= dynlen(domains); i++)
      {
  	  	fwUi_getDomainPrefix(domains[i], dp);
        if(!dynContains(FwFsmDomains, domains[i]))
      	{
      		dynAppend(FwFsmDomains, domains[i]);
      	 	dynAppend(FwFsmDomainsOn, 0);
      	 	dynAppend(FwFsmDevicesOn, 0);
//DebugTN("dpConnect","domain_change",dp+".running");
       	  dpConnect("domain_change",dp+".running");
        }
      }
	  	for(i = 1; i <= dynlen(FwFsmDomains); i++)
	  	{
	  	  fwUi_getDomainPrefix(FwFsmDomains[i], dp);
	  	  if(!dynContains(domains, FwFsmDomains[i]))
	  	  {
//DebugTN("dpDisonnect","domain_change",dp+".running", "removing ", FwFsmDomains[i], FwFsmDomains[1], FwFsmDomainsOn[i], FwFsmDevicesOn[1]);
          if(dpExists(dp+".running"))
	     	 	  dpDisconnect("domain_change",dp+".running");
	  	    dynRemove(FwFsmDomains, i);
	  	    dynRemove(FwFsmDomainsOn, i);
//??	  	    dynRemove(FwFsmDevicesOn, 1);
	  	    dynRemove(FwFsmDevicesOn, i);
          i--;
	  	  }
	  	}
	  	old_domains = domains;
    }
    return dynlen(domains);
  }
	 domains = fwFsm_getLocalDomains();
//DebugTN("getLocalDomains",domains);
  domains = get_selected_domains(domains, special);
//DebugTN("get_selected_domains",domains, special);
  ctrlPids = getCtrlDomains(ctrlDomains);
//DebugTN("get_domains TOP special", TopLevel, TopDomain, old_domains, domains, special, ctrlDomains);
//  DebugTN("getCtrlDomains", ctrlPids, ctrlDomains);
  for(i = 1; i <= dynlen(special); i++)
  {
    if(!dynContains(ctrlDomains, special[i]))
    {
//      if(getManId(special[i] == -1))
//        setManId(special[i], 0);
      dynAppend(ctrlPids,special[i]+" 0");
      dynAppend(newDomains, special[i]);
    }
  }
//  DebugTN("check new Domains", old_domains, domains, newDomains);
//DebugTN("XXXXX ",ctrlPids, ctrlDomains, newDomains, old_domains, domains);
	if((old_domains != domains) || (dynlen(newDomains)))
	{
//DebugTN("get_domains TOP", TopLevel, TopDomain, old_domains, domains, newDomains);
		for(i = 1; i <= dynlen(domains); i++)
		{
			fwUi_getDomainPrefix(domains[i], dp);
		  if(!dynContains(FwFsmDomains, domains[i]))
			{
				dynAppend(FwFsmDomains, domains[i]);
				dynAppend(FwFsmDomainsOn, 0);
			 	dynAppend(FwFsmDevicesOn, 0);
//DebugTN("dpConnect1","domain_change",dp+".running");
		 	 	dpConnect("domain_change",dp+".running");
			}
		}
		for(i = 1; i <= dynlen(FwFsmDomains); i++)
		{
			fwUi_getDomainPrefix(FwFsmDomains[i], dp);
		  if(!dynContains(domains, FwFsmDomains[i]))
			{
//DebugTN("dpDisonnect1","domain_change",dp+".running", "removing ", FwFsmDomains[i], FwFsmDomains[1], FwFsmDomainsOn[i], FwFsmDevicesOn[1]);
        if(dpExists(dp+".running"))
		 	 	  dpDisconnect("domain_change",dp+".running");
				dynRemove(FwFsmDomains, i);
				dynRemove(FwFsmDomainsOn, i);
//??			 	dynRemove(FwFsmDevicesOn, 1);
			 	dynRemove(FwFsmDevicesOn, i);
        i--;
			}
		}
    if(dynlen(newDomains))
    {
      dpSetWait("ToDo.moreCtrlPids",ctrlPids);
      startCtrls(newDomains);
      dpConnect("checkCtrls","ToDo.moreCtrlPids");
    }
		old_domains = domains;
	}
  return 1;
}

checkCtrls(string dp, dyn_string ctrlPids)
{
  int i, manId;
  dyn_string items, domains;

//DebugTN("checkCtrls", ctrlPids);
  for(i = 1; i <= dynlen(ctrlPids); i++)
  {
    items = strsplit(ctrlPids[i]," ");
    manId = (int)items[2];
    if(manId == 0)
      dynAppend(domains, items[1]);
  }
  startCtrls(domains);
}

startCtrls(dyn_string ctrlDomains)
{
  int i, j, manId;
  dyn_string ctrlPids;

	for(i = 1; i <= dynlen(ctrlDomains); i++)
  {
    manId = getManId(ctrlDomains[i]);
    if(manId == 0)
    {
	    if(_WIN32)
	    {
	    	system("start /B "+fwFsm_getPvssPath()+"/bin/WCCOActrl -proj "+PROJ+" fwFSM/fwFsmDeviceHandler.ctl");
	    }
	    else
	    {
	    	system(fwFsm_getPvssPath()+"/bin/WCCOActrl -proj "+PROJ+" fwFSM/fwFsmDeviceHandler.ctl &");
	    }
    }
    waitManId(ctrlDomains[i]);
  }
}

int waitManId(string domain)
{
  int manId;
  int tmout = 150;  // 150X100 milliseconds = 15 seconds

  while(1)
  {
    manId = getManId(domain);
    if(manId > 0)
      break;
    delay(0, 100);
    tmout--;
    if(tmout <= 0)
    {
      manId = -1;
      setManId(domain, manId);
      break;
    }
  }
  return manId;
}

int getManId(string domain)
{
  dyn_string ctrlPids, items;
  int i, manId = -1;

  dpGet("ToDo.moreCtrlPids",ctrlPids);
  for(i = 1; i <= dynlen(ctrlPids); i++)
  {
    if(strpos(ctrlPids[i],domain+" ") == 0)
    {
      items = strsplit(ctrlPids[i]," ");
      manId = (int)items[2];
      break;
    }
  }
  return manId;
}

setManId(string domain, int manId)
{
  dyn_string ctrlPids;
  int i, done = 0;

  dpGet("ToDo.moreCtrlPids",ctrlPids);
  for(i = 1; i <= dynlen(ctrlPids); i++)
  {
    if(strpos(ctrlPids[i],domain+" ") == 0)
    {
      ctrlPids[i] = domain+" "+manId;
      done = 1;
    }
  }
  if(!done)
  {
    dynAppend(ctrlPids,domain+" "+manId);
    done = 1;
  }
  if(done)
    dpSetWait("ToDo.moreCtrlPids",ctrlPids);
}

dyn_string getCtrlDomains(dyn_string &ctrlDomains)
{
  dyn_string ctrlPids, items;
  int i, found = 0;

  dynClear(ctrlDomains);
  dpGet("ToDo.moreCtrlPids",ctrlPids);
  for(i = 1; i <= dynlen(ctrlPids); i++)
  {
    items = strsplit(ctrlPids[i]," ");
    dynAppend(ctrlDomains, items[1]);
  }
  return ctrlPids;
}


clearCtrlDomain(string domain)
{
  dyn_string ctrlPids;
  int i, found = 0;

  dpGet("ToDo.moreCtrlPids",ctrlPids);
  for(i = 1; i <= dynlen(ctrlPids); i++)
  {
    if(strpos(ctrlPids[i],domain+" ") == 0)
    {
      found = i;
      break;
    }
  }
  if(found)
  {
    dynRemove(ctrlPids, found);
    dpSetWait("ToDo.moreCtrlPids",ctrlPids);
  }
}

string findMyDomain()
{
  string domain;
  dyn_string ctrlPids, items;
  int i, manId;

  dpGet("ToDo.moreCtrlPids",ctrlPids);
  for(i = 1; i <= dynlen(ctrlPids); i++)
  {
    items = strsplit(ctrlPids[i]," ");
    manId = (int)items[2];
    if(manId == 0)
    {
      domain = items[1];
      break;
    }
  }
  return domain;
}

main()
{
dyn_string domains, devices, todo;
string dp;
int i, n, manId, ret;

	check_domains_flag = 0;
	addGlobal("FwFsmDomains",DYN_STRING_VAR);
	addGlobal("FwFsmDomainsOn",DYN_INT_VAR);
	addGlobal("FwFsmDevicesOn",DYN_INT_VAR);
//  addGlobal("TopLevel", INT_VAR);
//  addGlobal("TopDomain", STRING_VAR);
//  addGlobal("CtrlDomains", DYN_STRING_VAR);

  TopLevel = 0;
  dpGet("ToDo.moreCtrlPids",todo);
  if(!dynlen(todo))
    TopLevel = 1;
	fwFsm_initialize();
	get_domains();
	manId = myManNum();
  if(TopLevel)
 	  dpSetWait("ToDo.ctrlPid", manId);
  else
    setManId(TopDomain, manId);
	n = 10;
	while(1)
	{
		delay(1);
		while(check_domains_flag)
		{
			check_domains_flag--;
			for(i = 1; i <= dynlen(FwFsmDomainsOn); i++)
			{
//      DebugTN("CheckDomains", i, FwFsmDomains[i], FwFsmDomainsOn[i], FwFsmDevicesOn[i]);
				devices = fwFsm_getDomainDevices(FwFsmDomains[i]);
				if(dynlen(devices))
				{
					if((FwFsmDomainsOn[i]) && (!FwFsmDevicesOn[i]))
					{
//						fwFsm_startDomainDevicesNewNew(FwFsmDomains[i]);
//						execScript("#uses \""+FwFsmDomains[i]+".ctl\"\n main() {startDomainDevices_"+FwFsmDomains[i]+"();}", makeDynString());

						startThread("do_start_domain", FwFsmDomains[i]);

						FwFsmDevicesOn[i] = 1;
					}
//					else if((!FwFsmDomainsOn[i]) && (FwFsmDevicesOn[i]))
//					{
////						fwFsm_stopDomainDevicesNewNew(FwFsmDomains[i]);
//						FwFsmDevicesOn[i] = 0;
//					}
				}
			}
		}
		n--;
		if(!n)
		{
			ret = get_domains();
      if(!ret)
      {
//DebugTN("Exiting thread ",TopDomain);
        break;
      }
			n = 10;
		}
	}
}

get_children_rec(string node, dyn_string &all_nodes)
{
	dyn_string nodes, exInfo, types;
	int i, ref;
	string dev, node_type, ref_obj;

 	fwTree_getChildren(node, nodes, exInfo);
	for(i = 1; i <= dynlen(nodes); i++)
	{
   get_children_rec(nodes[i], all_nodes);
   if(fwFsm_isDomain(nodes[i]))
     dynAppend(all_nodes, nodes[i]);
 }
}

dyn_string AllChildrenCUs;

get_all_children(string node, dyn_string &nodes)
{
  get_children_rec(node, nodes);
//DebugTN(node, nodes);
}

