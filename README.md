# PMenu
A SecondLife LSL library for making paginated and nested menus

## Features:
- Automatically adds customizable paginated navigation (Previous / Back / Next controls) on large menu lists.
- Multi-user contexts allows multiple individuals to navigate the menu system without conflicting with other users.
- Per-user menu overrides allow a group's options/header can be customized for a specific avatar, falling back to the shared definition when no override exists
- Auto purges handles/listeners from inactivity with configurable time. Automatically closes handles/listeners on selected option.
- Uses LinkSetData to manage menu structures and states. A LinkSetData Password can be configured.
- Lightweight menu library.
- Named menu groups that can reference each other as submenus, with automatic Back-button navigation via a per-user stack
- Supports Multiple independent instances on the same multi-prim object

## Preprocessor options
Define one or more of these options to customize PMenu

| Macro Directive | Default | Purpose |
|---|---|---|
| `PMENU_INSTANCE` | `"DEF_INST"` | Set a unique value per script if you run more than one PMenu instance in the same linkset. |
| `NEXT_PAGE` | `"►"` | Button label used for the next-page control. |
| `PREVIOUS_PAGE` | `"◄"` | Button label used for the previous-page control. |
| `BACK_MENU` | `"Back"` | Button label used to pop back to the parent menu. |
| `PMENU_PURGE_AGE_SECONDS` | `30` | Seconds of inactivity before a user's session and listener are cleaned up. |

## Setup Example
```lsl
#define PMENU_INSTANCE "SHOP"
#define PMENU_PURGE_AGE_SECONDS 60

#include "PMenu.lsl"
```

## Public API

### `InitPMenu(string password)`

Call once, typically in `state_entry`. You can optionally set the password used to protect PMenu's Linkset Data backend from other scripts.

### `SetMenuGroup(string group, string header, list options)`

Registers (or updates) a **shared** menu group, visible to every user unless a user specific override has been declared.

- `group` — the group's identifier. Use `"ROOT"` for the top-level menu.
- `header` — the text shown at the top of the `llDialog` for this group.
- `options` — the list of button labels for this group. Any entry that matches another registered group's name becomes a submenu link.

A group cannot list itself in its own `options`. `SetMenuGroup` rejects this and logs an owner-say warning.

```lsl
SetMenuGroup("ROOT", "Main Menu", ["Buy", "Info", "Settings"]);
SetMenuGroup("Settings", "Settings", ["Volume", "Notifications", "Reset"]);
```

### `SetUserMenuGroup(key user, string group, string header, list options)`

Registers (or updates) a **per-user override** for a menu group. When the specified user views `group`, they'll see this header/options instead of the shared definition set by `SetMenuGroup`. Other users are unaffected. Useful for personalizing a menu — e.g. showing an "Undo Purchase" option only to the user who just bought something, or tailoring a settings menu to a user's current state or permission.

Like `SetMenuGroup`, this rejects a group that references itself in its own `options`.

```lsl
// Shared default for everyone:
SetMenuGroup("ROOT", "Main Menu", ["Buy", "Info"]);

// Override just for this one user:
SetUserMenuGroup(llDetectedKey(0), "ROOT", "Welcome back!", ["Buy Again", "Info", "My Orders"]);
```

### `ShowPMenu(key user)`

Displays the menu to `user`.

### `HandlePMenu(integer channel, key user, string selection)`

Call this from your `listen` event, passing through the event's parameters. It:

- Ignores messages that don't match the user's registered listen channel
- Handles `NEXT_PAGE`, `PREVIOUS_PAGE`, and `BACK_MENU` events internally
- Pushes into a submenu if `selection` matches a group registered for this user (shared or per-user override, via `HasUserMenuGroup`)
- Otherwise treats `selection` as a final leaf choice, deregisters the user's listener, and returns `TRUE` so your script can act on it

Returns `FALSE` if the selection was consumed internally (pagination/navigation/blank button), or `TRUE` if it's a leaf selection your script should handle.

### `PurgeInactiveUsers()`

Removes any stale user handles/listeners. Call this either in a timer or whenever you think you need to clean them up.

# Example

```lsl
#include "PMenu.lsl"

default
{
    state_entry()
    {
        llLinksetDataReset();
        llSetTimerEvent(5);

        //Resets the specific Instance of PMenu which is a safer call to make than llLinksetDataReset();
        //ClearPMenuCache();

        InitPMenu("password");

        SetMenuGroup("ROOT", "Shop Options", ["Fruit & Veg","Meats","Electronics","Toiletry"]);
        SetMenuGroup("Fruit & Veg","A selection of green stuff", ["Cabbage","Broccoli","Sprouts","Peas"]);
        SetMenuGroup("Meats","You like burgers right?", ["Beef","Beef Again","Chicken","Lamb"]);
        SetMenuGroup("Electronics","Phones n TVs", ["Samsung Phone","Samsung TV","Samsung Tablet","Im not a Samsung Shill"]);
        SetMenuGroup("Toiletry","... Yes", ["Toilet Roll","Bleach","Soap","First Aid Kit"]);
    }

    touch_start(integer total_number)
    {
        ShowPMenu(llDetectedKey(0));
    }
    
    listen(integer chan, string name, key user, string msg)
    {
        if(HandlePMenu(chan,user,msg)) {
            llOwnerSay("User \"" + user + "\" Selected Option: " + msg);
        }
    }
    
    timer()
    {
        PurgeInactiveUsers();
    }
    
}

```
