local activity = require("../../forum/activity")

local utils = require("../../utils/utils")
local reactions = require("../../utils/enums/reactions")
local colors = require("../../utils/enums/colors")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../../utils/discord-objects").channels

local forum = require("../../forum").forum

local json_encode = require("json").encode

local next = next

local str_find = string.find
local str_format = string.format
local str_lower = string.lower
local str_split = string.split
local str_sub = string.sub
local str_upper = string.upper

local tbl_add = table.add
local tbl_arrayRange = table.arrayRange
local tbl_concat = table.concat
local tbl_copy = table.copy

local tostring = tostring
local type = type

local os_time = os.time

----------------------------------------------------------------------------------------------------

local commandSettingsByRole = {
	["modo"] = {
		name = "MODO",
		tag = "#0010",
		type = "moderator",
		color = 0xBABD2F
	},
	["senti"] = {
		name = "SENTI",
		tag = "#0015",
		type = "sentinel",
		color = 0x2ECF73
	}
}

local miscSanctionTypes = {
	["modo"] = { },
	["senti"] = {
		warn = { activity.sentinelMiscTypes["warnings"] },
		report = { activity.sentinelMiscTypes["reports"] },
		message = {
			activity.sentinelMiscTypes["moderated"],
			activity.sentinelMiscTypes["deleted"]
		}
	}
}

local booleanParameters = {
	-- ~=
	["modo"] = { },
	["senti"] = {
		warn = "FALSE",
		report = "FALSE",
		message = "FALSE"
	},

	-- ==
	common = {
		alltime = "TRUE",
		members = "TRUE",
		debug = "TRUE"
	}
}

local containerToParameterAssociation = {
	["modo"] = { },
	["senti"] = {
		["warnings"] = "warn",
		["handledReports"] = "report",
		["moderatedMessages"] = "message",
	}
}

local messageSeparator = string.rep('-', 20)

----------------------------------------------------------------------------------------------------

local setBusy = function(message)
	p("[FORUM] Forum set to 'Busy'")
	forum._BUSY = true

	message:addReaction(reactions.idle)

	return {
		validatePlayerList = 0,
		getActivityData = { },
		filter = 0,
		display = 0
	}
end

local unsetBusy = function(message, reactionType)
	p("[FORUM] Forum set to 'Available'")
	if message then
		message:clearReactions()
		message:addReaction(reactionType)
	end
	forum._BUSY = false
	return false
end

local getDataRange = function(parameters)
	parameters.month = utils.getMonth(parameters.month)
	parameters.year = utils.getYear(parameters.year)

	return utils.getMonthRange(parameters.month, parameters.year)
end

local checkVariableBoolParam = function(commandName, parameters)
	for parameter, oppositeDefaultValue in next, booleanParameters[commandName] do
		parameters[parameter] = str_upper(tostring(parameters[parameter])) ~= oppositeDefaultValue
	end

	for parameter, defaultValue in next, booleanParameters.common do
		parameters[parameter] = str_upper(tostring(parameters[parameter])) == defaultValue
	end
end

local validatePlayerList = function(message, parameters, commandSettings)
	if type(parameters.nick) ~= "table" or not parameters.nick[1] then
		utils.sendError(message, commandSettings.name, "Invalid parameter 'nick'.",
			"The parameter 'nick' must be a table with at least one value. E.g.: [ a, b ]")
		return false
	end

	p("[ACTIVITY] Validating nicknames")
	local invalidName = utils.validatePlayerList(parameters.nick, commandSettings.tag)
	if invalidName then
		message:clearReactions()
		message:addReaction(reactions.dnd)

		utils.sendError(message, commandSettings.name, "Invalid value for 'nick'.",
			"The player '" .. invalidName .. "' could not be found.")

		return false
	end

	return true
end

