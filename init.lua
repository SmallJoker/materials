--Todo:
--	make stairsplus working
--	add more nodes
--	add textures

local enable_stairsplus = true	-- Enable stairsplus support (mod "moreblocks" required)

local modpath = minetest.get_modpath("materials")
local materials_nodes = {}
local materials_formspec = ""
local materials_opened_formspecs = {}
local current_mod_enabled = true

if enable_stairsplus then
	enable_stairsplus = minetest.get_modpath("moreblocks") ~= nil
	if not enable_stairsplus then
		print("[materials] Can not enable stairsplus. Mod 'moreblocks' not enabled/found.")
	end
end

-- Add a new materials node
function materials_add_node(real_name, desc, texture, node_groups, stairs)
	local name = "materials:"..string.gsub(real_name, ":", "_")
	if current_mod_enabled then
		minetest.register_alias(name, "default:stone")
		return
	end
	
	minetest.register_node(name, {
		description = desc.."*",
		tiles = { texture },
		groups = node_groups,
		sounds = default.node_sound_stone_defaults()
	})
	table.insert(materials_nodes, name)
end

local mod_list = io.open(modpath.."/depends.txt", "r")
for supported_mod in mod_list:lines() do
	if supported_mod ~= "" and supported_mod ~= "default" and supported_mod ~= "moreblocks?" then
		local mod_name = string.sub(supported_mod, 1, -2)
		current_mod_enabled = minetest.get_modpath(mod_name) ~= nil
		dofile(modpath.."/mod_"..mod_name..".lua")
	end
end

-- Make formspec
local form_x, form_y = 0, 2
for i, v in ipairs(materials_nodes) do
	materials_formspec = materials_formspec..
			"item_image_button["..form_x..","..form_y..";1,1;"..v..";mag$"..i..";]"
	form_x = form_x + 1
	if form_x == 14 then
		form_y = form_y + 1
		form_x = 0
	end
	if form_y > 6 then
		print("[materials] Too many nodes registered - can not display all of them.")
		break
	end
end
-- Add player inventory
materials_formspec = materials_formspec.."list[current_player;main;3,7;8,4;]"
-- End make formspec

minetest.register_node("materials:generator", {
	description = "Material Generator",
	tiles = {"materials_generator_top.png", "materials_generator_top.png", "materials_generator_side.png",
		"materials_generator_side.png", "materials_generator_side.png", "materials_generator_front.png"},
	paramtype2 = "facedir",
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("src", 2*2)	-- stone
		inv:set_size("src2", 2)		-- mese
		inv:set_size("dst", 2*2)	-- output
		
		meta:set_string("infotext", "Materials generator")
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		
		local name = stack:get_name()
		
		if listname == "src" then
			if name ~= "default:stone" then
				return 0
			end
		elseif listname == "src2" then
			if name ~= "default:mese_crystal_fragment" then
				return 0
			end
		elseif listname == "dst" then
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return stack:get_count()
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		-- get & send formspec
		local player_name = clicker:get_player_name()
		local name = "nodemeta:"..pos.x..","..pos.y..","..pos.z
		local formspec = ("size[14,11]"..
				"label[9.5,0;Materials generator]"..
				"label[2,1.4;<- Stone]"..
				"list["..name..";src;0,0;2,2;]"..
				"label[3,0.8;Mese fragments]"..
				"list["..name..";src2;3,0;2,1;]"..
				"label[5,1.4;Output ->]"..
				"list["..name..";dst;6,0;2,2;]"..
				"label[9.4,0.6;Press a button to convert\n33 stone to 6 new materials.]")
		formspec = formspec..materials_formspec
		materials_opened_formspecs[player_name] = pos
		minetest.show_formspec(player_name, "materials:generator_formspec", formspec)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		-- convert stone to X
		print(dump(fields))
	end,
	--on_submit...
})

minetest.register_on_player_receive_fields(function(sender, formname, fields)
	if formname ~= "materials:generator_formspec" then
		return
	end
	local player_name = sender:get_player_name()
	if fields.quit then
		materials_opened_formspecs[player_name] = nil
		return
	end
	
	local add_material = ""
	for field, _ in pairs(fields) do
		local current = string.split(field, "$", 2)
		if current[1] == "mag" then
			add_material = materials_nodes[tonumber(current[2])]
			break
		end
	end
	if add_material == "" then
		return
	end
	local pos = materials_opened_formspecs[player_name]
	local inv = minetest.get_meta(pos):get_inventory()
	
	if not inv:contains_item("src", "default:stone 33") then
		return
	end
	if not inv:contains_item("src2", "default:mese_crystal_fragment") then
		return
	end
	
	-- Add 6 of them
	add_material = add_material.." 6"
	if not inv:room_for_item("dst", add_material) then
		return
	end
	
	inv:remove_item("src", "default:stone 33")
	inv:remove_item("src2", "default:mese_crystal_fragment")
	inv:add_item("dst", add_material)
end)