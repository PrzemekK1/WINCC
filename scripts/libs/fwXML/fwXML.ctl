/**@file

This library contains the XML SAX function call and some additional XML DOM function calls.

@par Creation Date
	01/12/2008

@par Modification History
        09/11/2015: Code Improvement as a result of Crucible
        19/08/2013: Generalise fwXml_appendChildContent
                    Bug in recovery mechanism of fwXml_appendChildContent
        06/04/2010: Removed .dll extension from #uses
        22/06/2009: Added fwXml_appendChildContent
        01/12/2008: Initial version
	
@par Constraints
	For PVSS 3.6 SP2 and later versions

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@author
  01/02/2016 - James Hamilton (EN-ICE)
	01/12/2008 - Daniel Davids (IT-CO)
*/

#uses "CtrlXml"
#uses "fwXML/fwXMLDeprecated.ctl"


/** @mainpage JCOP Framework XML
 *
 *
\section documentation Documentation:
* Documentation on <a href="fwXML_8ctl.html">Functions and Variables</a>.
*/


//@{


/** fwXml_PARSING_DOWNORACROSS
Constant used in calculating the type of 'callback' that needs to be executed!
This directive specifiy the 'callbacks' to be executed when parsing down or across for leave-nodes.
*/
private const int fwXml_PARSING_DOWNORACROSS = 0;

/** fwXml_PARSING_DOWNORACROSS
Constant used in calculating the type of 'callback' that needs to be executed!
This directive specifiy the 'callbacks' to be executed when parsing up, which means leaving the node.
*/
private const int fwXml_PARSING_WHEN_LEAVING = 1;





/** fwXml_SAXSTARTELEMENT
Constant used in the mapping that associates the user-defined callback to the start of an Xml element-node
*/
const int fwXml_SAXSTARTELEMENT       = 2;

/** fwXml_SAXENDELEMENT
Constant used in the mapping that associates the user-defined callback to the end of an Xml element-node
*/
const int fwXml_SAXENDELEMENT         = 3;

/** fwXml_SAXTEXT
Constant used in the mapping that associates the user-defined callback to an Xml text-node
*/
const int fwXml_SAXTEXT               = 6;





/** '_fwXml_getTypeOfCallback' calculates the type of 'callback' that needs to be executed!
  
@par Constraints
	None

@par Usage
	Private

@par PVSS managers
	UI, CTRL

@param parsingDownAcrossOrUp    input, the parsing direction
@param nodeType                 input, the node-type of the encopuntered node
@return                         output, the type of callback

@par Philosophy
            The philosophy behind this is that a non-leaf node can be parsed in two directions, when
            going down (pre-fix scanning) or when going up (post-fix scanning).  A leaf node can only
            be parsed in one direction, across (infix scanning).
@par
            To make an association between a note-type and the corresponding type of 'callback', one 
            has made the following rule: the type of callback to be executed when parsing down or across 
            is twice the node-type's value; the type of callback to be executed when parsing up is twice
            the node-type's value plus one!
*/

private int _fwXml_getTypeOfCallback ( int parsingDownAcrossOrUp , int nodeType )
{
  return ( 2 * nodeType + parsingDownAcrossOrUp );
}


/** '_fwXml_parseSaxRecursive' called by 'fwXml_parseSaxFromFile' and itself in a recursive way.

@par Constraints
	None

@par Usage
	Private

@par PVSS managers
	UI, CTRL

@param documentId        input, the document-ident of the loaded Xml file
@param callBackList      input, the callback functions to be called while parsing
@param level             input, the current nesting-level of the recursive calls
@param topNodeId         input, the top node-ident from which the sub-tree is parsed
@param exceptionInfo     inout, returns details of any exceptions
@return                  void
*/

