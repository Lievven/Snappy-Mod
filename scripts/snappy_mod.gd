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
const SMALL_ICON_PATH = "icons/snappy_icon_small.png"
const REWIND_ICON_PATH = "icons/rewind_icon.png"
const VERTICAL_HEX_ICON_PATH = "icons/hex_icon_vertical.png"
const HORIZONTAL_HEX_ICON_PATH = "icons/hex_icon_horizontal.png"
const SQUARE_ICON_PATH = "icons/square_icon.png"
const ISOMETRIC_ICON_PATH = "icons/isometric_icon.png"
const EDGE_ICON_PATH = "icons/to_edge_icon.png"
const CORNER_ICON_PATH = "icons/to_corner_icon.png"
const TRIANGLE_ICON_PATH = "icons/triangle_mode.png"
const HEX_ICON_PATH = "icons/hex_mode.png"

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
# Contains the buttons for selecting the geometry mode.
var geometry_mode_container
# The buttons for changing the hexagon's and isometric's radial mode between centre to corner and centre to edge.
var radial_mode_container
# The buttons for changing the hexagon's grid between triangles and hexagons
var triangle_display_container
# The option button for the preset menu.
var preset_menu


# ==== MOD STATE ====
var previous_zoom

# We snap according to the position of this given item if multiple items are selected
var item_index = 0
# The previously selected items. If changed, we need to update the selection snap transforms.
var raw_selectables
# The select tool, and the button controlling when a selection is snapped.
var select_tool
var snap_selection_button
# The last transformation made by the snap select tool button.
var previous_transform = Vector2(0, 0)
var initial_tranforms

# A timer to put a slight delay between changing the sliders and saving so we don't save a million times.
var save_timer = SAVE_DELAY
var save_timer_running = false

# If true, snap to our invisible Snappy Grid, otherwise use default DD behaviour for snapping.
var custom_snap_enabled = true
# If true, the custom grid overlay is visible. Otherwise, we show the vanilla DD overlay.
var custom_grid_enabled = true
# Whether or not the user can interact with the advanced section.
var advanced_section_enabled = false

# Choosing between a Square grid, vertical hex grid, and horizontal hex grid geometry.
# Vertical hexes are defined as having a flat top and bottom, hence allowing straight movement in the vertical but zig-zag movement in the horizontal axis.
# Horizontal hexes are defined as having a pointy top and bottom, hence requiring a zig-zag movement in the vertical but straight movement in the horizontal axis.
enum GEOMETRY {SQUARE, HEX_V, HEX_H, ISOMETRIC}
var active_geometry = GEOMETRY.HEX_H
# If true, we measure the hexagon's radius from the centre to the corner.
# Otherwise we measure the hexagon's radius as the shortest distance from the centre to the edge.
var radial_mode_to_corner = true
# If true, the display grid will use triangles. Otherwise hexagons will be used.
var display_mode_triangles = true
# If true, isometric snapping will use game projection of 1:2 ration rather than a hexagonal based one.
var isometric_mode_game = false

# If true, the offset and interval sliders' x and y sliders become linked and changing x changes y to the same value and the other way around.
var lock_aspect_offset = true
var lock_aspect_interval = true

# The offset by which the invisible Snappy Grid we snap to is deplaced from the vanilla grid.
var snap_offset = Vector2(0, 0)
# The space inbetween the invisible lines we snap to.
var snap_interval = Vector2(32, 32)

# Multiply the distance between grid overlay lines and snap points by this amount.
# Usually mesh size should be 2x the snap interval for less clutter.
var snap_interval_multiplier = 1.0
var mesh_size_multiplier = snap_interval_multiplier * 2.0

# The origin of any snap boxes. If null, there currently is no active snap box.
var box_origin = null

# The current preset for the preset menu.
var preset_menu_setting = 0

# Poolvectorarrays for drawing the hex mesh.
# Verts is the 3d position of the mesh's triangle corners.
# Uvs is the equivalent uv position mapping the pixel of the texture to the corresponding pixel in the mesh.
# Needs to be up here because GD3.4 can't pass these by reference.
var verts
var uvs

# An array of dictionaries of all the preset options.
# The first element is always the most recently used custom settings.
var preset_options = [
    {
        "preset_name": "Custom",
        "radial_mode_to_corner": true,
        "active_geometry": GEOMETRY.SQUARE,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 64,
        "snap_interval_y": 64,
    },
    {
        "preset_name": "1/4th (64px)",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.SQUARE,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 64,
        "snap_interval_y": 64,
    },
    {
        "preset_name": "1/8th (32px)",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.SQUARE,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 32,
        "snap_interval_y": 32,
    },
    {
        "preset_name": "Large Horizontal Hex",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.HEX_H,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 128,
        "snap_interval_y": 128,
    },
    {
        "preset_name": "Small Horizontal Hex",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.HEX_H,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 64,
        "snap_interval_y": 64,
    },
    {
        "preset_name": "Large Vertical Hex",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.HEX_V,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 128,
        "snap_interval_y": 128,
    },
    {
        "preset_name": "Small Vertical Hex",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.HEX_V,
        "lock_aspect_offset": true,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 0,
        "snap_interval_x": 64,
        "snap_interval_y": 64,
    },
    {
        "preset_name": "Roll20 Horizontal",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.HEX_H,
        "lock_aspect_offset": false,
        "lock_aspect_interval": true,
        "snap_offset_x": 0,
        "snap_offset_y": 73.9,
        "snap_interval_x": 128,
        "snap_interval_y": 128,
    },
    {
        "preset_name": "Roll20 Vertical",
        "radial_mode_to_corner": false,
        "active_geometry": GEOMETRY.HEX_V,
        "lock_aspect_offset": false,
        "lock_aspect_interval": true,
        "snap_offset_x": 73.9,
        "snap_offset_y": 0,
        "snap_interval_x": 128,
        "snap_interval_y": 128,
    },
    ]




# Vanilla start function called by Dungeondraft when the mod is first loaded
func start():

    # Loading any previous saved settings.
    load_user_settings()
    load_local_settings()
    preset_from_dictionary(preset_options[preset_menu_setting])

    # Fetch tool panels for level selection.
    tool_panel = Global.Editor.Toolset.CreateModTool(self, TOOL_CATEGORY, TOOL_ID, TOOL_NAME, Global.Root + TOOL_ICON_PATH)
    select_tool = Global.Editor.Tools["SelectTool"]

    # Begin core section
    tool_panel.BeginSection(false)

    # Creates the buttons do enable or disable the tool and the map.
    _create_tool_enable_buttons()
    
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
    _create_interval_sliders()
    tool_panel.CreateSeparator()
    _create_offset_sliders()
    tool_panel.CreateSeparator()
    _create_radial_buttons()

    # End advanced section
    tool_panel.EndSection()

    # Begin notes and debug section.
    tool_panel.BeginSection(true)

    # A small note to remind users to press the 'S' key.
    tool_panel.CreateNote("Remember that toggling the vanilla snap on or off will also turn the %s's snap on or off. "
            % MOD_DISPLAY_NAME
            + "No need to return to this tool, simply press the '%s' key."
            % InputMap.get_action_list("toggle_snap")[0].as_text())

    _create_debug_section()

    tool_panel.EndSection()

    print("[%s] Adding \"Snap to Grid\" option to Select menu" % MOD_DISPLAY_NAME)
    _create_snap_selection_button()
    
    # Connects grid draw to export functionality.
    print("[%s] Connecting Exporter" % MOD_DISPLAY_NAME)
    var export_button = Global.Editor.Windows["Export"].exportButton
    export_button.connect("pressed", self, "_draw_grid_mesh")

    _register_APIs()

    print("[%s] Init successful" % MOD_DISPLAY_NAME)



func _register_APIs():
    # Trying to register with _Lib, so other mods can use custom snapping.
    print("[%s] Registering with _Lib" % MOD_DISPLAY_NAME)
    if not Engine.has_signal("_lib_register_mod"):
        print("[%s] _Lib not found" % MOD_DISPLAY_NAME)
        return
    
    Engine.emit_signal("_lib_register_mod", self)
    Global.API.register(TOOL_ID, self)




