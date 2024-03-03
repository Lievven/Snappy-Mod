var script_class = "tool"

# Set to true to show debug buttons
const DEBUG_MODE = false

# Tool parameters
const TOOL_CATEGORY = "Settings"
const TOOL_ID = "snappy_mod"
const TOOL_NAME = "Custom Snap Settings"
const MOD_DISPLAY_NAME = "Custom Snap Mod"

# Icon paths
const TOOL_ICON_PATH = "icons/snappy_icon.png"
const REWIND_ICON_PATH = "icons/rewind_icon.png"

# The path for storing the mod's settings.
const MOD_DATA_PATH = "user://custom_snap_mod_data.txt"

# The amount of time we wait before saving when modifying a setting, in case there's other modifications coming in.
const SAVE_DELAY = 0.25

# The DD native sidebar where the tools are registered.
var tool_panel = null

# If true, snap to our invisible Snappy Grid, otherwise use default DD behaviour for snapping.
var custom_snap_enabled = true

# If true, the offset and interval sliders' x and y sliders become linked and changing x changes y to the same value and the other way around.
var lock_aspect_offset = true
var lock_aspect_interval = true

# The offset by which the invisible Snappy Grid we snap to is deplaced from the vanilla grid.
var snap_offset = Vector2(0, 0)
var old_offset = Vector2(0, 0)
# The space inbetween the invisible lines we snap to.
var snap_interval = Vector2(32, 32)
var old_interval = Vector2(32, 32)


# The current preset for the preset menu.
var preset_menu_setting = 2
var was_custom_mode = false
# The option button for the preset menu.
var preset_menu

# The HSlider UI Elements used for setting the offset and snap intervals.
var offset_slider_x
var offset_slider_y
var interval_slider_x
var interval_slider_y

# A timer to put a slight delay between changing the sliders and saving so we don't save a million times.
var save_timer = SAVE_DELAY
var save_timer_running = false

# The section containing the settings for more advanced users.
var advanced_settings_section
# The button for expanding or closing the advanced user section.
var enable_advanced_button
# Whether or not the user can interact with the advanced section.
var advanced_section_enabled = false


