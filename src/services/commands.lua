local _discord = require("../discord")

local temporaryObject = require("../utils/temporaryObject")

local utils = require("../utils/utils")
local colors = require("../utils/enums/colors")

------------------------------------------- Optimization -------------------------------------------

local channels = require("../utils/discord-objects").channels

local discord, protect = _discord.discord, _discord.protect

local forum = require("../forum").forum

local str_match = string.match
local str_lower = string.lower
local str_trim = string.trim

local next = next

local tostring = tostring
local type = type

----------------------------------------------------------------------------------------------------

local commands = {
	["help"] = true,
	["timezone"] = true,
	["translate"] = true,
	["list"] = true,
	["modo"] = true,
	["senti"] = true,
	["reboot"] = true
}

--[[
	isAdminOnly = false, -- whether only bot admins can trigger the command

	syntax = "", -- command syntax
	descripton = "", -- command descripton

	aliases = { ... }, -- command aliases

	channel = { [...] = true }, -- channels in which the command can be triggered

	usesForum = true, -- whether the commands uses the forum (_BUSY)

	execute = fn(message, parameters)
]]

local loadCommands = function()
	p("[LOAD] Command Handler")

	local tmpAliases
	for command in next, commands do
		p("[LOAD] Command " .. command)
		commands[command] = require("../commands/" .. command)

		tmpAliases = commands[command].aliases
		if tmpAliases then
			for alias = 1, #tmpAliases do
				--commands[tmpAliases[alias]] = command
			end
		end
	end
end

local getCommandAttempt = function(content)
	local command, parameters = str_match(content, "^/%s*(%S+)[\n ]+(.*)")
	command = command or str_match(content, "^/%s*(%S+)")
	command = str_lower(tostring(command))

	if not (command and commands[command]) then return end
	if type(commands[command]) == "string" then -- alias
		command = commands[command]
	end

	parameters = (parameters and parameters ~= '') and str_trim(parameters) or nil

	return commands[command], parameters, command
end

local messageHasPermissionCommandTrigger = function(commandObj, message)
	if (commandObj.channel and (not commandObj.channel[message.channel.id]
			and message.channel.id ~= channels["debug"].id))
		or (commandObj.isAdminOnly and discord.owner.id ~= message.author.id)
	then
		utils.sendError(message, "403", "Access denied.", "You cannot use this \z
			command in this channel.", colors.error)
		return false
	end
	return true
end

local isForumAvailableCommandTrigger = function(commandObj, message)
	if commandObj.usesForum then
		if --[[not forum.isConnected() or]] forum._BUSY then
			utils.sendError(message, "503", "Service unavailable.", "Try again in a few \z
				minutes.")
			return false
		end

		local isConnected = forum.heartbeatOrReconnect()
		p("[FORUM DEBUG] isConnected", isConnected)
	end
	return true
end

local checkCommandAttempt = function(message)
	local commandObj, parameters = getCommandAttempt(message.content)
	if not commandObj then return end

	if
		messageHasPermissionCommandTrigger(commandObj, message)
		and isForumAvailableCommandTrigger(commandObj, message)
	then
		commandObj:execute(message, parameters)
	end
end

----------------------------------------------------------------------------------------------------

discord:once("ready", protect(loadCommands))

discord:on("messageCreate", protect(function(message)
	-- Ignore its own messages
	if message.author.id == discord.user.id then return end

	-- Skips bot messages
	if message.author.bot then return end

	checkCommandAttempt(message)
end))

discord:on("messageDelete", protect(function(message)
	if temporaryObject[message.id] then
		message.channel:bulkDelete(temporaryObject[message.id])
		temporaryObject[message.id] = nil
	end
end))

discord:on("messageUpdate", protect(function(message)
	discord:emit("messageDelete", message)
	discord:emit("messageCreate", message)
end))

return commands