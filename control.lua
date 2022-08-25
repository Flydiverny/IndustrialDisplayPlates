------------------------------------------------------------------------------------------------------------------------------------------------------
-- DEADLOCK'S INDUSTRIAL DISPLAYS
-- Forked from Industrial Revolution, for your signage pleasure
------------------------------------------------------------------------------------------------------------------------------------------------------
-- constants
local DID = require("globals")

------------------------------------------------------------------------------------------------------------------------------------------------------

-- functions

local function get_global_player_info(player_index, info)
  if global[info] == nil then
    global[info] = {}
  end
  return global[info][player_index]
end

local function set_global_player_info(player_index, info, value)
  if global[info] == nil then
    global[info] = {}
  end
  global[info][player_index] = value
end

local function splitstring(s, d)
  local result = {};
  for m in (s .. d):gmatch("(.-)" .. d) do
    table.insert(result, m);
  end
  return result;
end

local function get_map_markers(entity)
  return entity.force.find_chart_tags(entity.surface, entity.bounding_box)
end

local function add_map_marker(entity, icon_type, icon_name)
  if icon_type and icon_name then
    local map_type = (icon_type == "virtual-signal") and "virtual" or icon_type
    entity.force.add_chart_tag(entity.surface, {
      icon = {
        type = map_type,
        name = icon_name
      },
      position = entity.position
    })
    entity.surface.play_sound {
      path = "map-marker-ping",
      position = entity.position,
      volume_modifier = 1
    }
  end
end

local function change_map_markers(entity, icon_type, icon_name)
  local map_type = (icon_type == "virtual-signal") and "virtual" or icon_type
  local markers = get_map_markers(entity)
  if markers then
    for _, marker in pairs(markers) do
      marker.icon = {
        type = map_type,
        name = icon_name
      }
    end
  end
end

local function get_has_map_marker(entity)
  return next(get_map_markers(entity)) ~= nil
end

local function remove_markers(entity)
  if entity and entity.valid then
    for _, marker in pairs(get_map_markers(entity)) do
      marker.destroy()
    end
  end
end

local function find_entity_render(entity)
  for _, id in pairs(rendering.get_all_ids(DID.mod_name)) do
    if rendering.get_target(id).entity == entity then
      return id
    end
  end
  return nil
end

local function get_render_sprite_info(entity)
  local id = find_entity_render(entity)
  if id then
    local strings = splitstring(rendering.get_sprite(id), "/")
    if #strings == 2 then
      return strings[1], strings[2], strings[1] == 'virtual-signal' and 'virtual' or strings[1]
    end
  end
  return nil, nil
end

local function gui_close(event)
  local player = game.players[event.player_index]
  local frame = player.gui.screen[DID.custom_gui]
  if frame then
    set_global_player_info(event.player_index, "display_gui_location", player.gui.screen[DID.custom_gui].location)
    return frame.destroy()
  end
  return false
end

local function render_overlay_sprite(entity, sprite)
  if game.is_valid_sprite_path(sprite) then
    local size = (string.find(entity.name, "small") and 0.65) or (string.find(entity.name, "medium") and 1.5) or 2.5
    rendering.draw_sprite {
      sprite = sprite,
      x_scale = size,
      y_scale = size,
      render_layer = "lower-object",
      target = entity,
      surface = entity.surface
    }
  end
end

local function render_overlay(entity, spritetype, spritename)
  render_overlay_sprite(entity, spritetype .. "/" .. spritename)
end

local function destroy_render(entity)
  local last_id = find_entity_render(entity)
  if last_id then
    rendering.destroy(last_id)
  end
end

local display_gui_click = {
  ["display-header-close"] = function(event)
    gui_close(event)
  end
}

local function is_a_display(entity)
  return DID.displays[entity.name] ~= nil
end

local function get_display_event_filter()
  local filters = {}
  for display, _ in pairs(DID.displays) do
    table.insert(filters, {
      filter = "name",
      name = display
    })
  end
  return filters