# Vanilla start function called by Dungeondraft when the mod is first loaded
func start():

    # Loading any previous saved settings.
    load_user_settings()

    # Fetch tool panel for level selection.
    tool_panel = Global.Editor.Toolset.CreateModTool(self, TOOL_CATEGORY, TOOL_ID, TOOL_NAME, Global.Root + TOOL_ICON_PATH)

    # Begin core section
    tool_panel.BeginSection(false)

    # This button will disable custom snapping and return the snapping behaviour to vanilla DD for as long as it is in the off state.
    var on_off_button = tool_panel.CreateCheckButton("Enabled", "", custom_snap_enabled)
    on_off_button.connect("toggled", self, "_toggle_tool_enabled")
    on_off_button.set_tooltip("Disable to return to vanilla snapping mechanics.")
    
    # The preset menu offers all the most important presets. Most users probably don't need any other settings.
    preset_menu = tool_panel.CreateLabeledDropdownMenu("", "Presets", ["Custom", "1/4 Tile (64px)", "1/8 Tile (32px)", "1/16 Tile (16px)", "1/32 Tile (8px)"], "Error")
    preset_menu.connect("item_selected", self, "_change_preset")
    preset_menu.selected = preset_menu_setting
    preset_menu.set_tooltip("Most practical presets for the snap spacing. For most users, they're all you'll ever need.")

    # This button will disable custom snapping and return the snapping behaviour to vanilla DD for as long as it is in the off state.
    enable_advanced_button = tool_panel.CreateCheckButton("Enable Advanced", "", advanced_section_enabled)
    enable_advanced_button.connect("toggled", self, "_enable_advanced_section")
    enable_advanced_button.set_tooltip("Turn on to enable the advanced settings for this mod.")

    # End core section
    tool_panel.EndSection()
    
    # Begin advanced section
    advanced_settings_section = tool_panel.BeginSection(false)
    advanced_settings_section.visible = advanced_section_enabled

    tool_panel.CreateSeparator()

    # Creating label and slider to adjust the snap interval in the X axis.
    tool_panel.CreateLabel("Horizontal Spacing")
    interval_slider_x = tool_panel.CreateSlider("", 32, 1, 256, 1, false)
    interval_slider_x.set_allow_greater(true)
    interval_slider_x.set_value(old_interval.x)
    interval_slider_x.connect("value_changed", self, "_changed_interval_x")

    # Creating label and slider to adjust the snap interval in the Y axis.
    tool_panel.CreateLabel("Vertical Spacing")
    interval_slider_y = tool_panel.CreateSlider("", 32, 1, 256, 1, false)
    interval_slider_y.set_allow_greater(true)
    interval_slider_y.set_value(old_interval.y)
    interval_slider_y.connect("value_changed", self, "_changed_interval_y")
    
    # This button locks the horizontal and vertical axis for our selection sliders.
    # After all most of the time the user does not need to have different behaviour for either axis.
    var lock_aspect_interval_button = tool_panel.CreateCheckButton("Lock Aspect Ratio", "", lock_aspect_interval)
    lock_aspect_interval_button.connect("toggled", self, "_toggle_lock_aspect_interval")
    lock_aspect_interval_button.set_tooltip("Locks aspect ration between the spacing sliders. Keep this locked unless you need to have different snap spacing for each axis.")
    
    tool_panel.CreateSeparator()

    # Creating label and slider to adjust the snap offset in the X axis.
    tool_panel.CreateLabel("Horizontal Offset (Right)")
    offset_slider_x = tool_panel.CreateSlider("", 32, 0, 256, 1, false)
    offset_slider_x.set_allow_greater(true)
    offset_slider_x.set_allow_lesser(true)
    offset_slider_x.set_value(old_offset.x)
    offset_slider_x.connect("value_changed", self, "_changed_offset_x")

    # Creating label and slider to adjust the snap offset in the Y axis.
    tool_panel.CreateLabel("Vertical Offset (Down)")
    offset_slider_y = tool_panel.CreateSlider("", 32, 0, 256, 1, false)
    offset_slider_y.set_allow_greater(true)
    offset_slider_y.set_allow_lesser(true)
    offset_slider_y.set_value(old_offset.y)
    offset_slider_y.connect("value_changed", self, "_changed_offset_y")
    
    # This button locks the horizontal and vertical axis for our selection sliders.
    # After all most of the time the user does not need to have different behaviour for either axis.
    var lock_aspect_offset_button = tool_panel.CreateCheckButton("Lock Aspect Ratio", "", lock_aspect_offset)
    lock_aspect_offset_button.connect("toggled", self, "_toggle_lock_aspect_offset")
    lock_aspect_offset_button.set_tooltip("Locks aspect ration between the offset sliders. Keep this locked unless you need to have different snap spacing for each axis.")
    
    tool_panel.CreateSeparator()

    # End advanced section
    tool_panel.EndSection()

    # Begin notes and debug section.
    tool_panel.BeginSection(true)

    # A small note to remind users to press the 'S' key.
    tool_panel.CreateNote("Remember that toggling the vanilla snap on or off will also turn the %s's snap on or off. "
            % MOD_DISPLAY_NAME
            + "No need to return to this tool, simply press the '%s' key."
            % InputMap.get_action_list("toggle_snap")[0].as_text())

    # If in DEBUG_MODE, print buttons for:
    # Debug button that prints a lot of useful information
    # Print cache button that prints the currently cached session times
    if DEBUG_MODE:
        tool_panel.CreateSeparator()
        tool_panel.CreateLabel("Debug Tools")

        var debug_button = tool_panel.CreateButton("DEBUG", Global.Root + REWIND_ICON_PATH)
        debug_button.connect("pressed", self, "_on_debug_button")

    tool_panel.EndSection()

    print("[%s] UI Layout: successful" % MOD_DISPLAY_NAME)


# Changes the currently selected preset.
func _change_preset(preset_index):
    preset_menu_setting = preset_index
    match preset_index:
        0:
            # Load the old custom mode settings.
            _set_to_custom_mode()
        1:
            # Otherwise store the old custom presets (if we have any) and load the selected preset
            _preserve_custom_mode()
            snap_offset = Vector2(0, 0)
            snap_interval = Vector2(64, 64)
        2:
            _preserve_custom_mode()
            snap_offset = Vector2(0, 0)
            snap_interval = Vector2(32, 32)
        3:
            _preserve_custom_mode()
            snap_offset = Vector2(0, 0)
            snap_interval = Vector2(16, 16)
        4:
            _preserve_custom_mode()
            snap_offset = Vector2(0, 0)
            snap_interval = Vector2(8, 8)
    _schedule_save()


