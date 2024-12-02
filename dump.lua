local dfhack = require("dfhack")
local argparse = require("argparse")
local util = dofile("hack/scripts/export/util.lua")

local function dumpTileTypes(filename)
	local file = io.open(filename, "w")
	
	local first = df.tiletype._first_item
	local last  = df.tiletype._last_item
	for n = first, last do
		local val = df.tiletype.attrs[n]
		file:write(tostring(n) .. "\n")
		for k,v in pairs(val) do
			file:write(string.format("\t%s (%s) = %s (%s)\n", tostring(k), type(k), tostring(v), type(v)))
		end
	end
	file:close()
end

local function dumpTileMaterials(filename)
	local file = io.open(filename, "w")
	
	local first = df.tiletype_material._first_item
	local last  = df.tiletype_material._last_item
	
	for n = first, last do
		local val = df.tiletype_material.attrs[n]
		file:write(tostring(n) .. "\n")
		for k,v in pairs(val) do
			file:write(string.format("\t%s (%s) = %s (%s)\n", tostring(k), type(k), tostring(v), type(v)))
		end
	end
	file:close()
end

local function dumpTileShapes(filename)
	local file = io.open(filename, "w")
	
	local first = df.tiletype_shape._first_item
	local last  = df.tiletype_shape._last_item
	
	for n = first, last do
		local val = df.tiletype_shape.attrs[n]
		file:write(tostring(n) .. "\n")
		for k,v in pairs(val) do
			file:write(string.format("\t%s (%s) = %s (%s)\n", tostring(k), type(k), tostring(v), type(v)))
		end
	end
	file:close()
end

local function buildShapeDict()
	local shape_dict = {}
	
	for i = df.tiletype_shape._first_item, df.tiletype_shape._last_item do
		shape_dict[df.tiletype_shape[i]] = i
	end
	
	return shape_dict
end

local function buildMatClassDict()
	local mat_class_dict = {}
	
	for i = df.tiletype_material._first_item, df.tiletype_material._last_item do
		mat_class_dict[df.tiletype_material[i]] = i
	end
	
	return mat_class_dict
end

local args = {...}

local parsed = argparse.processArgs(args, valid_args)

local x = tonumber(parsed["x"])
local y = tonumber(parsed["y"])
local z = tonumber(parsed["z"])

if x and y and z then
	util.print(df.tiletype.attrs[dfhack.maps.getTileType(x,y,z)])
	util.print(dfhack.maps.getTileFlags(x,y,z))
end

file = io.open("out.txt", "w")
file:write("shape_dict = " .. util.string.tostring(buildShapeDict()) .. "\n")
file:write("mat_dict = " .. util.string.tostring(buildMatClassDict()) .. "\n")
file:close()

print("Dumping tile IDs...")
dumpTileTypes("df.tiletype.attrs.lua")
print("Dumping materials...")
dumpTileMaterials("df.tiletype_material.lua")
print("Dumping shapes...")
dumpTileShapes("df.tiletype_shape.lua")