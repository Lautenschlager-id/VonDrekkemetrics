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

		if message.channel.id == badNamesChannel.id then
			message.member:send(collateValidator.getBadNameResponse(data))
		elseif message.channel.id == compromisedAccountsChannel.id then
			message.member:send(collateValidator.getCompromisedAccountResponse(data))
		end
	end
}