local dfhack = require("dfhack")
local argparse = require("argparse")
local util = dofile("hack/scripts/export/util.lua")
local mc = dofile("hack/scripts/export/mooncraft.lua")
local trans = dofile("hack/scripts/export/translate.lua")

local args = {...}

--Dump tile data as reexecutable Lua code for loading in an interpreter or other program
local function writeLua(bounds, filename)
	local file = io.open(filename, "w")
	if not file then
		error("Could not open file: " .. file)
	end
	
	local tile_data = {}

	for z = bounds.zmin, bounds.zmax do
		local new_layer = {}
		for y = bounds.ymin, bounds.ymax do
			local new_row = {}
			for x = bounds.xmin, bounds.xmax do
				table.insert(new_row, dfhack.maps.getTileType(x,y,z))
			end
			table.insert(new_layer, new_row)
		end
		table.insert(tile_data, new_layer)
	end
	
	file:write(util.string.tostring(tile_data, 5) .. "\n")
	file:close()
	return
end

--Write tile data to bitmap image format
local function writeBitmap(bounds, filename)
	local file = io.open(filename, "w")
	if not file then
		error("Could not open file: " .. file)
	end
	
	--TODO: tile_data -> pixels
	
	local y_size = #pixels
	local x_size = #pixels[1]
	local row_pad = 4 - ((3 * x_size) % 4) --padding to get rows to 4-byte multiple
	if 4 == row_pad then row_pad = 0 end
	
	local file_size = 54 + (y_size * ((3 * x_size) + row_pad)) --Bitmap header is 54 bytes
	row_pad = "" .. string.rep("\xFF", rowPad)
	
	local bmp = {
		"BM" ..               --file signature
		string.pack("I4", fileSize) ..
		"\x00\x00\x00\x00" .. --reserved bytes
		"\x36\x00\x00\x00" .. --pixel array offset
		"\x28\x00\x00\x00" .. --DIB header size
		string.pack("I4", x_size) ..
		string.pack("I4", y_size) ..
		"\x01\x00" ..         --single color plane
		"\x18\x00" ..         --24 bpp
		"\x00\x00\x00\x00" .. --RGB, no compression
		"\x00\x00\x00\x00" .. --no data size specified
		"\xC4\x0E\x00\x00" .. --3780 pix/m horizontal
		"\xC4\x0E\x00\x00" .. --3780 pix/m vertical
		"\x00\x00\x00\x00" .. --no color palette
		"\x00\x00\x00\x00"    --all colors significant
	}
	
	--TODO this might be reducible by table.concat if pixel types are already strings
	for _,row in ipairs(pixels) do
		for _,pix in ipairs(row) do
			table.insert(bmp, pix)
		end
		table.insert(bmp, row_pad)
	end
	
	file:write(table.concat(bmp))
	file:close()
end

--[[
	Creates a McDict object.
	This is a simple self-updating map of string keys to unique integers. Use it to build
	WorldEdit palettes. Index whatever string you want to look up. If it's been indexed before,
	you'll get the same value you got then. If it hasn't, the lowest unused integer will be
	assigned and you'll get that from now on. Since the table is clean (all non-entry data is
	stored as closure or metatable) you can feed this directly to writeWorldEditSchematic() as your
	block palette.
--]]
local function McDict()
	local size = 0
	local dict = {}
	local meta = {
		__index = function(t, k)
			rawset(t, k, size)
			size = size + 1
			return t[k]
		end,
		__newindex = function(t,k,v)
			error("Do not alter McDict entries directly")
		end,
		__len = function(t)
			return size
		end,
	}
	setmetatable(dict, meta)
	return dict
end

--Write tile data to a WorldEdit (Minecraft) schematic
local function writeWorldEdit(bounds, filename)
	local mc_blocks = {}
	local mc_dict = McDict()
	
	--All of these are declared outside loop to avoid create penalties, we do this a LOT
	local new_layer, new_row, attrs, block_type, lookup
	for z = bounds.zmin, bounds.zmax do
		new_layer = {}
		for y = bounds.ymin, bounds.ymax do
			new_row = {}
			for x = bounds.xmin, bounds.xmax do
				table.insert(new_row, mc_dict[trans.getMcBlock(x,y,z)])
			end
			table.insert(new_layer, new_row)
		end
		table.insert(mc_blocks, new_layer)
	end
	
	local result = mc.writeWorldEditSchematic(mc_blocks, mc_dict)
	local count = #mc_blocks * #mc_blocks[1] * #mc_blocks[1][1]
	
	file = io.open(filename, "wb")
	file:write(result)
	file:close()
	
	print(string.format("Output %d tiles in WorldEdit format to file \"%s\"\n", count, filename))
	return
end

--- END FUNCTION DEFINITIONS, BEGIN CONTENTS OF COMMAND ---

--List of arguments which can be given to the DF command invocation
local valid_args = {
	["x"]      = true,
	["y"]      = true,
	["z"]      = true,
	["file"]   = true,
	["format"] = true,
	["help"]   = true,
}

--Dictionary of output functions which can be given as --format arguments
local formats = {
	["lua"] = writeLua,
	["bmp"] = writeBitmap,
	["mc"]  = writeWorldEdit,
}

start_time = os.clock()

local parsed = argparse.processArgs(args, valid_args)

--Set up output
local filename = tostring(parsed["file"])
local format = tostring(parsed["format"])
if (not filename) or (not format) or parsed["help"] then
	print("TODO: usage")
	return
end

--Get area to export
x_size, y_size, z_size = dfhack.maps.getTileSize()
local bounds = {
	xmin = 0,
	xmax = x_size - 1,
	ymin = 0,
	ymax = y_size - 1,
	zmin = 0,
	ymax = y_size - 1,
}



if parsed["x"] then
	local x_str = tostring(parsed["x"])
	bounds.xmin, bounds.xmax = string.match(x_str, "^(%d+):(%d+)$")
	assert(bounds.xmax, "Unrecognized X bounds: " .. x_str)
	bounds.xmin = tonumber(bounds.xmin)
	bounds.xmax = tonumber(bounds.xmax)
	assert(bounds.xmin <= bounds.xmax, "X minimum cannot be higher than maximum")
	assert(bounds.xmax < x_size, "X boundary out of range (max " .. x_size .. ")")
end

if parsed["y"] then
	local y_str = tostring(parsed["y"])
	bounds.ymin, bounds.ymax = string.match(y_str, "^(%d+):(%d+)$")
	assert(bounds.ymax, "Unrecognized Y bounds: " .. y_str)
	bounds.ymin = tonumber(bounds.ymin)
	bounds.ymax = tonumber(bounds.ymax)
	assert(bounds.ymin <= bounds.ymax, "Y minimum cannot be higher than maximum")
	assert(bounds.ymax < y_size, "Y boundary out of range (max " .. y_size .. ")")
end

if parsed["z"] then
	local z_str = tostring(parsed["z"])
	bounds.zmin, bounds.zmax = string.match(z_str, "^(%d+):(%d+)$")
	assert(bounds.zmax, "Unrecognized Z bounds: " .. z_str)
	bounds.zmin = tonumber(bounds.zmin)
	bounds.zmax = tonumber(bounds.zmax)
	assert(bounds.zmin <= bounds.zmax, "Z minimum cannot be higher than maximum")
	assert(bounds.zmax < z_size, "Z boundary out of range (max " .. z_size .. ")")
end

export_func = formats[format]
assert(export_func, "Unknown format: " .. format)

export_func(bounds, filename)

print(string.format("%.02f seconds elapsed\n", os.clock() - start_time))
