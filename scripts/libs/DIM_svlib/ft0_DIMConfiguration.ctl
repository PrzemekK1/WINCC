// $License: NOLICENSE
//--------------------------------------------------------------------------------
 /**
   @file $relPath
   @copyright $copyright
   @author Sukhanov Mikhail
 */

// --------------------------------------------------------------------------------
//Libraries used (#uses)
#uses "wizardFramework" //chyba stockowe
#uses "fwDIM/fwDIM.ctl" //dodano do folderu
//#uses "ft0_libs/ft0_constants.ctl" pierwotne
#uses "DIM_svlib/ft0_constants.ctl"

//--------------------------------------------------------------------------------
//Variables and Constants

const string errCatalogName = "DIMListGeneration";

//Default DIM config names
const string FEEDIMConfig = "DIM_SV";
const string ALIDIMConfig = "LHCConfig";

//Default node names in usage
const string FEEDIMDNSNODE = "128.141.221.200";
//const string FEEDIMDNSNODE = "localhost";
//const string ALIDIMDNSNODE = "ALIDCSDIMDNS";
const string ALIDIMDNSNODE = "128.141.221.200";

//Default manager numbers
const int ALIDIMman = 4;
const int FEEDIMman = 1;

//List of parameters to status monitoring (old version is still maintained)
const dyn_string boardStatus     = makeDynString( "TEMP_BOARD", "TEMP_FPGA", "VOLTAGE_1V", "VOLTAGE_1_8V");
const dyn_string TrigBkgndStatus = makeDynString( "NAME", "CNT", "CNT_RATE" );

//Prefix for different subsystems
const string FEEserviceHat = "FT0/";
const string ALIserviceHat = "ALICE/LHC/BUNCHES/";

//Default scripts to generate lists
const string FEEDIMSCT = "generateFEEDIMobjects";
const string ALIDIMSCT = "generateALIDIMobjects";

//containers variables used by functions
dyn_string  services, commands, commandDPEs, serviceDPEs;

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------


public bool startDIMConfig(string listGenerationFunction = FEEDIMSCT, string config = FEEDIMConfig, int managerID = FEEDIMman, string dnsNode = FEEDIMDNSNODE){
  int DIMcurrentState;
  fwDim_getState(config, DIMcurrentState);
  if(!DIMcurrentState) fwDim_start(config, managerID, dnsNode);

  clearAllLists();
  callFunction(listGenerationFunction);
  if(dynlen(serviceDPEs)) fwDim_subscribeServices(config, services, serviceDPEs);
  if(dynlen(commandDPEs)) fwDim_subscribeCommands(config, commands, commandDPEs);

  //make Log Entry on each command send
  for(uint i = 1; i <= dynlen(commandDPEs); ++i){
     dpConnect("DIMcommandSent", false, commandDPEs[i]);
  }

  fwDim_getState(config, DIMcurrentState);
  return DIMcurrentState == 1;
}



//default code to get the subscription lists for FEE
  // Add the init function and the datapoint name
void generateFEEDIMobjects(){

   //Control Server
   initControlServer(CONTROL_SERVER_IN_USE);

   //Calibraton unit
   initCalibrationBusy("ft0_calibration.");

   //TCM laser generator
   initTCMlaserGenerator(LASER_GENRATOR_IN_USE);

   //Attenuator
   initFITattenuator(ATTENUATOR_IN_USE);

   //dynServices
   initDynServices("dynServices.");

   //dynCommands
   initDynCommands("dynCommands.");

   //TCM new
   initTCM("FEE/TCM.");

   //Background old services
   o_initBkgrnd();

   //PM old services and old datapoints
   o_initPM();

   //TCM old datapoint old services
   o_initTCM(TCM_IN_USE);

   //Triggers old services
   o_initTrigger("Trigger?_{Central,SemiCentral,Vertex,OrC,OrA}");

}

// same for LHC facilities
void generateALIDIMobjects(){
  initLHCinfo(LHC_INFORMATION);
}

public void unSubscribeServices(string config){
   fwDim_unSubscribeServices(config, "*");
 }

