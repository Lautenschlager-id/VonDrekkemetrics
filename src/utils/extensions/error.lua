local temporaryObject = require("../temporaryObject")
local colors = require("../enums/colors")

local sendError = function(message, command, err, description, errColor, image)
	temporaryObject[message.id] = message:reply({
		mention = message.author,
		embed = {
			color = errColor or colors.fail,
			title = "Command [" .. command .. "] => " .. err,
			description = description,
			image = image and { url = image } or nil
		}
	})
end

return {
	sendError = sendError
}