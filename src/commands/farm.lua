local temporaryObject = require("../utils/temporaryObject")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../utils/discord-objects").channels

local next = next

local str_gmatch = string.gmatch
local str_sub = string.sub

local table_concat = table.concat

----------------------------------------------------------------------------------------------------

local filter = function(parameters, p)
	local registeredAccounts, sourisAccounts, IPs = { }, { }, { }
	local regIndex, souIndex = 0, 0

	for name, isSouris, ip in str_gmatch(parameters, p) do
		if isSouris ~= '' then
			souIndex = souIndex + 1
			sourisAccounts[souIndex] = name
		else
			regIndex = regIndex + 1
			registeredAccounts[regIndex] = name
		end

		IPs[ip] = true
	end

	return registeredAccounts, sourisAccounts, IPs
end

return {
	channel = {
		[discordChannels["br-mod-utils"].id] = true,
		[discordChannels["int-mod-utils"].id] = true
	},

	syntax = "farm `text`",

	description = "Converts the results of your text into a list of nicknames.",

	execute = function(self, message, parameters)
		if not parameters then return end

		local split = ','
		if str_sub(parameters, 1, 4) == "noob" then
			split = ' '
		end

		local registeredAccounts, sourisAccounts, IPs = filter(parameters, "((%*?)%S+) / (#%S+)")
		if not next(IPs) then
			registeredAccounts, sourisAccounts, IPs = filter(parameters, "((%*?)[^%(%)%s]+)")
		end

		local ipArr, ipIndex = { }, 0
		for ip in next, IPs do
			ipIndex = ipIndex + 1
			ipArr[ipIndex] = ip
		end

		local data, messages, index = { registeredAccounts, sourisAccounts, ipArr }, { }, 0
		for _, tbl in next, data do
			if #tbl > 0 then
				index = index + 1
				messages[index] = message:reply("``" .. table_concat(tbl, split) .. "``")
			end
		end

		temporaryObject[message.id] = messages
	end
}