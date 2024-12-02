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

local mc_grass_match = {
	[mat_dict.GRASS_LIGHT] = true,
	[mat_dict.GRASS_DARK]  = true,
	[mat_dict.GRASS_DRY]   = true,
	[mat_dict.GRASS_DEAD]  = true,
}

local mc_blocks = {
	air        = "minecraft:air",
	stone      = "minecraft:stone",
	dirt       = "minecraft:dirt",
	grass      = "minecraft:grass_block[snowy=false]",
	log        = "minecraft:oak_log[axis=y]",
	tall_grass = "minecraft:tallgrass",
	leaves     = "minecraft:oak_leaves[distance=1,persistent=true,waterlogged=false]",
	sapling    = "minecraft:sapling",
	water      = "minecraft:water",
	lava       = "minecraft:lava",
}

local function mc_checkLiquid(x, y, z)
	local flags = dfhack.maps.getTileFlags(x, y, z)
	if flags.flow_size > 4 then
		if flags.liquid_type then
			return mc_blocks.lava
		else
			return mc_blocks.water
		end
	end
	return mc_blocks.air
end

local function mc_checkGrass(x, y, z)
--detect type above and make dirt/grass where appropriate
	local attrs = df.tiletype.attrs[dfhack.maps.getTileType(x, y, z+1)]
	if mc_grass_match[attrs.material] then
		return mc_blocks.grass
	else
		return mc_blocks.dirt
	end
end

local mc_wall_map = {
	[mat_dict.STONE]   = mc_blocks.stone,
	[mat_dict.MINERAL] = mc_blocks.stone,
	[mat_dict.SOIL]    = mc_checkGrass,
	[mat_dict.TREE]    = mc_blocks.log,
	[mat_dict.ROOT]    = mc_checkGrass,
	[mat_dict.PLANT]   = mc_blocks.tall_grass,
}

local mc_shape_map = {
	[shape_dict.EMPTY]        = mc_checkLiquid,
	[shape_dict.FLOOR]        = mc_checkLiquid,
	[shape_dict.RAMP]         = mc_checkLiquid,
	[shape_dict.WALL]         = mc_wall_map,
	[shape_dict.TRUNK_BRANCH] = mc_blocks.log,
	[shape_dict.BRANCH]       = mc_blocks.leaves,
	[shape_dict.TWIG]         = mc_blocks.leaves,
	[shape_dict.SAPLING]      = mc_blocks.sapling,
}

function translate.getMcBlock(x,y,z)
	local attrs = df.tiletype.attrs[dfhack.maps.getTileType(x,y,z)]
	
	local resp = mc_shape_map[attrs.shape]
	if type(resp) == "string" then return resp end
	if type(resp) == "function" then return resp(x,y,z) end
	if type(resp) == "table" then
		resp = resp[attrs.material]
		if type(resp) == "string" then return resp end
		if type(resp) == "function" then return resp(x,y,z) end
	end
	return mc_blocks.air
end

--Note these pixels are in BGR order, NOT RGB
local bmp_colors = {
	white        = "\255\255\255",
	red          = "\0\0\255",
	green        = "\0\255\0",
	green_forest = "\64\128\0",
	green_yellow = "\29\230\181",
	blue         = "\255\0\0",
	blue_dark    = "\204\72\63",
	grey_dark    = "\92\92\92",
	grey_medium  = "\128\128\128",
	grey_light   = "\192\192\192",
	brown        = "\87\122\185",
	brown_light  = "\152\173\211",
	brown_yellow = "\128\128\128",
	black        = "\0\0\0",
}

local bmp_floor_map = {
	[mat_dict.STONE]       = bmp_colors.grey_light,
	[mat_dict.SOIL]        = bmp_colors.brown_light,
	[mat_dict.GRASS_LIGHT] = bmp_colors.green_forest,
	[mat_dict.GRASS_DARK]  = bmp_colors.green_forest,
	[mat_dict.GRASS_DRY]   = bmp_colors.green_forest,
	[mat_dict.GRASS_DEAD]  = bmp_colors.green_forest,
}

local function bmp_checkLiquid(x, y, z)
	local flags = dfhack.maps.getTileFlags(x, y, z)
	if flags.flow_size > 4 then
		if flags.liquid_type then
			return bmp_colors.red
		else
			return bmp_colors.blue_dark
		end
	end
	return bmp_floor_map[df.tiletype.attrs[dfhack.maps.getTileType(x, y, z)].material] or bmp_colors.white
end

local bmp_wall_map = {
	[mat_dict.STONE]   = bmp_colors.grey_medium,
	[mat_dict.MINERAL] = bmp_colors.grey_dark,
	[mat_dict.SOIL]    = bmp_colors.brown,
	[mat_dict.TREE]    = bmp_colors.brown_yellow,
	[mat_dict.ROOT]    = bmp_colors.brown_yellow,
	[mat_dict.PLANT]   = bmp_colors.green,
}

local bmp_shape_map = {
	[shape_dict.EMPTY]        = bmp_checkLiquid,
	[shape_dict.FLOOR]        = bmp_checkLiquid,
	[shape_dict.RAMP]         = bmp_checkLiquid,
	[shape_dict.WALL]         = bmp_wall_map,
	[shape_dict.TRUNK_BRANCH] = bmp_colors.brown_yellow,
	[shape_dict.BRANCH]       = bmp_colors.green_yellow,
	[shape_dict.TWIG]         = bmp_colors.green_yellow,
	[shape_dict.SAPLING]      = bmp_colors.green,
}

function translate.getPixel(x,y,z)
	local attrs = df.tiletype.attrs[dfhack.maps.getTileType(x,y,z)]
	
	local resp = bmp_shape_map[attrs.shape]
	if type(resp) == "string" then return resp end
	if type(resp) == "function" then return resp(x,y,z) end
	if type(resp) == "table" then
		resp = resp[attrs.material]
		if type(resp) == "string" then return resp end
		if type(resp) == "function" then return resp(x,y,z) end
	end
	return bmp_colors.white
end

return translate