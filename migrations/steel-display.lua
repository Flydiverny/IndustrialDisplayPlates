-- Unlock tech should match globals.lua, requiring it in here breaks interactive tutorials.

local DID = {
    displays = {
        ["iron-display-small"] = {
            IR_unlock = "ir2-iron-milestone"
        },
        ["iron-display-medium"] = {
            IR_unlock = "ir2-iron-milestone"
        },
        ["iron-display"] = {
            IR_unlock = "ir2-iron-milestone"
        },
        ["steel-display-small"] = {
            unlock = "steel-processing",
            IR_unlock = "ir2-steel-milestone"
        },
        ["steel-display-medium"] = {
            unlock = "steel-processing",
            IR_unlock = "ir2-steel-milestone"
        },
        ["steel-display"] = {
            unlock = "steel-processing",
            IR_unlock = "ir2-steel-milestone"
        }
    }
}


for index, force in pairs(game.forces) do
  for display, displaydata in pairs(DID.displays) do
    if displaydata.IR_unlock and force.technologies[displaydata.IR_unlock] and
      force.technologies[displaydata.IR_unlock].researched then
      force.recipes[display].enabled = true
    elseif displaydata.unlock and force.technologies[displaydata.unlock] and
      force.technologies[displaydata.unlock].researched then
      force.recipes[display].enabled = true
    end
  end
end
