------------------------------------------- Optimization -------------------------------------------

local encodeUrl = require("./encode").encodeUrl

local http_request = require("coro-http").request

local str_find = string.find
local str_sub = string.sub

----------------------------------------------------------------------------------------------------

local forumHeader = { { "Accept-Language", "en-US,en;q=0.9" } }

local isPlayerCache = { }

----------------------------------------------------------------------------------------------------

local isPlayer = function(playerName)
	if not isPlayerCache[playerName] then
		local _, body = http_request("GET", "https://atelier801.com/profile?pr=" ..
			encodeUrl(playerName), forumHeader)

		isPlayerCache[playerName] = not str_find(body,
			"The request contains one or more invalid parameters")
	end
	return isPlayerCache[playerName]
end

local validatePlayerList = function(nicknames, defaultTag)
	local tmpNick
	for nick = 1, #nicknames do
		tmpNick = nicknames[nick]

		if str_sub(tmpNick, -5, -5) ~= '#' then
			tmpNick = tmpNick .. defaultTag
		end

		if not isPlayer(tmpNick) then
			return tmpNick

		end

		nicknames[nick] = tmpNick
	end
end

return {
	isPlayer = isPlayer,
	validatePlayerList = validatePlayerList
}