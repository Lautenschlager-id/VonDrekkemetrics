local http = require("coro-http")

local temporaryObject = require("../utils/temporaryObject")
local colors = require("./colors")

local isPlayerCache = { }

string.split = function(str, separator, raw)
	local out, counter = { }, 0

	local strPos = 1
	local i, j
	while true do
		i, j = string.find(str, separator, strPos, raw)
		if not i then break end
		counter = counter + 1
		out[counter] = string.sub(str, strPos, i - 1)
		out[counter] = tonumber(out[counter]) or out[counter]

		strPos = j + 1
	end
	counter = counter + 1
	out[counter] = string.sub(str, strPos)
	out[counter] = tonumber(out[counter]) or out[counter]

	return out, counter
end

table.add = function(src, add)
	local len = #src
	for i = 1, #add do
		src[len + i] = add[i]
	end
end

table.arrayRange = function(arr, i, j)
	i = i or 1
	j = j or #arr

	local newArray = { }
	if i > j then
		return newArray
	end

	local counter = 0
	for v = i, j do
		counter = counter + 1
		newArray[counter] = arr[v]
	end

	return newArray
end

local pairsByIndexes = function(list, f)
	local out, counter = { }, 0
	for index in next, list do
		counter = counter + 1
		out[counter] = index
	end
	table.sort(out, f)

	local i = 0
	return function()
		i = i + 1
		if out[i] ~= nil then
			return out[i], list[out[i]]
		end
	end
end

local sendError = function(message, command, err, description, errColor)
	temporaryObject[message.id] = message:reply({
		mention = message.author,
		embed = {
			color = errColor or colors.fail,
			title = "Command [" .. command .. "] => " .. err,
			description = description
		}
	})
end

local encodeUrl = function(url)
	local out, counter = { }, 0

	for letter in string.gmatch(url, '.') do
		counter = counter + 1
		out[counter] = string.upper(string.format("%02x", string.byte(letter)))
	end

	return '%' .. table.concat(out, '%')
end

local splitByLine = function(content, max)
	max = max or 1850

	local data = {}

	if content == '' or content == "\n" then return data end

	local current, tmp = 1, ''
	for line in string.gmatch(content, "([^\n]*)[\n]?") do
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

local getParametersTableSplitByEqualsSign = function(parameters)
	local list = { }

	-- Bad code pls
	for _, regex in next, { "(%S+)%s*=%s*([^%[]%S*)", "(%S+)%s*=%s*(%b[])" } do
		for arg, value in string.gmatch(parameters, regex) do
			if string.sub(value, 1, 1) == '[' then
				value = string.split(string.sub(value, 2, -2), ',', true)
				for v = 1, #value do
					value[v] = string.trim(value[v])
				end
			else
				value = tonumber(value) or value
			end
			list[string.lower(arg)] = value
		end
	end

	return list
end

local isPlayer = function(playerName)
	if not isPlayerCache[playerName] then
		local _, body = http.request("GET", "https://atelier801.com/profile?pr=" ..
			encodeUrl(playerName), { { "Accept-Language", "en-US,en;q=0.9" } })

		isPlayerCache[playerName] = not string.find(body, "The request contains one or more invalid parameters")
	end
	return isPlayerCache[playerName]
end

local validatePlayersList = function(nicknames, defaultTag)
	local tmpNick
	for nick = 1, #nicknames do
		tmpNick = nicknames[nick]

		if string.sub(tmpNick, -5, -5) ~= '#' then
			tmpNick = tmpNick .. defaultTag
		end

		if not isPlayer(tmpNick) then
			return tmpNick
		end

		nicknames[nick] = tmpNick
	end
end

local getMonth = function(value)
	if value then
		value = tonumber(value)
		value = (value >= 1 and value <= 12 and value or nil)
	end
	return value or os.date("%m")*1
end

local getYear = function(value)
	local currentYear = os.date("%Y")*1
	if value then
		value = tonumber(value)
		value = (value >= currentYear-2 and value or nil)
	end
	return value or currentYear
end

local getMonthRange = function(month, year)
	local firstDayRange = os.time({
		day = 1,
		month = month,
		year = year
	})

	local nextMonth = month % 12 + 1
	if nextMonth < month then
		year = year + 1
	end

	local lastDayRange = os.time({
		day = 1,
		month = nextMonth,
		year = year,
		hour = 0,
		min = 0,
		sec = -1
	})

	return firstDayRange, lastDayRange
end

return {
	pairsByIndexes = pairsByIndexes,
	sendError = sendError,
	splitByLine = splitByLine,
	encodeUrl = encodeUrl,
	getParametersTableSplitByEqualsSign = getParametersTableSplitByEqualsSign,
	isPlayer = isPlayer,
	validatePlayersList = validatePlayersList,
	getMonth = getMonth,
	getYear = getYear,
	getMonthRange = getMonthRange
}