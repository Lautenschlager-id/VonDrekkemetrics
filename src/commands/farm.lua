local temporaryObject = require("../utils/temporaryObject")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../utils/discord-objects").channels

local str_gmatch = string.gmatch

local table_concat = table.concat

----------------------------------------------------------------------------------------------------

local banCommand = "/banhack "
local messageLength = 255 - #banCommand + 1

return {
	channel = {
		[discordChannels["br-mod-utils"].id] = true,
		[discordChannels["int-mod-utils"].id] = true
	},

	syntax = "farm `text`",

	description = "Converts the results of your text into a list of nicknames.",

	execute = function(self, message, parameters)
		if not parameters then return end

		local names, mainIndex, subIndex = { { _len = 0 } }, 1, 0
		for name in str_gmatch(parameters, "(%S+#%d%d%d%d) / #") do
			local current = names[mainIndex]

			local len = current._len + #name + 1
			if len <= messageLength then
				current._len = len

				subIndex = subIndex + 1
				current[subIndex] = name
			else
				subIndex = 1
				mainIndex = mainIndex + 1
				names[mainIndex] = { _len = #name + 1, name }
			end
		end

		local messages, msgIndex = { }, 0
		for msg = 1, mainIndex do
			msgIndex = msgIndex + 1
			messages[msgIndex] = message:reply(table_concat(names[msg], ','))
		end

		temporaryObject[message.id] = messages
	end
}