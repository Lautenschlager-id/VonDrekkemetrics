local forum = require("../forum").forum

local uri = "activity?pr=%s&p=%d&n=100"

local uriByRole = {
	moderator = uri .. "&games=on",
	sentinel = uri .. "&forum=on" -- brings bandef too :thinking:
}

local totalPages = "\"input%-pagination\".-max=\"(%d+)\""
local accordionData = "%s.-<table .->.-<thead>(.-)</thead>.-<tbody>(.-)</tbody>"

local accordionTitles = {
	activeSanctions =
		"<h2 class=\"display%-inline%-block\">Active sanctions given %(players%)</h2>",
	terminatedSanctions =
		"<h2 class=\"display%-inline%-block\">Terminated sanctions given %(players%)</h2>",
	warnings = "<h2 class=\"display%-inline%-block\">Warnings sent</h2>",
	moderatedMessages = "<h2 class=\"ltr\">Moderated messages</h2>",
	handledReports = "<h2>Handled reports</h2>"
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
		--"moderatedMessages",
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

local ignorableState = {
	["Canceled"] = true,
	["Overwritten"] = true
}

local dataToDivideBy1k = {
	"Creation", "End", "Start", -- Sanction
	"Date", "ConsultationDate", -- Warn / Handled Report
}

-- Makes the data extracted more useful
local normalizeBodyData = function(registry, accordionName)
	for _, field in next, dataToDivideBy1k do
		registry[field] = registry[field] and registry[field]/1000
	end

	if accordionName == "activeSanctions" or accordionName == "terminatedSanctions" then
		registry.isIP = string.sub(registry.Target, 1, 1) == '#'

		if not registry.isIP and string.sub(registry.Target, -5, -5) ~= '#' then
			registry.Target = registry.Target .. "#0000"
		end

		registry.DurationInt = tonumber(string.match(tostring(registry.Duration), "%d+")) or 0
		registry.isPermanent = registry.Duration == "Perm"

		registry.__type = registry.Type
		registry.__sourceDate = registry.Creation
		registry.__messageSource = registry.Reason and string.lower(registry.Reason)
		registry.__checkState = true
	elseif accordionName == "warnings" then
		registry.__type = "warn"
		registry.__sourceDate = registry.Date
		registry.__messageSource = registry.Text and string.lower(registry.Text)
		registry.__checkType = true
	elseif accordionName == "handledReports" then
		registry.__type = "handledreport"
		registry.__sourceDate = registry.Date
		registry.__messageSource = registry.Message and string.lower(registry.Message)
		registry.__checkType = true
	end
end

-- Parses table headers
local parseTableHeader = function(thead)
	local headItems, counterHeadItems = { }, 0
	for _, item in string.gmatch(thead, "<t([hd]).->(.-)</t%1>") do
		counterHeadItems = counterHeadItems + 1
		headItems[counterHeadItems] = item:gsub("%s+(%a)", string.upper)
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

	for item in string.gmatch(tbody, "<td.->(.-)</td>") do
		if not tmpItem then
			tmpItem = { }

			counterBodyItems = counterBodyItems + 1
			bodyItems[counterBodyItems] = tmpItem
		end

		item = item
			:gsub("<.->", '')
			:gsub("^%s*(.-)%s*$", "%1")
			:gsub("%s%s+", '')
		tmpCounterCurrentItem = tmpCounterCurrentItem + 1
		tmpItem[headItems[tmpCounterCurrentItem]] = tonumber(item) or (item ~= '' and item or nil)

		if tmpCounterCurrentItem == counterHeadItems then
			if not tmpItem.__type or sanctionTypes[tmpItem.__type] then
				normalizeBodyData(tmpItem, accordionName)
				tmpItem.__playerName = playerName
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

	return bodyItems, counterBodyItems, foundOccurenceOfTargetDate
end

-- Gets the data from a specific accordion
local getAccordion = function(html, accordionPattern, role, targetDate, playerName, accordionName)
	local thead, tbody = string.match(html, accordionPattern)
	if not thead then
		return { }, false
	end

	local bodyItems, counterBodyItems, foundOccurenceOfTargetDate =
		parseTableBody(tbody, targetDate, role, playerName, accordionName, parseTableHeader(thead))

	return bodyItems, foundOccurenceOfTargetDate
end

local getActivityData
do
	local _getActivityData
	_getActivityData = function(playerName, role, targetDate, _pageNumber, _data, _rawPlayerName,
		_totalPages)
		local html = forum.getPage(string.format(uriByRole[role], playerName, _pageNumber))
		if _pageNumber == 1 then
			_totalPages = tonumber(string.match(html, totalPages)) or 1
		end

		local foundOccurenceOfTargetDate, tmpFoundOccurenceOfTargetDate, bodyItems = false
		for _, accordion in next, accordionsByRole[role] do
			bodyItems, tmpFoundOccurenceOfTargetDate =
				getAccordion(html, string.format(accordionData, accordionTitles[accordion]),
					role, targetDate, _rawPlayerName, accordion)

			if not _data[accordion] then
				_data[accordion] = bodyItems
			else
				table.add(_data[accordion], bodyItems)
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
		local queryPlayerName = string.gsub(playerName, '#', "%%23", 1)
		return _getActivityData(queryPlayerName, role, targetDate, 1, { }, playerName)
	end
end

return {
	getActivityData = getActivityData,
	sanctionTypes = sanctionTypes,
	ignorableState = ignorableState
}