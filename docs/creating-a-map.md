# Creating a map #

#TODO: create a template map to copy which has most of this already set

- In Tiled
    - Create a new map (tile size 32x32)
    - Map > Add External Tileset the tilemap at `res://Assets/Tiles/Tiles.tsx`
    - Create the map
        - tip: you can select multiple tiles in the tileset window to speed up the process by placing many tiles down at once
    - Rename the layer to 'Map'
    - Add a new 'Object Layer' called 'Collision' and add collision shapes to the map
        - Note: not one per tile, make the shapes span as much as possible, also make sure to snap to grid to avoid gaps
        - Note: only use the rectangle tool. The polygon tool causes collision issues with the player.
    - optional: only if one way platforms are required:
        - Add a new 'Object Layer' called 'OneWayCollision'
            - right click it and select 'Layer Properties'. Then in the properties pannel set the colour to `[255, 255, 0]`
            - you may want to check 'View > Snapping > Snap to Fine Grid' for placing one way platforms
    - Crop the map (optional)
        - Map > autocrop
        - or for more control: Map > crop to selection
    - File > Export As Image to save a screenshot for the main menu.
        - Will have to resize in an image editor
        - (set the Collision layer to not visible while exporting the image)
- In Godot
    - create a new scene and create a Node2D as the root named the same as the map (without .tmx)
    - right click on the root node and click 'Instance Child scene'
        - (this means that when the map is edited in Tiled, the Map and Collision nodes update, but other nodes can be added on top)
        - Select the new map file (.tmx file)
        - rename the new node to `Map`
        - on the toolbar above the main view, click 'Lock the selected object in place' and 'Makes sure the object's children are not selectable'. This will prevent accidentally modifying the tiles in Godot (which would cause it to no longer update when edited in Tiled!)
    - Save the scene (probably best to name identical to the tmx file but with the tscn extension)
    - Single click on the .tmx file in the FileSystem panel then open the Import panel:
        - use the following properties:
            - custom properties: off
            - tile metadata: off
            - UV clip: on
            - Image Flags: none
            - collision layer: none
            - Embed Internal Images: off
            - Save Tiled Properties: off
            - Add Background: off
            - Post Import Script: `res://Utils/TiledPostImport.gd`
        - then click 'reimport'
        - you may need to close and re-open the scene for the changes to take effect
    - Right click the root of the scene and click 'Merge From Scene'
        - select `res://Utils/BaseMap.tscn`
        - select all the nodes EXCEPT FOR the root node of `BaseMap.tscn` then click OK
        - (this will add the required nodes to the scene in one go)
    - Attach the `Gameplay.gd` script to the root of the new map (right click > attach script)
    - Add items to the map
    - In `res://MainMenu/Lobby.gd`, add an entry into `maps` for the newly created map



- Don't edit the map or collision in Godot. If you do this accidentally then after you save the scene, the map will no longer update to reflect the changes made in Tiled
    - to fix this, rename the scene to another name, then create a new inherited scene from the `.tmx` file
    - use 'Merge from Scene' and select the bad map scene and select everything except for the root, Map and Collision, then click OK
    - re-attach the `Gameplay.gd` script
    - now save the new scene and delete the bad scene file.
