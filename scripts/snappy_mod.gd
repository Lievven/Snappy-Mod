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
    # We only want to snap when the user actually has snapping enabled.
    if not Global.Editor.IsSnapping:
        return

    # Our current cursor position, adjusted to snap to our invisible Snappy Grid.
    var snap = get_snapped_position(Global.WorldUI.get_MousePosition())
    
    # Snaps the default snap position to our Snappy Grid.
    # Unfortunately, due to the update order many tools have already used the old position.
    # Hence we must update these tools to the new Snappy Grid position manually.
    Global.WorldUI.set_CursorHalfTilePosition(snap)
    Global.WorldUI.set_CursorTilePosition(snap)

    # Update the polygon editing selection for a variety of tools to snap the vertex we are editing to the previously set position.
    _update_poly_selection("PathTool")
    _update_poly_selection("FloorShapeTool")
    _update_poly_selection("PatternShapeTool")
    _update_poly_selection("WallTool")

    # Updates the normal movement of the Select Tool to move in intervals corresponding our Snap Interval
    _update_select_tool()
    # Updates the instant drag movement of the Select Tool to snap to our invisible Snappy Grid.
    _update_instant_drag()

    # Snaps portals, however only while they are freestanding.
    # Snapping portals to walls doesn't work as of now.
    _update_portals(snap)
    
    # Snaps path arcs to the Snappy Grid.
    # Aka. snaps the point that defines the curvature of the arc we are currently creating.
    if Global.WorldUI.EditArcPoint:
        Global.WorldUI.UpdateLastArcPoint()

    # Snaps the Object and Scatter tools to the Snappy Grid.
    _update_object_placement(snap)
    # Snaps the Building, Pattern, Water, Path, etc. polygons to the Snappy Grid.
    _update_selection_box(snap)



# Calculate the closest position snapped to our invisible Snappy Grid from the given Vector2.
func get_snapped_position(target_position):
    # Calculating snap for X axis
    # First we clean our snap offset from the position since we only want to work with the snap interval.
    var offset_snap = target_position.x - snap_offset.x
    # Then we snap to the smaller interval.
    var snap_x = floor(offset_snap / snap_interval.x) * snap_interval.x

    # If we are closer to the larger interval, we add 1 interval to our new position.
    if fmod(offset_snap, snap_interval.x) > snap_interval.x / 2:
        snap_x += snap_interval.x

    # Calculating snap for Y axis
    # First we clean our snap offset from the position since we only want to work with the snap interval.
    offset_snap = target_position.y - snap_offset.y
    # Then we snap to the smaller interval.
    var snap_y = floor(offset_snap / snap_interval.y) * snap_interval.y

    # If we are closer to the larger interval, we add 1 interval to our new position.
    if fmod(offset_snap, snap_interval.y) > snap_interval.y / 2:
        snap_y += snap_interval.y
    
    # Re-applying the offset.
    return Vector2(snap_x + snap_offset.x, snap_y + snap_offset.y)



# Snaps the instant drag of the Select Tool to our invisible Snappy Grid.
# It's important to note that we don't snap to our cursors position but rather relative to the cursor movement.
# As the cursor might be off-centre from the object(s) we are trying to move.
func _update_instant_drag():
    var select_tool = Global.Editor.Tools["SelectTool"]
    # Return if we aren't using instant drag
    if not select_tool.justManualMoved:
        return
    
    # Iterate over all selected objects that are instant dragable, as well as their positions before the instant drag.
    # This should only be 1 object, but since since for some reason it's an array I'm looping, just in case.
    var i = 0
    for movable in select_tool.movableThings:
        var previous_position = select_tool.preMovePositions[i]
        i += 1
        # The previous position is always where we picked the item up and the delta the mouse movement since we picked it up.
        var new_position = previous_position + select_tool.moveDelta
        movable.position = get_snapped_position(new_position)


