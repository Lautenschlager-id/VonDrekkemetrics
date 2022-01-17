local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

discord:on("messageCreate", protect(function(message)
	if message.channel.id ~= channels["shades-bridge"].id then return end

	channels["br-report"]:send({
		content = message.content,
		embed = message.embed
	})

	message:delete()
end))