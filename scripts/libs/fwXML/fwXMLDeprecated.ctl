/** 'fwXml_getChildNodesContent' returns tags, attributes and contained data of all children
  
@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	UI, CTRL

@param documentId        input, the document identifier
@param topNodeId         input, the top node-identifier of the parent element-node container
@param node_names        output, the node-names or tag-names for element-nodes
@param attributes        output, the attributes of element-nodes and added infomation
@param nodevalues        output, the node-values or values of the unique child's text-node
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, the combined types of the type of children which data is returned
        
@par
For the full description refer to the identical function: 'fwXml_childNodesContent'.
  
*/

public int fwXml_getChildNodesContent ( unsigned documentId , int topNodeId ,
           dyn_string &node_names , dyn_anytype &attributes , dyn_string &nodevalues ,
           dyn_string &exceptionInfo )
{

  FWDEPRECATED();

  return ( fwXml_childNodesContent ( documentId , topNodeId , node_names , attributes , nodevalues , exceptionInfo ) );
}





/** 'fwXml_getElementsByTagName' returns all children which have a specific element's tag-name

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	UI, CTRL

@param documentId        input, the document identifier
@param topNodeId         input, the top node-identifier of the parent or -1 (root-node)
@param tagName           input, the tag-name of the children which need to be returned
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, all children which have a specific element's tag-name
        
@par
For the full description refer to the identical function: 'fwXml_elementsByTagName'.

*/

public dyn_int fwXml_getElementsByTagName ( unsigned documentId , int topNodeId , string tagName ,
                                            dyn_string &exceptionInfo )
{

  FWDEPRECATED();

  return ( fwXml_elementsByTagName ( documentId , topNodeId , tagName , exceptionInfo ) );
}





/** 'fwXml_printAllNodeTypes' prints all the enumerated values of node-types out.

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	UI, CTRL

@return               void

@par
When called, it prints out the enumerated values of node-types as shown below.

\code
    ["Enumerated value for XML_ELEMENT_NODE is 1"]
    ["Enumerated value for XML_ATTRIBUTE_NODE is 2"]
    ["Enumerated value for XML_TEXT_NODE is 3"]
    ["Enumerated value for XML_CDATA_SECTION_NODE is 4"]
    ["Enumerated value for XML_ENTITY_REFERENCE_NODE is 5"]
    ["Enumerated value for XML_ENTITY_NODE is 6"]
    ["Enumerated value for XML_PROCESSING_INSTRUCTION_NODE is 7"]
    ["Enumerated value for XML_COMMENT_NODE is 8"]
    ["Enumerated value for XML_DOCUMENT_NODE is 9"]
    ["Enumerated value for XML_DOCUMENT_TYPE_NODE is 10"]
    ["Enumerated value for XML_DOCUMENT_FRAGMENT_NODE is 11"]
    ["Enumerated value for XML_NOTATION_NODE is 12"]
\endcode

*/
public void fwXml_printAllNodeTypes()
{

  FWDEPRECATED();

  DebugN ( "Enumerated value for XML_ELEMENT_NODE is "                + XML_ELEMENT_NODE );
 
  DebugN ( "Enumerated value for XML_ATTRIBUTE_NODE is "              + XML_ATTRIBUTE_NODE );
 
  DebugN ( "Enumerated value for XML_TEXT_NODE is "                   + XML_TEXT_NODE );
 
  DebugN ( "Enumerated value for XML_CDATA_SECTION_NODE is "          + XML_CDATA_SECTION_NODE );
 
  DebugN ( "Enumerated value for XML_ENTITY_REFERENCE_NODE is "       + XML_ENTITY_REFERENCE_NODE );
 
  DebugN ( "Enumerated value for XML_ENTITY_NODE is "                 + XML_ENTITY_NODE );
 
  DebugN ( "Enumerated value for XML_PROCESSING_INSTRUCTION_NODE is " + XML_PROCESSING_INSTRUCTION_NODE );
 
  DebugN ( "Enumerated value for XML_COMMENT_NODE is "                + XML_COMMENT_NODE );
 
  DebugN ( "Enumerated value for XML_DOCUMENT_NODE is "               + XML_DOCUMENT_NODE );
 
  DebugN ( "Enumerated value for XML_DOCUMENT_TYPE_NODE is "          + XML_DOCUMENT_TYPE_NODE );
 
  DebugN ( "Enumerated value for XML_DOCUMENT_FRAGMENT_NODE is "      + XML_DOCUMENT_FRAGMENT_NODE );
 
  DebugN ( "Enumerated value for XML_NOTATION_NODE is "               + XML_NOTATION_NODE );
}





/** 'fwXml_trim' to trim a string, especially to be used for trimming an Xml-Node's value.

@par Constraints
	None

@par Usage
	Public

@deprecated 2018-06-25

@par PVSS managers
	UI, CTRL

@param value          inout, the value to be trimmed
@return               output, the trimmed value
*/

public string fwXml_trim ( string value )
{

  FWDEPRECATED();

  return ( strltrim ( strrtrim ( value ) ) );
}