# Snaps the normal Select Tool movement based on our Snappy Interval.
# Unlike instant drag, the vanilla movement does not seem to snap to a specific position, but rather relative to the movement.
# So we're doing the same thing, therefore completely ignoring offset.
# We simply move the selection in steps equal to our interval, based on the mouse movement.
func _update_select_tool():
    var select_tool = Global.Editor.Tools["SelectTool"]
    # Return if we aren't actually currently moving anything with the Select Tool.
    if select_tool.transformMode != 1:
        return
    
    # The distance of our mouse movement from our initial position.
    # We want to snap this to the closest interval.
    var move_x = select_tool.moveDelta.x
    var move_y = select_tool.moveDelta.y

    # Snap the movement to the next interval smaller than the actual movement.
    var snap_x = floor(move_x / snap_interval.x) * snap_interval.x
    var snap_y = floor(move_y / snap_interval.y) * snap_interval.y

    # If we're closer to the next interval larger than the actual movement, we snap there instead.
    if fmod(move_x, snap_interval.x) > snap_interval.x / 2:
        snap_x += snap_interval.x
    if fmod(move_y, snap_interval.y) > snap_interval.y / 2:
        snap_y += snap_interval.y
    
    # As the basis for our transform, we take the transform from BEFORE any mouse movement.
    var move_transform = select_tool.preDragTransform
    # We simply add our calculated snap distance to said transformation.
    move_transform.origin += Vector2(snap_x, snap_y)

    # From there we simply need to apply the transformation.
    # This function will update all objects based on the transform.
    select_tool.ApplyTransforms(move_transform)
    # And finally we also need to move the box around our moved objects to the correct position as well.
    select_tool.transformBox.position = move_transform.origin


# Updates any point that is currently being edited in a given tool.
# Meaning we are in polygon or path editing mode and are dragging the point to a new position.
# This is only changing the preview of the path or polygon to the new position.
# The proper change already works normally by simply changing the default position, hence doesn't need to be updated.
func _update_poly_selection(apply_to_tool):
    # Asset that the given tool is in editing mode, aka. the 'Edit Points' button is toggled.
    if not Global.Editor.Tools[apply_to_tool].get_EditPoints().pressed:
        return
    # Assert that the given tool is the currently active tool.
    if not Global.Editor.ActiveToolName == apply_to_tool:
        return
    # Assert that we have selected a vertex to edit.
    if Global.WorldUI.Vertex == null:
        return
    # Assert that we are actually editing the Vertex and not just hovering it.
    # Important to note that this key seems to currently be hard-coded, so we can't bind it to an action group either.
    if not Input.is_mouse_button_pressed(BUTTON_LEFT):
        return

    # Prompt the selected tool to update the currently active polygon.
    # It uses the previously assigned default position.
    # Important that the tool actually has a polygon selected for editing, otherwise it crashes.
    # False is important here. Otherwise it saves the changes. Found out the hard way. TYVM to MBMM!
    Global.Editor.Tools[apply_to_tool].UpdateSelectionPosition(false)


# Updates the current preview of the Object and Scatter Tools to our invisible Snappy Grid.
func _update_object_placement(snap):
    var prop = Global.Editor.Tools["ObjectTool"].Preview
    prop.position = snap
    prop = Global.Editor.Tools["ScatterTool"].Preview
    prop.position = snap


# Updates the preview of any box or circle shaped selections to snap to the grid.
func _update_selection_box(snap):
    # Only clones the box, so we need to set it again later.
    var box = Global.WorldUI.GetSelectionBox()
    # Return if the selection box is at the world origin, as the tool is inactive.
    if box.position.x == 0 and box.position.y == 0 and box.position.x == 0 and box.position.y == 0:
        return
    
    # The initial box position is already placed correctly.
    # So we simply need to snap the End position of the box.
    box.end = snap
    # We still need to set the box again, as we only created a clone earlier.
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
func _update_portals(snap):
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