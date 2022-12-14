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

-- Listen to collate entries
require("./services/collate-validator")

-- Commands
require("./services/commands")

-- Listen for chat reports from Shades to be reported
require("./services/chat-policies-report")

--[[ Init ]]--
discord:run(secrets.DISCORD_TOKEN)