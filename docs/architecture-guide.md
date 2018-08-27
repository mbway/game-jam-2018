# Architecture Guide #
This is a guide for navigating the code base. It is written mostly chronologically as a game is started.


When the game starts, `MainMenu/MainMenu.tscn` is loaded. This scene doesn't have any visual content, those are stored in 'screens' which are the scenes: `MainMenu/StartScreen.tscn`, `MainMenu/OptionsMenu.tscn` and `MainMenu/Lobby.tscn`. When a screen is loaded it is added as a child node of the MainMenu with the name `Screen`.

The script `Utils/globals.gd` is loaded automatically when the game starts and reads user configuration from a settings file which is automatically generated if it doesn't exist. These settings are interactively managed through the options menu.
The globals script also stores information about the current game, such as the game mode, game mode options and player details. For this, a `PlayerConfig` class is defined in `Utils/globals.gd` which stores the information required to construct a `Player` node.

When `MainMenu/Lobby.tscn` is loaded, the available 'input methods' are detected. Keyboard/Mouse and AI are always added, along with one gamepad control option for every gamepad which is plugged in when the scene loads. Then `player_panel_scene` instances are automatically added for each input methods (except for AI). These panels contain information about the player such as their name and input method. The map and game mode options can also be chosen. After the start button is pressed, the current choices from the UI are processed and stored in the global data. Then the scene is changed to the scene of the selected map.

The mechanism for starting a game is to assign to the global data for the game mode and player config, then call `change_scene` with a map scene as the argument. The global data persists between scene changes, but all the resources for displaying previous scenes can be garbage collected. There is a script `Utils/QuickStart.gd` which can be hard-coded to construct a game with the desired settings and start immediately, bypassing the main menu.

Each map scene is constructed the same way:
- The basic nodes are added by copying from `Utils/BaseMap.tscn`
    - That includes a collider for the bottom of the map, Parent nodes for bullets and players, the HUD, camera and music
    - as well as a tree of nodes for game type specific use. Only the nodes relevant to the current mode are displayed.
        - for example, depending on the game mode, you may want spawn points or pickup locations to be in different locations etc
- The `Map` child is a dynamic node created from a `Tiled` `.tmx` file which is pre-processed by `Utils/TiledPostImport.gd` in order to interpret the map for use in Godot, eg converting all the polygons in the 'Collision' layer into collidable nodes.
- Each map scene has the `Gameplay/Gameplay.gd` script attached.

The `Gameplay.gd` script removes the game mode specific nodes from the scene tree and stores them, it also instances the gameplay scripts for each mode (eg `Gameplay/TDM.gd` for team death match) and stores them. The script creates `Player/Player.tscn` instances from the global player configuration data. It then sets the current game mode by adding the mode specific nodes to the tree and calling the `setup` method of the game mode script. Note that this approach was designed to facilitate switching game mode during gameplay.

The game mode scripts (eg `Gameplay/TDM.gd`) aren't added to the tree, they instead register callbacks in a `setup` method for events such as a player dying. Note that this mechanism may need to be made more capable in the future, but for now this is sufficient to implement team death match.

`Player/Player.gd` contains the data which is used by all players regardless of their input method. This script handles drawing and moving the player based on methods such as `try_jump()` and variables such as `move_direction` (which is a float from -1 to +1). The player script implements initiating a jump just before hitting the floor and shortly after falling off a platform. Double jumps are also supported. The player script also manages the inventory with methods such as `equip_weapon` which is called by the particular input method.

`Player/AIPlayer.tscn`, `Player/GamepadPlayer.tscn` and `Player/KeyboardPlayer.tscn` are scenes which inherit from `Player/Player.tscn` and implement a particular control scheme. This provides a nice separation of concerns since the keyboard and gamepad mostly require overriding `_input` and setting the appropriate variables in response, however the AI control requires many more components.

Note: the player is a kinematic body, meaning that it shouldn't be effected by physics, however `move_and_slide` is used to implement the platforming controls, and bullets effect this calculation causing a glitchy-looking knock back when hit. To eliminate this, the player is _not_ collidable with bullets. Instead, a child node called `BulletCollider` is used to detect bullet collisions and is a static body parented to the player. This way the movement calculations of the player are completely independent of bullet collisions, however in the future, proper knock back could be implemented when a collision is detected, but this way we have full control.

Most weapons use the same `Weapons/Gun.gd` script, but with different parameters such as fire rate, damage etc. When the gun fires it spawns a bullet. Because the bullet shouldn't be parented to the gun (because it would inherit the transform as the player modes the gun) every map has a `Bullets` child node. The gun parents new bullets to this node instead. Variables and Timers are used to determine whether a gun is ready to fire and whether to fire when the trigger is held etc.

Bullets use the `Weapons/Bullet.gd` script. When spawned, a collision exception is made between the bullet and the player who is holding the gun which spawned the bullet. Once the bullet hits any collidable object, or after the bullet travels a maximum distance, the bullet de-spawns. If the bullet collides with an object in the 'damageable' group, it calls the `take_damage` method of that object (the group is used like a duck-typed interface).

`Objects/PickupSpawn.tscn` periodically spawns a pickup which players receive if they collide with it. The available pickups are determined by creating a node in the tree, inside which, instances of `Weapons/AvailableWeapon.tscn` reside. These scenes have a parameter for the scene of the weapon and the texture of the weapon. This allows the pickup to use the weapon texture without instancing the weapon.

The player has a child node called `Inventory` where instances of weapons are placed by `equip_weapon()`. Since all weapons are removed when the player dies and respawns, a mutex is required to guard against concurrent modification of the inventory node. The active weapon is the only active child of `Inventory`, the others are deactivated and so not visible and don't update their position etc.


