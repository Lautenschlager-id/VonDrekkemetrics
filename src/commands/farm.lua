local temporaryObject = require("../utils/temporaryObject")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../utils/discord-objects").channels

local str_gmatch = string.gmatch

local table_concat = table.concat

----------------------------------------------------------------------------------------------------

return {
	channel = {
		[discordChannels["br-mod-utils"].id] = true,
		[discordChannels["int-mod-utils"].id] = true
	},

	syntax = "farm `text`",

	description = "Converts the results of your text into a list of nicknames.",

	execute = function(self, message, parameters)
		if not parameters then return end

		local names, index = { }, 0
		for name in str_gmatch(parameters, "(%S+#%d%d%d%d) / #") do
			index = index + 1
			names[index] = name
		end

		temporaryObject[message.id] = message:reply(table_concat(names, ','))
	end
}