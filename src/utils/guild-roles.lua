local discord = require("../discord").discord
local guilds = require("../utils/discord-objects").guilds

local roleFlags = { }

local createGuildRoleFlags = function()
	p("[LOAD] Role Flags")
	for guildId, guild in next, guilds do
		roleFlags[guild.id] = { }
		local rFlags = roleFlags[guildId]

		local roles = guild.roles
		local rolesCount = roles:count()

		for role in roles:iter() do
			local position = rolesCount - role.position
			rFlags[position] = role
			rFlags[role.name:lower()] = role
		end
	end
end

discord:once("ready", function()
	createGuildRoleFlags()
end)

return roleFlags