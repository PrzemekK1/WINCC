#uses "fwInstallation/fwInstallation.ctl"

main()
{
	string version;

	int idMenu = moduleAddMenu("JCOP Framework");
	bool isInstalled = fwInstallation_isComponentInstalled("fwAccessControl", version);
	if (!isInstalled) return;
	
	int idAction;
	int idACmenu = moduleAddSubMenu("Access Control", idMenu);
	idAction = moduleAddAction("Login",      "login.xpm",  "", idACmenu, -1, "_fwAccessControlGedi_login");
	idAction = moduleAddAction("Logout",     "exit.xpm",   "", idACmenu, -1, "_fwAccessControlGedi_logout");
	idAction = moduleAddAction("AC Toolbar", "userviewer", "", idACmenu, -1, "_fwAccessControlGedi_openToolbar");
	idAction = moduleAddAction("AC Setup",   "sysmgm",     "", idACmenu, -1, "_fwAccessControlGedi_openSetup");

    moduleAddDockModule("fwAccessControlToolbar", "fwAccessControl/fwAccessControl_Toolbar.pnl");
}

void _fwAccessControlGedi_openTool(string moduleName, string fileName, string panelName)
{
	if (isModuleOpen(moduleName) && isPanelOpen(panelName,moduleName)) {
		moduleRaise(moduleName);
	} else {
		ModuleOnWithPanel(	moduleName,
							-1, -1, 100, 200, 1, 1,
							"",
							fileName, panelName, makeDynString());
	}
}

void _fwAccessControlGedi_login()		{ fwAccessControl_login();	}
void _fwAccessControlGedi_logout()		{ fwAccessControl_logout();	}
void _fwAccessControlGedi_openToolbar() { _fwAccessControlGedi_openTool("Access Control Toolbar (GEDI)", "fwAccessControl/fwAccessControl_Toolbar.pnl", "Toolbar"); }
void _fwAccessControlGedi_openSetup()	{ _fwAccessControlGedi_openTool("Access Control Setup (GEDI)",   "fwAccessControl/fwAccessControl_Setup.pnl",   "Setup"); }
