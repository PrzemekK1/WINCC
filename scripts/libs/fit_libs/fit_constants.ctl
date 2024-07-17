// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

//Maximum number of bunches in LHC ring
const uint MAX_NUM_OF_BUNCH = 0xDECU;


public const string FV0_SYSTEM_NAME = "fv0_dcs:";
public const string FDD_SYSTEM_NAME = "fdd_dcs:";
public const string FT0_SYSTEM_NAME = "ft0_dcs:";


const string FT0_WN_NAME = "alift0wn001.cern.ch";
const string FV0_WN_NAME = "alifv0wn001.cern.ch";
const string FDD_WN_NAME = "alifddwn001.cern.ch";

const dyn_string FIT_CCDB_PM_CH_ACT_HEADERS = makeDynString("CH_MASK_DATA", "CH_MASK_TRG", "ADC_DELAY", "TIME_ALIGN", "CFD_ZERO", "THRESHOLD_CALIBR", "CFD_THRESHOLD","ADC0_RANGE", "ADC1_RANGE");
const dyn_string FIT_CCDB_PM_CH_ACT_DYNELEM = makeDynString(
                          "dynServices.fitPM.CH_MASK_DATA",
                          "dynServices.fitPM.CH_MASK_TRG",
                          "dynServices.fitPMchannel.ADC_DELAY",
                          "dynServices.fitPMchannel.TIME_ALIGN",
                          "dynServices.fitPMchannel.CFD_ZERO",
                          "dynServices.fitPMchannel.THRESHOLD_CALIBR",
                          "dynServices.fitPMchannel.CFD_THRESHOLD",
                          "dynServices.fitPMchannel.ADC_RANGE"
                          );

const string FIT_FSM_READY          = "READY";
const string FIT_FSM_STANDBY        = "STANDBY";
const string FIT_FSM_OFF            = "OFF";
const string FIT_FSM_MOVING_READY   = "MOVING_READY";
const string FIT_FSM_MOVING_STANDBY = "MOVING_STANDBY";

const string FIT_CS_STAT_NO_RESPONSE = "no response";
const string FIT_CS_STAT_OK          = "OK";
const string FIT_CS_STAT_OFFLINE     = "offline";

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

//the only name that should be changed for other detectors:
public const string THIS_SYSTEM_NAME = FT0_SYSTEM_NAME;
public const string systemName       = THIS_SYSTEM_NAME;

//LHC information datapoint with info from LHC side
public const string LHC_INFORMATION = THIS_SYSTEM_NAME + "LHC_info";

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

