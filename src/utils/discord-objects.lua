local _discord = require("../discord")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local next = next

----------------------------------------------------------------------------------------------------

local channels = {
	-- Int Staff
	["int-main"] = "800100513718075414", -- #staff-utils
	["int-breach"] = "814497990948814918", -- #data-breaches

	-- Br Staff
	["br-utils"] = "826082697185198140", -- #bot-utils

	-- Debug
	["debug"] = "818016844522586123", -- #von-drekkemetrics
}

local guilds = {

}

local getChannelAndGuildObjects = function()
	p("[LOAD] Get Channel and Guild Objects")
	for name, id in next, channels do
		channels[name] = discord:getChannel(id)
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