end

local function event_raised_destroy(event)
  if event.entity and event.entity.valid and is_a_display(event.entity) then
    -- remove any map markers
    remove_markers(event.entity)
    -- close any/all open guis
    for _, player in pairs(game.players) do
      local last_display = get_global_player_info(player.index, "last_display")
      local frame = player.gui.screen[DID.custom_gui]
      if frame and event.entity == last_display then
        frame.destroy()
      end
    end
  end
end

local function gui_click(event)
  -- is there a method for this element?
  local clicked = splitstring(event.element.name, ":")
  if display_gui_click[clicked[1]] then

    -- check the entity this gui refers to - in multiplayer it could have been removed while player wasn't logged in
    if event.player_index then
      local player = game.players[event.player_index]
      local frame = player.gui.screen[DID.custom_gui]
      local last_display = get_global_player_info(player.index, "last_display")
      if frame and (not last_display or not last_display.valid) then
        frame.destroy()
        return
      end
    end

    -- Call the click listener
    display_gui_click[clicked[1]](event, clicked[2])
    return
  end
end

local function gui_elem_changed(event)
  if event.element.name ~= "choose-signal" then
    return
  end
  -- check the entity this gui refers to - in multiplayer it could have been removed while player wasn't logged in
  local player = game.players[event.player_index]
  local last_display = get_global_player_info(player.index, "last_display")
  local frame = player.gui.screen[DID.custom_gui]
  if frame and (not last_display or not last_display.valid) then
    frame.destroy()
    return
  end

  if event.element.name == "choose-signal" then
    if event.element.elem_value == nil then
      -- Signal was deselected, cleanup and exit
      if last_display then
        destroy_render(last_display)
        if get_has_map_marker(last_display) then
          remove_markers(last_display)
        end
      end

      return
    end

    local spritename = event.element.elem_value.name or ''
    local typename = event.element.elem_value.type or ''
    local spritetype = typename == 'virtual' and 'virtual-signal' or typename
    local sprite = spritetype .. "/" .. spritename

    -- game.print("DisplayPlates: Plz help sprite: " .. sprite .. ' (' .. typename .. ") & (" .. spritename .. ")")
    -- for i, v in pairs(event.element.elem_value) do
    --   game.print("" .. i .. ' - ' .. v .. "")
    -- end

    if last_display then
      destroy_render(last_display)
      render_overlay_sprite(last_display, sprite)

      local switch = player.gui.screen[DID.custom_gui]["inner-frame"]["table"]["display-map-marker"]
      if (switch.switch_state == "right") then
        if get_has_map_marker(last_display) then
          change_map_markers(last_display, typename, spritename)
        else
          add_map_marker(last_display, typename, spritename)
        end
      end
    end
  end
end

local function gui_switch_state_changed(event)
  if event.element.name ~= "display-map-marker" then
    return
  end
  -- check the entity this gui refers to - in multiplayer it could have been removed while player wasn't logged in
  local player = game.players[event.player_index]
  local last_display = get_global_player_info(player.index, "last_display")
  local frame = player.gui.screen[DID.custom_gui]
  if frame and (not last_display or not last_display.valid) then
    frame.destroy()
    return
  end

  if event.element.name == "display-map-marker" then
    local last_display = get_global_player_info(event.player_index, "last_display")
    if last_display then

      if (event.element.switch_state == "left") then
        if get_has_map_marker(last_display) then
          remove_markers(last_display)
          local player = game.players[event.player_index]
          player.play_sound {
            path = "map-marker-pong"
          }
        end
      end

      if (event.element.switch_state == "right") then
        local spritetype, spritename = get_render_sprite_info(last_display)
        add_map_marker(last_display, spritetype, spritename)
      end
    end
  end
end

