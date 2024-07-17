// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author msukhano
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "fit_libs/fit_constants.ctl"
//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
//@public members
//--------------------------------------------------------------------------------

public void initBCorbitMask(const string LHCinfoDPE, const string TCMDPE){
  dpConnectUserData("CIRCULATING_BUNCHES_VALUES_Changed_CB", TCMDPE, LHCinfoDPE + ".CIRCULATING_BUNCHES_B1_VALUES", LHCinfoDPE + ".CIRCULATING_BUNCHES_B2_VALUES");
  dpConnect("DisplacedBucketsChanged_CB", LHCinfoDPE + ".ALICE.displacedBuckets_B1", LHCinfoDPE + ".ALICE.displacedBuckets_B2");
}
//------------------------------------------------------------------
//@private members
//--------------------------------------------------------------------------------
private int convertB1ToA(int value){
  return (value / 10 + 344) % MAX_NUM_OF_BUNCH;
}

private int convertB2ToC(int value){
  return (value / 10 + 3017) % MAX_NUM_OF_BUNCH;
}

private void DisplacedBucketsChanged_CB(string b1, dyn_int &vb1, string b2, dyn_int &vb2){
  dyn_int dispBunchesA = makeDynInt(), dispBunchesC = makeDynInt();
  for(uint i = 1; i <= dynlen(vb1); ++i){
    if(vb1[i] != -1)dispBunchesA.append(convertB1ToA(vb1[i]));
    if(vb1[i] != -1)dispBunchesC.append(convertB2ToC(vb2[i]));
  }
  dpSetWait(dpSubStr(b1, DPSUB_DP) + ".ALICE.displacedBunches_A", dispBunchesA,
            dpSubStr(b2, DPSUB_DP) + ".ALICE.displacedBunches_C", dispBunchesC);
}

private void CIRCULATING_BUNCHES_VALUES_Changed_CB(string TCMDPE, string b1, dyn_int &buckets1, string b2, dyn_int &buckets2){
  dyn_bit32 ORBIT_FILL_MASK; //0xDEC(=3564) 2-bit fields: bit0 - bunch in beamA, bit1 - bunch in beamC
  for (uint i = 0; i < 223; ++i){
    dynAppend(ORBIT_FILL_MASK, (bit32)0); //223 = ceil(0xDEC / 16)
  }
  dyn_int bunchesA, bunchesC;
  for (uint i = 1; (i <= dynlen(buckets1)) && (buckets1[i] != 0); ++i) {
    int BC_A = convertB1ToA(buckets1[i]);
    bunchesA.append(BC_A);
    setBit(ORBIT_FILL_MASK[BC_A/16 + 1], 2*(BC_A % 16)    , 1);
  }
  for (uint i = 1; (i <= dynlen(buckets2)) && (buckets2[i] != 0); ++i) {
    int BC_C = convertB2ToC(buckets2[i]);
    bunchesC.append(BC_C);
    setBit(ORBIT_FILL_MASK[BC_C/16 + 1], 2*(BC_C % 16) + 1, 1);
  }

  getBCs(bunchesA, bunchesC, b1);
  dpSetWait(TCMDPE + ".ORBIT_FILL_MASK", ORBIT_FILL_MASK); //sending ControlServer command
}

//setting the dpe values for BCs filling
private void getBCs(dyn_int &diBA, dyn_int &diBC, string bunchDPEl){
  string LHCinfo = dpSubStr(bunchDPEl, DPSUB_SYS_DP);
  int aLen;
  dyn_string dsCollisions, dsSingle;
  for(uint i = 1; i <= dynlen(diBA); ++i){
    if(dynContains(diBC, diBA[i])){
      dsCollisions.append((string)diBA[i]);
      diBC.removeAt(diBC.indexOf(diBA[i]));
    }else
      dsSingle.append("A:" + (string)diBA[i]);
  }
  aLen = dynlen(dsSingle);
  dpSetWait(LHCinfo + ".ALICE.Na", aLen);
  for(uint i = 1; i <= dynlen(diBC); ++i)
    dsSingle.append("C:" + (string)diBC[i]);
  dpSetWait(LHCinfo + ".ALICE.CollidingBeams", dsCollisions,
            LHCinfo + ".ALICE.SingleBeams", dsSingle,
            LHCinfo + ".ALICE.Nc", dynlen(dsSingle) - aLen,
            LHCinfo + ".ALICE.Nb", dynlen(dsCollisions));
}
