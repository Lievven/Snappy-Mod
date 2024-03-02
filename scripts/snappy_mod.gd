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
var snap_offset = Vector2(0, 0)
# The space inbetween the invisible lines we snap to.
var snap_interval = Vector2(64, 64)


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
    var snap = get_snapped_position(Global.WorldUI.get_MousePosition())
    
    # Snaps the default snap position to our Snappy Grid.
    # Unfortunately, due to the update order many tools have already used the old position.
    # Hence we must update these tools to the new Snappy Grid position manually.
    Global.WorldUI.set_CursorHalfTilePosition(snap)
    Global.WorldUI.set_CursorTilePosition(snap)

    # TODO: update Poly & Path editing visuals to Snappy Grid.
    _update_poly_selection("PathTool")
    _update_poly_selection("FloorShapeTool")
    _update_poly_selection("PatternShapeTool")
    _update_poly_selection("WallTool")


    # TODO: update Select tool to conform to Snappy Grid.
    _update_select_tool()

    # Snaps portals, however only while they are freestanding.
    # Snapping portals to walls doesn't work as of now.
    _snap_portals(snap)
    

    # Sets the vertex position when editing path nodes.
    # TODO: Needs to be changed to only apply when actually dragging them and not while only selecting the paths.
    if Global.WorldUI.Vertices != null and not Global.WorldUI.Vertices.empty():
        Global.WorldUI.SetVertex(snap)


    var s_tool = Global.Editor.Tools["SelectTool"]
    if not (s_tool.boxBegin.x == null and s_tool.boxBegin.y == null and s_tool.boxEnd.x == null and s_tool.boxEnd.y == null):
        #print(s_tool.boxBegin, " : ", s_tool.boxEnd)
        pass


    # Snaps path arcs to the Snappy Grid.
    if Global.WorldUI.EditArcPoint:
        Global.WorldUI.UpdateLastArcPoint()

    # Snaps the Object and Scatter tools to the Snappy Grid.
    _update_object_placement(snap)
    # Snaps the Building, Pattern, Water, etc. polygons to the Snappy Grid.
    _update_selection_box(snap)



func _update_select_tool():
    var select_tool = Global.Editor.Tools["SelectTool"]
    if select_tool.transformMode != 1:
        return
    
    var move_x = select_tool.moveDelta.x
    var move_y = select_tool.moveDelta.y

    move_x = floor(move_x / snap_interval.x) * snap_interval.x
    move_y = floor(move_y / snap_interval.y) * snap_interval.y
    var move_transform = select_tool.preDragTransform
    move_transform.origin += Vector2(move_x, move_y)

    select_tool.ApplyTransforms(move_transform)
    select_tool.transformBox.position = move_transform.origin



func get_snapped_position(target_position):
    # Calculating snap for X axis
    var snap_x = target_position.x
    var offset_snap = snap_x - snap_offset.x
    var intervals = floor(offset_snap / snap_interval.x)
    var remainder = fmod(offset_snap, snap_interval.x)
    snap_x = intervals * snap_interval.x

    if remainder > snap_interval.x / 2:
        snap_x += snap_interval.x

    # Calculating snap for Y axis
    var snap_y = target_position.y
    offset_snap = snap_y - snap_offset.y
    intervals = floor(offset_snap / snap_interval.y)
    remainder = fmod(offset_snap, snap_interval.y)
    snap_y = intervals * snap_interval.y

    if remainder > snap_interval.y / 2:
        snap_y += snap_interval.y
    
    return Vector2(snap_x + snap_offset.x, snap_y + snap_offset.y)


func _update_poly_selection(apply_to_tool):
    var is_edit_mode = Global.Editor.Tools[apply_to_tool].get_EditPoints().pressed
    var is_tool_active = Global.Editor.ActiveToolName == apply_to_tool
    var is_looking_at_vertex = Global.WorldUI.Vertex != null
    var is_dragging_mouse = Input.is_mouse_button_pressed(BUTTON_LEFT)
    if is_edit_mode and is_looking_at_vertex and is_dragging_mouse and is_tool_active:
        # False is important here. Otherwise it saves the changes. Found out the hard way. TYVM to MBMM!
        Global.Editor.Tools[apply_to_tool].UpdateSelectionPosition(false)


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


# NOTES ON SNAPPING PORTALS TO WALLS
# This line works as it should. We can find an apppropriate location for our portal near the snap location.
# ==> Global.Editor.Tools["PortalTool"].FindBestLocation(snap)
# This one is what breaks the implementation. This variable cannont cross the C# -> GDScript boundary.
# ==> var portal_location = Global.Editor.Tools["PortalTool"].get_FoundSpot()
# We could then set the location as simple as this.
# ==> Global.WorldUI.Texture.Transform = portal_location
# However, since we do not know exactly where the portal would go, our best bet will be a custom implementation.
# That might not be 100% accurate though.
# And more importantly, it's way too much work.
# Hence portals won't snap to walls
# If there's a tool that ain't an issue with, I think this is it.
# However they will still snap while freestanding.
func _snap_portals(snap):
    #Global.Editor.Tools["PortalTool"].FindBestLocation(snap)
    #var portal_location = Global.Editor.Tools["PortalTool"].get_FoundSpot()
    #Global.WorldUI.Texture.Transform = portal_location
    if Global.Editor.Tools["PortalTool"].Freestanding:
        Global.WorldUI.Texture.Transform.origin = snap


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
#    print_methods(Global.Editor.Tools["SelectTool"])
    print_properties(Global.Editor.Tools["SelectTool"])
#    print_signals(Global.Editor.Tools["PathTool"])
#    Global.World.print_tree_pretty()


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