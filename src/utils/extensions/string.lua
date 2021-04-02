------------------------------------------- Optimization -------------------------------------------

local str_find = string.find
local str_gmatch = string.gmatch
local str_sub = string.sub

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

return {
	splitByLine = splitByLine
}