func _create_tool_enable_buttons():
    # This button will disable custom snapping and return the snapping behaviour to vanilla DD for as long as it is in the off state.
    var on_off_button = tool_panel.CreateCheckButton("Enabled", "", custom_snap_enabled)
    on_off_button.connect("toggled", self, "_toggle_tool_enabled")
    on_off_button.set_tooltip("Disable to return to vanilla snapping mechanics.")

    # This button will disable custom grid overlay and return the overlay to vanilla DD for as long as it is in the off state.
    var grid_toggle = tool_panel.CreateCheckButton("Custom Grid", "", custom_grid_enabled)
    grid_toggle.connect("toggled", self, "_toggle_grid_visibility")
    grid_toggle.set_tooltip("Disable to use the vanilla grid overlay while still using custom snapping.")



## Creates the buttons to switch between the different grid modes, e.g. Square, Hex_V, or Hex_H
func _create_mode_buttons():
    # Here we are creating a custom horizontal section, as those are not yet supported by DD.
    # It's as easy as adding a new container and assigning it as 'Align', which is where DD puts any newly created items.
    # VERY IMPORTANT: we need to close the container afterwards, or DD will put everything else in there as well.
    geometry_mode_container = HBoxContainer.new()
    var section_container = tool_panel.Align
    section_container.add_child(geometry_mode_container)
    tool_panel.Align = geometry_mode_container

    # Creating a grouped toggle, meaning turning on one of them will turn off all others.
    # For some reason, this will always complain that the given property does not exist in ModBaseTool.
    # It's the same as all other CreateX though, so it's perfectly fine.
    # DON'T MESS WITH THE ORDER WITHOUT ALSO CHANGING THE ORDER OF ASSIGNING IDENTIFIERS BELOW
    var b_group = ButtonGroup.new()
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.SQUARE, Global.Root + SQUARE_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.HEX_H, Global.Root + HORIZONTAL_HEX_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.HEX_V, Global.Root + VERTICAL_HEX_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("", "", active_geometry == GEOMETRY.ISOMETRIC, Global.Root + ISOMETRIC_ICON_PATH, b_group)
    b_group.connect("pressed", self, "_on_toggle_mode_changed")

    # Assigning the proper identifiers to the button.
    # Note that we don't get the button returned from the CreateSharedToggle function, so we have to go by order here.
    # DON'T GET THE ORDER WRONG.
    geometry_mode_container.get_child(0).name = GEOMETRY.SQUARE
    geometry_mode_container.get_child(1).name = GEOMETRY.HEX_H
    geometry_mode_container.get_child(2).name = GEOMETRY.HEX_V
    geometry_mode_container.get_child(3).name = GEOMETRY.ISOMETRIC

    # Closing custom section
    # Easily done by replacing 'Align' with the container previously held by it.
    tool_panel.Align = section_container


