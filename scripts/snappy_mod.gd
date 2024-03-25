var script_class = "tool"

# Set to true to show debug buttons
const DEBUG_MODE = true

# Tool parameters
const TOOL_CATEGORY = "Settings"
const TOOL_ID = "snappy_mod"
const TOOL_NAME = "Custom Snap Settings"
const MOD_DISPLAY_NAME = "Custom Snap Mod"

# Icon paths
const TOOL_ICON_PATH = "icons/snappy_icon.png"
const REWIND_ICON_PATH = "icons/rewind_icon.png"
const VERTICAL_HEX_ICON_PATH = "icons/hex_icon_vertical.png"
const HORIZONTAL_HEX_ICON_PATH = "icons/hex_icon_horizontal.png"
const SQUARE_ICON_PATH = "icons/square_icon.png"

# The path for storing the mod's settings.
const MOD_DATA_PATH = "user://custom_snap_mod_data.txt"

# The amount of time we wait before saving when modifying a setting, in case there's other modifications coming in.
const SAVE_DELAY = 0.25


# ==== UI ELEMENTS ====

# The DD native sidebar where the tools are registered.
var tool_panel = null

# The HSlider UI Elements used for setting the offset and snap intervals.
var offset_slider_x
var offset_slider_y
var interval_slider_x
var interval_slider_y

# The section containing the settings for more advanced users.
var advanced_settings_section
# The button for expanding or closing the advanced user section.
var enable_advanced_button
# The option button for the preset menu.
var preset_menu


# ==== MOD STATE ====

# A timer to put a slight delay between changing the sliders and saving so we don't save a million times.
var save_timer = SAVE_DELAY
var save_timer_running = false

# Choosing between a Square grid, vertical hex grid, and horizontal hex grid geometry.
# Vertical hexes are defined as having a flat top and bottom, hence allowing straight movement in the vertical but zig-zag movement in the horizontal axis.
# Horizontal hexes are defined as having a pointy top and bottom, hence requiring a zig-zag movement in the vertical but straight movement in the horizontal axis.
enum GEOMETRY {SQUARE, HEX_V, HEX_H, ISOMETRIC}
var active_geometry = GEOMETRY.HEX_H
# If true, we measure the hexagon's radius from the centre to the corner.
# Otherwise we measure the hexagon's radius as the shortest distance from the centre to the edge.
var radial_mode_to_corner = true

# If true, snap to our invisible Snappy Grid, otherwise use default DD behaviour for snapping.
var custom_snap_enabled = true
# Whether or not the user can interact with the advanced section.
var advanced_section_enabled = false

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
# This is all the options that will be in the preset menu.
# The first option will always be "Custom", and afterwards all of these in order.
# While not the cleanest implementation, I chose this for readability since some users indicated an interest into tinkering with this.
# Just remember that if you are tinkering with this, fractions need to have a .0 given.
var preset_menu_options = {
        "1/4 Tile (64px)": Vector2(64, 64),
        "1/8 Tile (32px)": Vector2(32, 32),
        "1/16 Tile (16px)": Vector2(16, 16),
        "1/32 Tile (8px)": Vector2(8, 8),
        "1/3 Tile": Vector2(256.0/3, 256.0/3),
        "1/5 Tile": Vector2(256.0/5, 256.0/5)
        }

# A dictionary of the user's most recently used custom settings.
var last_custom_settings = {}
# An array of dictionaries of all the preset options.
var preset_options = []


# Vanilla start function called by Dungeondraft when the mod is first loaded
func start():

    # Loading any previous saved settings.
    load_user_settings()
    load_local_settings()

    # Fetch tool panel for level selection.
    tool_panel = Global.Editor.Toolset.CreateModTool(self, TOOL_CATEGORY, TOOL_ID, TOOL_NAME, Global.Root + TOOL_ICON_PATH)

    # Begin core section
    tool_panel.BeginSection(false)

    # This button will disable custom snapping and return the snapping behaviour to vanilla DD for as long as it is in the off state.
    var on_off_button = tool_panel.CreateCheckButton("Enabled", "", custom_snap_enabled)
    on_off_button.connect("toggled", self, "_toggle_tool_enabled")
    on_off_button.set_tooltip("Disable to return to vanilla snapping mechanics.")
    
    # Creates the button panel to switch between Sqare, Hex, etc. modes.
    _create_mode_buttons()
    
    _create_preset_menu()

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


