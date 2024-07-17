// $License: NOLICENSE
//--------------------------------------------------------------------------------
 /**
   @file $relPath
   @copyright $copyright
   @author Sukhanov Mikhail
 */

// --------------------------------------------------------------------------------
//Libraries used (#uses)
#uses "wizardFramework"
#uses "fwDIM/fwDIM.ctl" //biblioteka DIM


//--------------------------------------------------------------------------------
//Variables and Constants
 string CONFIG_NAME = "FRED";


main()
{
  fwDim_deleteConfig(CONFIG_NAME);
  fwDim_createConfig(CONFIG_NAME);
  fwDim_subscribeService(CONFIG_NAME, "CALCULATOR/SCORE", "dist_1:calculator.calculator", -28);
  fwDim_subscribeService(CONFIG_NAME, "DELPHI/RUN_NUMBER", "dist_1:calculator.number", -23);


   fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/Trigger4/NAME", "dist_1:calculator.send", 1);
  //fwDim_subscribeCommand(CONFIG_NAME, "CALCULATOR/OPERATION", "dist_1:calculator.send", 1);

//------------------------------------
//FT0
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/TEMP_BOARD", "dist_1:_mp_FT0.TCM/status/TEMP_BOARD", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/TEMP_BOARD_TEMP_FPGA", "dist_1:_mp_FT0.TCM/status/TEMP_FPGA", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/VOLTAGE_1V", "dist_1:_mp_FT0.TCM/status/VOLTAGE_1V", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/VOLTAGE_1_8V", "dist_1:_mp_FT0.TCM/status/VOLTAGE_1_8V", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/BOARD_TYPE", "dist_1:_mp_FT0.TCM/status/BOARD_TYPE", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/FW_TIME_MCU", "dist_1:_mp_FT0.TCM/status/FW_TIME_MCU", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/FW_TIME_FPGA", "dist_1:_mp_FT0.TCM/status/FW_TIME_FPGA", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/CH_BASELINES_NOK", "dist_1:_mp_FT0.TCM/status/CH_BASELINES_NOK", 1);
 fwDim_subscribeService(CONFIG_NAME, "FT0/TCM/status/SERIAL_NUM", "dist_1:_mp_FT0.TCM/status/SERIAL_NUM", 1);


}

 /*
  DebugN("createconfig: ", dp);
  dyn_string service_names;
  dyn_string dp_names;
  fwDim_getPublishedServices(dp, service_names, dp_names);
  DebugN(service_names);
 */
