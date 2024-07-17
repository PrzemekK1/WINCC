// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "fit_libs/fit_functions.ctl"
#uses "fit_libs/fit_constants.ctl"
#uses "fit_libs/fit_Log.ctl"
//--------------------------------------------------------------------------------
// Variables and Constants

//CAEN CHANNELS DPs (with THIS_SYSTEM_NAME)
const dyn_string HV_CHANNELS_IN_USE     = dpAliasesToNames(dpAliases("*MCP_??", "*"));
const dyn_string HV_CHANNELS_DETECTOR_A = dpAliasesToNames(dpAliases("*FT0_A/MCP_??", "*"));
const dyn_string HV_CHANNELS_DETECTOR_C = dpAliasesToNames(dpAliases("*FT0_C/MCP_??", "*"));
const dyn_string HV_CHANNELS_DETECTOR   = concatenateDyn(HV_CHANNELS_DETECTOR_A, HV_CHANNELS_DETECTOR_C);
const dyn_string HV_CHANNELS_REF        = dpAliasesToNames(dpAliases("*MCP_LC", "*"));

//FCB datapoints
const dyn_string FCBS_IN_USE            = dpNames(THIS_SYSTEM_NAME + "fcb??", "FIT_FCB");

//FEE datapoints
const dyn_string PMS_IN_USE             = dpNames(THIS_SYSTEM_NAME + "{PMA{0,1,2,3,4,5,6,7},PMC?}", "FIT_PM");
const dyn_string PMS_TOP_C_CRATE        = dpNames(THIS_SYSTEM_NAME + "{PMC(0,1,2,3,4,5,6,7,8)}", "FIT_PM");
const dyn_string PMS_BOT_A_CRATE        = dpNames(THIS_SYSTEM_NAME + "{PMA{0,1,2,3,4,5,6,7},PMC9}", "FIT_PM");
const dyn_string PMS_NEW_IN_USE         = dpNames(THIS_SYSTEM_NAME + "FEE/{PMA{0,1,2,3,4,5,6,7},PMC?}", "fitPM");
const dyn_string TRIGGERS_IN_USE        = dpNames(THIS_SYSTEM_NAME + "*", "FIT_trigger");
const dyn_string PM_CHANNELS_IN_USE     = dpNames(THIS_SYSTEM_NAME + "FEE/{PMA{0,1,2,3,4,5,6,7}/Ch??,PMC{0,1,2,3,4,5,6,7,8}/Ch??,PMC9/Ch0{1,2,3,4,5,6,7,8}}", "fitPMchannel");
const dyn_string PM_CHANNELS_DIM_ORDER  = concatenateDyn(
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch01", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch02", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch03", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch04", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch05", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch06", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch07", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch08", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch09", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch10", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch11", "fitPMchannel"),
                                            dpNames(THIS_SYSTEM_NAME + "FEE/PM??/Ch12", "fitPMchannel")
                                          );

const dyn_string FT0_GBT_READOUT        = dpNames("FEE/*", "fitReadout");

const string     TCM_IN_USE             = THIS_SYSTEM_NAME + "TCM";

const string     FT0_CONTROL_SERVER_IN_USE  = THIS_SYSTEM_NAME + "ft0_ControlServer";
const string     CONTROL_SERVER_IN_USE  = THIS_SYSTEM_NAME + "ft0_ControlServer";

const string     LASER_IN_USE           = THIS_SYSTEM_NAME + "ft0Laser";
const string     ATTENUATOR_IN_USE      = THIS_SYSTEM_NAME + "ft0Attenuator";
const string     LASER_GENRATOR_IN_USE  = THIS_SYSTEM_NAME + "ft0Generator";

//WIENER datapoints
const string     WIENER_WITH_TCM        = THIS_SYSTEM_NAME + "Wiener/FT0_C";
const string     WIENER_WITHOUT_TCM     = THIS_SYSTEM_NAME + "Wiener/FT0_A";


//FSM
const string FSM_TOP_NODE_NAME = "FT0_DCS";

const string LHC_INFORMATION = THIS_SYSTEM_NAME + "LHC_info";

const string RUN_LOGGER = THIS_SYSTEM_NAME + "ft0RunLogger";

//LOOKUPTABLE CONSTANTS

const fitLookUpTable FT0_LUT_DEFAULT = fitLookUpTable(PROJ_PATH + "data/Channels map.csv");

const fitLookUpTableEntry FT0_LUTE_CHANNEL_NO = fitLookUpTableEntry("channel #" , FT0_LUT_DEFAULT);
const fitLookUpTableEntry FT0_LUTE_DIM_IDX    = fitLookUpTableEntry("DIM position"   , FT0_LUT_DEFAULT);
const fitLookUpTableEntry FT0_LUTE_PM_CHANNEL = fitLookUpTableEntry("FEE address", FT0_LUT_DEFAULT);
const fitLookUpTableEntry FT0_LUTE_HV_CHANNEL = fitLookUpTableEntry("HV board channel", FT0_LUT_DEFAULT);
const fitLookUpTableEntry FT0_LUTE_HV_BOARD   = fitLookUpTableEntry("HV board", FT0_LUT_DEFAULT);
const fitLookUpTableEntry FT0_LUTE_CELL       = fitLookUpTableEntry("Cell", FT0_LUT_DEFAULT);

const fitLog FT0_LOG = fitLog(PROJ_PATH + "log/ft0_dcs/ft0_dcs.log");

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

