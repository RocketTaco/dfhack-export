local dfhack = require("dfhack")
local argparse = require("argparse")
local util = dofile("hack/scripts/export/util.lua")

local args = {...}

function render32(val)
	local result = {}

	for i = 1, 4 do
		table.insert(result, string.char(val % 256))
		val = math.floor(val / 256)
	end
	
	return table.concat(result)
end

function bitmap(pixels)
	local y_size = #pixels
	local x_size = #pixels[1]
	local row_pad = 4 - ((3 * x_size) % 4) --padding to get rows to 4-byte multiple
	if 4 == row_pad then row_pad = 0 end
	
	local file_size = 54 + (y_size * ((3 * x_size) + row_pad)) --Bitmap header is 54 bytes
	row_pad = "" .. string.rep("\xFF", rowPad)
	
	local bmp = {
		"BM" ..               --file signature
		snapshot.render32(fileSize) ..	
		"\x00\x00\x00\x00" .. --reserved bytes
		"\x36\x00\x00\x00" .. --pixel array offset
		"\x28\x00\x00\x00" .. --DIB header size
		snapshot.render32(x_size) ..		
		snapshot.render32(y_size) ..		
		"\x01\x00" ..         --single color plane
		"\x18\x00" ..         --24 bpp
		"\x00\x00\x00\x00" .. --RGB, no compression
		"\x00\x00\x00\x00" .. --no data size specified
		"\xC4\x0E\x00\x00" .. --3780 pix/m horizontal
		"\xC4\x0E\x00\x00" .. --3780 pix/m vertical
		"\x00\x00\x00\x00" .. --no color palette
		"\x00\x00\x00\x00"    --all colors significant
	}
	
	for _,row in ipairs(pixels) do
		for _,pix in ipairs(row) do
			table.insert(bmp, pix)
		end
		table.insert(bmp, row_pad)
	end
	
	return table.concat(bmp)
end

local valid_args = {
	["minz"] = true,
	["maxz"] = true,
	["file"] = true,
}

local x_size
local y_size
local z_size
x_size, y_size, z_size = dfhack.maps.getTileSize()

print("Map size:")
print("X: " .. x_size)
print("Y: " .. y_size)
print("Z: " .. z_size)

local parsed = argparse.processArgs(args, valid_args)

for k,v in pairs(parsed) do
	print(tostring(k) .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
end

--Validate minimum Z-level to export
local minz = tonumber(parsed["minz"]) or 0
if(type(minz) ~= "number") then
	error("Argument \"minz\" not of number type")
end
--assert(minz >= 0, "Argument \"minz\" out of range; minimum Z height is 0")

--Validate maximum Z-level to export
local maxz = tonumber(parsed["maxz"]) or z_size
if(type(maxz) ~= "number") then
	error("Argument \"maxz\" not of number type")
end
--assert(maxz <= z_size, "Argument \"maxz\" out of range; maximumum Z height is " .. z_size)

--Get filename for output
local filename = tostring(parsed["file"])
if not filename then
	print("No output file specified: continuing in validate mode only")
end


local block_data = {}

for z = minz, maxz do
	local new_layer = {}
	for y = 1, y_size do
		local new_row = {}
		for x = 1, x_size do
			table.insert(new_row, dfhack.maps.getTileType(x,y,z))
		end
		table.insert(new_layer, new_row)
	end
	block_data[z] = new_layer
end


if filename then
	local file = io.open(filename, "w")
	if not file then
		error("Could not open file: " .. file)
	end
	
	file:write(util.string.tostring(block_data, 5))
	--[[
	for _,layer in ipairs(block_data) do
		for _,row in ipairs(layer) do
			for _,tile in ipairs(row) do
				print(tile)
			end
		end
	end
	--]]
	file:close()
end
