local _discord = require("../discord")
local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

local colors = require("../utils/colors")

local commands = {
	["help"] = true,
	["timezone"] = true,
	["translate"] = true,
	["list"] = true,
	["modo"] = true
}

local temporaryObject = setmetatable({ }, {
	__newindex = function(list, index, value)
		if value then
			if value.id then -- Single message
				value = { value }
			end

			-- Only store message IDs to improve memory usage
			for m = 1, #value do
				value[m] = value[m].id
			end

			rawset(list, index, value)
		end
	end
})

local loadCommands = function()
	local tmpAliases
	for command in next, commands do
		p("[LOAD] Command " .. command)
		commands[command] = require("../commands/" .. command)

		tmpAliases = commands[command].aliases
		if tmpAliases then
			for alias = 1, #tmpAliases do
				commands[tmpAliases[alias]] = command
			end
		end
	end
end

local getCommandAttempt = function(content)
	local command, parameters = string.match(content, "^!%s*(%S+)[\n ]+(.*)")
	command = command or string.match(content, "^!%s*(%S+)")
	command = string.lower(tostring(command))

	if not (command and commands[command]) then return end
	if type(commands[command]) == "string" then -- alias
		command = commands[command]
	end

	parameters = (parameters and parameters ~= '') and string.trim(parameters) or nil

	return commands[command], parameters, command
end

local checkCommandAttempt = function(message)
	local commandObj, parameters = getCommandAttempt(message.content)
	if not commandObj then return end

	if commandObj.channel then
		if not commandObj.channel[message.channel.id]
			and message.channel.id ~= channels["debug"].id then
			return utils.sendError(message, "403", "Access denied.", "You cannot use this \z
				command in this channel.", colors.error)
		end
	end

	commandObj:execute(message, parameters)
end

discord:once("ready", protect(function()
	p("[LOAD] Command Handler")

	loadCommands()
end))

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

return {
	commands = commands,
	temporaryObject = temporaryObject
}