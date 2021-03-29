local commands = require("../services/commands")
local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")
local colors = require("../utils/colors")

return {
	syntax = "help [`command_name`]",

	description = "Displays all the commands available.",

	execute = function(self, message, parameters)
		local embed

		if not parameters then
			local cmds, counter = { }, 0
			for cmd, obj in utils.pairsByIndexes(commands) do
				counter = counter + 1
				cmds[counter] = string.format(":small_orange_diamond: **!%s** - %s",
					obj.syntax or cmd, obj.description or '')
			end

			embed = {
				color = colors.info,
				title = ":loudspeaker: Help",
				description = table.concat(cmds, "\n")
			}
		else
			parameters = string.lower(parameters)

			local command = commands[parameters]
			if command then
				embed = {
					color = colors.info,
					title = ":loudspeaker: Help ~> '!" .. parameters .. "'",
					description = "**Description:** " .. (command.description or "?") ..
						(command.syntax and ("\n\n**Syntax:** !" .. command.syntax) or '')
				}
			else
				embed = {
					color = colors.fail,
					title = ":loudspeaker: Help",
					description = "The command **!" .. parameters .. "** doesn't exist!"
				}
			end
		end

		temporaryObject[message.id] = message:reply({
			mention = message.author,
			embed = embed
		})
	end
}