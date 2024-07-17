/**@file

   @par Creation Date
        19/07/2010

   @par Constraints
       CtrlXml and fwXML/fwXML.ctl libraries

   @author Manuel Gonzalez Berges (IT-CO)
   @author Jonas Arroyo Garcia (BE-ICS-FD)

   @copyright CERN copyright
 */

//@{

// Library dependencies
#uses "CtrlXml"
#uses "fwXML/fwXML.ctl"
#uses "fwCaen/fwCaenDeprecated.ctl"


// Constants
/** @var string JCOP_FRAMEWORK_CAEN_DEBUG

 Debug flag used to show only fwCaen debug messages on runtime
*/
string JCOP_FRAMEWORK_CAEN_DEBUG = "JCOP_FRAMEWORK_CAEN_DEBUG";


struct FwCaenEasyDeviceInfo{
    string type;
    string model;
    int slot;
};



/** Internal function to parse an Easy System XML configuration file. It returns a dyn_dyn array with the list of devices.

   @par Constraints
       CtrlXml and fwXML/fwXML.ctl libraries

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param[in]   caenEasyFileName    string: XML file name that has been produced by the CAEN Easy rack configuration for WinCC OA
   @param[out]  easyDevicesInfo     vector<FwCaenEasyDeviceInfo>: contains the list of devices parsed from the CAEN Easy rack XML file
   @param[out]  exceptionInfo       dyn_string: returns details of any errors

   @return Nothing
*/
_fwCaen_parseXmlFile(string caenEasyFileName, vector<FwCaenEasyDeviceInfo> &easyDevicesInfo, dyn_string &exceptionInfo)
{
    DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "fwCaen_parseXmlFile: starting CAEN XML parsing...");

    string errMsg, errLin, errCol;
    int docum = xmlDocumentFromFile(caenEasyFileName, errMsg, errLin, errCol );
    DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "fwCaen_parseXmlFile: document id = " + docum );

    if (docum < 0){
        DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "fwCaen_parseXmlFile: parsing Error-Message = '" + errMsg + "' Line=" + errLin + " Column=" + errCol );
        return;
    }
    dyn_string exInfo;
    dyn_int racks = fwXml_elementsByTagName ( docum , -1 , "EASY_Rack" , exInfo );
    _fwCaen_printElements ( docum , racks );

    if(racks.isEmpty()){
      DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "Parsing CAEN XML file: could not find any racks");
      return;
    }

    int errorCode;
    // Iterate through the racks to fins the list of crates
    // @TODO: there should be only one rack, if more we get only the last one(i think - check?)
    dyn_int crateList;
    for(int i = 1; i <= dynlen(racks); i++){
      errorCode = xmlChildNodes(docum, racks[i], crateList);
    }

    _fwCaen_printElements(docum , crateList);

    string stringValue;
    // Iterate over the crates to find the boards
    for(int i = 1; i <= dynlen(crateList); i++){
      FwCaenEasyDeviceInfo easyCrateInfo;
      easyCrateInfo.type  = xmlNodeName(docum, crateList[i]);
      errorCode     = xmlGetElementAttribute(docum, crateList[i], "Name", stringValue);
      easyCrateInfo.model = stringValue;
      easyCrateInfo.slot  = i - 1;

      // Add crate to the list of devices
      easyDevicesInfo.append(easyCrateInfo);

      // Get list of boards in the crate
      dyn_int boardList;
      errorCode = xmlChildNodes(docum, crateList[i], boardList);

      // Iterate over the boards in the crate
      for(int j = 1; j <= dynlen(boardList); j++){
        FwCaenEasyDeviceInfo easyBoardInfo;
        easyBoardInfo.type  = xmlNodeName(docum, boardList[j]);
        errorCode     = _fwCaen_getAttributesOrChildNodeValue(docum, boardList[j], "EASY_Board_Model", stringValue);

        easyBoardInfo.model = stringValue;
        errorCode     = _fwCaen_getAttributesOrChildNodeValue(docum, boardList[j], "Slot", stringValue);

        easyBoardInfo.slot  = (int)stringValue;

        // Add board to the list of devices
        easyDevicesInfo.append(easyBoardInfo);
      }
    }

    DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, easyDevicesInfo);

    int rtn_code = xmlCloseDocument(docum);
    DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "rtn_code = " + rtn_code );
}




