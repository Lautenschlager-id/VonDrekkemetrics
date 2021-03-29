local http = require("coro-http")

local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")
local colors = require("../utils/colors")

return {
	syntax = "timezone [`country_code`]*",

	description = "Displays the timezone of a country.",

	execute = function(self, message, parameters)
		if not parameters or #parameters ~= 2 then
			return utils.sendError(message, "TIMEZONE", "Invalid or missing parameters.",
				"Use /" .. self.syntax .. ".")
		end
		parameters = string.upper(parameters)

		local head, body = http.request("GET", "https://pastebin.com/raw/di8TMeeG")
		if not body then
			return utils.sendError(message, "TIMEZONE", "Internal error.", "Try again later.")
		end

		body = load("return " .. body)() -- make it json some day
		if not body[parameters] then
			return utils.sendError(message, "TIMEZONE", "Country code not found",
				"Couldn't find '" .. parameters .. "'")
		end
		parameters = body[parameters]

		local currentTime = os.time()
		local timezones, counter = { }, 0
		for timezone = 1, #parameters do
			counter = counter + 1
			timezones[counter] = timezone .. " - **" .. parameters[timezone].zone .. "** - " ..
				os.date("%H:%M:%S `%d/%m/%Y`",
				currentTime + ((parameters[timezone].utc or 0) * 3600))
		end

		temporaryObject[message.id] = message:reply({
			embed = {
				color = colors.info,
				title = "🕐 " .. parameters[1].country,
				description = table.concat(timezones, "\n")
			}
		})
	end
}