private void _fwXml_parseSaxRecursive ( int documentId , 
             mapping callBackList , int level , int topNodeId ,
             dyn_string &exceptionInfo )
{
dyn_errClass error;
mapping      attributs;
int          rtn_code, node_typ;
string       node_nam, node_val;
int          this_node, neighbour;
string       commandCallback;

  node_typ = xmlNodeType ( documentId , topNodeId );
  node_nam = xmlNodeName ( documentId , topNodeId );
  node_val = xmlNodeValue ( documentId , topNodeId );

  if ( node_typ == XML_ELEMENT_NODE )
  {
    attributs = xmlElementAttributes ( documentId , topNodeId );
  }

  if ( mappingHasKey ( callBackList , _fwXml_getTypeOfCallback ( fwXml_PARSING_DOWNORACROSS , node_typ ) ) )
  {
    commandCallback = "int main(int level, int typ, string nam, string val, mapping map ) ";
    
    switch ( _fwXml_getTypeOfCallback ( fwXml_PARSING_DOWNORACROSS , node_typ ) )
    {
      case fwXml_SAXSTARTELEMENT:
              commandCallback += "{ "+callBackList[fwXml_SAXSTARTELEMENT]+"( nam , map ); return 0; }";
              break;
      case fwXml_SAXTEXT:
              commandCallback += "{ "+callBackList[fwXml_SAXTEXT]+"( val ); return 0; }";
              break;
      default:
              commandCallback = "";
              break;
    }
  
    // DebugN ( "callbk "+commandCallback );
  
    rtn_code = execScript(commandCallback, makeDynString(), 
                          level , node_typ, node_nam, node_val, attributs );
    // DebugN("execScript Returns '"+rtn_code+"'");
  }
  
  ++level;

  this_node = topNodeId;
  
  neighbour = xmlFirstChild ( documentId , this_node );
  
  while ( neighbour >= 0 )
  {
    _fwXml_parseSaxRecursive ( documentId , callBackList , level , neighbour , exceptionInfo );

    this_node = neighbour;

    neighbour = xmlNextSibling ( documentId , this_node );
  }
  
  --level;
  
  if ( mappingHasKey ( callBackList , _fwXml_getTypeOfCallback ( fwXml_PARSING_WHEN_LEAVING , node_typ ) ) )
  {
    commandCallback = "int main(int level, int typ, string nam, string val, mapping map ) ";
    
    switch ( _fwXml_getTypeOfCallback ( fwXml_PARSING_WHEN_LEAVING , node_typ ) )
    {
      case fwXml_SAXENDELEMENT:
              commandCallback += "{ "+callBackList[fwXml_SAXENDELEMENT]+"( nam ); return 0; }";
              break;
      default:
              commandCallback = "";
              break;
    }
  
    // DebugN ( "callbk "+commandCallback );
  
    rtn_code = execScript(commandCallback, makeDynString(), 
                          level , node_typ, node_nam, node_val, attributs );
    // DebugN("execScript Returns '"+rtn_code+"'");
  }  
}


/** 'fwXml_parseSaxFromFile' parses an Xml-file according to the SAX mechanism with user-defined callbacks.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param xmlDocumentName   input, the file-name of the Xml file to be parsed
@param callBackList      input, the callback functions to be called while parsing
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, 0 on success and -1 if an error during parsing occurred

@par SAX Callback Mechanism
        The callback function-names are passed to the 'fwXml_parseSaxFromFile' 
        function as a PVSS mapping.  Three different callbacks are currently 
        implemented which can be activated by associating them to corresponding 
        function-names in the PVSS mapping.  The parameter passing of the callback 
        functions follow very closely the Qt-implementation of the 'QXmlContentHandler'.
        These three types are the following:
@par
        Type 'fwXml_StartElement' called when an Xml element-node is encountered.<br>
        Activate: 'callBackList[fwXml_StartElement] = "<start-element-callback>";'<br>
        Declaration: 'void <start-element-callback> ( string elementName , mapping elementAttributes )'
@par
        Type 'fwXml_EndElement' called when an Xml element-node is left (exited).<br>
        Activate: 'callBackList[fwXml_EndElement] = "<end-element-callback>";'<br>
        Declaration: 'void <end-element-callback> ( string elementName )'
@par
        Type 'fwXml_Characters' called when an Xml text-node is encountered.<br>
        Activate: 'callBackList[fwXml_Characters] = "<characters-callback>";'<br>
        Declaration: 'void <characters-callback> ( string characters )'
            
@par
        A typical example is included in the example-panel "xmlParseSaxFromFileExample.pnl". 
        The Xml-file "xmlExampleSaxParsing.xml" is parsed by the program in this panel.
        The push-button parses the Xml-file in a pre-order traversal of the element tree
        and calls the user-defined callbacks on encountering the various node-boundaries.

@reviewed 2018-07-25 @whitelisted{FalsePositive}

*/