public void unSubscribeCommands(string config){
   fwDim_unSubscribeCommands(config, "*");
 }

public void unSubscribeAll(string config){
  unSubscribeCommands(config);
  unSubscribeServices(config);
}

//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

private void appendService(string dpe, string service){
   serviceDPEs.append(dpe);
   services.append(service);
}

private void appendCommand(string dpe, string command){
   commandDPEs.append(dpe);
   commands.append(command);
 }

private void clearAllLists(){
  serviceDPEs.clear();
  services.clear();
  commandDPEs.clear();
  commands.clear();
}

//return false if dp does not exist
private bool dpNameConverter(string &name, string dpType){
  if(dpTypeExists(dpType)){
    if(dpExists(name)){
      if(dpTypeName(name) == dpType){
        name = dpSubStr(name, DPSUB_SYS_DP) + ".";
        return true;
      }
    }
  }
  throwError(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "SKIP SUBSCRIPTION OF " + name + " FOR TYPE " + dpType));
  return false;
}

private void initLHCinfo(string LHCinfo){
  if(!dpNameConverter(LHCinfo, "LHC_info")) return;

  //Energy, name of filling scheme and clock transition aware information
  appendService(LHCinfo + "ENERGY"                   , "DCS_GRP_LHC_BEAM_ENERGY"      );
  appendService(LHCinfo + "FILL_SCHEME_NAME"         , "ALICEDAQ_LHCFillingSchemeName");
  appendService(LHCinfo + "clockTransiton.timeout"   , "TTCMI/MICLOCK_TRANSITION"     );
  appendService(LHCinfo + "clockTransiton.source"    , "TTCMI/MICLOCK"                );
  appendService(LHCinfo + "clockTransiton.TTCmi/QPLL", "TTCMI/QPLL"                   );

  //ALICE injected bunch numbers relatively to LHC with comma delimeter
  appendService(LHCinfo + "CIRCULATING_BUNCHES_B1", ALIserviceHat + "CIRCULATING_BUNCHES_B1");
  appendService(LHCinfo + "CIRCULATING_BUNCHES_B2", ALIserviceHat + "CIRCULATING_BUNCHES_B2");

  //The same but in dynamic list
  appendService(LHCinfo + "CIRCULATING_BUNCHES_B1_VALUES", ALIserviceHat + "CIRCULATING_BUNCHES_B1_VALUES");
  appendService(LHCinfo + "CIRCULATING_BUNCHES_B2_VALUES", ALIserviceHat + "CIRCULATING_BUNCHES_B2_VALUES");

  //Intensity of the bunches
  appendService(LHCinfo + "ALICE.intensity.B1.Displaced", ALIserviceHat + "INT_DISPLACEDCOLLISIONSBUNCHES_B1");
  appendService(LHCinfo + "ALICE.intensity.B2.Displaced", ALIserviceHat + "INT_DISPLACEDCOLLISIONSBUNCHES_B2");

  appendService(LHCinfo + "ALICE.intensity.B1.Interacting", ALIserviceHat + "INT_INTERACTINGCOLLISIONSBUNCHES_B1");
  appendService(LHCinfo + "ALICE.intensity.B2.Interacting", ALIserviceHat + "INT_INTERACTINGCOLLISIONSBUNCHES_B2");

  appendService(LHCinfo + "ALICE.intensity.B1.notInteracting", ALIserviceHat + "INT_NOTINTERACTINGCOLLISIONSBUNCHES_B1");
  appendService(LHCinfo + "ALICE.intensity.B2.notInteracting", ALIserviceHat + "INT_NOTINTERACTINGCOLLISIONSBUNCHES_B2");

  appendService(LHCinfo + "ALICE.displacedBuckets_B1", ALIserviceHat + "BUCKETS_DISPLACED_B1");
  appendService(LHCinfo + "ALICE.displacedBuckets_B2", ALIserviceHat + "BUCKETS_DISPLACED_B2");

}
//======================================= OLD SERVICES/COMMANDS FORMAT ====================================
//prefix o for old datapoint type

