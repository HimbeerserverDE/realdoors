realdoors = {}
realdoors.v = "0.1"

local mp = minetest.get_modpath(minetest.get_current_modname())

dofile(mp .. "/mechanical.lua")
dofile(mp .. "/electronic.lua")
dofile(mp .. "/controllers.lua")

dofile(mp .. "/nodes.lua")

minetest.log("action", "[realdoors] Loaded all v" .. realdoors.v .. " files")
