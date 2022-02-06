local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")

local roleFlags = require("../utils/guild-roles")
local colors = require("../utils/enums/colors")
local reactions = require("../utils/enums/reactions")

local collateValidator = require("../services/collate-validator")

------------------------------------------- Optimization -------------------------------------------

local discord = require("../discord").discord

local discordChannels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

local badNamesChannel = discordChannels["int-bad-names"]
local compromisedAccountsChannel = discordChannels["int-compromised-accounts"]

return {
	channel = {
		[badNamesChannel.id] = true,
		[compromisedAccountsChannel.id] = true,
	},

	syntax = "collate",

	description = "Compiles all entries from #bad-names into one message.",

	execute = function(self, message, parameters)
		local roleFlags = roleFlags[badNamesChannel.guild.id]
		if not roleFlags then
			return utils.sendError(message, "COLLATE", "Forbidden command.",
				"This server is not ready to use this comand.")
		end

		if not message.member:hasRole(roleFlags["admins"])
			and discord.owner.id ~= message.author.id then
			return utils.sendError(message, "COLLATE", "Forbidden command.",
				"You don't have the permisison to use this command.")
		end

		local data = collateValidator.validateAllEntries(message)

		local response
		if message.channel.id == badNamesChannel.id then
			response = collateValidator.getBadNameResponse(data)
		elseif message.channel.id == compromisedAccountsChannel.id then
			response = collateValidator.getCompromisedAccountResponse(data)
		end

		response = utils.splitByLine(response)
		for line = 1, #response do
			message.member:send(response[line])
		end
	end
}