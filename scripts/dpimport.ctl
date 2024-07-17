int max;

int maxsizedp()
{
  DebugN("wchodze");
  file f;
  string dummy;
  f=fopen("D:/CERN_new/dpimportpk.csv","r");
  while (feof(f)==0) // so long as it is not at the end
  {
    fgets(dummy,150,f); // reads from the file in dummy

dyn_string parts = strsplit(dummy, ";");
if (dynlen(parts) != 4)
    {
      continue;
    }

  string dp = parts[1];
    float value = (float) parts[2];
    string timestamp = parts[3];
    string type=parts[4];

    // Znalezienie datapointa
    string dpList;
    dpGet(dp, dpList);

dyn_string dpparts = strsplit(parts[1], "/");
  //  DebugN(parts[1]);
//sprawdzanie długości członu
int tabsize=dynlen(dpparts);
//DebugN(tabsize);
string gen;



//string r="\"\",";
string r=",+,";

int q,z,n,i;
dyn_dyn_string wartosci;
dyn_dyn_string xxdepes;
dyn_dyn_int xxdepei;

//rozdzielanie dp
if (max<tabsize) max=tabsize;

}
  rewind(f);
   //  DebugN("wychodze");
  //   DebugN(max);
     return max;
  fclose(f);

}
//________________________________________________________________________________________________________________________________




main()
{
int maxx=maxsizedp();
  file f;
  string dummy;
  f=fopen("D:/CERN_new/dpimportpk.csv","r");
  while (feof(f)==0) // so long as it is not at the end
  {
    fgets(dummy,150,f); // reads from the file in dummy

dyn_string parts = strsplit(dummy, ";");
 DebugN("___________________________________");

    if (dynlen(parts) != 4)
    {
      DebugN("WARNING: znaleziono błąd w pliku źródłowym");
      continue;
    }
  string dp = parts[1];
    float value = (float) parts[2];
    string timestamp = parts[3];
    string type=parts[4];

    // Znalezienie datapointa
    string dpList;
    dpGet(dp, dpList);
    /*if (!dpExists(dp))
    {
      DebugN("Nie znaleziono DP, tworze nowy:", dp);
    //  dpCreate(dp,"test");
      continue;
    }
    */

    //dpSetWait(("dist_1:"+parts[1]), value);
   //dpSet(("dist_1:"+dp+"."), 453);

//rozdział pierwszego elementu tablicy (DP) na pojedyncze człony
dyn_string dpparts = strsplit(parts[1], "/");
    DebugN(parts[1]);
//sprawdzanie długości członu
int tabsize=dynlen(dpparts);
DebugN(tabsize);
string gen;



//string r="\"\",";
string r=",+,";

int q,z,n,i;
dyn_dyn_string wartosci;
dyn_dyn_string xxdepes;
dyn_dyn_int xxdepei;

//rozdzielanie dp

for (q=1;q!=(int)tabsize+1;q++)
{
  //DebugN(dpparts[q]);
  gen=gen+dpparts[q]+r;
  for (i=1; i<=maxx;i++)
  {
    if (q==i)
    {
      xxdepes[q][i] = dpparts[q];
      if ( i == (int)tabsize)
        xxdepei[q][i] = DPEL_BIT32;
      else
        xxdepei[q][i] = DPEL_STRUCT;
    }
    else
    {
        xxdepes[q][i] = "";
       // if (i>q)
          //xxdepei[q][i] = "0";
    }
  }
 }

  DebugN(xxdepes);
  DebugN("Wypis:");
// DebugN(maxx);
 // DebugN(xxdepei);

//  n = dpTypeChange(xxdepes,xxdepei);
 // DebugN ("valve data point type created, result: ",n);

// DebugN(wartosci);

//gen=gen+dpparts[q];

}



  rewind(f); // back to the beginning
  //------------------------------------------------------------------------

/*
 int n;

  // Create the data type
  xxdepes[1] = makeDynString ("bbb","","","");
  xxdepes[2] = makeDynString ("","defaults","","");
  xxdepes[3] = makeDynString ("","","regratio","");
  xxdepes[4] = makeDynString ("","returns","","");
  xxdepes[5] = makeDynString ("","","faults","");
  xxdepes[6] = makeDynString ("","","","id");
  xxdepes[7] = makeDynString ("","","","text");
  xxdepes[8] = makeDynString ("","","states","");
  xxdepes[9] = makeDynString ("","","","endpos_open");
  xxdepes[10] = makeDynString ("","","","motor_running");
  xxdepes[11] = makeDynString ("","","","endpos_closed");
  xxdepes[12] = makeDynString ("","","regratio","");
  xxdepei[1] = makeDynInt (DPEL_STRUCT);
  xxdepei[2] = makeDynInt (0,DPEL_STRUCT);
  xxdepei[3] = makeDynInt (0,0,DPEL_FLOAT);
  xxdepei[4] = makeDynInt (0,DPEL_STRUCT);
  xxdepei[5] = makeDynInt (0,0,DPEL_STRUCT);
  xxdepei[6] = makeDynInt (0,0,0,DPEL_BIT32);
  xxdepei[7] = makeDynInt (0,0,0,DPEL_STRING);
  xxdepei[8] = makeDynInt (0,0,DPEL_STRUCT);
  xxdepei[9] = makeDynInt (0,0,0,DPEL_BOOL);
  xxdepei[10] = makeDynInt (0,0,0,DPEL_BOOL);
  xxdepei[11] = makeDynInt (0,0,0,DPEL_BOOL);
  xxdepei[12] = makeDynInt (0,0,DPEL_FLOAT);
  // Create the data point type
  n = dpTypeChange(xxdepes,xxdepei);
  //DebugN ("valve data point type created, result: ",n);


*/


  fclose(f);
}

