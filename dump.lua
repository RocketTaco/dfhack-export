local dfhack = require("dfhack")
local util = dofile("hack/scripts/export/util.lua")

local material_groups = {
	NONE = df.tiletype_material.NONE,
	AIR = df.tiletype_material.AIR,
	SOIL = df.tiletype_material.SOIL,
	STONE = df.tiletype_material.STONE,
	FEATURE = df.tiletype_material.FEATURE,
	LAVA_STONE = df.tiletype_material.LAVA_STONE,
	MINERAL = df.tiletype_material.MINERAL,
	FROZEN_LIQUID = df.tiletype_material.FROZEN_LIQUID,
	CONSTRUCTION = df.tiletype_material.CONSTRUCTION,
	GRASS_LIGHT = df.tiletype_material.GRASS_LIGHT,
	GRASS_DARK = df.tiletype_material.GRASS_DARK,
	GRASS_DRY = df.tiletype_material.GRASS_DRY,
	GRASS_DEAD = df.tiletype_material.GRASS_DEAD,
	PLANT = df.tiletype_material.PLANT,
	HFS = df.tiletype_material.HFS,
	CAMPFIRE = df.tiletype_material.CAMPFIRE,
	FIRE = df.tiletype_material.FIRE,
	ASHES = df.tiletype_material.ASHES,
	MAGMA = df.tiletype_material.MAGMA,
	DRIFTWOOD = df.tiletype_material.DRIFTWOOD,
	POOL = df.tiletype_material.POOL,
	BROOK = df.tiletype_material.BROOK,
	RIVER = df.tiletype_material.RIVER,
	ROOT = df.tiletype_material.ROOT,
	TREE = df.tiletype_material.TREE,
	MUSHROOM = df.tiletype_material.MUSHROOM,
	UNDERWORLD_GATE = df.tiletype_material.UNDERWORLD_GATE,
}

local shape_groups = {
	EMPTY = df.tiletype_shape.EMPTY,
	FLOOR = df.tiletype_shape.FLOOR,
	BOULDER = df.tiletype_shape.BOULDER,
	PEBBLES = df.tiletype_shape.PEBBLES,
	WALL = df.tiletype_shape.WALL,
	FORTIFICATION = df.tiletype_shape.FORTIFICATION,
	STAIR_UP = df.tiletype_shape.STAIR_UP,
	STAIR_DOWN = df.tiletype_shape.STAIR_DOWN,
	STAIR_UPDOWN = df.tiletype_shape.STAIR_UPDOWN,
	RAMP = df.tiletype_shape.RAMP,
	RAMP_TOP = df.tiletype_shape.RAMP_TOP,
	BROOK_BED = df.tiletype_shape.BROOK_BED,
	BROOK_TOP = df.tiletype_shape.BROOK_TOP,
	BRANCH = df.tiletype_shape.BRANCH,
	TRUNK_BRANCH = df.tiletype_shape.TRUNK_BRANCH,
	TWIG = df.tiletype_shape.TWIG,
	SAPLING = df.tiletype_shape.SAPLING,
	SHRUB = df.tiletype_shape.SHRUB,
	ENDLESS_PIT = df.tiletype_shape.ENDLESS_PIT,
}

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

print(_VERSION)

file = io.open("out.txt", "w")

file:write(util.string.tostring(type(df.tiletype_material[1])) .. "\n")
file:write(util.string.tostring(df.tiletype_material[1]) .. "\n")
file:write(util.string.tostring(df.tiletype_material.attrs[1]) .. "\n")

file:write(util.string.tostring(type(df.tiletype_shape[1])) .. "\n")
file:write(util.string.tostring(df.tiletype_shape[1]) .. "\n")
file:write(util.string.tostring(df.tiletype_shape.attrs[1]) .. "\n")
file:write(util.string.tostring(df.tiletype_shape.FLOOR) .. "\n")

file:write("shape_dict = " .. util.string.tostring(buildShapeDict()) .. "\n")
file:write("mat_dict = " .. util.string.tostring(buildMatClassDict()) .. "\n")

for i = df.tiletype_shape._first_item, df.tiletype_shape._last_item do
	file:write(string.format("%d = %s\n", i, df.tiletype_shape[i]))
end

file:close()

print("Dumping tile IDs...")
dumpTileTypes("df.tiletype.attrs.lua")
print("Dumping materials...")
dumpTileMaterials("df.tiletype_material.lua")
print("Dumping shapes...")
dumpTileShapes("df.tiletype_shape.lua")