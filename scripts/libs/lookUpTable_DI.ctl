// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
  DI - Datapoint independent. In order to make available constant objects of lookUpTable entries they should be datapoint independent and not use the timed function, such as dpGet.
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

const string catalog = "LUT";
//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

class fitLookUpTable{
  public fitLookUpTable(string fileName){
    dyn_string lines;
    separateFileOnLines(fileName, lines);

    if(!dynlen(lines)){throw(makeError(catalog, PRIO_SEVERE, ERR_PARAM, 8, fileName)); return;}
    if(dynlen(lines) < 2){throw(makeError(catalog, PRIO_WARNING, ERR_PARAM, 3, fileName)); return;}

    takeProperties(lines);
    getTypes(lines);
    getData(lines);

  }
  private const string patternString = "*[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,/:;\\|()*_?!#@$%&\"'~`^+ <=>]*";
  private const string patternFloat  = "*[0123456789].[01234456789]*";
  private const string patternInt    = "*[0123456789]*";

  private dyn_string properties = makeDynString(),
                     dataTypes = makeDynString();

  private dyn_dyn_string   data;
//
  public const dyn_string getProperties(){return properties;}
  public const dyn_string getDataTypes(){return dataTypes;}
  public const anytype getDataFor(string property){
    anytype output;
    int idx = properties.indexOf(property) + 1;
    if( idx > 0) output = (dataTypes[idx] == "float") ? (dyn_float)data[idx] : ( (dataTypes[idx] == "int") ? (dyn_int)data[idx] : data[idx]);
    else output = -1;
    return output;
  }


  private separateFileOnLines(string fileName, dyn_string &lines){
    string fileInString;
    lines.clear();
    if(!isfile(fileName)){
      throw(makeError(catalog, PRIO_WARNING, ERR_PARAM, 7, fileName));
      return;
    }
    if(!fileToString(fileName, fileInString)){
      throw(makeError(catalog, PRIO_WARNING, ERR_PARAM, 2, fileName));
      return;
    }
    lines = strsplit(fileInString, '\n');
  }

  private takeProperties(dyn_string &lines){
    properties.clear();
    properties = strsplit(lines[1], ',');
  }

  private string getPreferedType(string valueToCheck){
    if(uniPatternMatch(patternString, valueToCheck)) return "string";
    else if(uniPatternMatch(patternFloat, valueToCheck)) return "float";
    else if(uniPatternMatch(patternInt, valueToCheck)) return "int";
    else return "string";
  }

  private getTypes(dyn_string &lines){
    dyn_string entries = strsplit(lines[2], ',');
    for(uint i = 1; i <= dynlen(entries); ++i){
      dataTypes.append(getPreferedType(entries[i]));
      data[i] = makeDynString();
    }
  }

  private getData(dyn_string &lines){
    for(uint i = 2; i <= dynlen(lines) - 1; ++i){
      dyn_string values = strsplit(lines[i], ',');
      for(uint k = 1; k <= dynlen(values); ++k){
        data[k].append(values[k]);
      }
    }
  }

};

class fitLookUpTableEntry{
  public fitLookUpTableEntry(string prop, const fitLookUpTable &source){
    property = dynContains(source.getProperties(), prop) ? prop : "";
    type = (property == "") ? "" : source.getDataTypes()[dynContains(source.getProperties(), property)];
    data = source.getDataFor(property);
  }

  public const anytype getCorrespondingProperty(const fitLookUpTableEntry &entry, anytype value){
    return dynContains(entry.getData(), value) ? data[entry.positionOfValue(value)] : -1;
  }

  public const anytype getCorrespondingProperties(const fitLookUpTableEntry &entry, anytype value){
    dyn_anytype result;
    result.clear();
    anytype entryData = entry.getData();
    dyn_int indexes = entryData.indexListOf(value);

    for(uint i = 1; i <= dynlen(indexes); ++i){
      result.append(data[indexes[i] + 1]);
    }
    return getProperTypeArray(result);
  }

  public const int positionOfValue(anytype value){
    return dynContains(data, value);
  }

  public const dyn_int getPositionList(anytype value){
    dyn_int idxList = data.indexListOf(value);
    for(uint i = 1; i <= dynlen(idxList); ++i){
      idxList[i] += 1;
    }
    return idxList;
  }

  public const anytype getData(){return data;}
  public const string getProperty(){return property;}
  public const string getType(){return type;}

  private anytype data;
  private string property;
  private string type;

  private anytype getProperTypeArray(dyn_anytype array){
    if(type == "int"){
      return (dyn_int)array;
    }else if(type == "float"){
      return (dyn_float)array;
    }else{
      return (dyn_string)array;
    }
  }


};
//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

