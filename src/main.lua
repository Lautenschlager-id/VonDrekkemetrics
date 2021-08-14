local _discord = require("./discord")
local _forum = require("./forum")

local secrets = require("./secrets")
local utils = require("./utils/utils")

------------------------------------------- Optimization -------------------------------------------

local discord, discordia, protect = _discord.discord, _discord.discordia, _discord.protect

local forum, fromage = _forum.forum, _forum.fromage

----------------------------------------------------------------------------------------------------


--[[ Connect ]]--
discord:once("ready", protect(function()
	p("[DISCORD] OK")

	forum.heartbeatOrReconnect()
end))

--[[ Services ]]--

-- Retrieve channels objects
require("./utils/discord-objects")

-- Get discord objects
require("./utils/guild-roles")

-- Alert about data breaches
require("./services/breach-alert")

-- Listen to #bad-names entries
require("./services/bad-name-validator")

-- Commands
require("./services/commands")

--[[ Init ]]--
discord:run(secrets.DISCORD_TOKEN)