/** Internal function to get attributes or child node values in the Easy System XML configuration file. It returns the attribute value.

   @par Constraints
      CtrlXml and fwXML/fwXML.ctl libraries

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param[in]  doc   unsigned: document id, kept in memory
   @param[in]  node  unsigned: XML node id, kept in memory
   @param[in]  name  string: attribute name to be read
   @param[out] value string: attribute value read

   @return  int: 0 = success, -1 = error, no attribute name or node with the right name was found
*/
int _fwCaen_getAttributesOrChildNodeValue(unsigned doc, unsigned node, string name, string &value)
{
  unsigned i, j;
  int errorCode, childNodeType;
  string childNodeName, childNodeValue;
  dyn_string elementChildNodes;
  dyn_int childNodes;

  DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): looking for value for " + name);

  value = "";

  // Fisrt look in the attributes
   errorCode = xmlGetElementAttribute(doc, node, name, value);

  if(value != "")
    {
    DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): found " + name + " as attribute with value " + value);
    return 0;
    }

  // If it wasn't found in the attributes, look in the child nodes
  errorCode = xmlChildNodes(doc, node, childNodes);
  DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): there are " + dynlen(childNodes) + " children.");

  for(i = 1; i <= dynlen(childNodes); i++)
  {
      childNodeName = xmlNodeName(doc, childNodes[i]);
      DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): looking at " + childNodeName);

      // element node with the right name found, we have to look for a child text node
      if(childNodeName == name)
      {
         errorCode = xmlChildNodes(doc, childNodes[i], elementChildNodes);
          for(j = 1; j <= dynlen(elementChildNodes); j++)
      {
            DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "_fwCaen_getAttributesOrChildNodeValue(): xmlNodeType " + xmlNodeType(doc, elementChildNodes[j]) + " xmlNodeValue: " + xmlNodeValue(doc, elementChildNodes[j]));
            // if the node is of type text, get its value
          if (xmlNodeType(doc, elementChildNodes[j]) == XML_TEXT_NODE)
           {
          value = xmlNodeValue(doc, elementChildNodes[j]);
             return 0;
            }
        }
      }
   }

  // If no attribute or node with the right name was found then return error code
  if(value == "")
    return -1;
}






/** Print a list of node ids in memory

   @par Constraints
        CtrlXml and fwXML/fwXML.ctl libraries

   @par Usage
        Private

   @par PVSS managers
        VISION

   @param[in]  doc       unsigned: document id, kept in memory
   @param[in]  elements  dyn_int: array with the list of nodes to print

   @return Nothing
*/
void _fwCaen_printElements ( int docum , dyn_int elements )
{
  string tagname;
  mapping attribs;

  for ( int idx = 1 ; idx <= dynlen(elements) ; ++idx )
  {
    tagname = xmlNodeName ( docum , elements[idx] );
    attribs = xmlElementAttributes ( docum , elements[idx] );
    DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "TagName of Node " + elements[idx] + " = '" + tagname
          + "'   Attribs = '" + (string)attribs + "'" );
  }
  DebugFTN(JCOP_FRAMEWORK_CAEN_DEBUG, "");
}



