/**
  
  This scripts sets default CAEN OPC UA client driver settings.

  # Use case
  Create of restore default CAEN OPC UA client configuration.

  # Usage
  * Command line (replace <project_name> with the actual project name):
    > WCCOActrl -proj <project_name> fwCaen/fwCaenSetDefaultOpcUaSettings.ctl
  * Gedi:
    In Project View right click on this script file
    (component installation directory -> Scripts -> fwCaen -> fwCaenSetDefaultOpcUaSettings.ctl)
    and from the pop-up menu select 'Start/Stop Script'
  Check LogViewer or PVSS_II.log for diagnostic information on execution
  of this script. 

  # Effect
  It overwrites Config.* DPEs of the following internal OPC UA datapoints:
  - _OPCUA6 [_OPCUA]
  - _OPCUA_CAEN(_2) [_OPCUAServer]
  - _OPCUA_CAEN_DefaultSubscription(_2) [_OPCUASubscription]
  with the default values as provided in fwCaen/fwCaen.init script.
  If DPs do not exist, they will be created first.
  
*/

const string FW_CAEN_INIT_SCRIPT = "fwCaen/fwCaen.init";
const string FW_CAEN_OPCUA_CONFIG_FUNC = "fwCaen_init_createOpcUaDriverConfiguration";

main()
{
  string initScriptString;
  if(!fileToString(getPath(SCRIPTS_REL_PATH, FW_CAEN_INIT_SCRIPT), initScriptString)){
    DebugTN("Cannot execute function that restores default configuration. Reason: " +
            "Failed to load component init script: " + FW_CAEN_INIT_SCRIPT +
            "Check if file exists in installation directory and is readable");
    exit(1);
  }
  if(startScript(initScriptString, makeDynString(),
                 FW_CAEN_OPCUA_CONFIG_FUNC, makeDynAnytype(true)) < 0){
    DebugTN("Cannot execute function that restores default configuration. Reason: " +
            "Script " + FW_CAEN_INIT_SCRIPT + " is corrupted or function " + FW_CAEN_OPCUA_CONFIG_FUNC +
            "does not exist. Try reinstall component before executing this script");
    exit(2);
  }
  fwInstallation_throw("Restoring default CAEN OPC UA client driver settings", "INFO");
}