public int fwXml_parseSaxFromFile ( string xmlDocumentName , mapping callBackList , dyn_string &exceptionInfo )
{
int this_node, neighbour;
int rtn_code, documentId;
int errLin,errCol;
string errMsg;
int level = 0;

  documentId = xmlDocumentFromFile ( xmlDocumentName , errMsg , errLin , errCol );
  
  if ( documentId >= 0 )
  {
    neighbour = xmlFirstChild ( documentId );
    
    while ( neighbour >= 0 )
    {
      _fwXml_parseSaxRecursive ( documentId , callBackList , level , neighbour , exceptionInfo );
      
      this_node = neighbour;
      
      neighbour = xmlNextSibling ( documentId , this_node );
    }

    rtn_code = xmlCloseDocument ( documentId );
  }
  else
  {
    fwException_raise ( exceptionInfo , "ERROR" , "Line " + errLin + " Column " + errCol + " Reason: " + errMsg , "" );
  }

  return ( ( dynlen(exceptionInfo) > 0 ) ? -1 : 0 );
}


/** '_fwXml_getElementsRecursive' called by 'fwXml_elementsByTagName' and itself in a recursive way.

@par Constraints
	None

@par Usage
	Private

@par PVSS managers
	UI, CTRL

@param documentId        input, the document identifier
@param topNodeId         input, the top node-identifier of the parent or -1 (root-node)
@param tagName           input, the tag-name of the children which need to be returned
@param elements          inout, the elements satisfying the tag-name condition
@param exceptionInfo     inout, returns details of any exceptions
@return                  void
*/

private void _fwXml_getElementsRecursive ( unsigned documentId , int topNodeId , string tagName , dyn_int &elements ,
                                           dyn_string &exceptionInfo )
{
dyn_int children;
int node_typ;
string node_nam;

  node_typ = xmlNodeType ( documentId , topNodeId );
   
  if ( node_typ == XML_ELEMENT_NODE )
  {
    node_nam = xmlNodeName ( documentId , topNodeId );
    
    if ( node_nam == tagName ) { dynAppend ( elements , topNodeId ); }
    
    if ( xmlChildNodes ( documentId , topNodeId , children ) != 0 ) { return; }
  
    for ( int idx = 1 ; idx <= dynlen(children) ; ++idx )
    {
      _fwXml_getElementsRecursive ( documentId , children[idx] , tagName , elements , exceptionInfo );
    }     
  }  
}





/** 'fwXml_elementsByTagName' returns all children which have a specific element's tag-name

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param documentId        input, the document identifier
@param topNodeId         input, the top node-identifier of the parent or -1 (root-node)
@param tagName           input, the tag-name of the children which need to be returned
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, all children which have a specific element's tag-name
        
@par
Returns a dynamic-integer array containing all descendent elements of this 
element that are called tag-name. The order they are in the dynamic-integer
array is the order they are encountered in a pre-order traversal of the element 
tree.  If '-1' is given to the node-identifier's value, then the whole document 
is searched.
  
@par
A typical example is included in the example-panel "xmlElementsByTagNameExample.pnl". 
The Xml-file "xmlExampleProcessTags.xml" is parsed by the two programs in this panel.
The first push-button gets the element-nodes with tagnames 'home', 'room' and 'floor'.
The second push-button gets only the element-nodes of the 'room's which are within 
'bedrooms's.

@par How to use...
Note that one needs to load the XML document first into memory and that one may only close 
the XML document once all manipulations have been finished on the XML nodes of the document.

\code
string xml_full_name, errMsg;
int rtn_code, docum, errLin, errCol;
dyn_string exInfo;
dyn_int elements;

  docum = xmlDocumentFromFile ( xml_full_name , errMsg , errLin , errCol );
  
  if ( docum < 0 )
  {
    DebugN ( "Parsing Error-Message = '" + errMsg + "' Line=" + errLin + " Column=" + errCol );
  }
  else
  {
    // Manipulate here the XML nodes of the document
  
    elements = fwXml_elementsByTagName ( docum , ... , exInfo );
    
    rtn_code = xmlCloseDocument ( docum );
    DebugN ( "rtn_code = " + rtn_code );
  }
\endcode

*/

