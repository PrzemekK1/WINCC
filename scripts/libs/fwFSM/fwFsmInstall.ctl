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
		copy_files();
		import_dps();
		install_version();
	}
}

copy_files()
{
int ok;

	ok = copyAllFiles(fsm_path+"/smi", proj_path+"/smi");
	if(ok)
		DebugN("SMI files copied");
	else
		DebugN("Failed copying SMI files");
	ok = copyAllFiles(fsm_path+"/panels/fwFSMuser", proj_path+"/panels/fwFSMuser");
	if(ok)
		DebugN("User panels copied");
	else
		DebugN("Failed copying user panels");
}

import_dps()
{
	if (os=="Linux")
	{
		system(pvss_path+"/bin/PVSS00ascii -yes -in "+fsm_path+"/dplist/FwFsmDps.dpl");
	}
	else
	{
		system(pvss_path+"/bin/PVSS00ascii -yes -in "+fsm_path+"/dplist/FwFsmDps.dpl");
	}
}

install_version()
{
	const int FILE_SOURCE = 1, FILE_TARGET = 2;
	int ok, i;
	dyn_dyn_string windowsFiles, linuxFiles, filesToProcess;	
	
	windowsFiles[1] = makeDynString(fsm_path + "/bin/PVSS00smi" + pvss_version + ".exe",
	 	proj_path + "/bin/PVSS00smi.exe");
	windowsFiles[2] = makeDynString(fsm_path + "/bin/dim.dll",
 		proj_path + "/bin/dim.dll");
	windowsFiles[3] = makeDynString(fsm_path + "/bin/smirtl.dll",
		proj_path + "/bin/smirtl.dll");
	windowsFiles[4] = makeDynString(fsm_path + "/bin/smiuirtl.dll",
		proj_path + "/bin/smiuirtl.dll");
	windowsFiles[5] = makeDynString(fsm_path + "/bin/msvcrtd.dll",
		proj_path + "/bin/msvcrtd.dll");

	linuxFiles[1] = makeDynString(fsm_path + "/bin/PVSS00smi" + pvss_version, 
		proj_path + "/bin/PVSS00smi");
										
	if(os == "Linux")
		filesToProcess = linuxFiles;
	else
		filesToProcess = windowsFiles;
											
	for(i = 1; i <= dynlen(filesToProcess); i++)
	{
		ok = copyFile(filesToProcess[i][FILE_SOURCE], filesToProcess[i][FILE_TARGET]);
		if(ok)
			DebugN("fwFSM.postInstall: copied file " + filesToProcess[i][FILE_SOURCE] + " to " +  filesToProcess[i][FILE_TARGET]);
		else
			DebugN("fwFSM.postInstall: failed to copy file " + filesToProcess[i][FILE_SOURCE] + " to " +  filesToProcess[i][FILE_TARGET]);
	} 
	if(os == "Linux")
	{
		string str;
		file f;
		system("chmod a+x "+proj_path + "/bin/PVSS00smi");
		system("chmod a+x "+fsm_path + "/bin/smiTrans");
		system("chmod a+x "+fsm_path + "/bin/smiSM");
		system("chmod a+x "+fsm_path + "/bin/dim_send_command");
		system("chmod a+x "+fsm_path + "/bin/smi_send_command");
		system("chmod a+x "+fsm_path + "/bin/dns");
		str = "export LD_LIBRARY_PATH="+fsm_path+"/bin:"
			+"${LD_LIBRARY_PATH};"
			+fsm_path+"/bin/dns &";
		f = fopen(fsm_path+"/bin/Dns","w");
		fprintf(f,"%s",str); 
		fclose(f);
		system("chmod a+x "+fsm_path+ "/bin/Dns");
	}
}


int get_paths(string conf_path)
{
	file fin;
	string s;
	int pos, ok;
	int found = 0;
	dyn_string componentInfo;

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
	if(found == 2)
	{
		if(isFunctionDefined("fwInstallation_getComponentInfo"))
		{
			ok = fwInstallation_getComponentInfo("fwFSM", "installationdirectory", componentInfo);
			if(ok == 0)
			{
				fsm_path = componentInfo[1];
				found++;
			}
		}
	}
	return found;
}
