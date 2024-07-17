/** DOMBuilderCreate: function used in the past to interface C++ softwar to parse XML files
 *
 * @deprecated 2018-06-25
 */

DOMBuilderCreate(string caenEasyFileName, dyn_dyn_string &devices, dyn_string &exceptionInfo)
{
  FWDEPRECATED();

  _fwCaen_parseXmlFile(caenEasyFileName, devices, exceptionInfo);
}