# f1f_sling

A FiveM script for weapon slinging, custom weapon position adjustment, and immersive draw/holster animations. Supports persistent saving of weapon positions per player, with special animations for police and sheriff jobs.

![Preview](https://i.ibb.co/XktzzHdZ/Sn-mka-obrazovky-2025-08-09-130834.png)

---

## Features

- Attach large and small weapons to the player's back.
- Players can visually adjust weapon position and rotation using an in-game UI.
- Weapon position is saved per player in the database.
- Police and sheriff jobs have unique draw/holster animations.
- Fully OneSync compatible: All weapon positions and animations are synchronized and visible to all players.

---

## Requirements

- **ESX**
- **oxmysql** 
- **ox_lib** 
- **ox_inventory** 

---

## Installation

1. Add the resource to your `resources` folder.
2. Import the SQL table (see below) into your database.
3. Ensure you have oxmysql and ESX installed and configured.
4. Add `ensure f1f_sling` to your `server.cfg`.

---

## SQL

Create the following table in your database (make sure you use the correct database your server is connected to):

```sql
CREATE TABLE IF NOT EXISTS `sling_positions` (
  `identifier` VARCHAR(64) NOT NULL,
  `large` LONGTEXT DEFAULT NULL,
  `small` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## Usage

### Commands

- `/holster`  
  Attach your current weapon to position default or saved one.
- `/unholster`  
  Remove the weapon from holster and equip it.
- `/setpos`  
  Open the UI to visually adjust the weapon's position and rotation and save to database.

### How to Change Keybinds

#### 1. UI (HTML) Key Labels

To change the visual key labels in the UI, edit `html/index.html` and update the `<span class="keys">...</span>` elements for each control.  
Example:
```html
<span class="keys">UP/DOWN ARROW</span>
```

#### 2. Client Key Logic

To change which keys actually move/rotate the weapon, edit the key handling logic in `client/client.lua` (look for `IsControlPressed` and `IsControlJustPressed`).  
Example:
```lua
if IsControlPressed(0, 172) then -- UP ARROW
    position.x = position.x - 0.005
end
```
You can find a list of FiveM control codes here:  
https://docs.fivem.net/docs/game-references/controls/

#### 3. Key Labels in Controls Table

The labels shown in the UI are defined in the `controls` table in `client/client.lua`.  
Example:
```lua
local controls = {
    ["LEFT"] = "LEFT ARROW (left)",
    ...
}
```
Update these strings to match your preferred keybinds.

---

## Configuration

- Default weapon positions are set in `shared/config.lua` under `Config.DefaultLargeWeaponPosition` and `Config.DefaultSmallWeaponPosition`.
- Supported weapons for slinging are defined in `Config.AttachableWeapons` and `Config.SmallAttachableWeapons`.

---

## How Saving Works

- When a player uses `/setpos` and saves, their weapon position is stored in the database (`sling_positions` table) under their identifier.
- The script automatically loads the saved position when the player joins or requests it.
- No need to edit the code for saving/loading unless you want to change the database structure.

---

## Animations

- Police and sheriff jobs have unique draw and holster animations (see `client/client_animation.lua`).
- All other jobs use the default animation.

---

## Triggers

All server and client triggers use the `f1f_sling:` prefix for clarity and to avoid conflicts.

---

## Recommendations

- Do not edit the code unless you know what you are doing. All main settings can be changed in the config or via the UI.
- If you change keybinds, update both the UI and the client logic for consistency.

---

## Credits

- Script by f1f
- Based on ESX and ox_inventory

---

If you have any issues, please open an issue on the repository or contact the author on discord -> **f1f**.
