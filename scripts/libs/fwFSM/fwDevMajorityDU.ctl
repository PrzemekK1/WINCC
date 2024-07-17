int BusyThreshold = 0;

dyn_string Types;
dyn_dyn_string Devices;
dyn_dyn_string States;
dyn_dyn_int Enableds;
dyn_dyn_string Bad_states;
dyn_int And_enabled;
dyn_int Or_disabled;

dyn_int N_devices;
dyn_int Threshold;
dyn_int LowThreshold;

dyn_dyn_string Bad_devices;

fwDevMajorityDU_initialize(string domain, string device)
{
dyn_string children, items;
int maj_index, index, i;
string type, modeObj, lunit, dp, typeindex, dom;


    while(BusyThreshold)
	delay(0, 100);
    BusyThreshold = 1;

    typeindex = get_lunittype(device, dom, lunit, type);
    maj_index = get_maj_index(typeindex);

    BusyThreshold = 0;

    children = fwFsm_getLogicalUnitChildrenOfType(domain, lunit, type);
//    fwFsm_getDomainObjectsOfType(domain, type, children);
    if(index = dynContains(children, domain))
      dynRemove(children, index);
    N_devices[maj_index] = dynlen(children);
    if(domain == lunit)
        dp = domain+"/"+type+"_FWMAJ";
    else
        dp = domain+"/"+lunit+"/"+type+"_FWMAJ";
    dpConnect("new_settings",
          dp+".bad_states",
          dp+".disabled",
          dp+".enabled",
          dp+".threshold",
          dp+".low_threshold",
          dp+".reverse");

    dpSetWait(dp+".bad_devices",makeDynString());
    for(i = 1; i <= dynlen(children); i++)
    {
        States[maj_index][i] = "";
        Enableds[maj_index][i] = -2;
        Devices[maj_index][i] = children[i];
        fwUi_connectCurrentState("change_state_threshold",domain, children[i]);
	  modeObj = fwUi_getModeObj(domain, children[i]);
        if(modeObj == domain)
        {
//            if(fwFsm_isDU(domain, children[i]))
                fwUi_connectEnabled("change_enabled",domain, children[i]);
//            else
//                Enableds[maj_index][i] = 1;
        }
        else
		fwUi_connectCurrentState("change_excluded", domain, modeObj+"_FWM");
    }
}

fwDevMajorityDU_valueChanged( string domain, string device,
      dyn_string bad_devices, string &fwState )
{
int threshold, low_threshold, maj_index;
string type, typeindex, dom, lunit;

//      type = get_type(device);
//      maj_index = get_maj_index(type);

      typeindex = get_lunittype(device, dom, lunit, type);
      maj_index = get_maj_index(typeindex);

      threshold = Threshold[maj_index];
      low_threshold = LowThreshold[maj_index];
//DebugN(device, threshold, low_threshold, dynlen(bad_devices));
      if (dynlen(bad_devices) > threshold)
	    fwState = "MAJORITY_ERROR";
      else if (dynlen(bad_devices) >= low_threshold)
	    fwState = "MAJORITY_WARNING";
	else
	    fwState = "MAJORITY_OK";
/*
	if (!dynlen(bad_devices))
	{
		fwState = "MAJORITY_OK";
	}
	else if (dynlen(bad_devices) > threshold)
	{
		fwState = "MAJORITY_WARNING";
	}
	else
	{
		fwState = "MAJORITY_ERROR";
	}
*/
}

fwDevMajorityDU_doCommand(string domain, string device, string command)
{
}

new_settings(string dp1, dyn_string bad_states,
             string dp2, int or_enabled,
             string dp3, int and_enabled,
             string dp4, int threshold,
             string dp5, int low_threshold,
             string dp6, int reverse)
{
int maj_index, tmp;
dyn_string items;
string domain, lunit, type, typeindex;

    items = strsplit(dp1,":.");

    typeindex = get_lunittype(items[2], domain, lunit, type);
    maj_index = get_maj_index(typeindex);

    Bad_states[maj_index] = bad_states;
    And_enabled[maj_index] = and_enabled;
    Or_disabled[maj_index] = or_enabled;
    if(low_threshold == 0)
        low_threshold = 1;
    LowThreshold[maj_index] = low_threshold;

    if(reverse)
    {
        tmp = reverse - threshold;
        Threshold[maj_index] = N_devices[maj_index] - tmp;
    }
    else
        Threshold[maj_index] = threshold;

    recalculate_all(domain, maj_index);
}

string get_lunittype(string device,
    string &domain, string &lunit, string &type)
{
int pos;
dyn_string items;
string typeindex;

    items = strsplit(device,"/");
    domain = items[1];
    if(dynlen(items) == 3)
    {
        lunit = items[2];
        type = items[3];
        typeindex = lunit+"/";
    }
    else
    {
        lunit = domain;
        type = items[2];
        typeindex = "";
    }
    strreplace(type,"_FWMAJ","");
    typeindex += type;
    return typeindex;
}

