string lsdPassword;

#ifdef __OPTIMIZER__
	#define INL inline
#else
	#define INL
#endif

#ifndef PMENU_INSTANCE
    #define PMENU_INSTANCE "DEF_INST"
#endif

#ifndef NEXT_PAGE
    #define NEXT_PAGE "►"
#endif

#ifndef PREVIOUS_PAGE
    #define PREVIOUS_PAGE "◄"
#endif

#ifndef BACK_MENU
    #define BACK_MENU "Back"
#endif

#ifndef PMENU_PURGE_AGE_SECONDS
    #define PMENU_PURGE_AGE_SECONDS 30
#endif

#define LSD_DELIMITER "|"
#define PAGE_ELEMENTS 9

#define LSD_MENU_USER_CONTEXT ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_UC:")
#define LSD_MENU_USER_ACTIVITY ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_UA:")
#define LSD_MENU_USER_STACK ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_US:") 
#define LSD_MENU_USER_PAGE ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_UP:") 

#define LSD_MENU_OPTION_GROUP ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_OG:")
#define LSD_MENU_OPTION_GROUP_NUMERIC_MAP ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_OGNM:")
#define LSD_MENU_OPTION_GROUP_HEADER ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_OGH:")

SetMenuGroup(string group, string header, list options) INL {
    if(~llListFindList(options, (list)group)) {
        llOwnerSay("Cant add menu group: \"" + group + "\". The group refers to itself in its own options!"); 
        return;
    }
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP + group, llDumpList2String(options,LSD_DELIMITER), lsdPassword);
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP_HEADER + group, header, lsdPassword);
}

SetUserMenuGroup(key user, string group, string header, list options) INL {
    if(~llListFindList(options, (list)group)) {
        llOwnerSay("Cant add menu group: \"" + group + "\". The group refers to itself in its own options!"); 
        return;
    }
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP + group + ":" + (string)user, llDumpList2String(options,LSD_DELIMITER), lsdPassword);
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP_HEADER + group + ":" + (string)user, header, lsdPassword);
}

SetKeypadMenuGroup(string group, string header, list options) INL { SetUserKeypadMenuGroup((key)"", group, header, options); }

SetUserKeypadMenuGroup(key user, string group, string header, list options) INL {
    if(~llListFindList(options, (list)group)) {
        llOwnerSay("Cant add menu group: \"" + group + "\". The group refers to itself in its own options!"); 
        return;
    }
    list mOps = [];
    list hLst = [];
    integer i;
    integer llen = llGetListLength(options);
    for (i = 0; i < llen; ++i) {
        mOps += ["# " + (string)i];
        hLst += (string)options[i] + "\n";
    }

    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP + group + ":" + (string)user, llDumpList2String(mOps,LSD_DELIMITER), lsdPassword);
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP_NUMERIC_MAP + group + ":" + (string)user, llDumpList2String(hLst,LSD_DELIMITER), lsdPassword);
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP_HEADER + group + ":" + (string)user, header, lsdPassword);
}

string GetKeypadMenuValue(string group, integer selected) INL { return GetUserKeypadMenuValue((key)"", group, selected); }

string GetUserKeypadMenuValue(key user, string selected) INL {
    string group = LastUserMenuGroup(user);
    if(group != "") {
        integer num = (integer)llGetSubString(selected, llStringLength("# "), -1);
        string opt = llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP_NUMERIC_MAP + group + ":" + (string)user, lsdPassword);
        list lopt = llParseString2List(opt, [LSD_DELIMITER], []);
        llLinksetDataDeleteProtected(LSD_MENU_OPTION_GROUP_NUMERIC_MAP + group + ":" + (string)user, lsdPassword);
        return (string)lopt[num]; 
    }
    return "";
}

list GetUserMenuGroup(key user, string group) INL {
    string grp = llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group + ":" + (string)user,lsdPassword);
    if(grp != "") {
        return llParseString2List(grp, [LSD_DELIMITER], []); 
    }
    else {
        return llParseString2List(llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group,lsdPassword), [LSD_DELIMITER], []);
    }
}

string GetUserMenuGroupHeader(key user, string group) INL {
    string hdr = llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP_HEADER + group + ":" + (string)user, lsdPassword);
    if(hdr != "") {
        return hdr;
    }
    else {
        return llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP_HEADER + group, lsdPassword);
    }
}

