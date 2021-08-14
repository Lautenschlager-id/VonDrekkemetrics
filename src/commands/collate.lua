local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")

local roleFlags = require("../utils/guild-roles")
local colors = require("../utils/enums/colors")
local reactions = require("../utils/enums/reactions")

local badName = require("../services/bad-name-validator")

------------------------------------------- Optimization -------------------------------------------

local discord = require("../discord").discord

local discordChannels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

local badNamesChannel = discordChannels["int-bad-names"]

return {
	channel = {
		[badNamesChannel.id] = true
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

		local data = badName.validateAllEntries(message)
		message.member:send(badName.getResponse(data))
	end
}