void _fwCaen_makeEasyModelsDptsCache(mapping &easyModelNameToDeviceDpt, dyn_string &exceptionInfo){
    dyn_string easyModelDps = dpNames("FwCaenBoardEasy*", "_FwDeviceModel");
    dynAppendConst(easyModelDps, dpNames("FwCaenCrateEasy*", "_FwDeviceModel"));

    dyn_string easyModelDpTypeDpes;
    dyn_string easyModelNameDpes;
    for(int i=0;i<easyModelDps.count();i++){
        easyModelDpTypeDpes.append(easyModelDps.at(i) + ".dpType");
        easyModelNameDpes.append(easyModelDps.at(i) + ".model");
    }

    dyn_string easyModelDpTypes;
    dpGet(easyModelDpTypeDpes, easyModelDpTypes);
    dyn_string easyModelNames;
    dpGet(easyModelNameDpes, easyModelNames);

    if(easyModelDpTypes.count() != easyModelNames.count()){
        fwException_raise(exceptionInfo, "ERROR", "TODO: add exception description", "");
        return;
    }

    for(int i=0;i<easyModelDpTypes.count();i++){
        easyModelNameToDeviceDpt.insert(easyModelNames.at(i), easyModelDpTypes.at(i));
    }
}



void _fwCaen_getBoardAndChannels(string crateDeviceDpName,
                                 dyn_string dsDevice,
                                 int boardSlot,
                                 dyn_dyn_string &ddsDevicesToBeCreated,
                                 int &iCount,
                                 dyn_string &exceptionInfo){
    const string BOARD_PREFIX       = "   ";
    const string CHANNEL_PREFIX     = "      ";

    string boardModel = dsDevice[fwDevice_MODEL];
    fwDevice_getDefaultName(dsDevice, boardSlot, dsDevice[fwDevice_DP_NAME], exceptionInfo);

    string sBoardDeviceDpName = crateDeviceDpName + fwDevice_HIERARCHY_SEPARATOR + dsDevice[fwDevice_DP_NAME];
    string sBoardDeviceName   = dsDevice[fwDevice_DP_NAME];
    string sDeviceType;
    fwDevice_getType(dsDevice[fwDevice_DP_TYPE], sDeviceType, exceptionInfo);

    if(!exceptionInfo.isEmpty()){
        fwException_raise(exceptionInfo, "ERROR", "Error getting device definition type for device: " + dsDevice[fwDevice_DP_NAME], "");
        return;
    }

    string deviceObjStr = strjoin(dsDevice, "|");
    ddsDevicesToBeCreated[iCount++] = makeDynString(BOARD_PREFIX + dsDevice[fwDevice_DP_NAME],
                                                    sDeviceType,
                                                    dsDevice[fwDevice_MODEL],
                                                    deviceObjStr,
                                                    crateDeviceDpName);


    // Initialize the device type for channels to the default
    string sChannelDeviceType = "FwCaenChannel";
    string sChannelModel;

    switch( boardModel ){
        case "A6601":{
            dyn_dyn_string channelDevices;
            int channelNum = 1;
            channelDevices[channelNum++] =     makeDynString("", "FwCaenChannelA6601", "", "CAEN Easy Channel A6601 MainLV");
            for(int i=1;i<=12;i++){
                channelDevices[channelNum++] = makeDynString("", "FwCaenChannelA6601", "", "CAEN Easy Channel A6601 LV");
            }
            channelDevices[channelNum++] =     makeDynString("", "FwCaenChannelA6601", "", "CAEN Easy Channel A6601 AuxLV");
            for(int i=1;i<=3;i++){
                channelDevices[channelNum++] = makeDynString("", "FwCaenChannelA6601", "", "CAEN Easy Channel A6601 HV");
            }

            for(int i=1;i<=dynlen(channelDevices);i++){
                dsDevice = channelDevices[i];
                fwDevice_getDefaultName(dsDevice, i-1, dsDevice[fwDevice_DP_NAME], exceptionInfo);
                if(dynlen(exceptionInfo) > 0 ){
                    fwException_raise(exceptionInfo, "ERROR", "Error getting default name for device: " + dsDevice, "");
                    return;
                }

                fwDevice_getType(dsDevice[fwDevice_DP_TYPE], sDeviceType, exceptionInfo);
                if(dynlen(exceptionInfo) > 0){
                    fwException_raise(exceptionInfo, "ERROR", "Error getting device definition type for device LV1: " + dsDevice, "");
                    return;
                }
                string sAux = strjoin(dsDevice, "|");
                ddsDevicesToBeCreated[iCount++] = makeDynString(CHANNEL_PREFIX + dsDevice[fwDevice_DP_NAME],
                                                                sDeviceType,
                                                                dsDevice[fwDevice_MODEL],
                                                                sAux,
                                                                sBoardDeviceDpName);
            }
            break;
        }
        // CMS Tracker & Forward Pixel boards are special, treat them separately
        case "A4601F":
        case "A4601H":
        case "A4603":
        case "A4603DH":
            if( boardModel == "A4603DH" ){
                sChannelModel = boardModel;
                sChannelDeviceType = "FwCaenChannelA4603";
            }
            else{
                sChannelModel = substr(boardModel, 0, 5);
            }

            int iPos = 0;
            dsDevice[fwDevice_DP_NAME] = "";
            string sBoardDeviceName2;
            fwDevice_getDefaultName(dsDevice, boardSlot + 1 , sBoardDeviceName2, exceptionInfo);
            if( dynlen(exceptionInfo) > 0 ){
                fwException_raise          (exceptionInfo, "ERROR", "Error getting default name for device: " + dsDevice, "");
                fwExceptionHandling_display(exceptionInfo);
                return;
            }

            dyn_dyn_string channelDevices;
            channelDevices[1] = makeDynString("", sChannelDeviceType, "", "CAEN Easy Channel " + sChannelModel + " LV1");
            channelDevices[2] = makeDynString("", "FwCaenChannel", "", "CAEN Easy Channel " + sChannelModel + " LV2");
            channelDevices[3] = makeDynString("", "FwCaenChannel", "", "CAEN Easy Channel " + sChannelModel + " HV");
            channelDevices[4] = makeDynString("", "FwCaenChannel", "", "CAEN Easy Channel " + sChannelModel + " HV");

            for(int i=1;i<=dynlen(channelDevices);i++){
                dsDevice = channelDevices[i];
                fwDevice_getDefaultName(dsDevice, iPos++, dsDevice[fwDevice_DP_NAME], exceptionInfo);
                if(dynlen(exceptionInfo) > 0 ){
                    fwException_raise(exceptionInfo, "ERROR", "Error getting default name for device: " + dsDevice, "");
                    return;
                }

                fwDevice_getType(dsDevice[fwDevice_DP_TYPE], sDeviceType, exceptionInfo);
                if(dynlen(exceptionInfo) > 0){
                    fwException_raise(exceptionInfo, "ERROR", "Error getting device definition type for device LV1: " + dsDevice, "");
                    return;
                }
                string sAux = strjoin(dsDevice, "|");
                ddsDevicesToBeCreated[iCount++] = makeDynString(CHANNEL_PREFIX + dsDevice[fwDevice_DP_NAME],
                                                                sDeviceType,
                                                                dsDevice[fwDevice_MODEL],
                                                                sAux,
                                                                sBoardDeviceDpName);
            }

            // One of these special boards is seen in the Framework as two boards, so duplicate it
            int iLenLoopA = dynlen(ddsDevicesToBeCreated);
            for(int iLoopA = 4 ; iLoopA >= 0 ; iLoopA-- ){
                ddsDevicesToBeCreated[iCount] = ddsDevicesToBeCreated[iLenLoopA - iLoopA];
                int iLenLoopB = dynlen(ddsDevicesToBeCreated[iCount]);
                for(int iLoopB = 1 ; iLoopB <= iLenLoopB ; iLoopB++ ){
                    strreplace(ddsDevicesToBeCreated[iCount][iLoopB], sBoardDeviceName, sBoardDeviceName2);
                }
                iCount++;
            }
            break;

        case "A3802":
            sChannelModel              = "CAEN Easy Channel " + boardModel;
            sChannelDeviceType         = "FwCaenChannelDAC";
            int iPos                   = 0;
            dsDevice[fwDevice_DP_NAME] = "";

            // Iterate through the channels
            for(int iLoopA = 0 ; iLoopA <= 127 ; iLoopA++ )
            {
                // check if it is a channel group or a normal channel
                if( fmod(iLoopA, 8) == 0 )
                {
                    dsDevice = makeDynString("", sChannelDeviceType, "", sChannelModel + " Group");
                }
                else
                {
                    dsDevice = makeDynString("", sChannelDeviceType, "", sChannelModel);
                }
                fwDevice_getDefaultName(dsDevice, iPos++, dsDevice[fwDevice_DP_NAME], exceptionInfo);
                if( dynlen(exceptionInfo) > 0 )
                {
                    fwException_raise          (exceptionInfo, "ERROR", "Error getting default name for device: " + dsDevice, "");
                    fwExceptionHandling_display(exceptionInfo);
                    return;
                }

                fwDevice_getType(dsDevice[fwDevice_DP_TYPE], sDeviceType, exceptionInfo);
                if( dynlen(exceptionInfo) > 0 )
                {
                    fwException_raise          (exceptionInfo, "ERROR", "Error getting default type for device: " + dsDevice, "");
                    fwExceptionHandling_display(exceptionInfo);
                    return;
                }

                string sAux = strjoin(dsDevice, "|");
                ddsDevicesToBeCreated[iCount++] = makeDynString(CHANNEL_PREFIX + dsDevice[fwDevice_DP_NAME],
                                                                sDeviceType,
                                                                dsDevice[fwDevice_MODEL],
                                                                sAux,
                                                                sBoardDeviceDpName);
            }
            break;

        case "A3801":
        case "A3801A":
            sChannelDeviceType = "FwCaenChannelADC";
            // After setting the dp type continue as with a standard board

        default:{
            int iNumOfSlots;
            fwDevice_getModelSlots(makeDynString("", dsDevice[fwDevice_DP_TYPE], "", dsDevice[fwDevice_MODEL]), iNumOfSlots, exceptionInfo);
            if( dynlen(exceptionInfo) > 0 ){
                fwException_raise(exceptionInfo, "ERROR", "Error getting default number of slots for device type: " + dsDevice[fwDevice_DP_TYPE], "");
                return;
            }


            for(int iLoopA = 1 ; iLoopA <= iNumOfSlots ; iLoopA++ )
            {
                string sDefaultName;
                dsDevice = makeDynString("", sChannelDeviceType, "", "CAEN Easy Channel " + boardModel);
                fwDevice_getDefaultName(dsDevice, iLoopA - 1, sDefaultName, exceptionInfo);
                if( dynlen(exceptionInfo) > 0 )
                {
                    fwException_raise(exceptionInfo, "ERROR", "Error getting default name for device: " + dsDevice, "");
                    return;
                }
                dsDevice[fwDevice_DP_NAME] = sDefaultName;

                fwDevice_getType(dsDevice[fwDevice_DP_TYPE], sDeviceType, exceptionInfo);
                if( dynlen(exceptionInfo) > 0 )
                {
                    fwException_raise(exceptionInfo, "ERROR", "Error getting default type for device: " + dsDevice, "");
                    return;
                }
                string sAux = strjoin(dsDevice, "|");
                ddsDevicesToBeCreated[iCount++] = makeDynString(CHANNEL_PREFIX + dsDevice[fwDevice_DP_NAME],
                                                                sDeviceType,
                                                                dsDevice[fwDevice_MODEL],
                                                                sAux,
                                                                sBoardDeviceDpName);
            }
            // if it was an A1396, it contains 2 power supplies so it has to be duplicated
            if( boardModel == "A1396" )
            {
                dyn_string dsBoardDevice = dsDevice;
                dsBoardDevice[fwDevice_DP_NAME] = "";
                string sBoardDeviceName2;
                fwDevice_getDefaultName(dsBoardDevice, boardSlot + 1 , sBoardDeviceName2, exceptionInfo);
                if( dynlen(exceptionInfo) > 0 ){
                    fwException_raise(exceptionInfo, "ERROR", "Error getting default name for device: " + dsBoardDevice, "");
                    return;
                }

                int iLenLoopA = dynlen(ddsDevicesToBeCreated);
                for(int iLoopA = iNumOfSlots ; iLoopA >= 0 ; iLoopA-- )
                {
                    ddsDevicesToBeCreated[iCount] = ddsDevicesToBeCreated[iLenLoopA - iLoopA];
                    int iLenLoopB                     = dynlen(ddsDevicesToBeCreated[iCount]);
                    for(int iLoopB = 1 ; iLoopB <= iLenLoopB ; iLoopB++ )
                    {
                        strreplace(ddsDevicesToBeCreated[iCount][iLoopB], sBoardDeviceName, sBoardDeviceName2);
                    }
                    iCount++;
                }
            }
            break;
        }
    }
}

