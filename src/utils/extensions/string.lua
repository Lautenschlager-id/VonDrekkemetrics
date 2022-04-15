------------------------------------------- Optimization -------------------------------------------

local bit_rshift = bit.rshift

local str_byte = string.byte
local str_find = string.find
local str_format = string.format
local str_gmatch = string.gmatch
local str_gsub = string.gsub
local str_sub = string.sub

local tbl_concat = table.concat

local tonumber = tonumber

----------------------------------------------------------------------------------------------------

string.split = function(str, separator, raw)
	local out, counter = { }, 0

	local strPos = 1
	local i, j
	while true do
		i, j = str_find(str, separator, strPos, raw)
		if not i then break end
		counter = counter + 1
		out[counter] = str_sub(str, strPos, i - 1)
		out[counter] = tonumber(out[counter]) or out[counter]

		strPos = j + 1
	end
	counter = counter + 1
	out[counter] = str_sub(str, strPos)
	out[counter] = tonumber(out[counter]) or out[counter]

	return out, counter
end

do
	local charLength = function(byte)
		if bit_rshift(byte, 7) == 0x00 then
			return 1
		elseif bit_rshift(byte, 5) == 0x06 then
			return 2
		elseif bit_rshift(byte, 4) == 0x0E then
			return 3
		elseif bit_rshift(byte, 3) == 0x1E then
			return 4
		end
		return 0
	end

	string.utf8 = function(str)
		local utf8str = { }
		local index, append = 1, 0

		local charLen

		for i = 1, #str do
			repeat
				local char = str_sub(str, i, i)
				local byte = str_byte(char)
				if append ~= 0 then
					utf8str[index] = utf8str[index] .. char
					append = append - 1

					if append == 0 then
						index = index + 1
					end
					break
				end

				charLen = charLength(byte)
				utf8str[index] = char
				if charLen == 1 then
					index = index + 1
				end
				append = append + charLen - 1
			until true
		end

		return utf8str
	end
end

local splitByLine = function(content, max)
	max = max or 1850

	local data = {}

	if content == '' or content == "\n" then return data end

	local current, tmp = 1, ''
	for line in str_gmatch(content, "([^\n]*)[\n]?") do
		tmp = tmp .. line .. "\n"

		if #tmp > max then
			data[current] = tmp
			tmp = ''
			current = current + 1
		end
	end
	if #tmp > 0 then data[current] = tmp end

	return data
end

local strAutoEllipsis = function(str, maxLength)
	if #str <= maxLength then
		return str
	end

	str = tbl_concat(string.utf8(str), '', 1, maxLength - 3)
	return str .. "..."
end

return {
	splitByLine = splitByLine,
	strAutoEllipsis = strAutoEllipsis
}