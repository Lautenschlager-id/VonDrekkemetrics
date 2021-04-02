------------------------------------------- Optimization -------------------------------------------
local str_format = string.format
local str_gmatch = string.gmatch
local str_gsub = string.gsub
local str_lower = string.lower
local str_match = string.match
local str_sub = string.sub
local str_upper = string.upper

local tbl_add = table.add

local tonumber = tonumber
local tostring = tostring
----------------------------------------------------------------------------------------------------

local forum = require("../forum").forum

----------------------------------------------------------------------------------------------------

local uri = "activity?pr=%s&p=%d&n=100"

local uriByRole = {
	moderator = uri .. "&games=on",
	sentinel = uri .. "&forum=on" -- brings bandef too :thinking:
}

local totalPages = "\"input%-pagination\".-max=\"(%d+)\""
local accordionData = "%s.-<table .->.-<thead>(.-)</thead>.-<tbody>(.-)</tbody>"

local accordionTitles = {
	activeSanctions = str_format(accordionData,
		"<h2 class=\"display%-inline%-block\">Active sanctions given %(players%)</h2>"),
	terminatedSanctions = str_format(accordionData,
		"<h2 class=\"display%-inline%-block\">Terminated sanctions given %(players%)</h2>"),
	warnings = str_format(accordionData,
		"<h2 class=\"display%-inline%-block\">Warnings sent</h2>"),
	moderatedMessages =
		"<h2 class=\"ltr\">Moderated messages</h2>(.-)</div>%s+</div>%s+</div>%s+</div>",
	handledReports = str_format(accordionData, "<h2>Handled reports</h2>")
}

local accordionsByRole = {
	moderator = {
		"activeSanctions",
		"terminatedSanctions"
	},
	sentinel = {
		"activeSanctions",
		"terminatedSanctions",
		"warnings",
		"moderatedMessages",
		"handledReports"
	}
}

local sanctionTypes = {
	moderator = {
		["bandef"] = true,
		["banjeu"] = true,
		["mutejeu"] = true
	},
	sentinel = {
		["avatar"] = true,
		["muteforum"] = true,
		["mutemessage"] = true,
		["profile"] = true,
		["report"] = true
	}
}

local sentinelMiscTypes = {
	["warnings"] = "warn",
	["reports"] = "handledreport",
	["moderated"] = "moderatedmessage",
	["deleted"] = "deletedmessage"
}

local ignorableState = {
	["Canceled"] = true,
	["Overwritten"] = true
}

local dataToDivideBy1k = {
	"Creation", "End", "Start", -- Sanction
	"Date", "ConsultationDate", -- Warn / Handled Report
}

----------------------------------------------------------------------------------------------------

-- Makes the data extracted more useful
local normalizeBodyData = function(registry, accordionName, playerName)
	for _, field in next, dataToDivideBy1k do
		registry[field] = registry[field] and registry[field]/1000
	end
	registry.__playerName = playerName

	if accordionName == "activeSanctions" or accordionName == "terminatedSanctions" then
		registry.isIP = str_sub(registry.Target, 1, 1) == '#'

		if not registry.isIP and str_sub(registry.Target, -5, -5) ~= '#' then
			registry.Target = registry.Target .. "#0000"
		end

		registry.DurationInt = tonumber(str_match(tostring(registry.Duration), "%d+")) or 0
		registry.isPermanent = registry.Duration == "Perm"

		registry.__type = registry.Type
		registry.__sourceDate = registry.Creation
		registry.__messageSource = registry.Reason
		registry.__checkState = true
	elseif accordionName == "warnings" then
		registry.__type = sentinelMiscTypes["warnings"]
		registry.__sourceDate = registry.Date
		registry.__messageSource = registry.Text
		registry.__checkType = true
	elseif accordionName == "handledReports" then
		registry.__type = sentinelMiscTypes["reports"]
		registry.__sourceDate = registry.Date
		registry.__messageSource = registry.Message
		registry.__checkType = true
	elseif accordionName == "moderatedMessages" then
		registry.isDeleted = registry.MessageState == "supprime"

		if registry.Author then
			registry.Author = str_gsub(registry.Author, "%%23", '#', 1)
		end
		registry.Reason = str_gsub(registry.Reason, "<.->", '')

		registry.__type = (registry.isDeleted and sentinelMiscTypes["deleted"]
			or sentinelMiscTypes["moderated"])
		registry.__sourceDate = registry.Date
		registry.__messageSource = registry.Reason
		registry.__checkType = true
	end

	registry.__messageSource = registry.__messageSource and str_lower(registry.__messageSource)

	return registry
end

-- Parses table headers
local parseTableHeader = function(thead)
	local headItems, counterHeadItems = { }, 0
	for _, item in str_gmatch(thead, "<t([hd]).->(.-)</t%1>") do
		counterHeadItems = counterHeadItems + 1
		headItems[counterHeadItems] = item:gsub("%s+(%a)", str_upper)
	end

	return headItems, counterHeadItems
end