local captureActivityDate = function(self, message, parameters, commandName)
	local commandSettings = commandSettingsByRole[commandName]

	if not parameters or parameters == '?' then
		utils.sendError(message, commandSettings.name, "Invalid or missing parameters.",
			"Use /" .. self.bigSyntax)
		return false
	end

	parameters = utils.getParametersTableSplitByEqualsSign(parameters)

	local firstDayRange, lastDayRange = getDataRange(parameters)
	checkVariableBoolParam(commandName, parameters)

	local runtimeWhileBusy = setBusy(message)

	local runtime = os_time()
	if not validatePlayerList(message, parameters, commandSettings) then
		return unsetBusy(message, reactions.dnd)
	end
	runtimeWhileBusy.validatePlayerList = (os_time() - runtime)

	local activityRuntime = runtimeWhileBusy.getActivityData

	local data, tmpActivity, tmpTotalPages = { }
	for member = 1, #parameters.nick do
		runtime = os_time()
		tmpActivity, tmpTotalPages = activity.getActivityData(parameters.nick[member],
			commandSettings.type, firstDayRange)
		activityRuntime[member] = {
			runtime = (os_time() - runtime),
			totalPages = tmpTotalPages
		}

		for k, v in next, tmpActivity do -- Adds to all-members' data
			if not data[k] then
				data[k] = v
			else
				tbl_add(data[k], v)
			end
		end
	end
	unsetBusy()

	return parameters, data, firstDayRange, lastDayRange, runtimeWhileBusy
end

local transformActivityDataIntoSimpleTable = function(commandName, complexTable, parameters)
	local parameterToContainer = containerToParameterAssociation[commandName]

	local simpleTable = { }

	for containerName, complexData in next, complexTable do
		containerName = parameterToContainer[containerName] -- parameter name
		if not containerName or parameters[containerName] then
			tbl_add(simpleTable, complexData)
		end
	end

	return simpleTable
end

local getDefaultReasons = function(commandName, parameters)
	local rawReasons = parameters.reason
	local rawReasonsLen = rawReasons and #rawReasons

	if not rawReasonsLen then
		local sanctionTypes =
			tbl_copy(activity.sanctionTypes[commandSettingsByRole[commandName].type])

		for paramKey, types in next, miscSanctionTypes[commandName] do
			if parameters[paramKey] then
				for type = 1, #types do
					sanctionTypes[types[type]] = true
				end
			end
		end

		rawReasons =  { }
		rawReasonsLen = 0

		for reasonType in next, sanctionTypes do
			rawReasonsLen = rawReasonsLen + 1
			rawReasons[rawReasonsLen] = "#" .. reasonType
		end
	end

	return rawReasons, rawReasonsLen
end

local parseReasons = function(rawReasons, rawReasonsLen)
	local reasons, fields = { }, { }

	local tmpType, tmpPattern
	for reason = 1, rawReasonsLen do
		reasons[reason] = { __total = 0 }

		fields[reason] = {
			name = rawReasons[reason],
			value = nil,
			inline = true
		}

		-- pattern#type
		tmpPattern = str_split(rawReasons[reason], '#', true)

		rawReasons[reason] = {
			pattern = tmpPattern[1] ~= '' and tmpPattern[1],
			type = tmpPattern[2] ~= '' and tmpPattern[2] and str_lower(tmpPattern[2])
		}
	end

	return reasons, fields
end

local processActivityData = function(message, parameters, commandName, data, firstDayRange,
	lastDayRange, runtimeWhileBusy)
	data = transformActivityDataIntoSimpleTable(commandName, data, parameters)

	local filterAllTime = parameters.alltime

	local rawReasons, rawReasonsLen = getDefaultReasons(commandName, parameters)
	local reasons, fields = parseReasons(rawReasons, rawReasonsLen)

	local tmpReason, tmpType, tmpNickname, tmpMustCheckType, tmpCheckType
	local tmpPattern, tmpReasonObj

	-- Filter and count
	runtimeWhileBusy.filter = os_time()
	for dataObj = 1, #data do
		dataObj = data[dataObj]

		if
			dataObj.__sourceDate >= firstDayRange
			and (filterAllTime or dataObj.__sourceDate <= lastDayRange)
			and (not (dataObj.__checkState and activity.ignorableState[dataObj.State]))
		then
			dataObj.__captured = true -- depuration file

			tmpReason, tmpType, tmpNickname, tmpMustCheckType, tmpCheckType =
				dataObj.__messageSource, dataObj.__type, dataObj.__playerName,
				dataObj.__checkType

			for reason = 1, rawReasonsLen do
				tmpPattern = rawReasons[reason]

				tmpCheckType = tmpPattern.type == tmpType
				if not tmpMustCheckType then
					tmpCheckType = not tmpPattern.type or tmpCheckType
				end

				if tmpCheckType and (not tmpPattern.pattern or (tmpReason and
					str_find(tmpReason, tmpPattern.pattern))) then
					tmpReasonObj = reasons[reason]
					tmpReasonObj.__total = tmpReasonObj.__total + 1

					tmpReasonObj[tmpNickname] = (tmpReasonObj[tmpNickname] or 0) + 1
				end
			end
		end
	end
	runtimeWhileBusy.filter = (os_time() - runtimeWhileBusy.filter)

	return reasons, fields, rawReasonsLen, runtimeWhileBusy
