# PMenu
A SecondLife LSL Library for making paginated and nested menus

Example:

```

default
{
    state_entry()
    {
        llLinksetDataReset();
        llSetTimerEvent(5);
        //ClearPMenuCache();
        InitPMenu("password");
        SetMenuGroup("ROOT", "Top level menu", ["A","B","C","D"]);
        SetMenuGroup("A","second menu", ["1","2","3","4","5","6","7","8","9","10","11","12"]);
        SetMenuGroup("2","second menu", ["1A","2A","3A","4A","5A","6A","7A","8A","9A","10A","11A","12A"]);
    }

    touch_start(integer total_number)
    {
        ShowMenu(llDetectedKey(0));
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if(HandlePMenu(chan,id,msg)) {
            llOwnerSay("Selected Option: " + msg);
        }
    }
    
    timer()
    {
        PurgeInactiveUsers();
    }
    
}

```