integer HasUserMenuGroup(key user, string group) INL {
    if(llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group + ":" + (string)user, lsdPassword) != "") {
        return TRUE;
    }
    return llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group, lsdPassword) != "";
}

RegisterListener(key user) INL {
    if(IsUserRegistered(user)) {
        SetUserActivity(user);
        return;
    }
    integer chnl = ((integer)("0x"+llGetSubString((string)user,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
    integer handle = llListen(chnl, "", user, "");
    integer s = llLinksetDataWriteProtected(LSD_MENU_USER_CONTEXT+(string)user, (string)chnl + LSD_DELIMITER + (string)handle, lsdPassword);
    if(s == LINKSETDATA_OK) {
        ResetUserMenuStack(user);
        SetUserActivity(user);
    }
    else {
        llListenRemove(handle);
    }
}

DeregisterListener(key user) INL {
    list chHdl = llParseStringKeepNulls(llLinksetDataReadProtected(LSD_MENU_USER_CONTEXT+(string)user,lsdPassword),[LSD_DELIMITER],[]);
    llListenRemove((integer)chHdl[1]);
    llLinksetDataDeleteProtected(LSD_MENU_USER_CONTEXT + (string)user, lsdPassword);
    RemUserActivity(user);
}

integer IsUserRegistered(key user) INL {
    return llLinksetDataReadProtected(LSD_MENU_USER_CONTEXT+(string)user, lsdPassword) != "";
}

integer GetListenerChannel(key user) INL {
    list chHdl = llParseStringKeepNulls(llLinksetDataReadProtected(LSD_MENU_USER_CONTEXT+(string)user,lsdPassword),[LSD_DELIMITER],[]);
    return (integer)chHdl[0];
}

ResetUserMenuStack(key user) INL {
    llLinksetDataWriteProtected(LSD_MENU_USER_STACK + (string)user, "ROOT", lsdPassword);
    ResetMenuPage(user);
}

PushUserMenuStack(key user, string level) INL {
    list stk =llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []); 
    stk = [level] + stk;
    llLinksetDataWriteProtected(LSD_MENU_USER_STACK + (string)user, llDumpList2String(stk,LSD_DELIMITER), lsdPassword);
    ResetMenuPage(user);
}

PopUserMenuStack(key user) INL {
    list stk = llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []); 
    if(llGetListLength(stk) > 1) {
        stk = llList2List(stk,1,llGetListLength(stk));
    }
    llLinksetDataWriteProtected(LSD_MENU_USER_STACK + (string)user, llDumpList2String(stk,LSD_DELIMITER), lsdPassword);
    ResetMenuPage(user);
}

string LastUserMenuGroup(key user) INL {
    list stk = llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []);
    return (string)stk[0]; 
}

string LastUserMenuPath(key user) INL {
    list p = llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []);
    string path;
    integer i = llGetListLength(p);
    while (i--) {
        path += llList2String(p, i);
        if (i) path += "/";  // no trailing separator on the last piece
    }
    return path;
}

ResetMenuPage(key user) INL {
    llLinksetDataWriteProtected(LSD_MENU_USER_PAGE + (string)user, "0", lsdPassword);
}

IncMenuPage(key user) INL {
    llLinksetDataWriteProtected(LSD_MENU_USER_PAGE + (string)user, (string)(((integer)llLinksetDataReadProtected(LSD_MENU_USER_PAGE + (string)user, lsdPassword))+1), lsdPassword);
}

DecMenuPage(key user) INL {
    llLinksetDataWriteProtected(LSD_MENU_USER_PAGE + (string)user, (string)(((integer)llLinksetDataReadProtected(LSD_MENU_USER_PAGE + (string)user, lsdPassword))-1), lsdPassword);
}

integer GetMenuPage(key user) INL {
    return (integer)llLinksetDataReadProtected(LSD_MENU_USER_PAGE + (string)user, lsdPassword);
}

SetUserActivity(key user) INL {
    llLinksetDataWriteProtected(LSD_MENU_USER_ACTIVITY + (string)user, (string)llGetUnixTime(), lsdPassword);
}

RemUserActivity(key user) INL {
    llLinksetDataDeleteProtected(LSD_MENU_USER_ACTIVITY + (string)user, lsdPassword);
}