public dyn_int fwXml_elementsByTagName ( unsigned documentId , int topNodeId , string tagName ,
                                         dyn_string &exceptionInfo )
{
dyn_int elements = makeDynInt();
int ident;

  if ( topNodeId == -1 )
  {
    if ( ( ident = xmlFirstChild ( documentId ) ) >= 0 )
    {
      do {
           _fwXml_getElementsRecursive ( documentId , ident , tagName , elements , exceptionInfo );
         }
      while ( ( ident = xmlNextSibling ( documentId , ident ) ) >= 0 );
    }
  }
  else
  {
    _fwXml_getElementsRecursive ( documentId , topNodeId , tagName , elements , exceptionInfo );
  }
    
  return ( elements );
}


/** fwXml_CONTAINS_SIMPLE_ELEMENT_NODES
The constants used to check the return-code of the 'fwXml_childNodesContent' function.
One needs to OR those flags together and pass it as the 'requestedTypes' parameter in the call 
to 'fwXml_containsNodeTypes'.  The return-value of the function 'fwXml_childNodesContent' is 
then passed as the 'setOfTypes' parameter in the same call to 'fwXml_containsNodeTypes'.
*/
const int fwXml_CONTAINS_SIMPLE_ELEMENT_NODES  = 0;

/** fwXml_CONTAINS_TEXT_NODES
The constants used to check the return-code of the 'fwXml_childNodesContent' function.
One needs to OR those flags together and pass it as the 'requestedTypes' parameter in the call 
to 'fwXml_containsNodeTypes'.  The return-value of the function 'fwXml_childNodesContent' is 
then passed as the 'setOfTypes' parameter in the same call to 'fwXml_containsNodeTypes'.
*/
const int fwXml_CONTAINS_TEXT_NODES            = 8;

/** fwXml_CONTAINS_COMMENT_NODES
The constants used to check the return-code of the 'fwXml_childNodesContent' function.
One needs to OR those flags together and pass it as the 'requestedTypes' parameter in the call 
to 'fwXml_containsNodeTypes'.  The return-value of the function 'fwXml_childNodesContent' is 
then passed as the 'setOfTypes' parameter in the same call to 'fwXml_containsNodeTypes'.
*/
const int fwXml_CONTAINS_COMMENT_NODES         = 256;

/** fwXml_CONTAINS_COMPLEX_ELEMENT_NODES
The constants used to check the return-code of the 'fwXml_childNodesContent' function.
One needs to OR those flags together and pass it as the 'requestedTypes' parameter in the call 
to 'fwXml_containsNodeTypes'.  The return-value of the function 'fwXml_childNodesContent' is 
then passed as the 'setOfTypes' parameter in the same call to 'fwXml_containsNodeTypes'.
*/
const int fwXml_CONTAINS_COMPLEX_ELEMENT_NODES = 2;


/** 'fwXml_containsNodeTypes'
Checks if the returned contents node-types are all present in the set of requested ones.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param setOfTypes        input, contents node-types to be checked
@param requestedTypes    input, set of requested node-types that are allowed
@return                  output, boolean, returned contents node-types are all present in the set of requested ones

@reviewed 2018-07-25 @whitelisted{FalsePositive}

*/

public bool fwXml_containsNodeTypes ( int setOfTypes , int requestedTypes )
{
  return ( ( setOfTypes & ~requestedTypes == 0 ) ? true : false );
}


/** fwXml_CHILDNODESTYPE
Constant used in the mapping that identifies the node-type of the node in question
*/
const string fwXml_CHILDNODESTYPE = "fwXml_ChildNodesType";

/** fwXml_CHILDSUBTREEID
Constant used in the mapping that identifies the node-identifier of the node in question
*/
const string fwXml_CHILDSUBTREEID = "fwXml_ChildSubTreeId";