-- Parses table registries, checks if the target date has been found in the page or not.
local parseTableBody = function(tbody, targetDate, role, playerName, accordionName, headItems,
	counterHeadItems)
	local bodyItems, counterBodyItems = { }, 0
	local tmpItem, tmpCounterCurrentItem = nil, 0

	local foundOccurenceOfTargetDate = false
	local sanctionTypes = sanctionTypes[role]

	for item in str_gmatch(tbody, "<td.->(.-)</td>") do
		if not tmpItem then
			tmpItem = { }

			counterBodyItems = counterBodyItems + 1
			bodyItems[counterBodyItems] = tmpItem
		end

		item = str_gsub(str_gsub(str_gsub(item, "<.->", ''), "^%s*(.-)%s*$", "%1"), "%s%s+", '')
		tmpCounterCurrentItem = tmpCounterCurrentItem + 1
		tmpItem[headItems[tmpCounterCurrentItem]] = tonumber(item) or (item ~= '' and item or nil)

		if tmpCounterCurrentItem == counterHeadItems then
			if not tmpItem.__type or sanctionTypes[tmpItem.__type] then
				normalizeBodyData(tmpItem, accordionName, playerName)
			else  -- will overwrite
				bodyItems[counterBodyItems] = nil
				counterBodyItems = counterBodyItems - 1
			end

			if not foundOccurenceOfTargetDate and tmpItem.__sourceDate >= targetDate then
				foundOccurenceOfTargetDate = true
			end

			tmpCounterCurrentItem = 0
			tmpItem = nil
		end
	end

	return bodyItems, foundOccurenceOfTargetDate
end

-- Parses messages' list registries, checks if the target date has been found in the page or not.
local parseMessageListBody = function(body, targetDate, playerName, accordionName)
	local bodyItems, counterBodyItems = { }, 0

	local foundOccurenceOfTargetDate = false

	local tmpType, tmpDate, tmpAuthor
	for path, message, reason, info in str_gmatch(body,
		"<tr>(.-)</tr>%s+<tr>(.-)</tr>%s+<tr>(.-)</tr>%s+<tr>(.-)</tr>") do
		path = str_gsub(path, "%s*<.->%s*", '')

		tmpType, message = str_match(message, "cadre%-message%-(%l+).->\z
			Message</a></span> : (.*) </div>")

		reason = str_match(reason, ">Reason</span> : (.*) </div>")

		tmpDate = tonumber(str_match(info, "data%-afficher%-secondes=\"false\">(%d+)"))
		tmpAuthor = str_match(info, "\"profile%?pr=(%S+)\"")

		counterBodyItems = counterBodyItems + 1
		bodyItems[counterBodyItems] = normalizeBodyData({
			Author = tmpAuthor,
			Date = tmpDate,
			Message = message,
			MessageState = tmpType,
			Path = path,
			Reason = reason
		}, accordionName, playerName)

		if not foundOccurenceOfTargetDate
			and bodyItems[counterBodyItems].__sourceDate >= targetDate then
			foundOccurenceOfTargetDate = true
		end
	end

	return bodyItems, foundOccurenceOfTargetDate
end

-- Gets the data from a specific accordion
local getAccordion = function(html, accordionPattern, role, targetDate, playerName, accordionName)
	local bodyItems, foundOccurenceOfTargetDate

	if accordionName ~= "moderatedMessages" then
		local thead, tbody = str_match(html, accordionPattern)
		if not thead then
			return { }, false
		end

		bodyItems, foundOccurenceOfTargetDate =
			parseTableBody(tbody, targetDate, role, playerName, accordionName,
				parseTableHeader(thead))
	else
		local body = str_match(html, accordionPattern)
		if not body then
			return { }, false
		end

		bodyItems, foundOccurenceOfTargetDate =
			parseMessageListBody(body, targetDate, playerName, accordionName)
	end

	return bodyItems, foundOccurenceOfTargetDate
end

----------------------------------------------------------------------------------------------------

local getActivityData
do
	local _getActivityData
	_getActivityData = function(playerName, role, targetDate, _pageNumber, _data, _rawPlayerName,
		_totalPages)
		local html = forum.getPage(str_format(uriByRole[role], playerName, _pageNumber))
		if _pageNumber == 1 then
			_totalPages = tonumber(str_match(html, totalPages)) or 1
		end

		local foundOccurenceOfTargetDate, tmpFoundOccurenceOfTargetDate, bodyItems = false
		for _, accordion in next, accordionsByRole[role] do
			bodyItems, tmpFoundOccurenceOfTargetDate =
				getAccordion(html, accordionTitles[accordion], role, targetDate, _rawPlayerName,
					accordion)

			if not _data[accordion] then
				_data[accordion] = bodyItems
			else
				tbl_add(_data[accordion], bodyItems)
			end

			if not foundOccurenceOfTargetDate and tmpFoundOccurenceOfTargetDate then
				foundOccurenceOfTargetDate = true
			end
		end

		p("[getActivityData]", _rawPlayerName, _pageNumber .. "/" .. _totalPages,
			"Last page: " .. tostring(not foundOccurenceOfTargetDate))

		if _totalPages == _pageNumber or not foundOccurenceOfTargetDate then
			return _data
		end
		return _getActivityData(playerName, role, targetDate, _pageNumber + 1, _data,
			_rawPlayerName, _totalPages)
	end

	getActivityData = function(playerName, role, targetDate)
		local queryPlayerName = str_gsub(playerName, '#', "%%23", 1)
		return _getActivityData(queryPlayerName, role, targetDate, 1, { }, playerName)
	end
end

return {
	getActivityData = getActivityData,
	sanctionTypes = sanctionTypes,
	ignorableState = ignorableState,
	sentinelMiscTypes = sentinelMiscTypes
}