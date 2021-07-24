if game.active_mods["IndustrialDisplayPlates"] then
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

  for _, id in pairs(rendering.get_all_ids("IndustrialDisplayPlates")) do
    local entity = rendering.get_target(id).entity
    local sprite = rendering.get_sprite(id);
    rendering.destroy(id)
    render_overlay_sprite(entity, sprite)
  end
end

