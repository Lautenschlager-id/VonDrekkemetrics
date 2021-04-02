local temporaryObject = require("../temporaryObject")
local colors = require("../enums/colors")

local sendError = function(message, command, err, description, errColor)
	temporaryObject[message.id] = message:reply({
		mention = message.author,
		embed = {
			color = errColor or colors.fail,
			title = "Command [" .. command .. "] => " .. err,
			description = description
		}
	})
end

return {
	sendError = sendError
}