## Creates the buttons to switch between the different grid modes, e.g. Square, Hex_V, or Hex_H
func _create_mode_buttons():
    # Here we are creating a custom horizontal section, as those are not yet supported by DD.
    # It's as easy as adding a new container and assigning it as 'Align', which is where DD puts any newly created items.
    # VERY IMPORTANT: we need to close the container afterwards, or DD will put everything else in there as well.
    var mode_container = HBoxContainer.new()
    var section_container = tool_panel.Align
    section_container.add_child(mode_container)
    tool_panel.Align = mode_container

    # Creating a grouped toggle, meaning turning on one of them will turn off all others.
    # For some reason, this will always complain that the given property does not exist in ModBaseTool.
    # It's the same as all other CreateX though, so it's perfectly fine.
    # DON'T MESS WITH THE ORDER WITHOUT ALSO CHANGING THE ORDER OF ASSIGNING IDENTIFIERS BELOW
    var b_group = ButtonGroup.new()
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.SQUARE, Global.Root + SQUARE_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.HEX_H, Global.Root + HORIZONTAL_HEX_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.HEX_V, Global.Root + VERTICAL_HEX_ICON_PATH, b_group)
    b_group.connect("pressed", self, "_on_toggle_mode_changed")

    # Assigning the proper identifiers to the button.
    # Note that we don't get the button returned from the CreateSharedToggle function, so we have to go by order here.
    # DON'T GET THE ORDER WRONG.
    mode_container.get_child(0).name = GEOMETRY.SQUARE
    mode_container.get_child(1).name = GEOMETRY.HEX_H
    mode_container.get_child(2).name = GEOMETRY.HEX_V

    # Closing custom section
    # Easily done by replacing 'Align' with the container previously held by it.
    tool_panel.Align = section_container


## Creates the menu which offers all the most important presets. Most of the time users won't need any other settings.
func _create_preset_menu():
    preset_menu = tool_panel.CreateLabeledDropdownMenu("", "Presets", ["Custom"], "Error")
    for preset_item in preset_menu_options.keys():
        preset_menu.add_item(preset_item)

    # This is the future implementation once each preset is a dictionary.
    #for preset_item in preset_options:
    #    preset_menu.add_item(preset_item["preset_name"])

    preset_menu.connect("item_selected", self, "_change_preset")
    preset_menu.selected = preset_menu_setting
    preset_menu.set_tooltip("Most practical presets for the snap spacing. For most users, they're all you'll ever need.")



## Changes the grid mode. The button's 'name' property needs to equal the new grid mode.
func _on_toggle_mode_changed(something):
    # Gotta cast to int here as while we're using the GEOMETRY enum to set the button's name, that's a string, which won't match for int.
    match int(something.name):
        GEOMETRY.SQUARE:
            active_geometry = GEOMETRY.SQUARE
        GEOMETRY.HEX_H:
            active_geometry = GEOMETRY.HEX_H
        GEOMETRY.HEX_V:
            active_geometry = GEOMETRY.HEX_V
        GEOMETRY.ISOMETRIC:
            active_geometry = GEOMETRY.ISOMETRIC
    _schedule_save()


## Changes the currently selected preset.
func _change_preset(preset_index):
    preset_menu_setting = preset_index
    # If custom mode was selected, load the old custom mode settings and save the new settings.
    if preset_index == 0:
        _set_to_custom_mode()
        _schedule_save()
        return
    
    # Otherwise store the old custom presets (if we have any) and load the selected preset.
    _preserve_custom_mode()
    var selected_item = preset_menu.get_item_text(preset_index)
    snap_interval = preset_menu_options[selected_item]
    snap_offset = Vector2(0, 0)
    _schedule_save()



## Makes sure that we are set into custom mode.
## If we were not set into custom mode, loads all the necessary data from our last custom mode edits.
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
    


## If we are in custom mode and changing to a different preset, save the custom settings to retrieve them later.
func _preserve_custom_mode():
    # If we weren't in custom mode, don't do anything or we overwrite our important data.
    if !was_custom_mode:
        return
    
    # If we were in custom mode, preserve the necessary data.
    was_custom_mode = false
    old_offset = snap_offset
    old_interval = snap_interval


