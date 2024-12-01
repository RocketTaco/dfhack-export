local util = {}

--Determine whether a numeric character code is a numeral in ASCII
local function isNum(x)
	if x >= 48 and x <= 57 then return true else return false end
end

util.string={}

--[[Compare two strings. TRUE if first comes before second in ordering, else
	FALSE. This comparison checks for number length on non-comparison, so for
	instance FOO4 comes before FOO35.
--]]
function util.string.natStrComp(a,b)
	--null-terminating the strings makes it easy to detect EOS rather than wrap;
	--We iterate through the longer string, and in case of overrunning the
	--shorter the null compares as less. This also prevents out-of-bounds.
	a = {string.byte(a, 1, string.len(a))}
	b = {string.byte(b, 1, string.len(b))}
	table.insert(a, 0)
	table.insert(b, 0)
	local length = #a > #b and #a or #b
	local result
	local aNum
	local bNum
	for i = 1, length do
		if a[i] ~= b[i] then
			--Record the winner in case the numbers end up being equal length
			result = a[i] < b[i]
			--First to have a non-numeral wins - if tie, numbers are same length
			--so use the earlier dissimilar digit as tiebreaker
			for k = i, length do
				aNum = isNum(a[k])
				bNum = isNum(b[k])
				if not aNum and not bNum then return result end
				if aNum and not bNum then return false end
				if bNum and not aNum then return true end
			end
			--Strings same length (no null compare), so use tiebreaker
			return result
		end
	end
	--Strings are equal
	return false
end

util.string={}

--Print a table recursively down to a depth of n
local function tostringHelper(dest, x, n, tabs)
	local first = true
	table.insert(dest, "{")
	for k,v in pairs(x) do
		if not first then table.insert(dest, ",")	end
		first = false
		table.insert(dest, "\n")
		for i = 1, tabs + 1 do table.insert(dest, "    ") end
		--print key
		if "string" == type(k) then
			if string.match(k, "[^%w]") then
				table.insert(dest, "[" .. string.format("%q", k) .. "]")
			else
				table.insert(dest, k)
			end
		else
			table.insert(dest, "[" .. tostring(k) .. "]")
		end
		table.insert(dest, " = ")

		--print value
		if "table" == type(v) or "userdata" == type(v) then
			if 1 == n then
				table.insert(dest, tostring(v))
			else
				tostringHelper(dest, v, n-1, tabs+1)
			end
		elseif "string" == type(v) then
			table.insert(dest, string.format("%q", v))
		else
			table.insert(dest, tostring(v))
		end
		
	end
	if not first then
		table.insert(dest, "\n")
		for i = 1, tabs do table.insert(dest, "    ") end
	end
	table.insert(dest, "}")
end

--Alternative to tostring() that deep-prints tables to a given depth n
function util.string.tostring(x, n)
	n = n or 1

	if "table" ~= type(x) and "userdata" ~= type(x) then
		return tostring(x)
	end

	local result = {}
	tostringHelper(result, x, n, 0)
	return table.concat(result)
end

--Alternative to print() that deep-prints tables to a given depth n
function util.print(x, n)
	print(util.string.tostring(x, n))
end

--Wrap text to a specified line length
function util.string.wordWrap(text, width)
	text = text .. " " --to guarantee last match
	local wrapped_text = {}
	local line_chars = 0
	local start = 1
	local new_chars, new_width
	for word, break_char in string.gmatch(text, "([^%s%-]-)([%s%-]+)") do
		if "-" == break_char then word = word .. "-" end
		new_chars = string.len(word)
		new_width = line_chars + new_chars
		--fits on current line
		if new_width < width then
			table.insert(wrapped_text, word)
			line_chars = new_width
		--exact match to current line
		elseif new_width == width then
			table.insert(wrapped_text, word)
			table.insert(wrapped_text, "\n")
			line_chars = 0
		--word too long for a line
		elseif new_chars >= width then
			while new_chars >= width do
				table.insert(wrapped_text, string.sub(word, 1, width))
				table.insert(wrapped_text, "\n")
				word = string.sub(word, width + 1)
				new_chars = string.len(word)
			end
			table.insert(wrapped_text, word)
			line_chars = new_chars
		--overflows current line, fits on next
		else
			table.insert(wrapped_text, "\n")
			table.insert(wrapped_text, word)
			line_chars = new_chars
		end

		--add spaces if not starting new line
		if line_chars ~= 0 and "-" ~= break_char then
			line_chars = line_chars + 1
			if line_chars == width then
				table.insert(wrapped_text, "\n")
				line_chars = 0
			else
				table.insert(wrapped_text, " ")
			end
		end
	end
	return table.concat(wrapped_text)
end

--Split a string to an array of printing lines
function util.string.lines(str)
	local lines = {}
		for l in string.gmatch(str, "[^\n]-\n") do
			table.insert(lines, l)
		end
	return lines
end

return util