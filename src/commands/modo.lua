local activityStruct = require("../commands/struct/activity")

------------------------------------------- Optimization -------------------------------------------

local discordChannels = require("../utils/discord-objects").channels

----------------------------------------------------------------------------------------------------

return {
	channel = {
		[discordChannels["br-utils"].id] = true
	},

	syntax = "modo `[settings]` [Generator](https://lautenschlager-id.github.io/drekkemetrics.\z
		github.io/modo.html)",

	bigSyntax = "modo \
		      [ `nick=[ NICKNAME, TO, CHECK, ACTIVITY ]` ]*\
		      [ `reason=[ FILTER (PATTERN), FILTER2, FILTER3#BANTYPE ]` (DEFAULT=NULL) ]\
		      [ `month=ACTIVITY FOR THE SPECIFIC MONTH` (DEFAULT=CURRENT MONTH) ]\
		      [ `year=ACTIVITY FOR THE SPECIFIC YEAR` (DEFAULT=CURRENT YEAR) ]\
		      [ `members=WHETHER IT SHOULD DISPLAY DATA PER MEMBERS (TRUE/FALSE)` (DEFAULT=FALSE) ]\
		      [ `alltime=WHETHER THE MONTH/YEAR RANGE SHOULD NOT BE LIMITED TO 1 MONTH \z
				(TRUE/FALSE)` (DEFAULT=FALSE) ]\
		      [ `debug=WHETHER THE BOT SHOULD SEND AN AUDITION FILE (TRUE/FALSE)` (DEFAULT=FALSE) ]\
		\
		[CLICK HERE TO GENERATE THE COMMAND ONLINE](https://lautenschlager-id.github.io/\z
			drekkemetrics.github.io/modo.html)",

	description = "Gets the activity of the given moderators.",

	usesForum = true,

	execute = function(self, message, parameters)
		local parameters, data, firstDayRange, lastDayRange, runtimeWhileBusy =
			activityStruct.captureActivityDate(self, message, parameters, "modo")
		if not data then return end

		local reasons, fields, rawReasonsLen =
			activityStruct.processActivityData(message, parameters, "modo", data, firstDayRange,
				lastDayRange, runtimeWhileBusy)

		activityStruct.displayFilteredData(message, parameters, "modo", reasons, fields,
			rawReasonsLen, data, runtimeWhileBusy)
	end
}