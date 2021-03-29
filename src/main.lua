local secrets = require("./secrets")
local utils = require("./utils/utils")

--[[ Connect ]]--
local _discord = require("./discord")
local _forum = require("./forum")

local discord, discordia, protect = _discord.discord, _discord.discordia, _discord.protect
local forum, fromage = _forum.forum, _forum.fromage

discord:once("ready", protect(function()
	p("[DISCORD] OK")

	repeat
		forum.connect(secrets.FORUM_LOGIN, secrets.FORUM_PASSWORD)
	until forum.isConnected()
	p("[FORUM] OK")
end))

--[[ Services ]]--

-- Retrieve channels objects
require("./utils/discord-objects")

-- Alert about data breaches
require("./services/breach-alert")

-- Get discord objects
require("./utils/discord-objects")
require("./utils/guild-roles")

-- Commands
require("./services/commands")

--[[ Init ]]--
discord:run(secrets.DISCORD_TOKEN)