/** 'fwXml_childNodesContent' returns tags, attributes and contained data of all children

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param documentId        input, the document identifier
@param topNodeId         input, the top node-identifier of the parent element-node container
@param node_names        output, the node-names or tag-names for element-nodes
@param attributes        output, the attributes of element-nodes and added infomation
@param nodevalues        output, the node-values or values of the unique child's text-node
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, the combined types of the type of children which data is returned
        
@par When used for simple Xml-file structures
If the function returns 'fwXml_CONTAINS_SIMPLE_ELEMENT_NODES', then the child-nodes are all 
element-nodes which contain at most one text-node as their child.  The following is returned 
via the three output-parameters: 'node_names' returns the tag-names of the element-nodes, 
'attributes' returns all the attributes of the element-nodes, 'nodevalues' returns 
the value (character-data) of the contained text-node if present, otherwise it returns 
the empty string.

@par
A typical example is included in the example-panel "xmlChildNodesContentExample.pnl"
(first push-button).  The Xml-file "xmlExampleFlatListing.xml" can be completely 
read by issuing one single call to this function - specify for the 'node' variable 
the node-identifier of the element-node called "<room>".

@par
Note that this function was created especially for users who want to parse Xml-files
of a structure which corresponds to the above description.  Only read further if you
want to use this function to parse more complex Xml-file structures.

@par When used for complex Xml-file structures
If any of the child-nodes is different from an element-node which contains at most one
text-node as its child, then the return-code will be different from 'fwXml_CONTAINS_SIMPLE_ELEMENT_NODES' 
[and will be more specific the bitwise OR-ed values which are obtained by shifting the value '1' 
to the left by a number of places which corresponds to the internal enumerated value 
of the node-type].

@par
An example will illustrate this much easier.  Refer again to the example-panel
"xmlChildNodesContentExample.pnl" (second push-button).  The Xml-file corresponds
this time to "xmlExampleGreatText.xml".  In this example there is in addition to 
the above at least one text-node as a direct child (not as a child of an element-node).
In that case, the return-code is 'fwXml_CONTAINS_TEXT_NODES' [this is obtained by shifting 
'1' to the left by XML_TEXT_NODE places (1<<XML_TEXT_NODE) [1<<3]].  

@par
For nodes which are not element-nodes, the returned values are: 'node_names' returns 
the node-name of the node as queried by 'xmlNodeName', 'attributes' returns a single 
mapping "[fwXml_CHILDNODESTYPE;(int)<node-type>]" which indicates the node-type of the 
node, 'nodevalues' returns the node-value of the node as queried by 'xmlNodeValue'.

@par
If there is additionally at least one child-node with more than one child or with 
a child which is not a text-node then the return-code will have the bit-value '2'
also set.  The same example-panel "xmlChildNodesContentExample.pnl" illustrates
this.  Third button parses the "xmlExampleHierarchical.xml" Xml-file - return-code 
corresponds to 'fwXml_CONTAINS_COMPLEX_ELEMENT_NODES' [(1<<XML_ELEMENT_NODE) [1<<1]]. 
Fourth button parses the Xml-file "xmlExampleMoreComplex.xml"  - return-code corresponds 
to 'fwXml_CONTAINS_COMPLEX_ELEMENT_NODES | fwXml_CONTAINS_TEXT_NODES' [obtained by bitwise 
OR-ing of (1<<XML_ELEMENT_NODE) and (1<<XML_TEXT_NODE) which is [(1<<1)|(1<<3)]].

@par
For element-nodes with more than one child or with a child which is not a text-node, 
the returned values are: 'node_names' returns the tag-name of the node, 'attributes' 
returns all the attributes of the element-nodes with additionally the two following 
added mappings "[fwXml_CHILDNODESTYPE;(int)XML_ELEMENT_NODE]" which is the node-type 
and "[fwXml_CHILDSUBTREEID;(int)<element-node-identifier>]", 'nodevalues' returns 
the empty string.

@par How to use...
Note that one needs to load the XML document first into memory and that one may only close 
the XML document once all manipulations have been finished on the XML nodes of the document.

\code
string xml_full_name, errMsg;
int rtn_code, docum, nodeIdentifier, errLin, errCol;
dyn_string exInfo;

  docum = xmlDocumentFromFile ( xml_full_name , errMsg , errLin , errCol );
  
  if ( docum < 0 )
  {
    DebugN ( "Parsing Error-Message = '" + errMsg + "' Line=" + errLin + " Column=" + errCol );
  }
  else
  {
    // Search first for the XML element node one is interested in...
  
    rtn_code = fwXml_childNodesContent ( docum , nodeIdentifier , ... , exInfo );

    rtn_code = xmlCloseDocument ( docum );
  }
\endcode

*/

