local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

discord:on("messageCreate", protect(function(message)
	if message.channel.id ~= channels["shades-bridge-cafe"].id then return end
	if not message.embed then return end

	p("[DEBUG] Received message from Shade's bot [cafe]")

	channels["br-tmp-cafe-report"]:send({
		content = message.content,
		embed = message.embed
	})

	message:delete()
end))