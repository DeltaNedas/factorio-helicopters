function getHeliPadIndexFromBaseEntity(ent)
	for i, v in ipairs(global.heliPads) do
		if v.baseEnt == ent then
			return i
		end
	end

	return nil
end

heliPad = 
{
	new = function(placementEnt)
		local obj = 
		{
			valid = true,

			replacedTiles = {},
			baseEnt = game.surfaces[1].create_entity
			{
				name = "heli-pad-entity",
				force = placementEnt.force,
				position = placementEnt.position,
			}
		}

		--game.players[1].print("calc: ".. tostring(placementEnt.position.y - heli_pad_sprite_y_shift).. " real pos: "..tostring(obj.baseEnt.position.y))
		--game.players[1].print(tostring(placementEnt.position.x) .. "|" .. tostring(placementEnt.position.y))

		local boundingBox = 
		{
			left_top = {placementEnt.position.x - 3.5, placementEnt.position.y - 3.5},
			right_bottom = {placementEnt.position.x + 3.5, placementEnt.position.y + 3.5}
		}

		game.surfaces[1].destroy_decoratives(boundingBox)

		local scorches = game.surfaces[1].find_entities_filtered
		{
			area = boundingBox,
			type = "corpse",
			name = "small-scorchmark",
		}

		for k,v in pairs(scorches) do
			v.destroy()
		end

		local tiles = {}
		for i = -3, 3 do
			obj.replacedTiles[i] = {}

			for j = -3, 3 do
				table.insert(tiles, 
				{
					name = "heli-pad-concrete", 
					position = {x = placementEnt.position.x + i, y = placementEnt.position.y + j} 
				})

				local oldTile = game.surfaces[1].get_tile(placementEnt.position.x + i, placementEnt.position.y + j)

				obj.replacedTiles[i][j] = {
					name = oldTile.name,
					position = oldTile.position
				}
			end
		end

		game.surfaces[1].set_tiles(tiles, true)

		placementEnt.destroy()
		return setmetatable(obj, {__index = heliPad})
	end,

	destroy = function(self)
		self.valid = false

		local restoredTiles = {}

		for i = -3, 3 do
			for j = -3, 3 do
				if game.surfaces[1].get_tile(self.baseEnt.position.x + i, self.baseEnt.position.y + j).name == "heli-pad-concrete" then
					table.insert(restoredTiles, self.replacedTiles[i][j])
				end
			end
		end

		game.surfaces[1].set_tiles(restoredTiles, true)
	end
}