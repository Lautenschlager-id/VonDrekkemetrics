local json = require("json")

local temporaryObject = require("../utils/temporaryObject")

local utils = require("../utils/utils")
local reactions = require("../utils/enums/reactions")

------------------------------------------- Optimization -------------------------------------------

local http_request = require("coro-http").request

----------------------------------------------------------------------------------------------------

local googleHeader = {
	{ "user-agent", "Google-API-Java-Client Google-HTTP-Java-Client/1.21.0 (gzip)" }
}

return {
	syntax = "ocr `[image]`",

	description = "Transforms the written content of an image into text",

	execute = function(self, message, parameters)
		local srcMessage = message
		if parameters and tonumber(parameters) then
			srcMessage = message.channel:getMessage(parameters) or message
		end

		if not srcMessage.attachment then
			return utils.sendError(message, "OCR", "Missing attachment.",
				"Please, submit an image for the command to convert it into text.")
		end
		local _, image = http_request("GET", srcMessage.attachment.url)

		local _, body = http_request("POST", "https://content-vision.googleapis.com/v1/images:\z
			annotate?alt=json&key=", googleHeader,
			json.encode({
				requests = {
					{
						features = {
							{
								maxResults = 1,
								type = "TEXT_DETECTION"
							}
						},
						image = {
							content = utils.binBase64_encode(image)
						}
					}
				}
			}))

		body = json.decode(body).responses[1].textAnnotations
		if body then
			temporaryObject[message.id] = message:reply({
				content = body[1].description,
				allowed_mentions = { parse = { } }
			})
		else
			message:addReaction(reactions.thumbsdown)
		end
	end
}