integer GetUserActivity(key user) INL {
    return (integer)llLinksetDataReadProtected(LSD_MENU_USER_ACTIVITY + (string)user, lsdPassword);
}

ShowPMenu(key user) INL {
    RegisterListener(user);
    string uMStk = LastUserMenuGroup(user);
    integer uPage = GetMenuPage(user);
    list choices = MenuPage(GetUserMenuGroup(user, uMStk), uPage, uMStk == "ROOT");
    string numOps = GetUserMenuNumericOps(user, uMStk, uPage);
    llDialog(user, GetUserMenuGroupHeader(user, uMStk) + numOps, choices, GetListenerChannel(user));
}

string GetUserMenuNumericOps(key user, string group, integer page) INL {
    list mOps = llParseString2List(llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP_NUMERIC_MAP + group + ":" + (string)user, lsdPassword), [LSD_DELIMITER], []); 
    if(llGetListLength(mOps)) {

        integer pStart = page * PAGE_ELEMENTS;
        if(pStart < 0) pStart = 0;
        integer pStop = pStart-1 + PAGE_ELEMENTS;
        integer maxEl = llGetListLength(mOps)-1;
        if(pStop > maxEl) pStop = maxEl;
        list subList = llList2List(mOps, pStart, pStop);

        string hLst;

        integer i = llGetListLength(subList);
        while (i--) {
            hLst = (string)(i + (page*PAGE_ELEMENTS)) + ") " + (string)subList[i] + "\n" + hLst;
        }
        return hLst;
    }
    return "";
}

list MenuPage(list options, integer page, integer topLevel) INL {
    integer pStart = page * PAGE_ELEMENTS;
    if(pStart < 0) pStart = 0;
    integer pStop = pStart-1 + PAGE_ELEMENTS;
    integer maxEl = llGetListLength(options)-1;
    if(pStop > maxEl) pStop = maxEl;
    list subList = llList2List(options, pStart, pStop);
    
    list menuList = [];
    if(maxEl+1 > PAGE_ELEMENTS || page != 0 || topLevel == FALSE || pStop != maxEl) {
        menuList = [llList2String([PREVIOUS_PAGE," "],page == 0),
            llList2String([BACK_MENU," "],topLevel == TRUE),
            llList2String([NEXT_PAGE," "],pStop == maxEl)];
    }
    else {
        return options;
    }
    
    return menuList + llList2List(subList,6,8) + llList2List(subList,3,5) + llList2List(subList,0,2);
}

InitPMenu(string nlsdPassword) INL {
    lsdPassword = nlsdPassword;
    SetMenuGroup("ROOT", "No Root Menu has been set! Call SetMenuGroup(\"ROOT\",header,[options]) to set ROOT Group", []);
}


integer HandlePMenu(integer chnl, key user, string selection) INL {
    if(GetListenerChannel(user) == chnl) {
        //llOwnerSay((string)chnl + " _ " + (string)user + " _ " + selection);
        if(selection == NEXT_PAGE) {
            IncMenuPage(user);
            ShowPMenu(user);
            return FALSE;
        }
        else if(selection == PREVIOUS_PAGE) {
            DecMenuPage(user);
            ShowPMenu(user);
            return FALSE;
        }
        else if(selection == BACK_MENU) {
            PopUserMenuStack(user);
            ShowPMenu(user);
            return FALSE;
        }
        else if(HasUserMenuGroup(user, selection)) {
            PushUserMenuStack(user, selection);
            ShowPMenu(user);
            return FALSE;
        }
        else if(selection == " ") {
            ShowPMenu(user);
            return FALSE;
        }
        SetUserActivity(user);
    }
    DeregisterListener(user);
    return TRUE;
}

PurgeInactiveUsers() INL {
    list users = llLinksetDataFindKeys("^" + LSD_MENU_USER_ACTIVITY  +".*$",0,0);
    integer i = llGetListLength(users);
    while (--i >= 0) {
        list ut = llParseString2List((string)users[i],[":"],[]);
        integer uAct = GetUserActivity((key)ut[1]);
        if(uAct + PMENU_PURGE_AGE_SECONDS < llGetUnixTime()) {
            DeregisterListener((key)ut[1]);
        }
    }
}

ClearPMenuCache() INL {
    llLinksetDataDeleteFound("^@ⱣⱮ_.*$", lsdPassword );
}