## Creates the buttons to switch between the different hex radial modes.
## Corner mode measures the radius between the centre and  the corner, meaning the longest distance.
## Edge mode measures the radius between the centre and the middle of the edge, meaning the shortest distance.
func _create_radial_buttons():
    # Creates a wrapper section, this one is made purely for the purpopse of toggling visibility of the contained elements.
    # If we're in Hex mode, the buttons to be visible, otherwise we want them to be hidden until we need them.
    radial_mode_container = tool_panel.BeginSection(false)
    radial_mode_container.visible = active_geometry == GEOMETRY.HEX_H or active_geometry == GEOMETRY.HEX_V or active_geometry == GEOMETRY.ISOMETRIC

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
    var b_group = ButtonGroup.new()
    tool_panel.CreateSharedToggle ("Corner", "", radial_mode_to_corner, Global.Root + CORNER_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("Edge", "", not radial_mode_to_corner, Global.Root + EDGE_ICON_PATH, b_group)
    b_group.connect("pressed", self, "_on_radial_mode_changed")

    tool_panel.CreateSeparator()
    triangle_display_container = HBoxContainer.new()
    section_container.add_child(triangle_display_container)
    tool_panel.Align = triangle_display_container
    
    triangle_display_container.visible = active_geometry == GEOMETRY.HEX_H or active_geometry == GEOMETRY.HEX_V

    b_group = ButtonGroup.new()
    tool_panel.CreateSharedToggle ("Triangle", "", display_mode_triangles, Global.Root + TRIANGLE_ICON_PATH, b_group)
    tool_panel.CreateSharedToggle ("Hex", "", not display_mode_triangles, Global.Root + HEX_ICON_PATH, b_group)
    b_group.connect("pressed", self, "_on_triangle_display_mode_changed")

    # Closing custom section
    # Easily done by replacing 'Align' with the container previously held by it.
    tool_panel.Align = section_container

    tool_panel.CreateNote("Warning: Hexagon display is an experimental feature and may cause performance issues on large maps.")

    tool_panel.CreateSeparator()
    tool_panel.EndSection()


## Creates the menu which offers all the most important presets. Most of the time users won't need any other settings.
func _create_preset_menu():
    preset_menu = tool_panel.CreateLabeledDropdownMenu("", "Presets", [], "Error")

    for preset_item in preset_options:
        preset_menu.add_item(preset_item["preset_name"])

    preset_menu.connect("item_selected", self, "_change_preset")
    preset_menu.selected = preset_menu_setting
    preset_menu.set_tooltip("Most practical presets for the snap spacing. For most users, they're all you'll ever need.")


## Creates the sliders and buttons for adjusting the snap interval
func _create_interval_sliders():
    # Creating label and slider to adjust the snap interval in the X axis.
    tool_panel.CreateLabel("Horizontal Scaling")
    interval_slider_x = tool_panel.CreateSlider("", 32, 1, 256, 1, false)
    interval_slider_x.set_allow_greater(true)
    interval_slider_x.set_value(snap_interval.x)
    interval_slider_x.connect("value_changed", self, "_changed_interval_x")
    interval_slider_x.set_tooltip("The amount of space between snap points in pixels.")

    # Creating label and slider to adjust the snap interval in the Y axis.
    tool_panel.CreateLabel("Vertical Scaling")
    interval_slider_y = tool_panel.CreateSlider("", 32, 1, 256, 1, false)
    interval_slider_y.set_allow_greater(true)
    interval_slider_y.set_value(snap_interval.y)
    interval_slider_y.connect("value_changed", self, "_changed_interval_y")
    interval_slider_y.set_tooltip("The amount of space between snap points in pixels.")
    
    # This button locks the horizontal and vertical axis for our selection sliders.
    # After all most of the time the user does not need to have different behaviour for either axis.
    var lock_aspect_interval_button = tool_panel.CreateCheckButton("Lock Aspect Ratio", "", lock_aspect_interval)
    lock_aspect_interval_button.connect("toggled", self, "_toggle_lock_aspect_interval")
    lock_aspect_interval_button.set_tooltip("Locks aspect ratios between the spacing sliders. Keep this locked unless you need to have different snap spacing for each axis.")


## Creates the sliders asnd buttons for adjusting the snap offset
func _create_offset_sliders():
    # Creating label and slider to adjust the snap offset in the X axis.
    tool_panel.CreateLabel("Horizontal Offset (Right)")
    offset_slider_x = tool_panel.CreateSlider("", 32, 0, 256, 1, false)
    offset_slider_x.set_allow_greater(true)
    offset_slider_x.set_allow_lesser(true)
    offset_slider_x.set_value(snap_offset.x)
    offset_slider_x.connect("value_changed", self, "_changed_offset_x")
    offset_slider_x.set_tooltip("The offset of the grid from the top left corner in pixels.")

    # Creating label and slider to adjust the snap offset in the Y axis.
    tool_panel.CreateLabel("Vertical Offset (Down)")
    offset_slider_y = tool_panel.CreateSlider("", 32, 0, 256, 1, false)
    offset_slider_y.set_allow_greater(true)
    offset_slider_y.set_allow_lesser(true)
    offset_slider_y.set_value(snap_offset.y)
    offset_slider_y.connect("value_changed", self, "_changed_offset_y")
    offset_slider_y.set_tooltip("The offset of the grid from the top left corner in pixels.")
    
    # This button locks the horizontal and vertical axis for our selection sliders.
    # After all most of the time the user does not need to have different behaviour for either axis.
    var lock_aspect_offset_button = tool_panel.CreateCheckButton("Lock Aspect Ratio", "", lock_aspect_offset)
    lock_aspect_offset_button.connect("toggled", self, "_toggle_lock_aspect_offset")
    lock_aspect_offset_button.set_tooltip("Locks aspect ration between the offset sliders. Keep this locked unless you need to have different snap spacing for each axis.")


# Creates the button assigned to move all items selected by the selection tool to the closest grid snap.
func _create_snap_selection_button():
    var select_panel = Global.Editor.Toolset.GetToolPanel("SelectTool")
    snap_selection_button = select_panel.CreateButton("Snap Selection", Global.Root + SMALL_ICON_PATH)
    snap_selection_button.connect("pressed", self, "_on_snap_select_button")

    # We're using the Mirror node as an indicator, as we add the button right after it.
    var above_node = select_panel.mirrorButton

    # Moves the snap selection button below the node we want above it.
    snap_selection_button.get_parent().remove_child(snap_selection_button)
    if above_node:
        above_node.get_parent().add_child_below_node(above_node, snap_selection_button)
    else:
        print("[%s] Couldn't create Snap Selection button. Missing the 'mirrorButton' node" % MOD_DISPLAY_NAME)


## Finds a node by the content of its 'icon' property.
## We're actually looking for the icon's resource path since we don't know the icon itself.
## Does a recursive depth search through all children and their children up to given depth.
func _find_node_by_icon_path(parent, icon_path, depth = 10):
    if depth == 0:
        return null

    # Just loop over all the children and match for their 'icon' property's load path.
    for child in parent.get_children():
        if "icon" in child and child.icon.load_path.match(icon_path):
            return child

        # We doing recursion, since many UI items are hidden in containers.
        var next = _find_node_by_icon_path(child, icon_path, depth - 1)
        if not next == null:
            return next
    
    return null


# Finds a node by the content of its 'text' property.
# This is necessary since a lot of vanilla nodes in DD aren't named.
# Does a recursive depth search through all children and their children, up to the given depth.
# @DEPRECIATED
func _find_node_by_text(parent, text, depth = 10):
    if depth == 0:
        return null

    # Just loop over all the children and check their 'text' property
    for child in parent.get_children():
        if "text" in child and child.text == text:
            return child

        # We doing recursion, since many UI items are hidden in containers.
        var next = _find_node_by_text(child, text, depth - 1)
        if not next == null:
            return next
    
    return null


## Sets the flag to disable/enable the tool and return to/from vanilla DD snapping mechanics.
func _toggle_tool_enabled(new_state):
    custom_snap_enabled = new_state
    _schedule_save()
    _update_grid_visuals()


## Sets the flag to disable/enable the grid overlay visuals or return to the vanilla overlay.
func _toggle_grid_visibility(new_state):
    custom_grid_enabled = new_state
    _schedule_save()
    _update_grid_visuals()


## Enables to disables the advanced settings section.
func _enable_advanced_section(new_state):
    # Enable or disnable the preset selector's custom button based on whether we use advanced settings or not.
    enable_advanced_button.set_item_disabled(0, new_state)
    advanced_section_enabled = new_state
    advanced_settings_section.visible = new_state
    _schedule_save()


## Changes the grid mode. The button's 'name' property needs to equal the new grid mode.
func _on_toggle_mode_changed(button):
    # The corresponding signal is still triggered when the mode is changed programatically.
    # This will result in returning to custom mode, which we only want when the player presses this.
    # Since the geometry will already correspond to the button, we can catch this case easily like this.
    if active_geometry == int(button.name):
        return
    
    # Gotta cast to int here as while we're using the GEOMETRY enum to set the button's name, that's a string, which won't match for int.
    match int(button.name):
        GEOMETRY.SQUARE:
            active_geometry = GEOMETRY.SQUARE
            radial_mode_container.visible = false
            triangle_display_container.visible = false
        GEOMETRY.HEX_H:
            active_geometry = GEOMETRY.HEX_H
            radial_mode_container.visible = true
            triangle_display_container.visible = true
        GEOMETRY.HEX_V:
            active_geometry = GEOMETRY.HEX_V
            radial_mode_container.visible = true
            triangle_display_container.visible = true
        GEOMETRY.ISOMETRIC:
            active_geometry = GEOMETRY.ISOMETRIC
            radial_mode_container.visible = true
            triangle_display_container.visible = false
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


# Changes display mode between the faster triangle mode and the badly performing, better visual hexagon mode.
func _on_triangle_display_mode_changed(button):
    var previous_mode = display_mode_triangles
    match button.text:
        "Triangle":
            display_mode_triangles = true
        "Hex":
            display_mode_triangles = false
        _:
            display_mode_triangles = true
    # We don't want to update if the mode didn't change, as this function may be called by the preset change.
    if previous_mode == display_mode_triangles:
        return
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Changes the radial mode based on the given node's text component.
## "Corner" => corner, "Edge" => edge, and corner for any other default
func _on_radial_mode_changed(button):
    var previous_mode = radial_mode_to_corner
    match button.text:
        "Corner":
            radial_mode_to_corner = true
        "Edge":
            radial_mode_to_corner = false
        _:
            radial_mode_to_corner = true
    # We don't want to update if the mode didn't change, as this function may be called by the preset change.
    if previous_mode == radial_mode_to_corner:
        return
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Changes the currently selected preset.
func _change_preset(preset_index):
    preset_menu_setting = preset_index
    preset_from_dictionary(preset_options[preset_index])
    update_user_interface()
    _update_grid_visuals()
    _schedule_save()


## Updates the elements in the user interface to match the preset.
func update_user_interface():
    offset_slider_x.value = snap_offset.x
    offset_slider_y.value = snap_offset.y
    interval_slider_x.value = snap_interval.x
    interval_slider_y.value = snap_interval.y
    for button in geometry_mode_container.get_children():
        if int(button.name) == active_geometry:
            button.set_pressed(true)
    for button in radial_mode_container.get_child(0).get_children():
        match button.text:
            "Corner":
                button.set_pressed(radial_mode_to_corner)
            "Edge":
                button.set_pressed(not radial_mode_to_corner)
            "Triangle":
                button.set_pressed(display_mode_triangles)
            "Hex":
                button.set_pressed(not display_mode_triangles)



# Called by the 'Snap Select' button.
# Moves the selection to the closest snap point.
func _on_snap_select_button():
    var selection_changed = _populate_initial_transforms()

    var move_transform = _calculate_select_box_snap_offset(selection_changed)

    # Saving previous transforms for Undo history.
    select_tool.SavePreTransforms()
    select_tool.RecordTransforms()

    # Apply transformation to all selected objects and the outline box
    select_tool.ApplyTransforms(move_transform[0])
    select_tool.transformBox.position += move_transform[1]


# Populating 'initial transforms' for all objects chosen by the Select Tool.
# Returns @true if selected items changed and @false if not.
func _populate_initial_transforms():
    # If the selectables haven't changed, the corresponding intial transforms are still up to date.
    if raw_selectables == select_tool.RawSelectables \
    and initial_tranforms.values() == select_tool.initialRelativeTransforms.values():
        return false

    initial_tranforms = {}
    raw_selectables = select_tool.RawSelectables
    for selectable in raw_selectables:
        initial_tranforms[selectable] = selectable.Thing.transform

    select_tool.initialRelativeTransforms = initial_tranforms
    return true


func _calculate_select_box_snap_offset(selection_changed):
    # If item_index is 0, our target position is just the box outline's position
    var target_position = select_tool.transformBox.position
    
    var raw_selectables = select_tool.RawSelectables

    # Otherwise we go through the items in order.
    # Modulo operation exists to deal with potentially changing sizes.
    if item_index > 0:
        var selectable = raw_selectables[(item_index - 1) % raw_selectables.size()].Thing
        target_position = selectable.position

    # When counting up the index, remember we need to Modulo by 1 more, which is the box outline.
    item_index = (item_index + 1) % (raw_selectables.size() + 1)

    # If the previous selection changed, we're operating from a new position and don't need an offset.
    if selection_changed:
        previous_transform = Vector2(0, 0)

    # Gets the difference between the target position and its snapped equal
    # The ApplyTransform replaces the previous transform, so they need to add.
    var target_offset = get_snapped_position(target_position - previous_transform)
    var box_offset = target_offset - target_position
    target_offset = box_offset + previous_transform
    
    # Assigning the affine transform
    var move_transform = Transform2D()
    move_transform.origin += target_offset

    previous_transform = target_offset
    return [move_transform, box_offset]



## Set the preset mode to the custom preset meant for the most recent changes and also writes any changes to that preset.
func _update_custom_mode():
    preset_menu_setting = 0
    preset_menu.selected = 0
    # Store (but not save) the current settings into the preset for the most recent changes.
    preset_options[0] = preset_into_dictionary()


## Changes the snap interval's aspect locking behaviour to the given state.
## Usually called by the lock_aspect_interval_button's toggled signal
func _toggle_lock_aspect_interval(new_state):
    lock_aspect_interval = new_state
    if lock_aspect_interval:
        # immediately set the Y value and slider for the snap interval to that of the X slider.
        interval_slider_y.value = interval_slider_x.value
        snap_interval.y = snap_interval.x
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Changes the snap offset's aspect locking behaviour to the given state.
## Usually called by the lock_aspect_offset_button's toggled signal
func _toggle_lock_aspect_offset(new_state):
    lock_aspect_offset = new_state
    if lock_aspect_offset:
        # immediately set the Y value and slider for the snap offset to that of the X slider.
        offset_slider_y.value = offset_slider_x.value
        snap_offset.y = offset_slider_x.value
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Sets the new snap offset in the X axis.
## Also sets the offset_slider_y and offset in the Y axis if the snap aspect is locked.
## Usually called by the offset_slider_x
func _changed_offset_x(value):
    # Quit if the value stays identical, as we'll otherwise call updates when set programmatically.
    if value == snap_offset.x:
        return

    snap_offset.x = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_offset:
        snap_offset.y = value
        offset_slider_y.value = value
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Sets the new snap offset in the Y axis.
## Also sets the offset_slider_x and offset in the X axis if the snap aspect is locked.
## Usually called by the offset_slider_y
func _changed_offset_y(value):
    # Quit if the value stays identical, as we'll otherwise call updates when set programmatically.
    if value == snap_offset.y:
        return

    snap_offset.y = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_offset:
        snap_offset.x = value
        offset_slider_x.value = value
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Sets the new snap interval in the X axis.
## Also sets the interval_slider_y and interval in the Y axis if the snap aspect is locked.
## Usually called by the interval_slider_x
func _changed_interval_x(value):
    # Quit if the value stays identical, as we'll otherwise call updates when set programmatically.
    if value == snap_interval.x:
        return

    snap_interval.x = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_interval:
        snap_interval.y = value
        interval_slider_y.value = value
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Sets the new snap interval in the Y axis.
## Also sets the interval_slider_x and interval in the X axis if the snap aspect is locked.
## Usually called by the interval_slider_y
func _changed_interval_y(value):
    # Quit if the value stays identical, as we'll otherwise call updates when set programmatically.
    if value == snap_interval.y:
        return

    snap_interval.y = value
    # If aspect locked, we also need to set the slider for the other axis (our slider already changed), and of course both values.
    if lock_aspect_interval:
        snap_interval.x = value
        interval_slider_x.value = value
    _update_custom_mode()
    _update_grid_visuals()
    _schedule_save()


## Schedule a new save.
## We always up the delay to the maximum since the point is that we don't save immediately.
## Otherwise we might be saving dozens of times within seconds, when we only need the last save anyway.
func _schedule_save():
    save_timer = SAVE_DELAY
    save_timer_running = true


func _update_grid_visuals():
    if not custom_snap_enabled or not custom_grid_enabled:
        # Hacky way to get DD to redraw its vanilla grid, which we want in this case.
        Global.Camera.SetRawZoom(Global.Camera.zoom.x)
        return
    _draw_grid_mesh(true)


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
            save_local_settings()
            
    # Updates whether the 'Snap Selection' button is available to press or not.
    # Important to do now, since it has to work even when other snapping is disabled.
    _update_select_button_status()

    # If the user currently wishes to use default snapping, we return as we do not want to snap to anything.
    if not custom_snap_enabled:
        return
        
    # Updates the displayed grid to match the snap points.
    # We still draw even if we do not snap, so the user still sees the grid.
    _draw_grid_mesh()

    # If the user disabled vanilla snapping, we don't want to snap either.
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

    # Snaps a text box to the Snappy Grid.
    _update_text_box(snap)



## Calculate the closest position snapped to our invisible Snappy Grid from the given Vector2.
## This one simply snaps the delta from the offset, then reapplies the offset.
# If Custom Snap is disabled, will instead give the vanilla snapped position.
func get_snapped_position(target_position):
    # If the tool isn't active, we just return vanilla DD's default position.
    # This is useful in case any other mods or features use this function.
    if not custom_snap_enabled:
        return Global.WorldUI.GetSnappedPosition(target_position)

    var offset_position = target_position - snap_offset

    var snapped_position = get_snapped_delta(offset_position) + snap_offset

    # If we have access to the GuideLines API, we can try to find a snap point from said guidelines.
    if not Global.API or not Global.API.GuidesLinesApi:
        return snapped_position

    var guide_snapped_position = get_guide_snapped_position(target_position, snapped_position)
    if not guide_snapped_position:
        return snapped_position
    return guide_snapped_position


#TODO: IMPLEMENT SEPARATE, CURRENTLY UNREACHABLE PARTS
func get_guide_snapped_position(target_position, snapped_position):
    var radius = target_position.distance_to(snapped_position)
    var return_point = null

    var line_a = Vector2(0, 0)
    var line_b = Vector2(32, 32)
    var marker = Global.API.GuidesLinesApi.find_line_intersection(line_a, line_b, target_position, radius)
    if marker:
        if target_position.distance_to(marker["point"]) < radius:
            return_point = marker["point"]
            radius = target_position.distance_to(marker["point"])


    marker = Global.API.GuidesLinesApi.find_nearest_marker_by_geometry(target_position, radius)
    if marker:
        if marker["vertex"]:
            if target_position.distance_to(marker["vertex"]) < radius:
                return_point = marker["vertex"]
                radius = target_position.distance_to(marker["vertex"])
        elif target_position.distance_to(marker["point"]) < radius:
            return_point = marker["point"]
            radius = target_position.distance_to(marker["point"])


    marker = Global.API.GuidesLinesApi.find_nearest_geometry_point(target_position, radius)
    if marker:
        if target_position.distance_to(marker["point"]) < radius:
            return_point = marker["point"]
            radius = target_position.distance_to(marker["point"])
    
    return return_point


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
    var size = get_hexagon_size() * snap_interval_multiplier
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
## @size_multiplier optionally snaps to a larger or smaller resolution.
func snap_horizontal_hex_delta(target_delta, size_multiplier = 1.0):
    # We scale our position by the size vector so we can work with normalised sizes.
    # The scale is a vector so we can stretch hexes horizontally or vertically if we want to.
    var size = get_hexagon_size() * snap_interval_multiplier * size_multiplier
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
    return Vector2(x, y) * size


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
    # The multiplied snap values to potentially snap at double resolution compared to the grid overlay.
    var dist_x = snap_interval.x * snap_interval_multiplier
    var dist_y = snap_interval.y * snap_interval_multiplier

    # Snap the movement to the next interval smaller than the actual movement.
    var snap_x = floor(move_delta.x / dist_x) * dist_x
    var snap_y = floor(move_delta.y / dist_y) * dist_y

    # If we're closer to the next interval larger than the actual movement, we snap there instead.
    if fmod(move_delta.x, dist_x) > dist_x / 2:
        snap_x += dist_x
    if fmod(move_delta.y, dist_y) > dist_y / 2:
        snap_y += dist_y

    # Returning the new delta. Not a position.
    return Vector2(snap_x, snap_y)


## Isometric delta is equal to the horizontal hex delta.
## Or in game view, we use similar math, but use much simpler 2:1 ratios.
func snap_isometric_delta(target_delta):
    if not isometric_mode_game:
        return snap_horizontal_hex_delta(target_delta, 0.5 * snap_interval_multiplier)
    
    # We scale our position by the size vector so we can work with normalised sizes.
    # The scale is a vector so we can stretch hexes horizontally or vertically if we want to.
    var size = snap_interval * Vector2(0.5, 0.5) * snap_interval_multiplier
    target_delta /= size
    
    # First, we need to convert our world coordinates into hexagon coordinates.
    # Since the coordinates are already normalised, we don't need to divide by the scale anymore
    # Additionally, since we use game isometric with a 2:1 ratio, the math is a bit easier.
    var q = target_delta.x
    var r = -0.5 * target_delta.x + target_delta.y

    # We can then round the hexagon coordinates to snap our cursor into the closest hexagon.
    var hex = round_hex_coordinates(Vector2(q, r))

    # Having snapped our cursor into position, we can then once again convert the hexagon coordinates into world coordinates.
    # Since the coordinates are already normalised, we don't need to multiply by the scale anymore
    var x = hex.x
    var y = 0.5 * hex.x + hex.y

    # Don't forget to scale our vector back up to world size.
    return Vector2(x, y) * size



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
        # Set origin box to null to signal our next use case that it's starting a new box.
        box_origin = null
        return

    # Dungeondraft doesn't expose the origin position of the box to us, so we need to save it manually to create the correctly snapped outline.
    if box_origin == null:
        box_origin = get_snapped_position(Global.WorldUI.MousePosition)
        
    # In Godot, Rects always go left to right, top to bottom without negative values.
    # Hence we check which one of our corner coordinates is the leftmost coordinate.
    # Then simply assign that one for the box's start position and the other for the end position
    if box_origin.x < snap.x:
        box.position.x = box_origin.x
        box.end.x = snap.x
    else:
        box.position.x = snap.x
        box.end.x = box_origin.x

    # Same as before, but with Y coordinates selecting for the topmost coordinate
    if box_origin.y < snap.y:
        box.position.y = box_origin.y
        box.end.y = snap.y
    else:
        box.position.y = snap.y
        box.end.y = box_origin.y

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



# Updates the CENTRE position of the text box to the current snap position.
# This only happens while moving, since we don't want the textbox to flop around with every letterr.
func _update_text_box(snap):
    var text_tool = Global.Editor.Tools["TextTool"]
    var text = text_tool.focus
    if text_tool.isDragging:
        text.rect_position = snap - text.rect_size * text.rect_scale / 2



# Updates the Snap Selection button to only be active while items are selected.
func _update_select_button_status():
    if select_tool.RawSelectables.size() > 0:
        snap_selection_button.disabled = false
    else:
        snap_selection_button.disabled = true



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
    save_local_settings(false)
    print("[%s] Saving global user settings: successful" % MOD_DISPLAY_NAME)


## Loads the user settings from the MOD_DATA_PATH
## If there is no file in the specified location, we stop the attempt and leave the default values as they are.
func load_user_settings():
    var file = File.new()
    var error = file.open(MOD_DATA_PATH, File.READ)
    
    # If we cannot read the file, stop this attempt and leave the respective values at their default.
    if error != 0:
        print("[%s] Loading global user settings: no valid file found" % MOD_DISPLAY_NAME)
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
    var data = settings_into_dictionary(true)
    Global.ModMapData[TOOL_ID] = data
    print("[%s] Saving local map settings: successful" % MOD_DISPLAY_NAME)


# Loads the user settings of the current map.
func load_local_settings():
    var data = Global.ModMapData[TOOL_ID]
    if data == null or data.empty():
        print("[%s] Loading user map settings: no valid file found" % MOD_DISPLAY_NAME)
        return
    settings_from_dictionary(data)
    print("[%s] Loading user map settings: successful" % MOD_DISPLAY_NAME)



## Writes the current settings into a dictionary.
## If is_local, will only write the custom preset option, as the others are presumed to be global.
func settings_into_dictionary(is_local = false):
    var data = {
        "custom_snap_enabled": custom_snap_enabled,
        "custom_grid_enabled": custom_grid_enabled,
        "advanced_section_enabled": advanced_section_enabled,
        "active_preset": preset_options[preset_menu_setting]["preset_name"],
    }
    if is_local:
        data["custom_preset"] = preset_options[0]
    else:
        data["preset_options"] = preset_options
    return data


## Loads the user's settings from a given dictionary.
## It will try to overwrite the value with the setting corresponding to the key.
## If the key does not exist, we keep the previous value instead.
func settings_from_dictionary(data):
    custom_snap_enabled = data.get("custom_snap_enabled", custom_snap_enabled)
    custom_grid_enabled = data.get("custom_grid_enabled", custom_grid_enabled)
    advanced_section_enabled = data.get("advanced_section_enabled", advanced_section_enabled)
    # Global settings have preset options which we want to keep if we load local settings (which do not have preset_options).
    preset_options = data.get("preset_options", preset_options)
    # Local settings have the more valid custom preset, which we want to overwrite if available.
    preset_options[0] = data.get("custom_preset", preset_options[0])

    # The active preset is saved as a string, since the number of presets may change while not working on a given map.
    var active_preset = data.get("active_preset", "Custom")
    # When we match the name we can return, as preset_menu_setting corresponds to the index in preset_options.
    preset_menu_setting = 0
    for preset in preset_options:
        if preset["preset_name"] == active_preset:
            return
        preset_menu_setting += 1

    # If for some reason we find no active preset with the given name, we go back to Custom as the default preset.
    preset_menu_setting = 0


## Writes the current preset into a dictionary.
func preset_into_dictionary(name = "Custom"):
    var data = {
        "preset_name": name,
        "radial_mode_to_corner": radial_mode_to_corner,
        "display_mode_triangles": display_mode_triangles,
        "active_geometry": active_geometry,
        "lock_aspect_offset": lock_aspect_offset,
        "lock_aspect_interval": lock_aspect_interval,
        "snap_offset_x": snap_offset.x,
        "snap_offset_y": snap_offset.y,
        "snap_interval_x": snap_interval.x,
        "snap_interval_y": snap_interval.y,
    }
    return data


## Loads the user's settings from a given dictionary.
## It will try to overwrite the value with the setting corresponding to the key.
## If the key does not exist, we keep the previous value instead.
func preset_from_dictionary(data):
    radial_mode_to_corner = data.get("radial_mode_to_corner", radial_mode_to_corner)
    display_mode_triangles = data.get("display_mode_triangles", display_mode_triangles)
    active_geometry = int(data.get("active_geometry", active_geometry))
    lock_aspect_offset = data.get("lock_aspect_offset", lock_aspect_offset)
    lock_aspect_interval = data.get("lock_aspect_interval", lock_aspect_interval)
    snap_offset.x = data.get("snap_offset_x", snap_offset.x)
    snap_offset.y = data.get("snap_offset_y", snap_offset.y)
    snap_interval.x = data.get("snap_interval_x", snap_interval.x)
    snap_interval.y = data.get("snap_interval_y", snap_interval.y)



# Helper function to call the appropriate function to calculate the mesh based on the active geometry.
func _draw_grid_mesh(force_draw = false):
    # We don't want to draw the grid if it's disabled, even if we would otherwise force a draw.
    if not custom_grid_enabled:
        return

    # If we didn't change zoom settings or force a draw, we should already have the same grid mesh.
    if not force_draw and previous_zoom == Global.Camera.zoom:
        return

    previous_zoom = Global.Camera.zoom

    # Initialising subarrays of the surface array.
    verts = PoolVector3Array()
    uvs = PoolVector2Array()

    # Select the grid to calculate based on the active geometry.
    match active_geometry:
        GEOMETRY.HEX_V:
            if display_mode_triangles:
                _draw_vertical_triangle_surface_mesh()
            else:
                _draw_vertical_surface_mesh()
                return
        GEOMETRY.HEX_H:
            if display_mode_triangles:
                _draw_horizontal_triangle_surface_mesh()
            else:
                _draw_horizontal_surface_mesh()
                return
        GEOMETRY.SQUARE:
            _draw_square_surface_mesh()
        GEOMETRY.ISOMETRIC:
            _draw_isometric_surface_mesh()

        _:
            print("[%s] Drawing grid mesh: wrong active geometry" % MOD_DISPLAY_NAME)
            return
    
    # Actually add the calculated grid to the mesh.
    _add_surface_array_to_mesh()



func _draw_isometric_surface_mesh():
    # Isometric grid is actually the same as horizontal triangles, just with a few less lines.
    if not isometric_mode_game:
        _draw_horizontal_triangle_surface_mesh(true)
        return
    
    # Map size needed to calculate mesh from 0 to the end of the map.
    var map_size = Global.World.WoxelDimensions

    # Makes sure that if you go too low in detail, the grid doesn't paint the screen black.
    # Simply upscales the visuals (the snap points stay the same)
    # Not a clean solution but this shouldn't be used anyway.
    var size_factor = mesh_size_multiplier / 2.0
    while min(snap_interval.x, snap_interval.y) * size_factor < 32:
        size_factor *= 2
    
    # Distance between triangles along the respective borders.
    var vertical_multiplier = snap_interval.x / snap_interval.y * 2.0
    var north_increment = snap_interval.x * 2.0 * size_factor
    var east_increment = snap_interval.y * size_factor
    var south_east = Vector2(vertical_multiplier, 1)
    var south_west = Vector2(-vertical_multiplier, 1)

    # Calculating mesh surfaces from the north border going south-east.
    var line_x = snap_offset.x - snap_offset.y * vertical_multiplier
    line_x = fposmod(line_x, north_increment)
    _draw_north_triangle_lines(line_x, south_east, north_increment)
    
    # Calculating mesh surfaces from the east border going south-east.
    var line_y = snap_offset.y - snap_offset.x / vertical_multiplier
    line_y = fposmod(line_y, east_increment)
    var base_vector = Vector2(0, line_y)
    _draw_east_triangle_lines(base_vector, south_east, east_increment)
    
    # Calculating mesh surfaces from the north border going south-west.
    line_x = snap_offset.x + snap_offset.y * vertical_multiplier
    line_x = fposmod(line_x, north_increment)
    # x_offset required to continue the lines along the east wall in the same direction
    var x_offset = _draw_north_triangle_lines(line_x, south_west, north_increment)
    
    # Calculating mesh surfaces from the east border going south-east.
    x_offset -= map_size.x
    line_y = x_offset / vertical_multiplier   # y_offset and fposmod is already indirectly included via x_offset
    base_vector = Vector2(map_size.x, line_y)
    _draw_east_triangle_lines(base_vector, south_west, east_increment)


# Helper function to provide ratios for hexagon radius distances
func _get_triangle_ratio() -> Vector2:
    if radial_mode_to_corner:
        return Vector2(sqrt(3), 1.5)
    else:
        return Vector2(2, sqrt(3))


# Calculates the vertices and UVs for a hexagonal grid displayed as triangles in vertical (point sideways) orientation.
# Rendering and calculation is fast since the amount of straight lines is in O(n)
# As a rule of thumb, any lines drawn always originate from the HIGHER end of the line.
func _draw_vertical_triangle_surface_mesh():
    # Map size needed to calculate mesh from 0 to the end of the map.
    var map_size = Global.World.WoxelDimensions

    # Makes sure that if you go too low in detail, the grid doesn't paint the screen black.
    # Simply upscales the visuals (the snap points stay the same)
    # Not a clean solution but this shouldn't be used anyway.
    var size_factor = mesh_size_multiplier / 2.0
    while min(snap_interval.x, snap_interval.y) * size_factor < 32:
        size_factor *= 2
    
    # Calculating mesh surfaces for horizontal lines. Simply loop till we're off the map.
    var line_y = fposmod(snap_offset.y, snap_interval.y * _get_triangle_ratio().x * size_factor / 2)
    while line_y <= map_size.y:
        var horizontal_a = Vector2(0, line_y)
        var horizontal_b = Vector2(map_size.x, line_y)
        _add_grid_mesh_triangles(horizontal_a, horizontal_b)
        # Since we're doing triangle meshes, we do half resolution to not clutter the map.
        line_y += snap_interval.y * _get_triangle_ratio().x * size_factor / 2
    
    # Distance between triangles along the respective borders.
    var vertical_multiplier = get_hexagon_size().x / get_hexagon_size().y
    var north_increment = get_hexagon_size().x * sqrt(3) * size_factor
    var east_increment = snap_interval.y * _get_triangle_ratio().x * size_factor
    var south_east = Vector2(1, sqrt(3) / vertical_multiplier)
    var south_west = Vector2(-1, sqrt(3) / vertical_multiplier)

    # Calculating mesh surfaces from the north border going south-east.
    var line_x = snap_offset.x - snap_offset.y * sqrt(3) / 3 * vertical_multiplier
    line_x = fposmod(line_x, north_increment)
    _draw_north_triangle_lines(line_x, south_east, north_increment)
    
    # Calculating mesh surfaces from the east border going south-east.
    line_y = snap_offset.y - snap_offset.x * sqrt(3) / vertical_multiplier
    line_y = fposmod(line_y, east_increment)
    var base_vector = Vector2(0, line_y)
    _draw_east_triangle_lines(base_vector, south_east, east_increment)
    
    # Calculating mesh surfaces from the north border going south-west.
    line_x = snap_offset.x + snap_offset.y * sqrt(3) / 3 * vertical_multiplier
    line_x = fposmod(line_x, north_increment)
    # x_offset required to continue the lines along the east wall in the same direction
    var x_offset = _draw_north_triangle_lines(line_x, south_west, north_increment)
    
    # Calculating mesh surfaces from the east border going south-east.
    x_offset -= map_size.x
    line_y = x_offset * sqrt(3) / vertical_multiplier   # y_offset and fposmod is already indirectly included via x_offset
    base_vector = Vector2(map_size.x, line_y)
    _draw_east_triangle_lines(base_vector, south_west, east_increment)



# Calculates the vertices and UVs for a hexagonal grid displayed as triangles in horizontal (point up) orientation.
# Rendering and calculation is fast since the amount of straight lines is in O(n)
# As a rule of thumb, any lines drawn always originate from the HIGHER end of the line.
func _draw_horizontal_triangle_surface_mesh(isometric = false):
    # Map size needed to calculate mesh from 0 to the end of the map.
    var map_size = Global.World.WoxelDimensions

    # Makes sure that if you go too low in detail, the grid doesn't paint the screen black.
    # Simply upscales the visuals (the snap points stay the same)
    # Not a clean solution but this shouldn't be used anyway.
    var size_factor = mesh_size_multiplier / 2.0
    while min(snap_interval.x, snap_interval.y) * size_factor < 32:
        size_factor *= 2
    
    # Calculating mesh surfaces for vertical lines. Simply loop till we're off the map.
    # If we're in isometric view, these are unwanted, so we don't draw them then.
    var line_x = fposmod(snap_offset.x, snap_interval.x * _get_triangle_ratio().x * size_factor / 2)
    if not isometric:
        while line_x <= map_size.x:
            var vertical_a = Vector2(line_x, 0)
            var vertical_b = Vector2(line_x, map_size.y)
            _add_grid_mesh_triangles(vertical_a, vertical_b)
            # Since we're doing triangle meshes, we do half resolution to not clutter the map.
            line_x += snap_interval.x * _get_triangle_ratio().x * size_factor / 2
    
    # Distance between triangles along the respective borders.
    var vertical_multiplier = get_hexagon_size().x / get_hexagon_size().y
    var north_increment = snap_interval.x * _get_triangle_ratio().x * size_factor
    var east_increment = get_hexagon_size().y * sqrt(3) * size_factor
    var south_east = Vector2(sqrt(3) * vertical_multiplier, 1)
    var south_west = Vector2(-sqrt(3) * vertical_multiplier, 1)

    # Calculating mesh surfaces from the north border going south-east.
    line_x = snap_offset.x - snap_offset.y * sqrt(3) * vertical_multiplier
    line_x = fposmod(line_x, north_increment)
    _draw_north_triangle_lines(line_x, south_east, north_increment)
    
    # Calculating mesh surfaces from the east border going south-east.
    var line_y = snap_offset.y - snap_offset.x / sqrt(3) / vertical_multiplier
    line_y = fposmod(line_y, east_increment)
    var base_vector = Vector2(0, line_y)
    _draw_east_triangle_lines(base_vector, south_east, east_increment)
    
    # Calculating mesh surfaces from the north border going south-west.
    line_x = snap_offset.x + snap_offset.y * sqrt(3) * vertical_multiplier
    line_x = fposmod(line_x, north_increment)
    # x_offset required to continue the lines along the east wall in the same direction
    var x_offset = _draw_north_triangle_lines(line_x, south_west, north_increment)
    
    # Calculating mesh surfaces from the east border going south-east.
    x_offset -= map_size.x
    line_y = x_offset / sqrt(3) / vertical_multiplier   # y_offset and fposmod is already indirectly included via x_offset
    base_vector = Vector2(map_size.x, line_y)
    _draw_east_triangle_lines(base_vector, south_west, east_increment)


# Draws lines for the triangle mesh originating from the north side, aiming down left and down right.
# Lines going the same direction but not touching the north border of the world are drawn by _draw_east_triangle_lines() instead.
# @return the final position as it is required to calculated to calculate the starting points
# for the lines continuing on the east wall in the south-western direction.
func _draw_north_triangle_lines(line_x, directional_vector, increment):
    # Starts looping at line_x and loops until line_x is outside the world.
    while line_x <= Global.World.WoxelDimensions.x:
        var base_vector = Vector2(line_x, 0)
        _draw_vector_line(base_vector, directional_vector)
        # Since we're doing triangle meshes, we do half resolution to not clutter the map.
        # We need to do half further, since these lines are at an angle to the axis we loop over.
        line_x += increment
    return line_x


# Draws lines for the triangle mesh originating from the east or west side, aiming downwards.
# Any upwards running lines are drawn by _draw_north_triangle_lines() instead.
func _draw_east_triangle_lines(base_vector, directional_vector, increment):
    if base_vector.y == 0:
        base_vector.y += increment
    while base_vector.y <= Global.World.WoxelDimensions.y:
        _draw_vector_line(base_vector, directional_vector)
        # Since we're doing triangle meshes, we do half resolution to not clutter the map.
        # We need to do half further, since these lines are at an angle to the axis we loop over.
        base_vector.y += increment


# Takes a base vector and directional vector, then draws a line originating from the base vector in that direction.
# The line always ends at the screen border.
# Lines should always go in a downwards direction
func _draw_vector_line(base_vector, directional_vector):
    var map_size = Global.World.WoxelDimensions
    var end_x = base_vector.x + (map_size.y - base_vector.y) * directional_vector.x / directional_vector.y
    var end_y = base_vector.y + (map_size.x - base_vector.x) * directional_vector.y / directional_vector.x
    if end_x > map_size.x:
        end_x = map_size.x
    else:
        end_y = map_size.y
    _add_grid_mesh_triangles(base_vector, Vector2(end_x, end_y))


# Calculates the vertices and UVs for a square grid.
# Both rendering and calculation are fast since it operates in O(n)
func _draw_square_surface_mesh():
    # Map size needed to calculate mesh from 0 to the end of the map.
    var map_size = Global.World.WoxelDimensions

    # Reduce mesh resolution for less clutter from grid lines.
    var dist_x = snap_interval.x * mesh_size_multiplier
    var dist_y = snap_interval.y * mesh_size_multiplier

    # Calculating mesh surfaces for vertical lines. Simply loop till we're off the map.
    var line_x = fposmod(snap_offset.x, dist_x)
    while line_x <= map_size.x:
        var vertical_a = Vector2(line_x, 0)
        var vertical_b = Vector2(line_x, map_size.y)
        _add_grid_mesh_triangles(vertical_a, vertical_b)
        line_x += dist_x

    # Calculating mesh surfaces for horizontal lines. Simply loop till we're off the map.
    var line_y = fposmod(snap_offset.y, dist_y)
    while line_y <= map_size.y:
        var horizontal_a = Vector2(0, line_y)
        var horizontal_b = Vector2(map_size.x, line_y)
        _add_grid_mesh_triangles(horizontal_a, horizontal_b)
        line_y += dist_y


# Calculates the vertices and UVs for a hexagonal grid in vertical orientation.
# While rendering is fast, the calculation is still somewhat slow and may cause lagg.
func _draw_vertical_surface_mesh():
    # Retrieving mesh and cleaning vanilla DD grid.
    var mesh = Global.World.get_child("GridMesh").get_mesh()
    mesh.clear_surfaces()
    
    # We make sure the snap interval can't be less than 64
    # Anything smaller than that is just gonna cause horrible performance.
    # Multiplying by mesh size also lets us control the size relative to the snap point interval.
    var clamped_interval = snap_interval * mesh_size_multiplier / 2.0
    var size = get_hexagon_size()
    while min(clamped_interval.x, clamped_interval.y) < 64:
        clamped_interval *= 2
        size *= 2


    # We tile caltrop shapes to form a hexagon grid. Three spikes per hexagon. These are the ends of the spikes relative to the middle vertex.
    var offset_e = Vector2(sqrt(3), 0) * size
    var offset_sw = Vector2(-sqrt(3) * 0.5, 1.5) * size
    var offset_nw = Vector2(-sqrt(3) * 0.5, -1.5) * size

    # The shape we use for tilings means we only gotta place it every second Hexagon in one direction, and twice per  hexagon in the other.
    var rows = Global.World.WoxelDimensions.y / size.y * 2 + 1
    var columns = Global.World.WoxelDimensions.x / size.x / 2 + 1

    # Since hexagons don't tile in a square, use a parallelogram shape.
    for q in range(columns):
        # Calculate the base vector for each spike.
        # Vertical arrangement only requires one caltrop every 3 hexagons
        # Horizontal arrangement on the other one one every hexagon
        var vec_x = sqrt(3) * q * 3
        var vec_y = 0
        # Move the base vector based on the grid interval and offset.
        var shifted_offset_x = fposmod(snap_offset.x, clamped_interval.x * _get_triangle_ratio().y * 2)
        shifted_offset_x -= clamped_interval.x * _get_triangle_ratio().y * 2
        var shifted_offset_y = fposmod(snap_offset.y, clamped_interval.y * _get_triangle_ratio().x)
        shifted_offset_y -= clamped_interval.y * _get_triangle_ratio().x
        # Move the base vector based on the grid interval and offset.
        var hex_origin = Vector2(vec_x, vec_y) * size + Vector2(shifted_offset_x, shifted_offset_y)
        
        # Apply the offsets and add the lines to the mesh.
        _add_grid_mesh_triangles(hex_origin, hex_origin + offset_e)
        _add_grid_mesh_triangles(hex_origin, hex_origin + offset_sw)
        _add_grid_mesh_triangles(hex_origin, hex_origin + offset_nw)

    # Initialising the surface array.
    var surface_array = []
    surface_array.resize(Mesh.ARRAY_MAX)

    # Gotta paint each vertex white. DD just tints the thing in a shader or the texture.
    var colours = PoolColorArray()
    for i in range(verts.size()):
        colours.append(Color.white)

    # Insert the subarrays into the surface array.
    surface_array[Mesh.ARRAY_VERTEX] = verts
    surface_array[Mesh.ARRAY_TEX_UV] = uvs
    surface_array[Mesh.ARRAY_COLOR] = colours
    
    # Adds the surface to the mesh.
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

    # Copy the surface for the first column of caltrop shapes into all other columns
    for r in range(rows):
        # Offset jiggle sideways since caltrops are staggered.
        var jiggle = Vector3(sqrt(3) * 1.5 * size.x, 1.5 * size.y, 0)
        if r % 2 == 0:
            jiggle = Vector3(-sqrt(3) * 1.5 * size.x, 1.5 * size.y, 0)

        # Add jiggles to all surfaces of the column
        for i in range(verts.size()):
            verts[i] = verts[i] + jiggle
        surface_array[Mesh.ARRAY_VERTEX] = verts
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)