public int fwXml_childNodesContent ( unsigned documentId , int topNodeId ,
           dyn_string &node_names , dyn_anytype &attributes , dyn_string &nodevalues ,
           dyn_string &exceptionInfo )
{
int rtn_code;
int node_typ;
mapping node_att;
string node_nam, node_val;
dyn_int children, subnodes;
int child_types = 0;

  node_names = makeDynString();
  attributes = makeDynAnytype();
  nodevalues = makeDynString();
  
  rtn_code = xmlChildNodes ( documentId , topNodeId , children );
  if ( rtn_code != 0 ) return ( rtn_code );
  
  for ( int idx = 1 ; idx <= dynlen(children) ; ++idx )
  {
    node_typ = xmlNodeType ( documentId , children[idx] );
    node_nam = xmlNodeName ( documentId , children[idx] );
    
    mappingClear ( node_att );
    
    if ( node_typ == XML_ELEMENT_NODE )
    {
      node_att = xmlElementAttributes ( documentId , children[idx] );
      
      rtn_code = xmlChildNodes ( documentId , children[idx] , subnodes );
      if ( dynlen(subnodes) == 0 )
         { node_val = ""; }
      else if (  ( dynlen(subnodes) == 1 )
              && ( xmlNodeType ( documentId , subnodes[1] ) == XML_TEXT_NODE ) )
         { node_val = xmlNodeValue ( documentId , subnodes[1] ); }
      else
      {
        node_val = "";
        node_att[fwXml_CHILDNODESTYPE] = node_typ;
        node_att[fwXml_CHILDSUBTREEID] = children[idx];
        child_types |= ( 1 << node_typ );
      }
    }
    else
    {
      node_val = xmlNodeValue ( documentId , children[idx] );
      node_att[fwXml_CHILDNODESTYPE] = node_typ;
      child_types |= ( 1 << node_typ );
    }
    
    dynAppend ( node_names , node_nam );
    dynAppend ( attributes , node_att );
    dynAppend ( nodevalues , node_val );
  }
  
  return ( child_types );
}


/** 'fwXml_appendChildContent' appends element-nodes, attributes and contained data to the Xml Tree

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	UI, CTRL

@param documentId        input, the document identifier
@param topNodeId         input, the top node-identifier of the parent element-node container
@param node_names        input, tag-names for element-nodes
@param attributes        input, the attributes of element-nodes
@param nodevalues        input, the values of the unique child's text-node
@param exceptionInfo     inout, returns details of any exceptions
@return                  output, 0 on success and -1 if an error during construction occurred

@par Used for simple and more complex Xml-file structures
This function constructs underneath the given node an ordered list of children element-nodes,
or other types of nodes like: text-nodes, cdata-section nodes or comment nodes.  Each of these 
children element-nodes gets their corresponding attributes and if defined and not the empty-string 
their corresponding child text-node.

@par
A typical example is included in the example-panel "xmlCreateChildContentExample.pnl".
The first push-button creates a list of element-nodes.  The second push-button creates 
a list of element-nodes with most of them having a unique child's text-node.  The third 
push-button creates a list of element-nodes with some of them having one or more qualifying 
attributes.  The fourth push-button combines all the above examples together and creates 
a list of element-nodes with some of them attributes and most of them a unique child's 
text-node.  The fifth push-button shows you how to add more exotic elements like
text-nodes, cdata-section nodes and comment nodes.

@reviewed 2018-07-25 @whitelisted{FalsePositive}

*/

