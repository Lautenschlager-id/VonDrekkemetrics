local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

local boundChannels = {
	karma = {
		xx = "debug",
		br = "br-report"
	},

	event = {
		xx = "debug",
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
	if meta[3] then
		msg.content = message.embed.description
	else
		msg.embed = message.embed
	end

	channelToPost:send(msg)

	message:delete()
end))