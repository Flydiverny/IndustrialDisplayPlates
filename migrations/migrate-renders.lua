if script.active_mods["IndustrialDisplayPlates"] then
  local function render_overlay_sprite(entity, sprite)
    if helpers.is_valid_sprite_path(sprite) then
      local size = (string.find(entity.name, "small") and 0.65) or (string.find(entity.name, "medium") and 1.5) or 2.5
      rendering.draw_sprite({
        sprite = sprite,
        x_scale = size,
        y_scale = size,
        render_layer = "lower-object",
        target = entity,
        surface = entity.surface,
      })
    end
  end

  for _, object in pairs(rendering.get_all_objects("IndustrialDisplayPlates")) do
    local entity = object.target.entity
    local sprite = object.sprite
    object.destroy()
    render_overlay_sprite(entity, sprite)
  end
end