public int fwXml_appendChildContent ( unsigned documentId , int topNodeId ,
           dyn_string node_names , dyn_anytype attributes , dyn_string nodevalues ,
           dyn_string &exceptionInfo )
{
int children, childr_a, childr_v;
int subchild, func_rtn, rtn_code;
anytype child_attrs;
dyn_int subnodes;
string attr_key;
int childtype;

int old_children = 0;

  func_rtn = 0;
  
  children = dynlen(node_names);
  childr_a = dynlen(attributes);
  childr_v = dynlen(nodevalues);
  
  if ( ( childr_a != 0 ) && ( childr_a != children ) )
  {
    fwException_raise(exceptionInfo, "ERROR", "Node-Name and Attribute Lists have Different Size!", "" );
    return ( -1 );
  }
  
  if ( ( childr_v != 0 ) && ( childr_v != children ) )
  {
    fwException_raise(exceptionInfo, "ERROR", "Node-Name and Node-Value Lists have Different Size!", "" );
    return ( -1 );
  }

  // Check firsdt how many children are already there...  This is needed for possible recovery!
  if ( xmlChildNodes ( documentId , topNodeId , subnodes ) == 0 ) old_children = dynlen ( subnodes );
      
  for ( int idx = 1 ; idx <= children ; ++idx )
  {
    if ( ( childr_a > 0 ) && mappingHasKey(attributes[idx],fwXml_CHILDNODESTYPE) )
    {
      childtype = attributes[idx][fwXml_CHILDNODESTYPE];
      
      if (  ( childtype == XML_TEXT_NODE )
         || ( childtype == XML_COMMENT_NODE ) 
         || ( childtype == XML_CDATA_SECTION_NODE ) )
      {
        if ( ( subchild = xmlAppendChild ( documentId , topNodeId , childtype , nodevalues[idx] ) ) < 0 )
        {
          fwException_raise(exceptionInfo, "ERROR", "Child '"+idx+"' Could Not be Added!", "" );
          func_rtn = -1;
          break;
        }
        
        mappingRemove(attributes[idx],fwXml_CHILDNODESTYPE);
      }
      else
      {
        fwException_raise(exceptionInfo, "ERROR", "Child '"+idx+"' is of Inacceptable Type!", "" );
        func_rtn = -1;
        break;
      }      
    }
    else if ( ( subchild = xmlAppendChild ( documentId , topNodeId , XML_ELEMENT_NODE , node_names[idx] ) ) < 0 )
    {
      fwException_raise(exceptionInfo, "ERROR", "Child '"+idx+"' Could Not be Added!", "" );
      func_rtn = -1;
      break;
    }
    else if ( childr_a > 0 )
    {
      child_attrs = attributes[idx];
      
      for ( int i = 1 ; i <= mappinglen(child_attrs) ; i++ )
      {
        attr_key = mappingGetKey ( child_attrs , i );
        
        if ( ( xmlSetElementAttribute ( documentId , subchild , attr_key , child_attrs[attr_key] ) ) != 0 )
        { 
          fwException_raise(exceptionInfo, "ERROR", "Attribute of Child '"+idx+"' Could Not be Added!", "" );
          func_rtn = -1;
          break;
        }
      }
      
      if ( func_rtn != 0 ) { break; }
    }
    
    if ( childr_v )
    {
      if ( nodevalues[idx] != "" )
      {
        if ( ( rtn_code = xmlAppendChild ( documentId , subchild , XML_TEXT_NODE , nodevalues[idx] ) ) < 0 )
        {
          fwException_raise(exceptionInfo, "ERROR", "Sub-Child '"+idx+"' Could Not be Added!", "" );
          func_rtn = -1;
          break;
        }
      }
    }
  }
  
  if ( func_rtn != 0 )
  {
    if ( xmlChildNodes ( documentId , topNodeId , subnodes ) == 0 )
    {
      for ( int idx = old_children + 1 ; idx <= dynlen(subnodes) ; ++idx )
      {
        xmlRemoveNode ( documentId , subnodes[idx] );
      }
    }
  }
  
  return ( func_rtn );
}


//@}

