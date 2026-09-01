string lsdPassword;

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
#define LSD_MENU_OPTION_GROUP_HEADER ("@ⱣⱮ_" + ##PMENU_INSTANCE + "_OGH:")

SetMenuGroup(string group, string header, list options) {
    if(~llListFindList(options, (list)group)) {
        llOwnerSay("Cant add menu group: \"" + group + "\". The group refers to itself in its own options!"); 
        return;
    }
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP + group, llDumpList2String(options,LSD_DELIMITER), lsdPassword);
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP_HEADER + group, header, lsdPassword);
}

SetUserMenuGroup(key user, string group, string header, list options) {
    if(~llListFindList(options, (list)group)) {
        llOwnerSay("Cant add menu group: \"" + group + "\". The group refers to itself in its own options!"); 
        return;
    }
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP + group + ":" + (string)user, llDumpList2String(options,LSD_DELIMITER), lsdPassword);
    llLinksetDataWriteProtected(LSD_MENU_OPTION_GROUP_HEADER + group + ":" + (string)user, header, lsdPassword);
}

list GetUserMenuGroup(string group, key user) {
    string grp = llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group + ":" + (string)user,lsdPassword);
    if(grp != "") {
        return llParseString2List(grp, [LSD_DELIMITER], []); 
    }
    else {
        return llParseString2List(llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group,lsdPassword), [LSD_DELIMITER], []);
    }
}

string GetUserMenuGroupHeader(string group, key user) {
    string hdr = llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP_HEADER + group + ":" + (string)user, lsdPassword);
    if(hdr != "") {
        return hdr;
    }
    else {
        return llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP_HEADER + group, lsdPassword);
    }
}

integer HasMenuGroup(string group) {
    return llLinksetDataReadProtected(LSD_MENU_OPTION_GROUP + group,lsdPassword) != ""; 
}

RegisterListener(key user) {
    if(IsUserRegistered(user)) {
        SetUserActivity(user);
        return;
    }
    integer chnl = ((integer)("0x"+llGetSubString((string)user,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF;
    integer handle = llListen(chnl, "", user, "");
    integer s = llLinksetDataWriteProtected(LSD_MENU_USER_CONTEXT+(string)user, (string)chnl + LSD_DELIMITER + (string)handle, lsdPassword);
    if(s == LINKSETDATA_OK) {
        PushUserMenuStack(user,"ROOT");
        ResetMenuPage(user);
        SetUserActivity(user);
    }
    else {
        llListenRemove(handle);
    }
}

DeregisterListener(key user) {
    list chHdl = llParseStringKeepNulls(llLinksetDataReadProtected(LSD_MENU_USER_CONTEXT+(string)user,lsdPassword),[LSD_DELIMITER],[]);
    llListenRemove((integer)chHdl[1]);
    llLinksetDataDeleteProtected(LSD_MENU_USER_CONTEXT + (string)user, lsdPassword);
    llLinksetDataDeleteProtected(LSD_MENU_USER_STACK + (string)user, lsdPassword);
    RemUserActivity(user);
}

integer IsUserRegistered(key user) {
    return llLinksetDataReadProtected(LSD_MENU_USER_CONTEXT+(string)user, lsdPassword) != "";
}

integer GetListenerChannel(key user) {
    list chHdl = llParseStringKeepNulls(llLinksetDataReadProtected(LSD_MENU_USER_CONTEXT+(string)user,lsdPassword),[LSD_DELIMITER],[]);
    return (integer)chHdl[0];
}

PushUserMenuStack(key user, string level) {
    list stk =llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []); 
    stk = [level] + stk;
    llLinksetDataWriteProtected(LSD_MENU_USER_STACK + (string)user, llDumpList2String(stk,LSD_DELIMITER), lsdPassword);
    ResetMenuPage(user);
}

PopUserMenuStack(key user) {
    list stk = llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []); 
    if(llGetListLength(stk) > 1) {
        stk = llList2List(stk,1,llGetListLength(stk));
    }
    llLinksetDataWriteProtected(LSD_MENU_USER_STACK + (string)user, llDumpList2String(stk,LSD_DELIMITER), lsdPassword);
    ResetMenuPage(user);
}

string PeekUserMenuStack(key user) {
    list stk = llParseString2List(llLinksetDataReadProtected(LSD_MENU_USER_STACK + (string)user,lsdPassword), [LSD_DELIMITER], []);
    return (string)stk[0]; 
}

ResetMenuPage(key user) {
    llLinksetDataWriteProtected(LSD_MENU_USER_PAGE + (string)user, "0", lsdPassword);
}

IncMenuPage(key user) {
    llLinksetDataWriteProtected(LSD_MENU_USER_PAGE + (string)user, (string)(((integer)llLinksetDataReadProtected(LSD_MENU_USER_PAGE + (string)user, lsdPassword))+1), lsdPassword);
}

DecMenuPage(key user) {
    llLinksetDataWriteProtected(LSD_MENU_USER_PAGE + (string)user, (string)(((integer)llLinksetDataReadProtected(LSD_MENU_USER_PAGE + (string)user, lsdPassword))-1), lsdPassword);
}

integer GetMenuPage(key user) {
    return (integer)llLinksetDataReadProtected(LSD_MENU_USER_PAGE + (string)user, lsdPassword);
}

SetUserActivity(key user) {
    llLinksetDataWriteProtected(LSD_MENU_USER_ACTIVITY + (string)user, (string)llGetUnixTime(), lsdPassword);
}

RemUserActivity(key user) {
    llLinksetDataDeleteProtected(LSD_MENU_USER_ACTIVITY + (string)user, lsdPassword);
}

integer GetUserActivity(key user) {
    return (integer)llLinksetDataReadProtected(LSD_MENU_USER_ACTIVITY + (string)user, lsdPassword);
}

ShowPMenu(key user) {
    RegisterListener(user);
    string uMStk = PeekUserMenuStack(user);
    list choices = MenuPage(GetUserMenuGroup(uMStk,user), GetMenuPage(user), uMStk == "ROOT");
    llDialog(user, GetUserMenuGroupHeader(uMStk,user), choices, GetListenerChannel(user));
}

list MenuPage(list options, integer page, integer topLevel) {
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

InitPMenu(string nlsdPassword) {
    lsdPassword = nlsdPassword;
    SetMenuGroup("ROOT", "No Root Menu has been set! Call SetMenuGroup(\"ROOT\",header,[options]) to set ROOT Group", []);
}


integer HandlePMenu(integer chnl, key user, string selection) {
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
        else if(HasMenuGroup(selection)) {
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

PurgeInactiveUsers() {
    list users = llLinksetDataFindKeys("^" + LSD_MENU_USER_ACTIVITY  +".*$",0,0);
    integer i = llGetListLength(users);
    while (--i >= 0) {
        list ut = llParseString2List((string)users[i],[":"],[]);
        integer uAct = GetUserActivity((key)ut[1]);
        if(uAct + PMENU_PURGE_AGE_SECONDS < llGetUnixTime()) {
            DeregisterListener((key)ut[1]);
            //llLinksetDataDeleteProtected(LSD_MENU_USER_STACK + (string)ut[1], lsdPassword);
            //llLinksetDataDeleteProtected(LSD_MENU_USER_PAGE + (string)ut[1], lsdPassword);
        }
    }
}

ClearPMenuCache() {
    list keys = llLinksetDataFindKeys("^@ⱣⱮ_.*$",0,0);
    integer i;
    integer nk = llGetListLength(keys);
    while (i < nk) { 
        llLinksetDataDeleteProtected((string)keys[i],lsdPassword);
        i++;
    }
}