private void o_initPM(string PMDPE = "PM??"){
  if(!dpTypeExists("FIT_PM")){
    throwError(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "Datapoints of type FIT_PM not found"));
    return;
  }
  dyn_string PMlist = dpNames(PMDPE, "FIT_PM");
  if(!dynlen(PMlist)){
    throw(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "Datapoints of type FIT_PM not found"));
  }else{
    for(uint i = 1; i <= dynlen(PMlist); ++i){
      for(uint k = 1; k <= dynlen(boardStatus); ++k){
        appendService(PMlist[i] + ".BoardStatus." + boardStatus[k], FEEserviceHat + dpSubStr(PMlist[i], DPSUB_DP) + "/status/" + boardStatus[k]);
      }
    }
  }
}

private void o_initTCM(string TCMDPE){
  if(!dpNameConverter(TCMDPE, "FIT_TCM")) return;
  for(uint k = 1; k <= dynlen(boardStatus); ++k){
    appendService(TCMDPE + "BoardStatus." + boardStatus[k], FEEserviceHat +  dpSubStr(TCMDPE, DPSUB_DP) + "/status/" + boardStatus[k]);
  }

  appendService(TCMDPE + "PM_MASK_SPI", FEEserviceHat + "TCM/status/PM_MASK_SPI");

  appendCommand(TCMDPE + "ORBIT_FILL_MASK",                FEEserviceHat + "TCM/control/ORBIT_FILL_MASK/set");
}

private o_initBkgrnd(string bkgrndDPE = "Bkgrnd?"){
  if(!dpTypeExists("FIT_background_counter")){
    throwError(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "Datapoints of type FIT_background_counter not found"));
    return;
  }
  dyn_string bkgrnds = dpNames(bkgrndDPE, "FIT_background_counter");
  if(!dynlen(bkgrnds)){
    throw(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "Datapoints of type FIT_background_counter not found"));
  }else{
    for(uint i = 1; i <= 10; i++){
      appendService(dpSubStr(bkgrnds[i], DPSUB_SYS_DP) + ".CNT_RATE", FEEserviceHat + "TCM/" + dpSubStr(bkgrnds[i], DPSUB_DP) + "/CNT_RATE");
      appendService(dpSubStr(bkgrnds[i], DPSUB_SYS_DP) + ".CNT"     , FEEserviceHat + "TCM/" + dpSubStr(bkgrnds[i], DPSUB_DP) + "/CNT"      );
      appendService(dpSubStr(bkgrnds[i], DPSUB_SYS_DP) + ".NAME"    , FEEserviceHat + "TCM/" + dpSubStr(bkgrnds[i], DPSUB_DP) + "/NAME"    );
    }
  }
}

private o_initTrigger(string trigDPE = "*"){
  if(!dpTypeExists("FIT_trigger")){
    throwError(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "Datapoints of type FIT_trigger not found"));
    return;
  }
  dyn_string triggers = dpNames(trigDPE, "FIT_trigger");
  if(!dynlen(triggers)){
    throw(makeError(errCatalogName, PRIO_INFO, ERR_PARAM, 1, "Datapoints of type FIT_trigger not found"));
  }else{
    for(uint i = 1; i <= dynlen(triggers); i++){
      appendService(triggers[i] + ".CNT_RATE", FEEserviceHat + "TCM/Trigger" + (string)i + "/CNT_RATE");
      appendService(triggers[i] + ".CNT"     , FEEserviceHat + "TCM/Trigger" + (string)i + "/CNT"      );
      appendService(triggers[i] + ".NAME"    , FEEserviceHat + "TCM/Trigger" + (string)i + "/NAME"    );
    }
  }
}

//======================================= NEW SERVICES/COMMANDS FORMAT====================================

