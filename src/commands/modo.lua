-- falta cancelled, overwritten

local utils = require("../utils/utils")
local reactions = require("../utils/reactions")

local forum = require("../forum").forum
local activity = require("../forum/activity")

return {
	syntax = "modo \
		      [ `nick=[ NICKNAME, TO, CHECK, ACTIVITY ]` ]*\
		      [ `reason=[ FILTER (PATTERN), FILTER2, FILTER3#BANTYPE ]` (DEFAULT=NULL) ]\
		      [ `month=ACTIVITY FOR THE SPECIFIC MONTH` (DEFAULT=CURRENT MONTH) ]\
		      [ `year=ACTIVITY FOR THE SPECIFIC YEAR` (DEFAULT=CURRENT YEAR) ]\
		      [ `members=IF IT SHOULD DISPLAY DATA PER MEMBERS (TRUE/FALSE)` (DEFAULT=FALSE) ]\
		\
		[CLICK HERE TO GENERATE THE COMMAND ONLINE](https://lautenschlager-id.github.io/drekkemetrics.github.io/)",

	description = "Gets the activity of the given moderators.",

	execute = function(self, message, parameters)
		if not forum.isConnected() or forum._BUSY then
			return utils.sendError(message, "MODO", "Service unavailable.", "Try again in a few \z
				minutes.")
		end

		if not parameters or parameters == '?' then
			return utils.sendError(message, "MODO", "Invalid or missing parameters.", "Use !" ..
				self.syntax)
		end

		parameters = utils.getParametersTableSplitByEqualsSign(parameters)

		if type(parameters.nick) ~= "table" or not parameters.nick[1] then
			return utils.sendError(message, "MODO", "Invalid parameter 'nick'.",
				"The parameter 'nick' must be a table with at least one value. E.g.: [ a, b ]")
		end

		local invalidName = utils.validatePlayersList(parameters.nick, "#0010")
		if invalidName then
			utils.sendError(message, "MODO", "Invalid value for 'nick'.", "The player '" ..
					invalidName .. "' could not be found.")
		end

		parameters.month = utils.getMonth(parameters.month)
		parameters.year = utils.getYear(parameters.year)

		local firstDayRange, lastDayRange = utils.getMonthRange(parameters.month, parameters.year)

		forum._BUSY = true
		message:addReaction(reactions.idle)

		local data, tmpActivity = { }
		for member = 1, #parameters.nick do
			tmpActivity = activity.getActivityData(parameters.nick[member], "moderator",
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

		local rawReasons = parameters.reason
		local rawReasonsLen = rawReasons and #rawReasons

		if not rawReasonsLen then
			rawReasons =  { }
			rawReasonsLen = 0

			for reasonType in next, activity.sanctionTypes.moderator do
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
		local sanctionTypes = activity.sanctionTypes

		local tmpReason, tmpType, tmpNickname, tmpReasonObj
		for sanction = 1, #sanctions do
			sanction = sanctions[sanction]

			if sanction.Creation >= firstDayRange and sanction.Creation <= lastDayRange then
				tmpReason, tmpType, tmpNickname = sanction.Reason, sanction.Type,
					sanction.__playerName

				for reason = 1, rawReasonsLen do
					tmpPattern = rawReasons[reason]
					if (not tmpPattern.pattern or string.find(tmpReason, tmpPattern.pattern)) and
						(not tmpPattern.type or tmpPattern.type == tmpType) then


						tmpReasonObj = reasons[reason]
						tmpReasonObj.__total = tmpReasonObj.__total + 1

						tmpReasonObj[tmpNickname] = (tmpReasonObj[tmpNickname] or 0) + 1
					end
				end
			end
		end

		local tmpNicknames, tmpNicknamesLen, tmpNickname

		parameters.members = parameters.members and string.upper(tostring(parameters.members))

		if parameters.members == "TRUE" then
			tmpNicknames, tmpNicknamesLen = parameters.nick, #parameters.nick
			if tmpNicknamesLen > 1 then
				tmpNicknamesLen = tmpNicknamesLen + 1
				tmpNicknames[tmpNicknamesLen] = "__total"
			end
		else
			tmpNicknames, tmpNicknamesLen = { "__total" }, 1
		end

		for member = 1, tmpNicknamesLen do
			tmpNickname = tmpNicknames[member]

			for reason = 1, rawReasonsLen do
				fields[reason].value = reasons[reason][tmpNickname] or 0
			end

			message:reply({
				embed = {
					color = 0xBABD2F,
					title = (tmpNickname == "__total" and "Total" or tmpNickname),
					fields = fields
				}
			})
		end

		message:clearReactions()
		message:addReaction(reactions.online)
	end
}