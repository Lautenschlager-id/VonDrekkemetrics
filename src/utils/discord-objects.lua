local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local next = next

----------------------------------------------------------------------------------------------------

local channels = {
	-- Int Staff
	["int-main"] = "800100513718075414", -- #staff-utils
	["int-breach"] = "814497990948814918", -- #data-breaches
	["int-sent-only"] = "835519281427906611", -- #senti-only
	["int-mod-utils"] = "865271568984440853", -- #mod-utils
	["int-bad-names"] = "872921934818594826", -- #bad-names
	["int-compromised-accounts"] = "872922245645889616", -- #compromised-accounts
	["int-patch-notes"] = "902137628718145557", -- #patch-notes
	["int-report"] = "935823003332263936", -- #reports-auto

	-- Br Staff
	["br-utils"] = "826082697185198140", -- #bot-utils
	["br-mod-utils"] = "864920454192300042", -- #mod-utils
	["br-senti"] = "421763072722599967", -- #sentinelas
	["br-modsents"] = "727175201552466010", -- #modsents
	["br-report"] = "421763648252542976", -- #aovivonojogo

	-- Debug
	["debug"] = "818016844522586123", -- #von-drekkemetrics
	["shades-bridge"] = "930925530281279489", -- #shades-von
	["wag-bridge"] = "941899224239460362", -- #wag-von
}

local guilds = {

}

local getChannelAndGuildObjects = function()
	p("[LOAD] Get Channel and Guild Objects")
	for name, id in next, channels do
		repeat
			channels[name] = discord:getChannel(id)
		until channels[name]
		name = channels[name]

		-- Populates Guilds as well
		if not guilds[name.guild.id] then
			guilds[name.guild.id] = name.guild
		end
	end
end

discord:once("ready", protect(getChannelAndGuildObjects))

return {
	channels = channels,
	guilds = guilds
}