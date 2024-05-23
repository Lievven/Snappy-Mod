# Custom Snap Mod
For all those who need finer control over where to snap to in Dungeondraft.


### Installation.
1. Download the mod
2. Extract the zip somewhere into your Dungeondraft mod folder.
3. If you do not have a mod folder yet, the Mods tab will let you choose one.
4. Use the mods tab to select the mod and simply open your map.

If you have a previous version installed, simply delete or replace the old mod files.


### How to use.
- You can find the menu to interact with this mod in the Settings category.
- Switch between vanilla snapping and custom snapping using the 'Enable' button in this menu.
- You can still turn off snapping altogether with the vanilla keybind ('S' by default).
- With the mod and snapping enabled, all the tools should properly snap to the given grid.
- Simply select a snapping resolution from the presets, or enable the advanced mode to set your own custom resolution or even an offset.


### FAQ.
Q. Can I snap for hexagonal maps? \
A. Absolutely! Simply check out one of the respective presets, or click one of the hexagonal icons in the mod's tool.

Q. Does the mod save my settings? \
A. Yes. You can find the file with the settings by navigating 'Menu' -> 'Open User Folder' and there look for 'custom_snap_mod_data.txt' Note that this file only shows up after you edit your setting for the first time.

Q. The Portal tool doesn't snap to walls. \
A. Yes. It snaps properly in Freestanding mode but unfortuantely, due to a technology constraint, it cannot work in Anchored mode.

Q. The Select tool doesn't snap to where it should. \
A. It snaps based on distance moved. This is how it works in vanilla, too. You can still snap individual objects normally as the other tools do, by "instant dragging" them without selecting them first.

Q. What are the offset sliders doing? \
A. Using these, you can move all the snap points an equal distance. Useful when you want to place objects slightly off-centred from the grid. Pro tip: you can manually enter a negative value.

Q. Offset tool? Where can I find that? \
A. Enable the advanced section of the tool.

Q. I was hoping I could set my own distance for the snapping points. \
A. You can! Simply enable the advanced section of the tool and play around with the Spacing sliders.

Q. Why is there 2 sliders for spacing and offset each? \
A. If you turn off the locked aspect ratio, you can set a separate spacing and offset for each axis. Useful for isometric maps.

Q. What are the 'Lock Aspect Ratio' toggles doing? \
A. Turning them off lets you use the sliders for each axis separately (see the point above). This behaviour is turned off by default so you don't have to change 2 values every time.

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


### Thanks
Many thanks to you for checking out my mod, as well as MBMM for saving me tons of work. I hope you're going to have a lot of fun with this mod. Should you come across issues or potential for improvements, come find me (Hieronymos) in the modding channel in the official [Megasploot Discord](https://discord.gg/J9Czgpu).