# Calculates the vertices and UVs for a hexagonal grid in horizontal orientation.
# While rendering is fast, the calculation is still somewhat slow and may cause lagg.
func _draw_horizontal_surface_mesh():
    # Retrieving mesh and cleaning vanilla DD grid.
    var mesh = Global.World.get_child("GridMesh").get_mesh()
    mesh.clear_surfaces()

    # We make sure the snap interval can't be less than 64
    # Anything smaller than that is just gonna cause horrible performance.
    # Multiplying by mesh size also lets us control the size relative to the snap point interval.
    var clamped_interval = snap_interval * mesh_size_multiplier / 2.0
    var size = get_hexagon_size()
    while min(clamped_interval.x, clamped_interval.y) < 64:
        clamped_interval *= 2
        size *= 2

    # We tile caltrop shapes to form a hexagon grid. Three spikes per hexagon. These are the ends of the spikes relative to the middle vertex.
    var offset_s = Vector2(0, sqrt(3)) * size
    var offset_ne = Vector2(1.5, - sqrt(3) * 0.5) * size
    var offset_nw = Vector2(-1.5, -sqrt(3) * 0.5) * size

    # The shape we use for tilings means we only gotta place it every second Hexagon in one direction, and twice per  hexagon in the other.
    var rows = Global.World.WoxelDimensions.y / size.y / 2 + 1
    var columns = Global.World.WoxelDimensions.x / size.x * 2 + 1

    # Since hexagons don't tile in a square, use a parallelogram shape.
    for r in range(rows):
        # Calculate the base vector for each spike.
        # Horizontal arrangement only requires one caltrop every 3 hexagons
        # Vertical arrangement on the other one one every hexagon
        var vec_x = 0
        var vec_y = sqrt(3) * 3 * r
        # Move the base vector based on the grid interval and offset.
        var shifted_offset_x = fposmod(snap_offset.x, clamped_interval.x * _get_triangle_ratio().x)
        shifted_offset_x -= clamped_interval.x * _get_triangle_ratio().x
        var shifted_offset_y = fposmod(snap_offset.y, clamped_interval.y * _get_triangle_ratio().y * 2)
        shifted_offset_y -= clamped_interval.y * _get_triangle_ratio().y * 2
        var hex_origin = Vector2(vec_x, vec_y) * size + Vector2(shifted_offset_x, shifted_offset_y)

        # Apply the offsets and add the lines to the mesh.
        _add_grid_mesh_triangles(hex_origin, hex_origin + offset_s)
        _add_grid_mesh_triangles(hex_origin, hex_origin + offset_ne)
        _add_grid_mesh_triangles(hex_origin, hex_origin + offset_nw)

    # Initialising the surface array.
    var surface_array = []
    surface_array.resize(Mesh.ARRAY_MAX)

    # Gotta paint each vertex white. DD just tints the thing in a shader or the texture.
    var colours = PoolColorArray()
    for i in range(verts.size()):
        colours.append(Color.white)

    # Insert the subarrays into the surface array.
    surface_array[Mesh.ARRAY_VERTEX] = verts
    surface_array[Mesh.ARRAY_TEX_UV] = uvs
    surface_array[Mesh.ARRAY_COLOR] = colours
    
    # Adds the surface to the mesh.
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

    # Copy the surface for the first column of caltrop shapes into all other columns
    for q in range(columns):
        # Offset jiggle sideways since caltrops are staggered.
        var jiggle = Vector3(1.5 * size.x, sqrt(3) * 1.5 * size.y, 0)
        if q % 2 == 0:
            jiggle = Vector3(1.5 * size.x, -sqrt(3) * 1.5 * size.y, 0)
    
        # Add jiggles to all surfaces of the row
        for i in range(verts.size()):
            verts[i] = verts[i] + jiggle
        surface_array[Mesh.ARRAY_VERTEX] = verts
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)



