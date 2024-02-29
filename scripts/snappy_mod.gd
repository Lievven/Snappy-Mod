var script_class = "tool"

# Set to true to show debug buttons
const DEBUG_MODE = true

# Tool parameters
const TOOL_CATEGORY = "Settings"
const TOOL_ID = "snappy_mod"
const TOOL_NAME = "Snappy Settings"

# Icon paths
const TOOL_ICON_PATH = "icons/snappy_icon.png"
const REWIND_ICON_PATH = "icons/rewind_icon.png"

# The path for storing the mod's settings.
const MOD_DATA_PATH = "user://snappy_mod_data.txt"

# The DD native sidebar where the tools are registered.
var tool_panel = null

# The offset by which the invisible grid we snap to is deplaced from the vanilla grid.
var snap_offset = Vector2(64, 64)



# Vanilla start function called by Dungeondraft when the mod is first loaded
func start():

    # Fetch tool panel for level selection.
    tool_panel = Global.Editor.Toolset.CreateModTool(self, TOOL_CATEGORY, TOOL_ID, TOOL_NAME, Global.Root + TOOL_ICON_PATH)

    tool_panel.BeginSection(true)

    # Todo: CREATE ACTUAL USER INTERFACE HERE


    # If in DEBUG_MODE, print buttons for:
    # Debug button that prints a lot of useful information
    # Print cache button that prints the currently cached session times
    if DEBUG_MODE:
        tool_panel.CreateSeparator()
        tool_panel.CreateLabel("Debug Tools")

        var debug_button = tool_panel.CreateButton("DEBUG", Global.Root + REWIND_ICON_PATH)
        debug_button.connect("pressed", self, "_on_debug_button")

    
    
    tool_panel.EndSection()


    print("[Snappy Mod] UI Layout: successful")
    



# Vanilla update called by Godot every frame.
func update(delta):
    # TODO: replace with properly calculated custom grid and offset
    var snap = Global.WorldUI.get_CursorHalfTilePosition()
    snap += snap_offset


    Global.WorldUI.set_CursorHalfTilePosition(snap)
    Global.WorldUI.set_CursorTilePosition(snap)

    
    _update_object_placement(snap)
    _update_selection_box(snap)


func _update_object_placement(snap):
    var prop = Global.Editor.Tools["ObjectTool"].Preview
    prop.position = snap
    prop = Global.Editor.Tools["ScatterTool"].Preview
    prop.position = snap

func _update_selection_box(snap):
    var box = Global.WorldUI.GetSelectionBox()
    if not (box.position.x == 0 and box.position.y == 0 and box.position.x == 0 and box.position.y == 0):
        box.end = snap
        Global.WorldUI.SetSelectionBox(box)


# Saves the user settings as JSON in the MOD_DATA_PATH
func save_user_settings():
    var data = {
        "snappy_mod_data": "Yikes! It looks like this version doesn't have any data yet."
    }
    var file = File.new()
    file.open(MOD_DATA_PATH, File.WRITE)
    file.store_line(JSON.print(data, "\t"))
    file.close()


# Loads the user settings from the MOD_DATA_PATH
# If there is no file in the specified location, we stop the attempt and leave the default values as they are.
func load_user_settings():
    var file = File.new()
    var error = file.open(MOD_DATA_PATH, File.READ)
    
    # If we cannot read the file, stop this attempt and leave the respective values at their default.
    if error != 0:
        print("[Snappy Mod] Loading user settings: no user settings found")
        return

    var line = file.get_as_text()
    var data = JSON.parse(line).result
    file.close()

    print("[Snappy Mod] Loading user settings: successful")




# =========================================================
# ANYTHING BEYOND THIS POINT IS FOR DEBUGGING PURPOSES ONLY
# =========================================================



# Debug function, very important. Prints whatever stuff I need to know at the moment.
func _on_debug_button():
    print("========== DEBUG BUTTON ==========")
#    print_parents(tool_panel)
#    load_user_settings()
#    print_levels()
#    print_methods(Global.WorldUI)
    print_properties(Global.WorldUI)
#    print_signals(Global.WorldUI)
#    Global.World.print_tree_pretty()
    Global.WorldUI.SetSelectionBox(Rect2(Vector2(1024, 1024), Vector2(1024, 1024)))


func print_parents(node):
    var parent = node.get_parent()
    while parent != null:
        print(parent)
        parent = parent.get_parent()


# Debug function, prints out the info for every level
func print_levels():
    for level in Global.World.levels:
        print("==== Level %s ====" % level.name)
        print("Z Index: %s" % level.z_index)
        print("Z Relative: %s" % level.z_as_relative)



# Debug function, prints properties of the given node
func print_properties(node):
    print("========= PRINTING PROPERTIES OF %s ==========" % node.name)
    var properties_list = node.get_property_list()
    for property in properties_list:
        print(property.name)


# Debug function, prints methods of the given node
func print_methods(node):
    print("========= PRINTING METHODS OF %s ==========" % node.name)
    var method_list = node.get_method_list()
    for method in method_list:
        print(method.name)


# Debug function, prints signals of the given node
func print_signals(node):
    print("========= PRINTING SIGNALS OF %s ==========" % node.name)
    var signal_list = node.get_signal_list()
    for sig in signal_list:
        print(sig.name)