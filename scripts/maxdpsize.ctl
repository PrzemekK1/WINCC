int max;
int maxsize(int l)
{

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
    DebugN(parts[1]);
//sprawdzanie długości członu
int tabsize=dynlen(dpparts);

if(max<tabsize) max=tabsize;


}
  return max;
  rewind(f); // back to the beginnin
  fclose(f);

}

