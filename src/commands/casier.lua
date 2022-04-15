local casier = require("./struct/casier")

local utils = require("../utils/utils")
local reactions = require("../utils/enums/reactions")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../utils/discord-objects").channels

local forum = require("../forum").forum

local tostring = tostring

----------------------------------------------------------------------------------------------------

return {
	channel = {
		[discordChannels["br-utils"].id] = true,
		[discordChannels["br-report-forum"].id] = true,
		[discordChannels["br-report-game"].id] = true
	},

	syntax = "casier [nickname]",

	description = "Displays the avatar casier of a player.",

	usesForum = true,

	execute = function(self, message, parameters)
		parameters = tostring(parameters)
		if not utils.isPlayer(parameters) then
			message:addReaction(reactions.dnd)

			utils.sendError(message, "CASIER", "Invalid value for 'playerName'.",
				"The player '" .. parameters .. "' could not be found.")

			return
		end

		local data, success = casier.captureAvatarCasier(parameters)
		if not success then
			return utils.sendError(message, "CASIER", "Unknown error.", "Try again later.")
		end

		data = casier.processActivityData(data, 6)
		casier.displayAvatarCasier(message, parameters, data)

		message:addReaction(reactions.online)
	end
}