void _fwCaen_buildListOfDevicesToCreate(string parentDeviceDp,
                                        const vector<FwCaenEasyDeviceInfo> &easyDevicesInfo,
                                        dyn_dyn_string &ddsDevicesToBeCreated,
                                        dyn_string &exceptionInfo){
    mapping easyModelNameToDeviceDpt;
    _fwCaen_makeEasyModelsDptsCache(easyModelNameToDeviceDpt, exceptionInfo);
    if(!exceptionInfo.isEmpty()){
        return;
    }

    int iCount = 1;
    int iSlotIncrement;
    string sCrateDeviceDpName;

    for(int i=0;i<easyDevicesInfo.count();i++){
        FwCaenEasyDeviceInfo easyDeviceInfo = easyDevicesInfo.at(i);

        if(strtoupper(easyDeviceInfo.model) == "EMPTY"){ // Undefined crate in branch controller configuration
            continue;
        }
        if(!easyModelNameToDeviceDpt.contains(easyDeviceInfo.model)){
            fwException_raise(exceptionInfo, "ERROR", "Not supported " + easyDeviceInfo.type + " model " + easyDeviceInfo.model, "");
            return;
        }

        dyn_string dsDevice = makeDynString(
                "",
                easyModelNameToDeviceDpt.value(easyDeviceInfo.model),
                "",
                easyDeviceInfo.model);


      switch( easyDeviceInfo.type )
      {
          case "EASY_Crate":{
          switch( easyDeviceInfo.model )
          {
            case "EASY4000":
              iSlotIncrement = 2;
              break;

            case "EASY3000":
              iSlotIncrement = 1;
              break;

            default:
              fwException_raise(exceptionInfo, "ERROR", "Not supported Easy crate model " + easyDeviceInfo.model, "");
              return;
          }

          fwDevice_getDefaultName(dsDevice, easyDeviceInfo.slot, dsDevice[fwDevice_DP_NAME], exceptionInfo);
        if(!exceptionInfo.isEmpty()){
            fwException_raise(exceptionInfo, "ERROR", "Error getting default name for device: " + dsDevice[fwDevice_DP_NAME], "");
            return;
        }

          sCrateDeviceDpName = parentDeviceDp + fwDevice_HIERARCHY_SEPARATOR + dsDevice[fwDevice_DP_NAME];
          string sDeviceType;
          fwDevice_getType(dsDevice[fwDevice_DP_TYPE], sDeviceType, exceptionInfo);
          if(!exceptionInfo.isEmpty()){
            fwException_raise(exceptionInfo, "ERROR", "Error getting device definition type for device: " + dsDevice[fwDevice_DP_NAME], "");
            return;
          }

          string deviceObjStr = strjoin(dsDevice, "|");
          ddsDevicesToBeCreated[iCount++] = makeDynString(dsDevice[fwDevice_DP_NAME],
                                                          sDeviceType,
                                                          dsDevice[fwDevice_MODEL],
                                                          deviceObjStr,
                                                          parentDeviceDp);
          break;
        }


        case "EASY_Board":
              _fwCaen_getBoardAndChannels(sCrateDeviceDpName,
                                          dsDevice,
                                          easyDeviceInfo.slot * iSlotIncrement,
                                          ddsDevicesToBeCreated,
                                          iCount,
                                          exceptionInfo);
              break;

        default:
          break;
      }
    }
}

//@}

