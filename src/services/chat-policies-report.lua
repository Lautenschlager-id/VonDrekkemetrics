local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

local boundChannels = {
	karma = {
		xx = "int-report",
		br = "br-report-game"
	},

	event = {
		xx = "int-report",
		br = "br-report-game"
	},

	evento = {
		xx = "br-report-game"
	},

	br = {
		xx = "br-report-game"
	},

	pt = {
		xx = "br-report-game"
	},
}

discord:on("messageCreate", protect(function(message)
	if message.channel.id ~= channels["shades-bridge"].id then return end

	-- channelName, playerCommunity, postRaw
	local meta = string.split(message.content, ',')

	local channelToPost = boundChannels[meta[1]]
	channelToPost = channelToPost[meta[2]] or channelToPost.xx
	channelToPost = channels[channelToPost]

	local msg = {
		allowed_mentions = { parse = { } }
	}
	if meta[3] == "true" then
		msg.content = message.embed.description
	else
		msg.embed = message.embed
	end
	p("[DEBUG] Post Rule Processor Report", channelToPost.name, msg)

	channelToPost:send(msg)

	message:delete()
end))

discord:on("messageCreate", protect(function(message)
	-- Wag's karma bot
	if message.channel.id ~= channels["wag-bridge"].id then return end
	if not message.embed then return end

	p("[DEBUG] Received message from Wag's bot")

	channels["br-report-game"]:send({
		content = "__Wag's bridge__ ↓",
		embed = message.embed
	})

	message:delete()
end))