private void initTCMlaserGenerator(string TCMLaserGeneratorDPE){
   if(!dpNameConverter(TCMLaserGeneratorDPE, "fitTCMLaserGenerator")) return;

   //if laser enabled
   appendService(TCMLaserGeneratorDPE + "actual.isOn",               FEEserviceHat + "LASER_ENABLED/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.onOff",            FEEserviceHat + "LASER_ENABLED/apply");

  //represent the source of trigger pulses for laser
   appendService(TCMLaserGeneratorDPE + "actual.source",             FEEserviceHat + "LASER_SOURCE/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.source",           FEEserviceHat + "LASER_SOURCE/apply");

   //laser Frequency
   appendService(TCMLaserGeneratorDPE + "actual.frequency",          FEEserviceHat + "LASER_FREQUENCY_Hz/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.frequency",        FEEserviceHat + "LASER_FREQUENCY_Hz/apply");

   //laser frequency divider
   appendService(TCMLaserGeneratorDPE + "actual.frequencyDivider",   FEEserviceHat + "LASER_DIVIDER/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.frequencyDivider", FEEserviceHat + "LASER_DIVIDER/apply");

   //laser delay
   appendService(TCMLaserGeneratorDPE + "actual.delay",              FEEserviceHat + "LASER_DELAY_ns/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.delay",            FEEserviceHat + "LASER_DELAY_ns/apply");

   //pattern
   appendService(TCMLaserGeneratorDPE + "actual.pattern",            FEEserviceHat + "LASER_PATTERN/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.pattern",          FEEserviceHat + "LASER_PATTERN/apply");

   //suppression
   appendService(TCMLaserGeneratorDPE + "actual.suppressionDuration",FEEserviceHat + "LSR_TRG_SUPPR_DUR/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.suppressionDuration", FEEserviceHat + "LSR_TRG_SUPPR_DUR/apply");
   appendService(TCMLaserGeneratorDPE + "actual.suppressionDelay",   FEEserviceHat + "LSR_TRG_SUPPR_DELAY/actual");
   appendCommand(TCMLaserGeneratorDPE + "settings.suppressionDelay", FEEserviceHat + "LSR_TRG_SUPPR_DELAY/apply");

 }

private void initFITattenuator(string fitAttenuatorDPE){
   if(!dpNameConverter(fitAttenuatorDPE, "fitAttenuator")) return;

   appendService(fitAttenuatorDPE + "actual.status" ,                 FEEserviceHat + "ATTEN_STATUS"      );

   appendService(fitAttenuatorDPE + "actual.value"  ,                 FEEserviceHat + "ATTEN_STEPS/actual");
   appendCommand(fitAttenuatorDPE + "settings.value",                 FEEserviceHat + "ATTEN_STEPS/apply" );
 }

private void initDynServices(string fitDynServicesDPE){
   if(!dpNameConverter(fitDynServicesDPE, "DIM_dynServices")) return;

   //PM channels
   appendService(fitDynServicesDPE + "fitPMchannel.ADC_ZERO" ,        FEEserviceHat + "ADC_ZERO/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.ADC_DELAY",        FEEserviceHat + "ADC_DELAY/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.ADC_RANGE",        FEEserviceHat + "ADC_RANGE/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.TIME_ALIGN",       FEEserviceHat + "TIME_ALIGN/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.CFD_ZERO",         FEEserviceHat + "CFD_ZERO/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.CFD_THRESHOLD",    FEEserviceHat + "CFD_THRESHOLD/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.THRESHOLD_CALIBR", FEEserviceHat + "THRESHOLD_CALIBR/actual");
   appendService(fitDynServicesDPE + "fitPMchannel.ADC_BASELINE",     FEEserviceHat + "ADC_BASELINE");
   appendService(fitDynServicesDPE + "fitPMchannel.ADC_MEANAMPL",     FEEserviceHat + "ADC_MEANAMPL");
   appendService(fitDynServicesDPE + "fitPMchannel.ADC_RMS",          FEEserviceHat + "ADC_RMS");
   appendService(fitDynServicesDPE + "fitPMchannel.RATE",             FEEserviceHat + "CNT_RATE_CH");
   appendService(fitDynServicesDPE + "fitPMchannel.COUNTER",          FEEserviceHat + "CNT_CH");

   //PM
   appendService(fitDynServicesDPE + "fitPM.CH_MASK_TRG",             FEEserviceHat + "CH_MASK_TRG/actual");
   appendService(fitDynServicesDPE + "fitPM.CH_MASK_DATA",            FEEserviceHat + "CH_MASK_DATA/actual");

   //Triggers

   //Readout
   appendService(fitDynServicesDPE + "fitReadout.RX_PHASE",           FEEserviceHat + "GBT/RX_PHASE");

 }