# Makes sure that we are set into custom mode.
# If we were not set into custom mode, loads all the necessary data from our last custom mode edits.
func _set_to_custom_mode():
    # If we were already in custom mode, we don't need to do anything.
    if was_custom_mode:
        return

    # Otherwise, set ourselves to custom mode.
    was_custom_mode = true
    # Also update the presets menu in case this was called by one of the sliders.
    preset_menu_setting = 0
    preset_menu.selected = 0
    
    # And finally load our last used custom mode settings.
    snap_offset = old_offset
    snap_interval = old_interval
    


# If we are in custom mode and changing to a different preset, save the custom settings to retrieve them later.
func _preserve_custom_mode():
    # If we weren't in custom mode, don't do anything or we overwrite our important data.
    if !was_custom_mode:
        return
    
    # If we were in custom mode, preserve the necessary data.
    was_custom_mode = false
    old_offset = snap_offset
    old_interval = snap_interval


# Enables to disables the advanced settings section.
func _enable_advanced_section(new_state):
    # Enable or disnable the preset selector's custom button based on whether we use advanced settings or not.
    enable_advanced_button.set_item_disabled(0, new_state)
    advanced_section_enabled = new_state
    advanced_settings_section.visible = new_state
    _schedule_save()


# Changes the snap interval's aspect locking behaviour to the given state.
# Usually called by the lock_aspect_interval_button's toggled signal
func _toggle_lock_aspect_interval(new_state):
    lock_aspect_interval = new_state
    if lock_aspect_interval:
        # immediately set the Y value and slider for the snap interval to that of the X slider.
        interval_slider_y.value = interval_slider_x.value
        snap_interval.y = snap_interval.x
    _schedule_save()

# Changes the snap offset's aspect locking behaviour to the given state.
# Usually called by the lock_aspect_offset_button's toggled signal
func _toggle_lock_aspect_offset(new_state):
    lock_aspect_offset = new_state
    if lock_aspect_offset:
        # immediately set the Y value and slider for the snap offset to that of the X slider.
        offset_slider_y.value = offset_slider_x.value
        snap_offset.y = offset_slider_x.value
    _schedule_save()


# Sets the flag to disable/enable the tool and return to/from vanilla DD snapping mechanics.
func _toggle_tool_enabled(new_state):
    custom_snap_enabled = new_state
    _schedule_save()


