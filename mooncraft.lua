
local util = dofile("hack/scripts/export/util.lua")

local mc = {}

--[[
	The tag type list contains one member for each NBT data object type. Each tag must have the
	following fields:
		name   Human-identifiable string name for reading data dumps
		id     Type identifier byte used to indicate this data format in NBT
		read   Function to process binary file data and return a usable Lua object.
		       Takes the data buffer and index of first byte being interpreted as this object.
		       Returns index of first byte following this object.
		write  Function to turn a properly tagged Lua object into binary file data.
		       Takes the Lua object to be serialized.
		       Returns a raw string of the serialized data.
	A reverse-lookup table is also provided in tag_lookup to identify the correct handlers from the
	ID tags in encoded data. DO NOT MODIFY THESE TABLES OR THEIR CHILDREN AT RUNTIME.
--]]
local tag
local tag_lookup
tag = {
	End       = {
		name = "End",
		id   = 0,
		
		read = function(data, index)
			return nil, index
		end,
		
		write = function(tag)
			return "\0"
		end
	},
	Byte      = {
		name = "Byte",
		id   = 1,
		
		read = function(data, index)
			local result = {value = string.unpack("B", data, index)}
			result.tag_type = tag.Byte
			return result, index + 1
		end,
		
		write = function(tab)
			return string.pack("B", tab.value)
		end
	},
	Short     = {
		name = "Short",
		id   = 2,
		
		read = function(data, index)
			local result = {value = string.unpack(">I2", data, index)}
			result.tag_type = tag.Short
			return result, index + 2
		end,
		
		write = function(tab)
			return string.pack(">I2", tab.value)
		end
	},
	Int       = {
		name = "Int",
		id   = 3,
		
		read = function(data, index)
			local result = {value = string.unpack(">I4", data, index)}
			result.tag_type = tag.Int
			return result, index + 4
		end,
		
		write = function(tab)
			return string.pack(">I4", tab.value)
		end
	},
	Long      = {
		name = "Long",
		id   = 4,
		
		read = function(data, index)
			local result = {value = string.unpack(">I8", data, index)}
			result.tag_type = tag.Long
			return result, index + 8
		end,
		
		write = function(tab)
			return string.pack("I8", tab.value)
		end
	},
	Float     = {
		name = "Float",
		id   = 5,
		
		read = function(data, index)
			local result = {value = string.unpack(">f", data, index)}
			result.tag_type = tag.Float
			return result, index + 4
		end,
		
		write = function(tab)
			return string.pack(">f", tab.value)
		end
	},
	Double    = {
		name = "Double",
		id   = 6,
		
		read = function(data, index)
			local result = {value = string.unpack(">d", data, index)}
			result.tag_type = tag.Double
			return result, index + 8
		end,
		
		write = function(tab)
			return string.pack(">d", tab.value)
		end
	},
	ByteArray = {
		name = "ByteArray",
		id   = 7,
		
		read = function(data, index)
			local result = {value = {}}
			local length = string.unpack(">i4", data, index)
			index = index + 4
			for i = 1, length do
				result.value[i] = string.byte(data, index)
				index = index + 1
			end
			
			result.tag_type = tag.ByteArray
			return result, index
		end,
		
		write = function(tag)
			local result = {}
			local count = 0
			for i, v in ipairs(tag.value) do
				result[i + 1] = string.char(v)
				count = i
			end
			result[1] = string.pack(">i4", count)
			return table.concat(result)
		end
	},
	String    = {
		name = "String",
		id   = 8,
		
		read = function(data, index)
			local length = string.unpack(">I2", data, index)
			index = index + 2
			local result = {value = string.sub(data, index, index + length - 1)}
			result.tag_type = tag.String
			return result, index + length
		end,
		
		write = function(tab)
			return string.pack(">I2", #tab.value) .. tab.value
		end
	},
	List      = {
		name = "List",
		id   = 9,
		
		read = function(data, index)
			local result = {value = {}}
			local val_id = string.byte(data, index)
			local val_type = tag_lookup[val_id]
			if not val_type then
				error("Unknown value type in list at byte: " .. index .. ": " .. val_id)
			end
			
			local length = string.unpack(">i4", data, index + 1)
			index = index + 3
			
			for i = 1, length do
				result.value[i], index = val_type.read(data, index) 
			end
			
			result.data_type = val_type
			result.tag_type = tag.List
			return result, index
		end,
		
		write = function(tag)
			local result = {}
			local count = 0
			for i, v in ipairs(tag.value) do
				result[i + 1] = tag.data_type.write(v)
				count = i
			end
			result[1] = string.pack(">Bi4", tag.data_type.id, count)
			return table.concat(result)
		end
	},
	Compound  = {
		name = "Compound",
		id   = 10,
		
		read = function(data, index)
			local result = {value = {}}
			local name_len
			local tag_type
			while(index < #data) do
				--Pull the leading data for the next object
				tag_type = string.byte(data, index)
				index = index + 1
				
				--Get the reader for that tag type
				tag_type = tag_lookup[tag_type]
				if not tag_type then
					error("Unknown tag type at byte " .. index .. ": " .. tag_type)
				end
				
				--Detect end of tag and produce
				if(tag_type == tag.End) then
					result.tag_type = tag.Compound
					return result, index
				end
				
				--Get the associated name
				name_len = string.unpack(">I2", data, index)
				index = index + 2
				name = string.sub(data, index, index + name_len - 1)
				if result.value[name] then
					error("Duplicate tag at byte " .. index .. ": " .. name)
				end
			
				--Read the data object and record it
				index = index + name_len
				result.value[name], index = tag_type.read(data, index)
			end
			
			error("Data ended with unclosed compound tag")
		end,
		
		write = function(tag)
			local result = {}
			for k,v in pairs(tag.value) do
				assert(type(k) == "string", "Non-string index cannot be converted to NBT tag name")
				table.insert(result, string.pack(">BI2", v.tag_type.id, #k))
				table.insert(result, k)
				table.insert(result, v.tag_type.write(v))
			end
			table.insert(result, '\0')
			return table.concat(result)
		end
	},
	IntArray  = {
		name = "IntArray",
		id   = 11,
		
		read = function(data, index)
			local result = {value = {}}
			local length = string.unpack(">i4", data, index)
			for i = 1, length do
				result.value[i] = string.unpack(">i4", data, index + (4 * i))
			end
			
			result.tag_type = tag.IntArray
			return result, index + 4 + (4 * length)
		end,
		
		write = function(tag)
			local result = {}
			local count
			for i, v in ipairs(tag.value) do
				result[i + 1] = string.pack(">i4", v)
				count = i
			end
			result[1] = string.pack(">i4", count)
			return table.concat(result)
		end
	},
	LongArray = {
		name = "LongArray",
		id   = 12,
		
		read = function(data, index)
			local result = {value = {}}
			local length = string.unpack(">i4", data, index)
			for i = 1, length do
				result[i] = string.unpack(">i8", data, index + (8 * i))
			end
			
			result.tag_type = tag.LongArray
			return result, index + 4 + (8 * length)
		end,
		
		write = function(tag)
			local result = {}
			local count
			for i, v in ipairs(tag) do
				result[i + 1] = string.pack(">i8", v)
				count = i
			end
			result[1] = string.pack(">i4", count)
			return table.concat(result)
		end
	}
}
mc.tag = tag

tag_lookup = {
	[tag.End.id]       = tag.End,
	[tag.Byte.id]      = tag.Byte,
	[tag.Short.id]     = tag.Short,
	[tag.Int.id]       = tag.Int,
	[tag.Long.id]      = tag.Long,
	[tag.Float.id]     = tag.Float,
	[tag.Double.id]    = tag.Double,
	[tag.ByteArray.id] = tag.ByteArray,
	[tag.String.id]    = tag.String,
	[tag.List.id]      = tag.List,
	[tag.Compound.id]  = tag.Compound,
	[tag.IntArray.id]  = tag.IntArray,
	[tag.LongArray.id] = tag.LongArray
}
mc.tag_lookup = tag_lookup

--[[
	Transform an NBT-encoded binary file into a usable Lua structure.
	Each data object will be encoded as a table with a field "value" containing either, depending on
	the object type: 1. the	retrieved value, if it is singular; 2. an array	of values or 3. a series
	of key-value pairs. The field "tag_type" indicates the NBT format the data was sourced from.
	List types will also have "data_type" indicating the format the values were sourced from.
--]]
function mc.readNBT(raw)
	local struct = mc.tag_lookup[string.byte(raw, 1)].read(raw, 1)
	return struct.value[""]
end

--[[
	Transform a tagged Lua structure into NBT binary encoding.
	Every data item must be marked with the NBT tag type it is stored as. Refer to the output of a
	call to readNBT() for what this looks like - every data object will be a table with the subfield
	"value" containing the actual data and the subfield "tag_type" which should be set to one of the
	members of mc.tag. List objects must also contain "data_type", also set to a mc.tag member, that
	indicates the type of the objects it contains.
--]]
function mc.writeNBT(src)
	assert(src ~= nil, "No data provided")
	
	return string.pack(">BI2", tag.Compound.id, 0) .. src.tag_type.write(src)
end

--[[
	For block IDs, try https://minecraft-ids.grahamedgecombe.com/
--]]
function mc.writeWorldEditSchematic(blocks, dict)
	local block_array = {}
	local block_palette = {}

	for _, layer in ipairs(blocks) do
		for _, row in ipairs(layer) do
			for _, block in ipairs(row) do
				table.insert(block_array, block)
			end
		end
	end
	
	for k, v in pairs(dict) do
		block_palette[k] = {tag_type = tag.Int, value = v}
	end

	local schem = { tag_type = tag.Compound, value = {
		Schematic = { tag_type = tag.Compound, value = {
			Version     = { tag_type = tag.Int,      value = 3 },
			DataVersion = { tag_type = tag.Int,      value = 4082 }, -- It's not clear what this means, obtained from WorldEdit saves
			Offset  = { tag_type = tag.IntArray,     value = {0, 0, 0} },
			Height  = { tag_type = tag.Short,        value = #blocks },
			Length  = { tag_type = tag.Short,        value = #blocks[1] },
			Width   = { tag_type = tag.Short,        value = #blocks[1][1] },
			Metadata    = { tag_type = tag.Compound, value = {
				Date      = { tag_type = tag.Long,     value = os.time()},
				WorldEdit = { tag_type = tag.Compound, value = {
					Version         = {tag_type = tag.String,    value = "(unknown)" },
					Origin          = {tag_type = tag.IntArray,  value = {0, 0, 0} },
					EditingPlatform = {tag_type = tag.String,    value = "enginehub:forge" },
					Platforms       = { tag_type = tag.Compound, value = {
						["enginehub:forge"] = { tag_type = tag.Compound, value = {
							Version = { tag_type = tag.String, value = "7.3.9+6959-7adf70b" },
							Name    = { tag_type = tag.String, value = "Forge-Official" },
						}},
					}},
				}},
			}},
			Blocks  = { tag_type = tag.Compound, value = {
				Data          = { tag_type = tag.ByteArray, value = block_array },
				Palette       = { tag_type = tag.Compound,  value = block_palette },
				BlockEntities = { tag_type = tag.List,  data_type = tag.Compound, value = {} },
				
			}},
		}},
	}}
	
	return mc.writeNBT(schem)
end

return mc