private void initDynCommands(string fitDynCommandsDPE){
   if(!dpNameConverter(fitDynCommandsDPE, "DIM_dynCommands")) return;

   //PM channels
   appendCommand(fitDynCommandsDPE + "fitPMchannel.ADC_ZERO" ,        FEEserviceHat + "ADC_ZERO/apply");
   appendCommand(fitDynCommandsDPE + "fitPMchannel.ADC_DELAY",        FEEserviceHat + "ADC_DELAY/apply");
   appendCommand(fitDynCommandsDPE + "fitPMchannel.ADC_RANGE",        FEEserviceHat + "ADC_RANGE/apply");
   appendCommand(fitDynCommandsDPE + "fitPMchannel.TIME_ALIGN",       FEEserviceHat + "TIME_ALIGN/apply");
   appendCommand(fitDynCommandsDPE + "fitPMchannel.CFD_ZERO",         FEEserviceHat + "CFD_ZERO/apply");
   appendCommand(fitDynCommandsDPE + "fitPMchannel.CFD_THRESHOLD",    FEEserviceHat + "CFD_THRESHOLD/apply");
   appendCommand(fitDynCommandsDPE + "fitPMchannel.THRESHOLD_CALIBR", FEEserviceHat + "THRESHOLD_CALIBR/apply");

   //PM
   appendCommand(fitDynCommandsDPE + "fitPM.CH_MASK_TRG",             FEEserviceHat + "CH_MASK_TRG/apply");
   appendCommand(fitDynCommandsDPE + "fitPM.CH_MASK_DATA",            FEEserviceHat + "CH_MASK_DATA/apply");

 }

private void initControlServer(string fitControlserverDPE){
   if(!dpNameConverter(fitControlserverDPE, "fitControlServer")) return;

   appendService(fitControlserverDPE + "status.boardsOK"            , FEEserviceHat + "BOARDS_OK");
   appendService(fitControlserverDPE + "status.description"         , FEEserviceHat + "SERVER_STATUS");

   appendCommand(fitControlserverDPE + "commands.clearErrors"       , FEEserviceHat + "CLEAR_ERRORS");
   appendCommand(fitControlserverDPE + "commands.loadDefaultConfigs", FEEserviceHat + "LOAD_CONFIG");
   appendCommand(fitControlserverDPE + "commands.reconnect"         , FEEserviceHat + "RECONNECT");
   appendCommand(fitControlserverDPE + "commands.restartSystem"     , FEEserviceHat + "RESTART_SYSTEM");
   appendCommand(fitControlserverDPE + "commands.stopServer"        , FEEserviceHat + "STOP_SERVER");
   appendCommand(fitControlserverDPE + "commands.suppressErrorReports", FEEserviceHat + "GBT/SUPPRESS_ERROR_REPORTS");
}

private void initCalibrationBusy(string calibrationDPE){
   if(!dpNameConverter(calibrationDPE, "fit_calibration")) return;

   appendService(calibrationDPE + "busy",                            "BUSY_CALIBRATING");
}

private void initTCM(string TCMDPE){
   if(!dpNameConverter(TCMDPE, "fitTCM")) return;

   appendCommand(TCMDPE + "settings.resetCounters",                  FEEserviceHat + "RESET_COUNTS");
//    appendCommand(TCMDPE + "settings.ORBIT_FILL_MASK",                FEEserviceHat + "TCM/control/ORBIT_FILL_MASK/set");

   appendService(TCMDPE + "actual.PMmaskSPI",                        FEEserviceHat + "TCM/status/PM_MASK_SPI");
}

private void DIMcommandSent(string dpe, anytype value){
  FT0_LOG.addLogEntry("DIM command sent: " + dpSubStr(dpe, DPSUB_DP_EL), LOG_WRITE, LOG_NO_SHOW);
}