## Enables to disables the advanced settings section.
func _enable_advanced_section(new_state):
    # Enable or disnable the preset selector's custom button based on whether we use advanced settings or not.
    enable_advanced_button.set_item_disabled(0, new_state)
    advanced_section_enabled = new_state
    advanced_settings_section.visible = new_state
    _schedule_save()


## Changes the snap interval's aspect locking behaviour to the given state.
## Usually called by the lock_aspect_interval_button's toggled signal
func _toggle_lock_aspect_interval(new_state):
    lock_aspect_interval = new_state
    if lock_aspect_interval:
        # immediately set the Y value and slider for the snap interval to that of the X slider.
        interval_slider_y.value = interval_slider_x.value
        snap_interval.y = snap_interval.x
    _schedule_save()

## Changes the snap offset's aspect locking behaviour to the given state.
## Usually called by the lock_aspect_offset_button's toggled signal
func _toggle_lock_aspect_offset(new_state):
    lock_aspect_offset = new_state
    if lock_aspect_offset:
        # immediately set the Y value and slider for the snap offset to that of the X slider.
        offset_slider_y.value = offset_slider_x.value
        snap_offset.y = offset_slider_x.value
    _schedule_save()


## Sets the flag to disable/enable the tool and return to/from vanilla DD snapping mechanics.
func _toggle_tool_enabled(new_state):
    custom_snap_enabled = new_state
    _schedule_save()


