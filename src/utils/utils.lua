local temporaryObject = require("../services/commands").temporaryObject
local colors = require("./colors")

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

local sendError = function(message, command, err, description)
	temporaryObject[message.id] = message:reply({
		mention = message.author,
		embed = {
			color = colors.fail,
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

return {
	pairsByIndexes = pairsByIndexes,
	sendError = sendError,
	splitByLine = splitByLine,
	encodeUrl = encodeUrl
}