local dfhack = require("dfhack")

local translate = {}

--Construct dictionary of DF tile shapes
local function buildShapeDict()
	local shape_dict = {}
	
	for i = df.tiletype_shape._first_item, df.tiletype_shape._last_item do
		shape_dict[df.tiletype_shape[i]] = i
	end
	
	return shape_dict
end

--Construct dictionary of DF material groups
local function buildMatClassDict()
	local mat_class_dict = {}
	
	for i = df.tiletype_material._first_item, df.tiletype_material._last_item do
		mat_class_dict[df.tiletype_material[i]] = i
	end
	
	return mat_class_dict
end

local mat_dict = buildMatClassDict()
local shape_dict = buildShapeDict()

local function checkLiquid(x, y, z)
	local flags = dfhack.maps.getTileFlags(x, y, z)
	if flags.flow_size > 4 then
		if flags.liquid_type then
			return "minecraft:lava"
		else
			return "minecraft:water"
		end
	end
	return "minecraft:air"
end

local grass_match = {
	[mat_dict.GRASS_LIGHT] = true,
	[mat_dict.GRASS_DARK]  = true,
	[mat_dict.GRASS_DRY]   = true,
	[mat_dict.GRASS_DEAD]  = true,
}

local function checkGrass(x, y, z)
--detect type above and make dirt/grass where appropriate
	local attrs = df.tiletype.attrs[dfhack.maps.getTileType(x, y, z+1)]
	if grass_match[attrs.material] then
		return "minecraft:grass_block[snowy=false]"
	else
		return "minecraft:dirt"
	end
end

local wall_map = {
	[mat_dict.STONE]   = "minecraft:stone",
	[mat_dict.MINERAL] = "minecraft:stone",
	[mat_dict.SOIL]    = checkGrass,
	[mat_dict.TREE]    = "minecraft:oak_log[axis=y]",
	[mat_dict.ROOT]    = checkGrass,
	[mat_dict.PLANT]   = "minecraft:tallgrass",
}

local shape_map = {
	[shape_dict.EMPTY]        = checkLiquid,
	[shape_dict.FLOOR]        = checkLiquid,
	[shape_dict.RAMP]         = checkLiquid,
	[shape_dict.WALL]         = wall_map,
	[shape_dict.TRUNK_BRANCH] = "minecraft:oak_log[axis=y]",
	[shape_dict.BRANCH]       = "minecraft:oak_leaves[distance=1,persistent=true,waterlogged=false]",
	[shape_dict.TWIG]         = "minecraft:oak_leaves[distance=1,persistent=true,waterlogged=false]",
	[shape_dict.SAPLING]      = "minecraft:sapling",
}

function translate.getMcBlock(x,y,z)
	local attrs = df.tiletype.attrs[dfhack.maps.getTileType(x,y,z)]
	
	local resp = shape_map[attrs.shape]
	if type(resp) == "string" then return resp end
	if type(resp) == "function" then return resp(x,y,z) end
	if type(resp) == "table" then
		resp = resp[attrs.material]
		if type(resp) == "string" then return resp end
		if type(resp) == "function" then return resp(x,y,z) end
	end
	return "minecraft:air"
end

return translate