local function create_display_gui(player, selected)

  if not player or not selected then
    return
  end

  -- cache which entity this gui belongs to
  set_global_player_info(player.index, "last_display", selected)

  -- close any existing gui
  local frame = player.gui.screen[DID.custom_gui]
  if frame then
    frame.destroy()
  end
  player.opened = player.gui.screen

  -- get markers and currently rendered sprite
  local markers = next(get_map_markers(selected)) ~= nil
  local stype, sname, itype = get_render_sprite_info(selected)

  -- create frame
  frame = player.gui.screen.add {
    type = "frame",
    name = DID.custom_gui,
    direction = "vertical",
    style = "display_frame"
  }

  -- update frame location if cached
  if get_global_player_info(player.index, "display_gui_location") then
    frame.location = get_global_player_info(player.index, "display_gui_location")
  else
    frame.force_auto_center()
  end

  -- header
  local header = frame.add {
    type = "flow",
    direction = "horizontal",
    name = "display-header"
  }
  header.style.bottom_padding = -4
  header.style.horizontally_stretchable = true

  -- title
  header.add {
    type = "label",
    caption = {"controls.display-plate"},
    style = "frame_title"
  }

  -- "drag filler"
  local filler = header.add {
    type = "empty-widget",
    style = "draggable_space_header"
  }
  filler.style.natural_height = 24
  filler.style.minimal_width = 32
  filler.style.horizontally_stretchable = true
  filler.drag_target = frame

  -- close button
  local close_button = header.add {
    name = "display-header-close",
    type = "sprite-button",
    style = "display_small_button",
    sprite = "utility/close_white",
    tooltip = {"controls.close-gui"}
  }

  -- body frame
  local content_frame = frame.add {
    type = "frame",
    name = "inner-frame",
    style = "display_inside_frame",
    direction = "vertical"
  }
  content_frame.style.top_margin = 8

  local table = content_frame.add {
    type = "table",
    name = "table",
    column_count = 2
  }
  table.style.cell_padding = 2
  table.style.horizontally_stretchable = true
  table.style.bottom_padding = 8

  local label = table.add {
    type = "label",
    caption = {"controls.signal"}
  }
  label.style.top_margin = 5

  local choose_signal = table.add {
    type = "choose-elem-button",
    name = 'choose-signal',
    elem_type = "signal"
  }
  choose_signal.elem_value = (sname and stype) and {
    name = sname,
    type = itype
  } or nil

  local labelMap = table.add {
    type = "label",
    caption = {"controls.display-map-marker"}
  }
  labelMap.style.top_margin = 5
  -- map marker button
  table.add {
    name = "display-map-marker",
    type = "switch",
    switch_state = markers and "right" or "left",
    left_label_caption = {"controls.off"},
    right_label_caption = {"controls.on"},
    tooltip = {"controls.display-map-marker"}
  }
end

local function player_cannot_reach(player, entity)
  player.play_sound {
    path = "utility/cannot_build"
  }
  player.create_local_flying_text {
    text = {"cant-reach"},
    position = entity.position
  }
end

local function set_up_display_from_ghost(entity, tags)
  if tags["display-plate-sprite-type"] and tags["display-plate-sprite-name"] then
    render_overlay(entity, tags["display-plate-sprite-type"], tags["display-plate-sprite-name"])
    if tags["display-plate-sprite-map-marker"] then
      add_map_marker(entity, tags["display-plate-sprite-type"], tags["display-plate-sprite-name"])
    end
  end
end

-- local function reset_globals()
-- global.translations = nil
-- end

------------------------------------------------------------------------------------------------------------------------------------------------------

-- script.on_configuration_changed(reset_globals)
script.on_event(defines.events.on_gui_closed, gui_close)
script.on_event(defines.events.on_gui_elem_changed, gui_elem_changed)
script.on_event(defines.events.on_gui_switch_state_changed, gui_switch_state_changed)
script.on_event(defines.events.on_gui_click, gui_click)
script.on_event(defines.events.on_player_mined_entity, event_raised_destroy, get_display_event_filter())
script.on_event(defines.events.on_robot_mined_entity, event_raised_destroy, get_display_event_filter())
script.on_event(defines.events.on_entity_died, event_raised_destroy, get_display_event_filter())

