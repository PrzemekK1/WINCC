string proj_path, dim_path, pvss_path, pvss_version;

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
DebugN("FwDIM: "+dim_path);
		import_dps();
		install_version();
	}
}


import_dps()
{
	if (os=="Linux")
	{
		system(pvss_path+"/bin/PVSS00ascii -yes -in "+dim_path+"/dplist/FwDimDps.dpl");
	}
	else
	{
		system(pvss_path+"/bin/PVSS00ascii -yes -in "+dim_path+"/dplist/FwDimDps.dpl");
	}
}

install_version()
{
	int ok;

	if (os == "Linux")
	{
		ok = copyFile(dim_path + "/bin/PVSS00dim" + pvss_version,	proj_path + "/bin/PVSS00dim");
	}
	else
	{
		ok = copyFile(dim_path + "/bin/dim.dll", proj_path + "/bin/dim.dll");
		ok = copyFile(dim_path + "/bin/msvcrtd.dll", proj_path + "/bin/msvcrtd.dll");
		ok = copyFile(dim_path + "/bin/PVSS00dim" + pvss_version + ".exe", proj_path + "/bin/PVSS00dim.exe");
	}
	
	if(os == "Linux")
	{
		string str;
		file f;
		system("chmod a+x "+proj_path + "/bin/PVSS00dim");
		system("chmod a+x "+dim_path + "/bin/dns");
		system("chmod a+x "+dim_path + "/bin/did");
		system("chmod a+x "+dim_path + "/bin/pvss_dim_server");
		system("chmod a+x "+dim_path + "/bin/pvss_dim_client");
		str = "export LD_LIBRARY_PATH="+dim_path+"/bin:"
			+"${LD_LIBRARY_PATH}\n"
			+"alias Dns="+dim_path+"/bin/dns\n"
			+"alias Did="+dim_path+"/bin/did\n";
		f = fopen(dim_path+"/bin/fwDim.sh","w");
		fprintf(f,"%s",str); 
		fclose(f);
		str = "setenv LD_LIBRARY_PATH "+dim_path+"/bin:"
			+"${LD_LIBRARY_PATH}\n"
			+"alias Dns "+dim_path+"/bin/dns\n"
			+"alias Did "+dim_path+"/bin/did\n";
		f = fopen(dim_path+"/bin/fwDim.csh","w");
		fprintf(f,"%s",str); 
		fclose(f);
	}
	if(ok)
		DebugN("fwDIM.postInstall: PVSS00dim for version " + pvss_version + " installed");
	else
		DebugN("fwDIM.postInstall: Failed installing PVSS00dim for version " + pvss_version);
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
		if(strpos(s,"FwDIM\"") >= 0)
		{
			pos = strpos(s,"\"");
			dim_path = substr(s,pos+1);
			pos = strpos(dim_path,"\"");
			dim_path = substr(dim_path,0,pos);
DebugN(dim_path);
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
DebugN(found);
	if(found == 2)
	{
		if(isFunctionDefined("fwInstallation_getComponentInfo"))
		{
			ok = fwInstallation_getComponentInfo("fwDIM", "installationdirectory", componentInfo);
			if(ok == 0)
			{
				dim_path = componentInfo[1];
				found++;
			}
		}
	}
DebugN(dim_path);
	return found;
}
