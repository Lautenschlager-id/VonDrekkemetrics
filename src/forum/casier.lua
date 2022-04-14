local activity = require("./activity")

local utils = require("../utils/utils")

------------------------------------------- Optimization -------------------------------------------

local forum = require("../forum").forum

local str_format = string.format

----------------------------------------------------------------------------------------------------

local uri = "case-sanctions-ajax?pr=%s&games=true&forum=true&by_player=false&by_ip=false\z
	&author=true"

local accordionTitle = "<thead>(.-)</thead>.-<tbody>(.-)</tbody>"

local getForumAvatarCasier = function(playerName)
	local html = forum.getPage(str_format(uri, utils.readableToEncodedNickname(playerName)))

	local bodyItems, error = activity.getAccordion(html, accordionTitle, "avatarOnly", 0, playerName,
		"activeSanctions")

	return bodyItems, error
end

return {
	getForumAvatarCasier = getForumAvatarCasier
}