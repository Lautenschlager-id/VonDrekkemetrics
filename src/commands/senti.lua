local json = require("json")

local utils = require("../utils/utils")
local reactions = require("../utils/reactions")

local forum = require("../forum").forum
local activity = require("../forum/activity")

local discordChannels = require("../utils/discord-objects").channels

return {
	channel = {
		[discordChannels["br-utils"].id] = true
	},

	syntax = "senti `[settings]` [Generator](https://lautenschlager-id.github.io/drekkemetrics.\z
		github.io/senti.html)",

	bigSyntax = "senti \
		      [ `nick=[ NICKNAME, TO, CHECK, ACTIVITY ]` ]*\
		      [ `reason=[ FILTER (PATTERN), FILTER2, FILTER3#BANTYPE ]` (DEFAULT=NULL) ]\
		      [ `month=ACTIVITY FOR THE SPECIFIC MONTH` (DEFAULT=CURRENT MONTH) ]\
		      [ `year=ACTIVITY FOR THE SPECIFIC YEAR` (DEFAULT=CURRENT YEAR) ]\
		      [ `members=WHETHER IT SHOULD DISPLAY DATA PER MEMBERS (TRUE/FALSE)` (DEFAULT=FALSE) ]\
		      [ `alltime=WHETHER THE MONTH/YEAR RANGE SHOULD NOT BE LIMITED TO 1 MONTH \z
				(TRUE/FALSE)` (DEFAULT=FALSE) ]\
		      [ `warn=WHETHER IT SHOULD DISPLAY WARNINGS DATA (TRUE/FALSE)` (DEFAULT=TRUE) ]\
		      [ `report=WHETHER IT SHOULD DISPLAY HANDLED REPORTS DATA (TRUE/FALSE)` (DEFAULT=TRUE\z
				) ]\
		      [ `debug=WHETHER THE BOT SHOULD SEND AN AUDITION FILE (TRUE/FALSE)` (DEFAULT=FALSE) ]\
		\
		[CLICK HERE TO GENERATE THE COMMAND ONLINE](https://lautenschlager-id.github.io/\z
			drekkemetrics.github.io/senti.html)",

	description = "Gets the activity of the given sentinels.",

	usesForum = true,

	execute = function(self, message, parameters)
		if not parameters or parameters == '?' then
			return utils.sendError(message, "SENTI", "Invalid or missing parameters.", "Use /" ..
				self.bigSyntax)
		end

		parameters = utils.getParametersTableSplitByEqualsSign(parameters)

		if type(parameters.nick) ~= "table" or not parameters.nick[1] then
			return utils.sendError(message, "SENTI", "Invalid parameter 'nick'.",
				"The parameter 'nick' must be a table with at least one value. E.g.: [ a, b ]")
		end

		forum._BUSY = true
		message:addReaction(reactions.idle)

		local invalidName = utils.validatePlayersList(parameters.nick, "#0015")
		if invalidName then
			message:clearReactions()
			message:addReaction(reactions.dnd)
			return utils.sendError(message, "SENTI", "Invalid value for 'nick'.", "The player '" ..
					invalidName .. "' could not be found.")
		end

		parameters.month = utils.getMonth(parameters.month)
		parameters.year = utils.getYear(parameters.year)

		local firstDayRange, lastDayRange = utils.getMonthRange(parameters.month, parameters.year)

		local data, tmpActivity = { }
		for member = 1, #parameters.nick do
			tmpActivity = activity.getActivityData(parameters.nick[member], "sentinel",
				firstDayRange)

			for k, v in next, tmpActivity do -- Adds to all-members' data
				if not data[k] then
					data[k] = v
				else
					table.add(data[k], v)
				end
			end
		end
		forum._BUSY = false

		local sanctions = data.activeSanctions or { }
		if data.terminatedSanctions then
			table.add(sanctions, data.terminatedSanctions)
		end

		local filterWarnings = string.upper(tostring(parameters.warn)) ~= "FALSE"
		if filterWarnings and data.warnings then
			table.add(sanctions, data.warnings)
		end

		local filterReports = string.upper(tostring(parameters.report)) ~= "FALSE"
		if filterReports and data.handledReports then
			table.add(sanctions, data.handledReports)
		end

		local filterModeratedAndDeletedMessages =
			string.upper(tostring(parameters.message)) ~= "FALSE"
		if filterModeratedAndDeletedMessages and data.moderatedMessages then
			table.add(sanctions, data.moderatedMessages)
		end

		local footer = {
			text = "Data from " .. parameters.month .. "/" .. parameters.year
		}

		local filterAllTime = string.upper(tostring(parameters.alltime)) == "TRUE"
		if filterAllTime then
			footer.text = footer.text .. " to " .. utils.getMonth() .. "/" .. utils.getYear()
		end

		local rawReasons = parameters.reason
		local rawReasonsLen = rawReasons and #rawReasons

		if not rawReasonsLen then
			local sanctionTypes = table.copy(activity.sanctionTypes.sentinel)
			if filterWarnings then
				sanctionTypes[activity.sentinelMiscTypes["warnings"]] = true
			end
			if filterReports then
				sanctionTypes[activity.sentinelMiscTypes["reports"]] = true
			end
			if filterModeratedAndDeletedMessages then
				sanctionTypes[activity.sentinelMiscTypes["moderated"]] = true
				sanctionTypes[activity.sentinelMiscTypes["deleted"]] = true
			end

			rawReasons =  { }
			rawReasonsLen = 0

			for reasonType in next, sanctionTypes do
				rawReasonsLen = rawReasonsLen + 1
				rawReasons[rawReasonsLen] = "#" .. reasonType
			end
		end

		local reasons, fields, tmpType, tmpPattern = { }, { }
		for reason = 1, rawReasonsLen do
			reasons[reason] = { __total = 0 }

			fields[reason] = {
				name = rawReasons[reason],
				value = nil,
				inline = true
			}

			-- pattern#type
			tmpPattern = string.split(rawReasons[reason], '#', true)

			rawReasons[reason] = {
				pattern = tmpPattern[1] ~= '' and tmpPattern[1],
				type = tmpPattern[2] ~= '' and tmpPattern[2] and string.lower(tmpPattern[2])
			}
		end

		local tmpReason, tmpType, tmpNickname, tmpReasonObj, tmpCheckType
		for sanction = 1, #sanctions do
			sanction = sanctions[sanction]

			if sanction.__sourceDate >= firstDayRange and
				(filterAllTime or sanction.__sourceDate <= lastDayRange) and
				(not (sanction.__checkState and activity.ignorableState[sanction.State])) then

				sanction.__captured = true -- depuration file

				tmpReason, tmpType, tmpNickname, tmpMustCheckType, tmpCheckType =
					sanction.__messageSource, sanction.__type, sanction.__playerName,
					sanction.__checkType

				for reason = 1, rawReasonsLen do
					tmpPattern = rawReasons[reason]

					tmpCheckType = tmpPattern.type == tmpType
					if not tmpMustCheckType then
						tmpCheckType = not tmpPattern.type or tmpCheckType
					end

					if tmpCheckType and (not tmpPattern.pattern or (tmpReason and
						string.find(tmpReason, tmpPattern.pattern))) then
						tmpReasonObj = reasons[reason]
						tmpReasonObj.__total = tmpReasonObj.__total + 1

						tmpReasonObj[tmpNickname] = (tmpReasonObj[tmpNickname] or 0) + 1
					end
				end
			end
		end

		local tmpNicknames, tmpNicknamesLen, tmpNickname

		if string.upper(tostring(parameters.members)) == "TRUE" then
			tmpNicknames, tmpNicknamesLen = parameters.nick, #parameters.nick
			if tmpNicknamesLen > 1 then
				tmpNicknamesLen = tmpNicknamesLen + 1
				tmpNicknames[tmpNicknamesLen] = "__total"
			end
		else
			tmpNicknames, tmpNicknamesLen = { "__total" }, 1
		end

		local tmpPayload, tmpEmbed, tmpFieldRangeLimit
		local separator, totalFields = string.rep('-', 20), #fields
		local tmpNicknameList = table.concat(parameters.nick, '\n')

		for member = 1, tmpNicknamesLen do
			tmpNickname = tmpNicknames[member]

			for reason = 1, rawReasonsLen do
				fields[reason].value = reasons[reason][tmpNickname] or 0
			end

			tmpPayload = {
				content = (member > 1 and separator or nil),
				embed = {
					color = 0x2ECF73,
					description = (tmpNickname == "__total" and tmpNicknameList or nil),
					title = (tmpNickname == "__total" and "Total" or tmpNickname),
					fields = nil,
					footer = nil
				}
			}
			tmpEmbed = tmpPayload.embed

			for field = 1, totalFields, 25 do
				tmpFieldRangeLimit = field + 25-1
				if tmpFieldRangeLimit >= totalFields then
					tmpEmbed.footer = footer
				end

				tmpEmbed.fields = table.arrayRange(fields, field, tmpFieldRangeLimit)

				message:reply(tmpPayload)

				tmpEmbed.title = nil
				tmpEmbed.description = nil
				tmpPayload.content = nil
			end
		end

		if string.upper(tostring(parameters.debug)) == "TRUE" then
			message:reply({
				file = { "audition_data.json", json.encode(sanctions) }
			})
		end

		message:clearReactions()
		message:addReaction(reactions.online)
	end
}