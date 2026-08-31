# PMenu
A SecondLife LSL library for making paginated and nested menus

#Features:
- Automatically adds customizable paginated navigation on large menu lists.
- Multi-user contexts allows multiple individuals to navigate the menu system without conflicting with other users.
- Auto purges handles/listeners from inactivity with configurable time. Automatically closes handles/listeners on selected option.#
- Uses LinkSetData to manage menu structures and states. A LinkSetData Password can be configured.
- Lightweight menu library.

#Preprocessor options
Define one or more of these options to customize PMenu

| Directive  | Description | Default |
| ---- | ---- | ---- |
| NEXT_PAGE | The special identity of the next page button | "►" |
| PREVIOUS_PAGE | The special identity of the previous page button | "◄" |
| BACK_MENU | The special identity of the back a menu button | "Back" |
| PMENU_PURGE_AGE_SECONDS | The age of a listener and its respective user entry before it is discarded | 30 |
| PMENU_INSTANCE | If you are running multiple scripts in the same linked prim system, this allows you to have concurrently running menu systems without conflicting with states. | "DEF_INST" |

Example:

```
#include "PMenu.lsl"

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
    
    listen(integer chan, string name, key user, string msg)
    {
        if(HandlePMenu(chan,id,msg)) {
            llOwnerSay("User \"" + user + "\" Selected Option: " + msg);
        }
    }
    
    timer()
    {
        PurgeInactiveUsers();
    }
    
}

```