# Adds the subarrays to the surface array and then to the mesh for rendering.
# TODO: We might be able to store the meshes for immediate rendering.
func _add_surface_array_to_mesh():
    # Retrieving mesh and cleaning vanilla DD grid.
    var mesh = Global.World.get_child("GridMesh").get_mesh()
    mesh.clear_surfaces()

    # Initialising the surface array.
    var surface_array = []
    surface_array.resize(Mesh.ARRAY_MAX)

    # Gotta paint each vertex white. DD just tints the thing in a shader or the texture.
    var colours = PoolColorArray()
    for i in range(verts.size()):
        colours.append(Color.white)

    # Insert the subarrays into the surface array.
    surface_array[Mesh.ARRAY_VERTEX] = verts
    surface_array[Mesh.ARRAY_TEX_UV] = uvs
    surface_array[Mesh.ARRAY_COLOR] = colours
    
    # Adds the surface to the mesh.
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)


# Appends the necessary values to the surface sub-arrays to render a line from @point_a to @point_b.
# Only creates the necessary arrays, which must then still be added to the surface array and subsequently the mesh.
# Points can be Vector2 or Vector3
func _add_grid_mesh_triangles(point_a, point_b):
    
    # The current zoom scale. Note that a zoom of 1.0 is not necessarily displayed as 100% in DD.
    # A higher value means the camera is zoomed out and sees a larger part of the canvas.
    # Since the DD vanilla grid works with clamped values, so will we.
    var zoom_scale = max(Global.Camera.zoom.x, 2.0)
    
    # Calculating the normalized perpendicular to the line, which is needed to give the surface width
    var diff = point_b - point_a
    var perpendicular = Vector3(-diff.y, diff.x, 0).normalized()
    perpendicular *= zoom_scale * 2
    # The UV length is used to scale the amount of the texture used to not be distorted.
    var uv_length = diff.length() / (zoom_scale * 4)

    # Calculating the four corner points of the line
    var corner_1 = Vector3(point_a.x, point_a.y, 0) + perpendicular
    var corner_2 = Vector3(point_a.x, point_a.y, 0) - perpendicular
    var corner_3 = Vector3(point_b.x, point_b.y, 0) + perpendicular
    var corner_4 = Vector3(point_b.x, point_b.y, 0) - perpendicular

    # The first triangle half of the square creating the line
    verts.append(corner_1)
    verts.append(corner_2)
    verts.append(corner_3)
    
    # The second triangle half of the square creating the line
    verts.append(corner_3)
    verts.append(corner_4)
    verts.append(corner_2)
    
    # This array gives each vertex a corresponding pixel in the source texture.
    # From there the shader computes which pixel of the surface corresponds to which pixel in the texture.
    # The UV is [(0, 0), (0, 1), (16 * length, 0), (16*length, 1)]
    # Where length is the length of the line being drawn in DD tiles
    var uv_1 = Vector2(0, 0)
    var uv_2 = Vector2(0, 1)
    var uv_3 = Vector2(uv_length, 0)
    var uv_4 = Vector2(uv_length, 1)

    # UVs for the first half of the square creating the line
    uvs.append(uv_1)
    uvs.append(uv_2)
    uvs.append(uv_3)

    # UVs for the second half of the square creating the line
    uvs.append(uv_3)
    uvs.append(uv_4)
    uvs.append(uv_2)




# =========================================================
# ANYTHING BEYOND THIS POINT IS FOR DEBUGGING PURPOSES ONLY
# =========================================================


## Creates the UI section for the debug tools
func _create_debug_section():
    # If in DEBUG_MODE, print buttons for:
    # Debug button that prints a lot of useful information
    if DEBUG_MODE:
        tool_panel.CreateSeparator()
        tool_panel.CreateLabel("Debug Tools")

        var debug_button = tool_panel.CreateButton("DEBUG", Global.Root + REWIND_ICON_PATH)
        debug_button.connect("pressed", self, "_on_debug_button")


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
        print(property.name + ": " + type_string(typeof(property)))
        if property is Object:
            print_properties(property)


## Debug function, prints methods of the given node
func print_methods(node):
    print("========= PRINTING METHODS OF %s ==========" % node.name)
    var method_list = node.get_method_list()
    for method in method_list:
        print(method.name)
        #print(method)


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