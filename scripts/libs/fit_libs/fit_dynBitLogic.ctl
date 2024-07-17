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


//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------
class List{
  public List(const anytype &source, bool filled = false){
    if(checkIfTypeDyn(source)){
      allItemsList = source;
      list = allItemsList;
      if(!filled) list.clear();
    }else{
      DebugN("The variable's type is not dynamic (" + getTypeName(source) + "). Can not create an object");
    }
  }

  public anytype getContent(){return list;}
  public void makeEmpty(){list.clear();}
  public void makeFull(){list = allItemsList;}

  public void fill(const anytype &term){
    if(!checkTypeCorrespondence(term)) return;
    list.clear();
    for(uint i = 1; i <= dynlen(term); ++i)
      dynAppendConst(list, term);
    dynSort(list);
  }

  public anytype OR(const anytype &term){
    if(checkTypeCorrespondence(term)){
      for(uint i = 1; i <= dynlen(term); ++i)
        if(!dynContains(list, term[i])) dynAppend(list, term[i]);
      dynSort(list);
    }
    return list;
  }

  public anytype AND(const anytype &term){
    if(checkTypeCorrespondence(term)){
      anytype tmp = list;
      dynClear(tmp);
      for(uint i = 1; i <= dynlen(term); ++i)
       if(dynContains(list, term[i])) dynAppend(tmp, term[i]);
      list = tmp;
    }
    return list;
  }

  public anytype NOT(){
    anytype tmp = list;
    dynClear(tmp);
    for(uint i = 1; i <= dynlen(allItemsList); ++i){
      if(!dynContains(list, allItemsList[i])) dynAppend(tmp, allItemsList[i]);
    }
    list = tmp;
    return list;
  }

  private anytype allItemsList, list;

  private bool checkIfTypeDyn(const anytype &lst){
    string type = getTypeName(lst);
    return type.contains("dyn");
  }

  //Making a check before bit operations
  private bool checkTypeCorrespondence(const anytype &term){
    //Check if the elements are valid and exist in allItemsList.
    for(uint i = 1; i <= dynlen(term); ++i){
      if(!dynContains(allItemsList, term[i])){
        DebugN("Complete list has no element " + (string)term[i]);
        return false;
      }
    }
    //Check if the types of list are equal
    bool typeOk = (getType(term) == getType(allItemsList));
    if(!typeOk){DebugN("Invalid term type. Expected " + getTypeName(allItemsList) + " but " + getTypeName(term));}
    return typeOk;
  }
};

public anytype dynOR(const anytype &a, const anytype &b){
  if(typeChecker(a, b, "dynOR")){
    dyn_anytype result = a;
    for(uint i = 1; i <= dynlen(b); ++i)
      if(!a.contains(b[i]))result.append(b[i]);
    return result;
  }else{
    return -1;
  }
}

public anytype dynAND(const anytype &a, const anytype &b){
  if(typeChecker(a, b, "dynAND")){
     dyn_anytype result = makeDynAnytype();
     for(uint i = 1; i <= dynlen(a); ++i)
       if(b.contains(a[i]))result.append(a[i]);
     return result;
  }else{
    return -1;
  }
}

public anytype dynXOR(const anytype &a, const anytype &b){
  if(typeChecker(a, b, "dynXOR")){
     dyn_anytype result = makeDynAnytype();
     anytype _b = b;
     dynUnique(_b);
     for(uint i = 1; i <= dynlen(a); ++i){
       if(_b.contains(a[i])){
         dynRemove(_b, _b.indexOf(a[i]) + 1);
       }else{
         result.append(a[i]);
       }
     }
     dynAppend(result, _b);
     return result;
  }else{
    return -1;
  }
}

public anytype dynNOT(const anytype &a, const anytype &source){
  if(typeChecker(a, source, "dynNOT")){
     dyn_anytype result = makeDynAnytype();
     for(uint i = 1; i <= dynlen(source); ++i)
       if(!a.contains(source[i])) result.append(source[i]);
     return result;
  }else{
    return -1;
  }
}


//--------------------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------

private bool typeChecker(const anytype &a, const anytype &b, const string func){
  bool result = getType(a) == getType(b);
   if(!result)
    DebugN("---> " + func + " different types: " + getTypeName(a) + " and " + getTypeName(b));
  return result;
}
