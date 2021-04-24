local activityStruct = require("../commands/struct/activity")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

return {
	channel = {
		[discordChannels["br-utils"].id] = true,
		[discordChannels["int-sent-only"].id] = true
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
		      [ `message=WHETHER IT SHOULD DISPLAY DATA OF MODERATED MESSAGES (TRUE/FALSE)` \z
				(DEFAULT=TRUE) ]\
		      [ `debug=WHETHER THE BOT SHOULD SEND AN AUDITION FILE (TRUE/FALSE)` (DEFAULT=FALSE) ]\
		\
		[CLICK HERE TO GENERATE THE COMMAND ONLINE](https://lautenschlager-id.github.io/\z
			drekkemetrics.github.io/senti.html)",

	description = "Gets the activity of the given sentinels.",

	usesForum = true,

	execute = function(self, message, parameters)
		local parameters, data, firstDayRange, lastDayRange, runtimeWhileBusy =
			activityStruct.captureActivityDate(self, message, parameters, "senti")
		if not data then return end

		local reasons, fields, rawReasonsLen, runtimeWhileBusy =
			activityStruct.processActivityData(message, parameters, "senti", data, firstDayRange,
				lastDayRange, runtimeWhileBusy)

		activityStruct.displayFilteredData(message, parameters, "senti", reasons, fields,
			rawReasonsLen, data, runtimeWhileBusy)
	end
}