realdoors.manager_formspec = "size[10,10]" ..
"field[1,1;2,1;doorname;Door name;]" ..
"button[3,0.7;2,1;dooradd;Add door]" ..
"button[5,0.7;2,1;doorrm;Remove door]" ..
"button[7,0.7;2,1;doorls;List doors]"

realdoors.manager_data_formspec = "size[4,4]" ..
"field[0.75,1;3,1;pos;Position;]" ..
"list[context;cardslot;1.5,1.85;1,1]" ..
"button_exit[1,3;2,1;submit;Submit]"

minetest.register_node("realdoors:manager", {
	description = "Manager",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.5, -0.25, 0.25, -0.4, 0.25},
		},
	},
	tiles = {"manager.png"},
	groups = {snappy = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", realdoors.manager_formspec)
		local inv = minetest.get_inventory({type = "node", pos = pos})
		inv:set_size("cardslot", 1)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		
	end,
})
