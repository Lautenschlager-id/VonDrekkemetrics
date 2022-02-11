local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

local boundChannels = {
	karma = {
		xx = "int-report",
		br = "br-report"
	},

	event = {
		xx = "int-report",
		br = "br-report"
	},

	evento = {
		xx = "br-report"
	},

	br = {
		xx = "br-report"
	},

	pt = {
		xx = "br-report"
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
	if message.author.id ~= "261628653727776769" or not message.embed then return end

	p("[DEBUG] Received message from Wag's bot")

	channels["br-report"]:send({
		content = "__Wag's bridge__ ↓",
		embed = message.embed
	})
end))