end

local getIterablePlayerList = function(parameters)
	local iterableNicknames, totalIterableNicknames = parameters.nick
	local nicknamesList = tbl_concat(iterableNicknames, ", ")
	if #nicknamesList > 1900 then
		nicknamesList = str_sub(nicknamesList, 1, 1900) .. "..."
	end

	if parameters.members then
		totalIterableNicknames = #iterableNicknames

		if totalIterableNicknames > 1 then
			totalIterableNicknames = totalIterableNicknames + 1
			iterableNicknames[totalIterableNicknames] = "__total"
		end
	else
		iterableNicknames, totalIterableNicknames = { "__total" }, 1
	end

	return iterableNicknames, totalIterableNicknames, nicknamesList
end

local getFooter = function(parameters)
	local footer = {
		text = "Data from " .. parameters.month .. "/" .. parameters.year
	}

	if parameters.alltime then
		footer.text = footer.text .. " to " .. utils.getMonth() .. "/" .. utils.getYear()
	end

	return footer
end

local executeDebug = function(message, data, runtimeWhileBusy, nicknames)
	data = json_encode(data)

	p("[DEBUG] Data Len: ", #data)
	message:reply({
		file = { "audition_data.json", data }
	})

	local runtimeTotal = runtimeWhileBusy.validatePlayerList + runtimeWhileBusy.filter
		+ runtimeWhileBusy.display

	local getActivityData, tmpData = runtimeWhileBusy.getActivityData
	for m = 1, #getActivityData do
		tmpData = getActivityData[m]
		getActivityData[m] = str_format("%s → %ds (%ds/page)", nicknames[m],
			tmpData.runtime, tmpData.runtime / tmpData.totalPages)
		runtimeTotal = runtimeTotal + tmpData.runtime
	end

	p("[DEBUG] Runtime")
	message:reply({
		embed = {
			color = colors.info,
			title = "⏰ Runtime",
			description = str_format(
				"Validating player list: %ds\n\z
				Reason and date filter: %ds\n\z
				Display processing: %ds\n\n\z
				Activity extraction per player:\n%s\n\n\z
				Total runtime: %ds",

				runtimeWhileBusy.validatePlayerList, runtimeWhileBusy.filter,
				runtimeWhileBusy.display, tbl_concat(getActivityData, "\n"), runtimeTotal)
		}
	})
end

local displayFilteredData = function(message, parameters, commandName, reasons, fields,
	rawReasonsLen, data, runtimeWhileBusy)
	local iterableNicknames, totalIterableNicknames, nicknamesList =
		getIterablePlayerList(parameters)

	local footer = getFooter(parameters, filterAllTime)

	local tmpEmbed = {
		color = commandSettingsByRole[commandName].color,

		description = nil,
		title = nil,
		fields = nil,
		footer = nil
	}
	local tmpPayload = {
		content = nil,
		embed = tmpEmbed
	}

	local totalFields, tmpFieldRangeLimit = #fields
	local tmpNickname

	runtimeWhileBusy.display = os_time()
	for member = 1, totalIterableNicknames do
		tmpNickname = iterableNicknames[member]

		for reason = 1, rawReasonsLen do
			fields[reason].value = reasons[reason][tmpNickname] or 0
		end

		tmpPayload.content = (member > 1 and messageSeparator or nil)
		tmpEmbed.description = (tmpNickname == "__total" and nicknamesList or nil)
		tmpEmbed.title = (tmpNickname == "__total" and "Total" or tmpNickname)
		tmpEmbed.fields = nil
		tmpEmbed.footer = nil

		for field = 1, totalFields, 25 do
			tmpFieldRangeLimit = field + 25-1
			if tmpFieldRangeLimit >= totalFields then
				tmpEmbed.footer = footer
			end

			tmpEmbed.fields = tbl_arrayRange(fields, field, tmpFieldRangeLimit)

			message:reply(tmpPayload)

			tmpEmbed.title = nil
			tmpEmbed.description = nil
			tmpPayload.content = nil
		end
	end
	runtimeWhileBusy.display = (os_time() - runtimeWhileBusy.display)

	if parameters.debug then
		executeDebug(message, data, runtimeWhileBusy, parameters.nick)
	end

	unsetBusy(message, reactions.online)
end

return {
	captureActivityDate = captureActivityDate,
	processActivityData = processActivityData,
	displayFilteredData = displayFilteredData
}