script.on_event(defines.events.on_built_entity, function(event)
  if event.tags and event.created_entity and event.created_entity.valid then
    set_up_display_from_ghost(event.created_entity, event.tags)
  end
end, get_display_event_filter())

script.on_event(defines.events.on_robot_built_entity, function(event)
  if event.tags and event.created_entity and event.created_entity.valid then
    set_up_display_from_ghost(event.created_entity, event.tags)
  end
end, get_display_event_filter())

script.on_event(defines.events.script_raised_revive, function(event)
  if event.tags and event.entity and event.entity.valid and is_a_display(event.entity) then
    set_up_display_from_ghost(event.entity, event.tags)
  end
end)

script.on_event("deadlock-open-gui", function(event)
  local player = game.players[event.player_index]
  if player.cursor_stack and player.cursor_stack.valid_for_read then
    return
  end
  local selected = player and player.selected
  if selected and selected.valid and is_a_display(selected) then
    if player.can_reach_entity(selected) then
      create_display_gui(player, selected)
    else
      player_cannot_reach(player, selected)
    end
  end
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  if event.destination and event.destination.valid and event.source and event.source.valid and
    is_a_display(event.destination) and is_a_display(event.source) then
    local spritetype, spritename = get_render_sprite_info(event.source)
    if spritetype and spritename then
      destroy_render(event.destination)
      render_overlay(event.destination, spritetype, spritename)
      remove_markers(event.destination)
      if get_has_map_marker(event.source) then
        add_map_marker(event.destination, spritetype, spritename)
      end
    end
  end
end)

script.on_event(defines.events.on_player_setup_blueprint, function(event)
  local player = game.players[event.player_index]
  local blueprint = nil
  if player and player.blueprint_to_setup and player.blueprint_to_setup.valid_for_read then
    blueprint = player.blueprint_to_setup
  elseif player and player.cursor_stack.valid_for_read and player.cursor_stack.name == "blueprint" then
    blueprint = player.cursor_stack
  end
  if blueprint then
    for index, entity in pairs(event.mapping.get()) do
      local stype, sname = get_render_sprite_info(entity)
      if stype and sname then
        blueprint.set_blueprint_entity_tag(index, "display-plate-sprite-type", stype)
        blueprint.set_blueprint_entity_tag(index, "display-plate-sprite-name", sname)
        blueprint.set_blueprint_entity_tag(index, "display-plate-sprite-map-marker", get_has_map_marker(entity))
      end
    end
  end
end)

script.on_event(defines.events.on_gui_location_changed, function(event)
  if event.element.name == DID.custom_gui then
    set_global_player_info(event.player_index, "display_gui_location", event.element.location)
  end
end)

script.on_event(defines.events.on_player_changed_position, function(event)
  local player = game.players[event.player_index]
  if player.gui.screen[DID.custom_gui] then
    local last_display = get_global_player_info(event.player_index, "last_display")
    if last_display and last_display.valid and not player.can_reach_entity(last_display) then
      gui_close(event)
    end
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  if game.active_mods["IndustrialDisplayPlates"] then
    local player = game.players[event.player_index]
    game.print(
      "DisplayPlates: Renders should have been copied from IndustrialDisplayPlates, save the game, and disable IndustrialDisplayPlates for DisplayPlates to take over")
  end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------

remote.add_interface("DisplayPlates", {
    get_sprite = function(event)
        if event and event.entity and event.entity.valid then
            local spritetype, spritename = get_render_sprite_info(event.entity)
            return {
                spritetype = spritetype,
                spritename = spritename
            }
        else
            return nil
        end
    end,

    set_sprite = function(event)
        if event and event.entity and event.entity.valid and event.sprite and game.is_valid_sprite_path(event.sprite) then
            destroy_render(event.entity)
            render_overlay_sprite(event.entity, event.sprite)
        end
    end
})
