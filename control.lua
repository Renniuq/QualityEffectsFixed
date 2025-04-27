local function stringStarts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

local machines = {}
for name, machine in pairs(prototypes.get_entity_filtered{{filter="type", type="assembling-machine"}}) do
    if machine.module_inventory_size > 0 and not stringStarts(name, "QualityEffects-") then
        machines[name] = true
    end
end

local function check_entity(entity_name)
    if machines[entity_name] ~= nil then return true end
    return false
end

-- lifted from BigContainersUPSPlus by Taurunti (https://mods.factorio.com/mod/BigContainersUPSPlus)
local function copy_circuit_connections(old, new)
  -- https://lua-api.factorio.com/stable/classes/LuaEntity.html#get_wire_connectors
  local connections = old.get_wire_connectors()
  --if (not connections) then return end

  for wire_id, luaWireConnector in pairs(connections) do
    local newLuaWireConnector = new.get_wire_connector(wire_id, true)

    for _, connection in ipairs(luaWireConnector.connections) do
      -- https://lua-api.factorio.com/stable/classes/LuaWireConnector.html#connect_to
      newLuaWireConnector.connect_to(connection.target)
    end
  end
end

local on_built = function (data)
    local entity = data.entity
    if not entity.quality then return end
    if entity.quality.level == 0 then return end
    if not check_entity(entity.name) then return end

    local surface = entity.surface
    local info = {
        name = "QualityEffects-" .. entity.quality.name .. "-" .. entity.name,
        position = entity.position,
        direction = entity.direction,
        quality = entity.quality,
        force = entity.force,
        fast_replace = true,
        player = entity.last_user,
        move_stuck_players = true,
        spill=true,
    }

    -- lifted from Factory Levels by sensenmann (https://mods.factorio.com/mod/factory-levels)
    local existing_requests = surface.find_entity("item-request-proxy", entity.position)
	if existing_requests then
		-- Module requests do not survive the machine being replaced.  Preserve them before the machine is replaced.
		item_requests = {}
		for module_name, count in pairs(existing_requests.item_requests) do
			item_requests[module_name] = count
		end
		if next(item_requests, nil) == nil then
			item_requests = nil
		end
	end

    local new_entity = surface.create_entity(info)
    copy_circuit_connections(entity, new_entity)
    new_entity.copy_settings(entity)
    if item_requests then
    	surface.create_entity({ name = "item-request-proxy",
								position = created.position,
								force = created.force,
								target = created,
								item-request-proxy = item_requests })
	end
    -- new_entity.set_recipe(entity.get_recipe())
    entity.destroy()
end

script.on_event(defines.events.on_built_entity, on_built, {{filter = "crafting-machine"}})
script.on_event(defines.events.on_robot_built_entity, on_built, {{filter = "crafting-machine"}})
script.on_event(defines.events.on_space_platform_built_entity, on_built, {{filter = "crafting-machine"}})