# Sets the new snap offset in the X axis.
# Also sets the offset_slider_y and offset in the Y axis if the snap aspect is locked.
# Usually called by the offset_slider_x
func _changed_offset_x(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_offset.x = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_offset:
        snap_offset.y = value
        offset_slider_y.value = value
    _schedule_save()


# Sets the new snap offset in the Y axis.
# Also sets the offset_slider_x and offset in the X axis if the snap aspect is locked.
# Usually called by the offset_slider_y
func _changed_offset_y(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_offset.y = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_offset:
        snap_offset.x = value
        offset_slider_x.value = value
    _schedule_save()


# Sets the new snap interval in the X axis.
# Also sets the interval_slider_y and interval in the Y axis if the snap aspect is locked.
# Usually called by the interval_slider_x
func _changed_interval_x(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_interval.x = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_interval:
        snap_interval.y = value
        interval_slider_y.value = value
    _schedule_save()


# Sets the new snap interval in the Y axis.
# Also sets the interval_slider_x and interval in the X axis if the snap aspect is locked.
# Usually called by the interval_slider_y
func _changed_interval_y(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_interval.y = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_interval:
        snap_interval.x = value
        interval_slider_x.value = value
    _set_to_custom_mode()
    _schedule_save()


# Schedule a new save.
# We always up the delay to the maximum since the point is that we don't save immediately.
# Otherwise we might be saving dozens of times within seconds, when we only need the last save anyway.
func _schedule_save():
    save_timer = SAVE_DELAY
    save_timer_running = true


# Vanilla update called by Godot every frame.
func update(delta):
    # Check to see if we need to save our user settings.
    if save_timer_running:
        # Timer still running.
        if save_timer > 0:
            save_timer -= delta
        else:
            # Save settings and turn timer off.
            save_timer_running = false
            save_user_settings()

    # If the user currently wishes to use default snapping, or has snapping disabled entirely, we return as we do not want to snap to anything.
    if not (custom_snap_enabled and Global.Editor.IsSnapping):
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


# Snap the delta of a given movement based on our snap interval.
# Since the movement is not linked to a position, we ignore the offset.
# Returns a new delta, which is the old delta snapped to the closest multiple of our snap interval.
func get_snapped_movement(move_delta):
    # Snap the movement to the next interval smaller than the actual movement.
    var snap_x = floor(move_delta.x / snap_interval.x) * snap_interval.x
    var snap_y = floor(move_delta.y / snap_interval.y) * snap_interval.y

    # If we're closer to the next interval larger than the actual movement, we snap there instead.
    if fmod(move_delta.x, snap_interval.x) > snap_interval.x / 2:
        snap_x += snap_interval.x
    if fmod(move_delta.y, snap_interval.y) > snap_interval.y / 2:
        snap_y += snap_interval.y

    # Returning the new delta. Not a position.
    return Vector2(snap_x, snap_y)


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

    # As the basis for our transform, we take the transform from BEFORE any mouse movement.
    var move_transform = select_tool.preDragTransform
    # We simply add our calculated snap distance to said transformation.
    move_transform.origin += get_snapped_movement(select_tool.moveDelta)

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
    if box.position.x == 0 and box.position.y == 0 and box.size.x == 0 and box.size.y == 0:
        return
    
    # Dungeondraft is a bit convoluted here as it doesn't seem to save the original position of the box.
    # Instead, to "invert" the box when the box extends towards the negative directions, it simply swaps the position and end values.
    # That's bad for us, because we modify them yet we don't know which one is the origin.
    # Hacky solution: we find where vanilla DD would snap the box to.
    var vanilla_snap = Global.WorldUI.GetSnappedPosition(Global.WorldUI.MousePosition)

    # If the current X coordinate of the box is where vanilla DD would snap to, we adjust it while preserving the origin (in this case end.x) of the box.
    if box.position.x == vanilla_snap.x:
        var end = box.end.x
        box.position.x = snap.x
        box.end.x = end
    # Otherwise we can simply write our value into the end, as the origin (in this case position.x) is already preserved
    else:
        box.end.x = snap.x

    # If the current Y coordinate of the box is where vanilla DD would snap to, we adjust it while preserving the origin (in this case end.y) of the box.
    if box.position.y == vanilla_snap.y:
        var end = box.end.y
        box.position.y = snap.y
        box.end.y = end
    # Otherwise we can simply write our value into the end, as the origin (in this case position.y) is already preserved
    else:
        box.end.y = snap.y

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
        "custom_snap_enabled": custom_snap_enabled,
        "preset_menu_setting": preset_menu_setting,
        "advanced_section_enabled": advanced_section_enabled,
        "lock_aspect_offset": lock_aspect_offset,
        "lock_aspect_interval": lock_aspect_interval,
        "snap_interval_x": snap_interval.x,
        "snap_interval_y": snap_interval.y,
        "old_interval_x": old_interval.x,
        "old_interval_y": old_interval.y,
        "snap_offset_x": snap_offset.x,
        "snap_offset_y": snap_offset.y,
        "old_offset_x": old_offset.x,
        "old_offset_y": old_offset.y
    }
    # Opening/creating of the actual file and writing of the data here.
    var file = File.new()
    file.open(MOD_DATA_PATH, File.WRITE)
    file.store_line(JSON.print(data, "\t"))
    file.close()

    print("[%s] Saving user settings: successful" % MOD_DISPLAY_NAME)


# Loads the user settings from the MOD_DATA_PATH
# If there is no file in the specified location, we stop the attempt and leave the default values as they are.
func load_user_settings():
    var file = File.new()
    var error = file.open(MOD_DATA_PATH, File.READ)
    
    # If we cannot read the file, stop this attempt and leave the respective values at their default.
    if error != 0:
        print("[%s] Loading user settings: no user settings found" % MOD_DISPLAY_NAME)
        return

    # Loading, parsing, and closing the file.
    var line = file.get_as_text()
    var data = JSON.parse(line).result
    file.close()

    # Writing user settings back where they belong.
    custom_snap_enabled = data["custom_snap_enabled"]
    preset_menu_setting = data["preset_menu_setting"]
    advanced_section_enabled = data["advanced_section_enabled"]
    lock_aspect_offset = data["lock_aspect_offset"]
    lock_aspect_interval = data["lock_aspect_interval"]
    snap_offset.x = data["snap_offset_x"]
    snap_offset.y = data["snap_offset_y"]
    old_offset.x = data["old_offset_x"]
    old_offset.y = data["old_offset_y"]
    snap_interval.x = data["snap_interval_x"]
    snap_interval.y = data["snap_interval_y"]
    old_interval.x = data["old_interval_x"]
    old_interval.y = data["old_interval_y"]

    was_custom_mode = preset_menu_setting == 0
    print("[%s] Loading user settings: successful" % MOD_DISPLAY_NAME)




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
#    print_properties(Global.WorldUI)
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