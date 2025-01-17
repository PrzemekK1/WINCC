string proj_path, fsm_path, pvss_path, pvss_version;

main()
{
string conf_path;
int pos, ok;

	addGlobal("os",STRING_VAR);
/*
	os = getenv("OSTYPE");
	if(strpos(os,"linux") >= 0)
		os = "Linux";
*/
	if(_UNIX)
		os = "Linux";
	conf_path = getPath(CONFIG_REL_PATH, "config");
	pos = strpos(conf_path,"/config/config");
	proj_path = substr(conf_path, 0, pos);
DebugN("Project: "+proj_path);
	if(get_paths(conf_path) == 3)
	{
DebugN("FwFSM: "+fsm_path);
		import_dps();
		install_demo("DemoDCS");
	}
}

import_dps()
{
	if (os=="Linux")
	{
		system(pvss_path+"/bin/PVSS00ascii -in "+fsm_path+"/dplist/FwFsmDemoDps.dpl");
	}
	else
	{
		system(pvss_path+"/bin/PVSS00ascii -in "+fsm_path+"/dplist/FwFsmDemoDps.dpl");
	}
}

install_demo(string node)
{
	string dev, type;
	dyn_string children, exInfo;
	int i;

	fwTree_getNodeDevice(node, dev, type, exInfo);
	dev = fwFsm_extractSystem(dev);
	dev = fwFsm_getSystemName()+":"+dev;
	fwTree_setNodeDevice(node, dev, type, exInfo);
	fwTree_getChildren(node, children, exInfo);
	for(i = 1; i <= dynlen(children); i++)
	{
		install_demo(children[i]);
	}		
}

int get_paths(string conf_path)
{
	file fin;
	string s;
	int pos;
	int found = 0;

	fin = fopen(conf_path,"r");
	if(fin == 0)
	{
		int err=ferror(fin);
		DebugN("Could not open "+conf_path+" - Error No. "+err);
		return 0;
	} 	
	while(!feof(fin))
	{
		fgets(s,2000,fin);
		if(strpos(s,"FwFSM") >= 0)
		{
			pos = strpos(s,"\"");
			fsm_path = substr(s,pos+1);
			pos = strpos(fsm_path,"\"");
			fsm_path = substr(fsm_path,0,pos);
			found++;
		}
		if(strpos(s,"proj_version") >= 0)
		{
			pos = strpos(s,"\"");
			pvss_version = substr(s,pos+1);
			pos = strpos(pvss_version,"\"");
			pvss_version = substr(pvss_version,0,pos);
			found++;
		}
		if(strpos(s,"pvss_path") >= 0)
		{
			pos = strpos(s,"\"");
			pvss_path = substr(s,pos+1);
			pos = strpos(pvss_path,"\"");
			pvss_path = substr(pvss_path,0,pos);
			found++;
		}
		if(found == 3)
			break;
	}
	fclose(fin);
	return found;
}