int get_maj_index(string type)
{
int index;

    if(!(index = dynContains(Types, type)))
    {
        index = dynAppend(Types, type);
	  States[index] = makeDynString();
        Enableds[index] = makeDynInt();
        Devices[index] = makeDynString();
        Bad_states[index] = makeDynString();
        Bad_devices[index] = makeDynString();
    }
    return index;
}

int find_maj_index(string device)
{
    int i;

    for(i = 1; i <= dynlen(Devices); i++)
    {
        if(dynContains(Devices[i], device))
        {
            return i;
        }
    }
    return 0;
}

change_state_threshold(string dp, string state)
{
int n, maj_index, index;
dyn_string items, dis_ids, bad_states, bad_devices;
string domain, device, type;

    items = strsplit(dp,":.");
    items = strsplit(items[2],fwFsm_separator);
    domain = items[1];
    device = items[2];
    if(dynlen(items) > 2)
    {
        device += "::"+items[3];
    }

    maj_index = find_maj_index(device);

    index = dynContains(Devices[maj_index], device);
    States[maj_index][index] = state;
    calculate_bad_devices(domain, maj_index, index);
}

change_excluded(string dp, string state)
{
int n, maj_index, index, cu;
dyn_string items, dis_ids, bad_states, bad_devices;
string domain, device, type, modeObj, mode;

    items = strsplit(dp,":.");
    items = strsplit(items[2],fwFsm_separator);
    domain = items[1];
    modeObj = items[2];
    device = modeObj;
    strreplace(device,"_FWM","");
    device += "::"+device;

    maj_index = find_maj_index(device);

    index = dynContains(Devices[maj_index], device);
    fwUi_getCurrentState(domain, modeObj, mode);
    fwUi_convertObjState(domain, modeObj, mode);
    if((mode == "Included") || (mode == "Manual"))
      Enableds[maj_index][index] = 1;
    else
      Enableds[maj_index][index] = 0;
    calculate_bad_devices(domain, maj_index, index);
}

change_enabled(string dp, int enabled)
{
int n, maj_index, index, or_disabled;
dyn_string items, dis_ids, bad_states, bad_devices;
string domain, device, type;

    items = strsplit(dp,":.");
    items = strsplit(items[2],fwFsm_separator);
    domain = items[1];
    device = items[2];
    if(dynlen(items) > 2)
    {
        device += "::"+items[3];
    }

    maj_index = find_maj_index(device);

    index = dynContains(Devices[maj_index], device);
    Enableds[maj_index][index] = enabled;
    calculate_bad_devices(domain, maj_index, index);
}

calculate_bad_devices(string domain, int maj_index, int index)
{
dyn_string bad_devices;
string device, typeindex, state;
int enabled, done;

    if((States[maj_index][index] == "") ||
       (Enableds[maj_index][index] == -2))
        return;

    while(BusyThreshold)
	delay(0, 100);
    BusyThreshold = 1;

    done = 0;
    device = Devices[maj_index][index];
    state = States[maj_index][index];
    enabled = Enableds[maj_index][index];
    typeindex = Types[maj_index];
    if(dynContains(Bad_states[maj_index], state))
    {
        if(And_enabled[maj_index])
        {
            if(enabled == 1)
            {
                if(!dynContains(Bad_devices[maj_index], device))
                {
                    dynAppend(Bad_devices[maj_index], device);
                    done = 1;
                }
            }
            else
            {
                if(index = dynContains(Bad_devices[maj_index], device))
                {
                    dynRemove(Bad_devices[maj_index], index);
                    done = 1;
                }
            }
        }
        else
        {
            if(!dynContains(Bad_devices[maj_index], device))
            {
                dynAppend(Bad_devices[maj_index], device);
                done = 1;
            }
        }
    }
    else
    {
        if(Or_disabled[maj_index])
        {
            if(enabled <= 0)
            {
                if(!dynContains(Bad_devices[maj_index], device))
                {
                    dynAppend(Bad_devices[maj_index], device);
                    done = 1;
                }
            }
            else
            {
                if(index = dynContains(Bad_devices[maj_index], device))
                {
                    dynRemove(Bad_devices[maj_index], index);
                    done = 1;
                }
            }
        }
        else
        {
            if(index = dynContains(Bad_devices[maj_index], device))
            {
                dynRemove(Bad_devices[maj_index], index);
                done = 1;
            }
        }
    }
    if(done)
        dpSetWait(domain+"/"+typeindex+"_FWMAJ.bad_devices", Bad_devices[maj_index]);
    BusyThreshold = 0;
}

recalculate_all(string domain, int maj_index)
{
int i;

    for(i = 1; i <= dynlen(Devices[maj_index]); i++)
        calculate_bad_devices(domain, maj_index, i);
}
