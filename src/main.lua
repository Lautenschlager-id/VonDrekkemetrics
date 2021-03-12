local secrets = require("./secrets")
local utils = require("./utils/utils")

--[[ Connect ]]--
local _discord = require("./discord")
local _forum = require("./forum")

local discord, discordia = _discord.discord, _discord.discordia
local forum, fromage = _forum.forum, _forum.fromage

discord:once("ready", function()
	p("[DISCORD] OK")

	--forum.connect(secrets.FORUM_LOGIN, secrets.FORUM_PASSWORD)
	--if forum.isConnected then
	--	p("[FORUM] OK")
	--end
end)

--[[ Services ]]--

-- Retrieve channels objects
require("./utils/discord-objects")

-- Alert about data breaches
require("./services/breach-alert")

-- Get discord objects
require("./utils/discord-objects")
require("./utils/guild-roles")

--[[ Init ]]--
discord:run(secrets.DISCORD_TOKEN)