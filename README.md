# Custom Snap Mod
For all those who need finer control over where to snap to in Dungeondraft.
Version 1.1.2 Now comes with Hexagons
Version 1.2.1 Now comes with a custom Grid Overlay


### Installation.
1. Download the mod
2. Extract the zip somewhere into your Dungeondraft mod folder.
3. If you do not have a mod folder yet, the Mods tab will let you choose one.
4. Use the mods tab to select the mod and simply open your map.

If you have a previous version installed, simply delete or replace the old mod files.
On the current beta version of Dungeondraft, you have to head over to your Dungeondraft installation location and delete the duplicate mod files in there to use this mod.


### How to use.
- You can find the menu to interact with this mod in the Settings category.
- Switch between vanilla snapping and custom snapping using the 'Enable' button in this menu.
- If you want to continue using the vanilla grid, disable the 'Custom Grid' button in this menu.
- You can still turn off snapping altogether with the vanilla keybind ('S' by default).
- With the mod and snapping enabled, all the tools should properly snap to the given grid.
- Simply select a snapping resolution from the presets, or enable the advanced mode to set your own custom resolution or even an offset.


### FAQ.
Q. On the newest beta of Dungeondraft, the mod keeps crashing.
A. Megasploot is testing shipping mods with the vanilla download and Custom Snap is among them. Unfortunately Dungeondraft doesn't yet handle duplicate mods. Simply head over to your Dungeondraft installation location and delete the duplicate mod files in there.

Q. Can I snap for hexagonal maps? \
A. Absolutely! Simply check out one of the respective presets, or click one of the hexagonal icons in the mod's tool.

Q. This says it comes with a Hex grid, how come I can only see triangles?
A. This is the default as the hexagonal grid can cause severe lagg on larger maps. Simply click the 'Hex' button at the bottom of the mod's menu to change to hexes. That said, triangles are really just hexes with a line from each corner to the centre.

Q. I exported the map and it's back to vanilla grid!
A. Unfortunately I need to write a completely new tool to fix that issue. I'm working on it, I promise!

Q. Does the mod save my settings? \
A. Yes. You can find the file with the settings by navigating 'Menu' -> 'Open User Folder' and there look for 'custom_snap_mod_data.txt' Note that this file only shows up after you edit your setting for the first time.

Q. The Portal tool doesn't snap to walls. \
A. Yes. It snaps properly in Freestanding mode but unfortuantely, due to a technology constraint, it cannot work in Anchored mode.

Q. The Select tool doesn't snap to where it should. \
A. It snaps based on distance moved. This is how it works in vanilla, too. You can still snap individual objects normally as the other tools do, by "instant dragging" them without selecting them first.

Q. What should I do if I want to snap multiple selected items at once?
A. Press the 'Snap Selection' button. Since I do not know which item you want as a basis for the snap, it first snaps the centre of the selection box and on consecutive clicks cycles through all items. Simply click the button until it snaps to the position you wish.

Q. What are the offset sliders doing? \
A. Using these, you can move all the snap points an equal distance. Useful when you want to place objects slightly off-centred from the grid. Pro tip: you can manually enter a negative value. Values are in pixels

Q. Offset tool? Where can I find that? \
A. Enable the advanced section of the tool.

Q. I was hoping I could set my own distance for the snapping points. \
A. You can! Simply enable the advanced section of the tool and play around with the Spacing sliders.

Q. Why is there 2 sliders for spacing and offset each? \
A. If you turn off the locked aspect ratio, you can set a separate spacing and offset for each axis. Useful for isometric maps.

Q. What are the 'Lock Aspect Ratio' toggles doing? \
A. Turning them off lets you use the sliders for each axis separately (see the point above). This behaviour is turned off by default so you don't have to change 2 values every time.

Q. What are the 'Corner' and 'Edge' buttons at the bottom of the advanced setting doing? \
A. Hexagons' sizes are measured differently by different artists and tools. Sometimes they're measured from the corners, which are the furthest points from the center. And at other times they're measured from the middle of the edges, which are the closest points to the center. Using these buttons you can switch between these settings.

Q. Nothing is snapping anymore. \
A. Have you accidentally disabled the mod or turned off snapping altogether? Try pressing 'S'. Or maybe you're just using a very fine snapping resolution. Try lowering the spacing.

Q. The snapping is back to vanilla. \
A. You might have disabled the mod. Or alternatively you might have set the snap spacing to either 256 or 128 which are the default values for normal snapping and half snapping.


### Compatibility.
- No known imcompatiblities as of yet. Please notify me and the other authors if you find any and maybe there will be a compatibility patch in the future.
- The mod is highly dependent on the order of operations and manually adding functionality for multiple tools. Therefore any mods with custom tools may cause unforseen behaviour, such as:
    1. Working perfectly with this mod.
    2. Simply work as intended without benefiting from the Custom Snap Mod.
    3. Have some functionalities snap to the vanilla grid and others to the modded grid.
    4. A random one of the above based on load order.
- The Custom Snap mod registers to the _Lib API. If your mod of choice supports this aspect of the Custom Snap mod, downloading and enabling the [_Lib mod](https://cartographyassets.com/assets/31828/_lib/) might fix this.


### Changelog.
- Version 1.2.5
    - Updated presets to actually be correct for Roll20 hex grids.
- Version 1.2.4
    - Fixed issue with the Snap Select button not appearing in other Dungeondraft versions.
- Version 1.2.3
    - The Snap Select button now properly snaps to the vanilla grid if Custom Snap is disabled.
    - Fixed bug where Snap Select button would vanish selection if it was moved between two instances of pressing the button.
- Version 1.2.2
    - Now comes with dedicated isometric view.
- Version 1.2.1
    - Implemented grid overlay (doesn't yet work during export)
    - Fix bug with coordinate display when using polygon tools.
    - You can now snap a whole multi-selection or Prefab to the grid using the Select tool.
    - The Text tool can now also snap while in 'Move' mode.
    - Mod now saves settings individually for each map.
    - 'Spacing' sliders renamed to 'Scaling' as this conveys more accurately that it changes the distance between snap points.
    - Now works with _Lib to allow other mods to use snapping.
    - Wrap contents of .zip into its own folder to prevent loose mod files crashing Dungeondraft.
    - Updated some Tooltips.
    - Updated some icons.


### Notes for Modders.
- If you have your mod registered with the _Lib mod, you can access the Custom Snap mod's functionalities as Global.API.snappy_mod.method_name()
- When you place items in the World that depend on a snapped position, please call the following methods:
    1. get_snapped_position(position: Vector2): Vector2 - This will return the absolute position of the closest snap point on the map from the given @position.
    2. get_snapped_delta(delta: Vector2): Vector2 - When moving items, you may not want to snap to a position but rather have movement happen in discrete bounds. This method will return the snapped delta of a movement from an origin.


### Thanks
Many thanks to you for checking out my mod, as well as MBMM for saving me tons of work. I hope you're going to have a lot of fun with this mod. Should you come across issues or potential for improvements, come find me (Hieronymos) in the modding channel in the official [Megasploot Discord](https://discord.gg/J9Czgpu).