## Sets the new snap offset in the X axis.
## Also sets the offset_slider_y and offset in the Y axis if the snap aspect is locked.
## Usually called by the offset_slider_x
func _changed_offset_x(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_offset.x = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_offset:
        snap_offset.y = value
        offset_slider_y.value = value
    _schedule_save()


## Sets the new snap offset in the Y axis.
## Also sets the offset_slider_x and offset in the X axis if the snap aspect is locked.
## Usually called by the offset_slider_y
func _changed_offset_y(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_offset.y = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_offset:
        snap_offset.x = value
        offset_slider_x.value = value
    _schedule_save()


## Sets the new snap interval in the X axis.
## Also sets the interval_slider_y and interval in the Y axis if the snap aspect is locked.
## Usually called by the interval_slider_x
func _changed_interval_x(value):
    # Set to custom mode first, as we'll have to overwrite this value with the new one we just received
    _set_to_custom_mode()

    snap_interval.x = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_interval:
        snap_interval.y = value
        interval_slider_y.value = value
    _schedule_save()


## Sets the new snap interval in the Y axis.
## Also sets the interval_slider_x and interval in the X axis if the snap aspect is locked.
## Usually called by the interval_slider_y
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


## Schedule a new save.
## We always up the delay to the maximum since the point is that we don't save immediately.
## Otherwise we might be saving dozens of times within seconds, when we only need the last save anyway.
func _schedule_save():
    save_timer = SAVE_DELAY
    save_timer_running = true


## Vanilla update called by Dungeondraft every frame.
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



## Calculate the closest position snapped to our invisible Snappy Grid from the given Vector2.
## This one simply snaps the delta from the offset, then reapplies the offset.
func get_snapped_position(target_position):
    var offset_position = target_position - snap_offset
    return get_snapped_delta(offset_position) + snap_offset


## Snap the delta of a given movement or position based on our snap interval.
## Selects the function for the currently selected geometry mode
func get_snapped_delta(delta):
    match active_geometry:
        GEOMETRY.SQUARE:
            return snap_square_delta(delta)
        GEOMETRY.HEX_V:
            return snap_vertical_hex_delta(delta)
        GEOMETRY.HEX_H:
            return snap_horizontal_hex_delta(delta)
        GEOMETRY.ISOMETRIC:
            return snap_isometric_delta(delta)


## IMPORTANT: we're snapping to the centre of hexes with a pointy top in this function, which is 90° off from vertical hexes.
## That's because the user wants to snap to the VERTICES of the hexes, not solely the centres.
## The vertices of vertical hexes just happen to be the centres of half as big, 90° rotated hexes.
## The algorithm was nabbed from here: https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
## It's a very interesting read and an essential for game devs, so check it out.
func snap_vertical_hex_delta(target_delta):
    # We scale our position by the size vector so we can work with normalised sizes.
    # The scale is a vector so we can stretch hexes horizontally or vertically if we want to.
    var size = get_hexagon_size()
    target_delta /= size

    # First, we need to convert our world coordinates into hexagon coordinates.
    # Since the coordinates are already normalised, we don't need to divide by the scale anymore
    var q = sqrt(3) / 3 * target_delta.x - 1.0 / 3 * target_delta.y
    var r = 2.0 / 3 * target_delta.y

    # We can then round the hexagon coordinates to snap our cursor into the closest hexagon.
    var hex = round_hex_coordinates(Vector2(q, r))

    # Having snapped our cursor into position, we can then once again convert the hexagon coordinates into world coordinates.
    # Since the coordinates are already normalised, we don't need to multiply by the scale anymore
    var x = sqrt(3) * hex.x + sqrt(3) / 2 * hex.y
    var y = 3.0 / 2 * hex.y

    # Don't forget to scale our vector back up to world size.
    return Vector2(x, y) * size


## IMPORTANT: we're snapping to the centre of hexes with a flat top in this function, which is 90° off from horizontal hexes.
## That's because the user wants to snap to the VERTICES of the hexes, not solely the centres.
## The vertices of horizontal hexes just happen to be the centres of half as big, 90° rotated hexes.
## The algorithm was nabbed from here: https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
## It's a very interesting read and an essential for game devs, so check it out.
func snap_horizontal_hex_delta(target_delta):
    # We scale our position by the size vector so we can work with normalised sizes.
    # The scale is a vector so we can stretch hexes horizontally or vertically if we want to.
    var size = get_hexagon_size()
    target_delta /= size
    
    # First, we need to convert our world coordinates into hexagon coordinates.
    # Since the coordinates are already normalised, we don't need to divide by the scale anymore
    var q = 2.0 / 3 * target_delta.x
    var r = -1.0 / 3 * target_delta.x + sqrt(3) / 3 * target_delta.y

    # We can then round the hexagon coordinates to snap our cursor into the closest hexagon.
    var hex = round_hex_coordinates(Vector2(q, r))

    # Having snapped our cursor into position, we can then once again convert the hexagon coordinates into world coordinates.
    # Since the coordinates are already normalised, we don't need to multiply by the scale anymore
    var x = 3.0 / 2 * hex.x
    var y = sqrt(3) / 2 * hex.x + sqrt(3) * hex.y

    # Don't forget to scale our vector back up to world size.
    return Vector2(x, y)


## A helper function to adjust the size of the hexagons.
## Note that this is the inverse of the distances between the actual snap areas we calculate, as those need to be rotated 90° to our hex grid.
func get_hexagon_size():
    if radial_mode_to_corner:
        return snap_interval / sqrt(3.0)
    else:
        return snap_interval / 1.5


## Rounding coordinates in a hexagonal system (3-dimensional coordinates, meaning q, r, s overlap) to the closest hex.
## This algorithm was nabbed from https://www.redblobgames.com/grids/hexagons/#rounding
## It's a very interesting read that's an essential for every game dev, so go check it out.
## This algorithm can be used by both styles of hex grid.
## Input can be a Vector2 or Vector3, although only the x and y axes will be used.
## Output is a Vector3 with the final axes being calculated from the first two.
func round_hex_coordinates(fractional_hex):
    # Rounding every coordinate to the closest integer.
    # This may round one of the 3 coordinates to the wrong value.
    var q = round(fractional_hex.x)
    var r = round(fractional_hex.y)
    var s = round(- fractional_hex.x - fractional_hex.y)

    # Here we calculate which one of the values has the greatest deviation from the fractional values.
    # That's the value which might be wrong.
    var q_diff = abs(q - fractional_hex.x)
    var r_diff = abs(r - fractional_hex.y)
    var s_diff = abs(s + fractional_hex.x + fractional_hex.y)

    # Finally, since the values overlap, we can simply calculate the correct value for it from the other 2 values.
    if q_diff > r_diff and q_diff > s_diff:
        q = -r-s
    elif r_diff > s_diff:
        r = -q-s
    else:
        s = -q-r
    
    # We return a 3 dimensional vector, although only the q and r dimension will be needed in all likelyhood.
    return Vector3(q, r, s)


## Snap the delta of a given delta based on our square snap interval.
## Returns a new delta, which is the old delta snapped to the closest multiple of our snap interval.
func snap_square_delta(move_delta):
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


## TODO: IMPLEMENT
func snap_isometric_delta(target_position):
    pass


## Snaps the instant drag of the Select Tool to our invisible Snappy Grid.
## It's important to note that we don't snap to our cursors position but rather relative to the cursor movement.
## As the cursor might be off-centre from the object(s) we are trying to move.
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


## Snaps the normal Select Tool movement based on our Snappy Interval.
## Unlike instant drag, the vanilla movement does not seem to snap to a specific position, but rather relative to the movement.
## So we're doing the same thing, therefore completely ignoring offset.
## We simply move the selection in steps equal to our interval, based on the mouse movement.
func _update_select_tool():
    var select_tool = Global.Editor.Tools["SelectTool"]
    # Return if we aren't actually currently moving anything with the Select Tool.
    if select_tool.transformMode != 1:
        return

    # As the basis for our transform, we take the transform from BEFORE any mouse movement.
    var move_transform = select_tool.preDragTransform
    # We simply add our calculated snap distance to said transformation.
    move_transform.origin += get_snapped_delta(select_tool.moveDelta)

    # From there we simply need to apply the transformation.
    # This function will update all objects based on the transform.
    select_tool.ApplyTransforms(move_transform)
    # And finally we also need to move the box around our moved objects to the correct position as well.
    select_tool.transformBox.position = move_transform.origin


## Updates any point that is currently being edited in a given tool.
## Meaning we are in polygon or path editing mode and are dragging the point to a new position.
## This is only changing the preview of the path or polygon to the new position.
## The proper change already works normally by simply changing the default position, hence doesn't need to be updated.
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


## Updates the current preview of the Object and Scatter Tools to our invisible Snappy Grid.
func _update_object_placement(snap):
    var prop = Global.Editor.Tools["ObjectTool"].Preview
    prop.position = snap
    prop = Global.Editor.Tools["ScatterTool"].Preview
    prop.position = snap


## Updates the preview of any box or circle shaped selections to snap to the grid.
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


## NOTES ON SNAPPING PORTALS TO WALLS
## This line works as it should. We can find an apppropriate location for our portal near the snap location.
## ==> Global.Editor.Tools["PortalTool"].FindBestLocation(snap)
## This one is what breaks the implementation. This variable cannont cross the C# -> GDScript boundary.
## ==> var portal_location = Global.Editor.Tools["PortalTool"].get_FoundSpot()
## We could then set the location as simple as this.
## ==> Global.WorldUI.Texture.Transform = portal_location
## However, since we do not know exactly where the portal would go, our best bet will be a custom implementation.
## That might not be 100% accurate though.
## And more importantly, it's way too much work.
## Hence portals won't snap to walls
## If there's a tool that ain't an issue with, I think this is it.
## However they will still snap while freestanding.
func _update_portals(snap):
    #Global.Editor.Tools["PortalTool"].FindBestLocation(snap)
    #var portal_location = Global.Editor.Tools["PortalTool"].get_FoundSpot()
    #Global.WorldUI.Texture.Transform = portal_location
    if Global.Editor.Tools["PortalTool"].Freestanding:
        Global.WorldUI.Texture.Transform.origin = snap


## Saves the user settings as JSON in the MOD_DATA_PATH
func save_user_settings():
    var data = settings_into_dictionary()
    # Opening/creating of the actual file and writing of the data here.
    var file = File.new()
    file.open(MOD_DATA_PATH, File.WRITE)
    file.store_line(JSON.print(data, "\t"))
    file.close()

    # Currently I simply save any change to both the map and the general settings.
    # In the future I may only want to save changes locally, and only update global settings from elsewhere.
    save_local_settings()
    print("[%s] Saving user settings: successful" % MOD_DISPLAY_NAME)



## Loads the user settings from the MOD_DATA_PATH
## If there is no file in the specified location, we stop the attempt and leave the default values as they are.
func load_user_settings():
    var file = File.new()
    var error = file.open(MOD_DATA_PATH, File.READ)
    
    # If we cannot read the file, stop this attempt and leave the respective values at their default.
    if error != 0:
        print("[%s] Loading user settings: no global user settings found" % MOD_DISPLAY_NAME)
        return

    # Loading, parsing, and closing the file.
    var line = file.get_as_text()
    var data = JSON.parse(line).result
    file.close()

    # Writing user settings back where they belong.
    settings_from_dictionary(data)
    print("[%s] Loading global user settings: successful" % MOD_DISPLAY_NAME)


# Saves the current user settings into the mod data of the map that is being worked on.
func save_local_settings():
    var data = settings_into_dictionary()
    Global.ModMapData[TOOL_ID] = data


# Loads the user settings of the current map.
func load_local_settings():
    var data = Global.ModMapData[TOOL_ID]
    if data == null or data.empty():
        print("[%s] Loading user settings: no user map settings found" % MOD_DISPLAY_NAME)
        return
    settings_from_dictionary(data)
    print("[%s] Loading user map settings: successful" % MOD_DISPLAY_NAME)



## Writes the current settings into a dictionary.
func settings_into_dictionary():
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
    return data


## Loads the user's settings from a given dictionary.
## It will try to overwrite the value with the setting corresponding to the key.
## If the key does not exist, we keep the previous value instead.
func settings_from_dictionary(data):
    custom_snap_enabled = data.get("custom_snap_enabled", custom_snap_enabled)
    preset_menu_setting = data.get("preset_menu_setting", preset_menu_setting)
    advanced_section_enabled = data.get("advanced_section_enabled", advanced_section_enabled)
    lock_aspect_offset = data.get("lock_aspect_offset", lock_aspect_offset)
    lock_aspect_interval = data.get("lock_aspect_interval", lock_aspect_interval)
    snap_offset.x = data.get("snap_offset_x", snap_offset.x)
    snap_offset.y = data.get("snap_offset_y", snap_offset.y)
    old_offset.x = data.get("old_offset_x", old_offset.x)
    old_offset.y = data.get("old_offset_y", old_offset.y)
    snap_interval.x = data.get("snap_interval_x", snap_interval.x)
    snap_interval.y = data.get("snap_interval_y", snap_interval.y)
    old_interval.x = data.get("old_interval_x", old_interval.x)
    old_interval.y = data.get("old_interval_y", old_interval.y)

    # Since 0 is the index for the custom setting, we'll go into custom mode as that's what we last left with.
    # We're also overwriting the old interval since that's what we're using to set the sliders.
    # Might wanna change this to be part of the sliders in the future but as of now there's no reason to go back to a previous custom setting.
    was_custom_mode = preset_menu_setting == 0
    if was_custom_mode:
        old_offset = snap_offset
        old_interval = snap_interval



# =========================================================
# ANYTHING BEYOND THIS POINT IS FOR DEBUGGING PURPOSES ONLY
# =========================================================



## Debug function, very important. Prints whatever stuff I need to know at the moment.
func _on_debug_button():
    print("========== DEBUG BUTTON ==========")
#    hexagon_radius = fmod(hexagon_radius + 64, 256)
#    print(hexagon_radius)
#    print_children(tool_panel)
#    print_parents(tool_panel)
#    load_user_settings()
#    print_levels()
#    print_methods(Global.Editor.Tools["MapSettings"])
#    print_properties(tool_panel)
#    print_signals(Global.Editor.Tools["PathTool"])
#    Global.World.print_tree_pretty()


## Debug function, prints out the entire hierarchy of parents for a given node
func print_parents(node):
    var parent = node.get_parent()
    while parent != null:
        print(parent)
        parent = parent.get_parent()


## Debug function, prints out the info for every level
func print_levels():
    for level in Global.World.levels:
        print("==== Level %s ====" % level.name)
        print("Z Index: %s" % level.z_index)
        print("Z Relative: %s" % level.z_as_relative)


## Debug function, prints properties of the given node
func print_properties(node):
    print("========= PRINTING PROPERTIES OF %s ==========" % node.name)
    var properties_list = node.get_property_list()
    for property in properties_list:
        print(property.name)


## Debug function, prints methods of the given node
func print_methods(node):
    print("========= PRINTING METHODS OF %s ==========" % node.name)
    var method_list = node.get_method_list()
    for method in method_list:
        print(method.name)


## Debug function, prints signals of the given node
func print_signals(node):
    print("========= PRINTING SIGNALS OF %s ==========" % node.name)
    var signal_list = node.get_signal_list()
    for sig in signal_list:
        print(sig.name)


## Debug function, prints all other nodes lower in the tree
func print_children(node):
    for child in node.get_children():
        print(child.name, " ", child.text)
        print_children(child)