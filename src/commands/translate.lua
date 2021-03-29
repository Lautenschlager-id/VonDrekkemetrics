local http = require("coro-http")
local json = require("json")

local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")
local colors = require("../utils/colors")

local _countryFlags = require("../utils/country-flags")
local countryFlags = _countryFlags.countryFlags
local countryFlagsAliases = _countryFlags.countryFlagsAliases

return {
	syntax = "translate [`country_from`-`country_to` | `country_to`]* [`text`]*",

	description = "Translates a sentence using Google Translate.",

	execute = function(self, message, parameters)
		local syntax = "Use /" .. self.syntax .. "."

		if not parameters or parameters == '' then
			return utils.sendError(message, "TRANSLATE", "Missing parameters.", syntax)
		end

		local language, content = string.match(parameters, "(%S+)[ \n]+(.+)$")
		if not language or not content or content == '' then
			return utils.sendError(message, "TRANSLATE", "Invalid parameters.", syntax)
		end

		if #content == 18 and tonumber(content) then -- by message id
			local msgContent = message.channel:getMessage(content)
			if msgContent then
				msgContent = msgContent.content or
					(msgContent.embed and msgContent.embed.description)
				content = (msgContent and (string.gsub(msgContent, '`', '')) or content)
			end
		end

		language = string.lower(language)
		local sourceLanguage, targetLanguage = string.match(language, "^(..)[%-~]>?(..)$")
		if not sourceLanguage then
			sourceLanguage = "auto"
			targetLanguage = language
		end

		content = string.sub(content, 1, 250)
		local head, body = http.request("GET", "https://translate.googleapis.com/translate_a/\z
			single?client=gtx&sl=" .. sourceLanguage .. "&tl=" .. targetLanguage .. "&dt=t&q=" ..
			utils.encodeUrl(content), { { "User-Agent","Mozilla/5.0" } })
		body = json.decode(tostring(body))

		if not body or body == '' then
			return utils.sendError(message, "TRANSLATE", "Internal Error.", "Couldn't translate \z
				```\n" .. parameters .. "```")
		end

		sourceLanguage = string.upper((sourceLanguage == "auto" and tostring(body[3])
			or sourceLanguage))
		targetLanguage = string.upper(targetLanguage)

		sourceLanguage = countryFlagsAliases[sourceLanguage] or sourceLanguage
		targetLanguage = countryFlagsAliases[targetLanguage] or targetLanguage

		local rawContent = body[1]

		local translatedText = { }
		for word = 1, #rawContent do
			translatedText[word] = rawContent[word][1]
		end
		translatedText = table.concat(translatedText, ' ')

		temporaryObject[message.id] = message:reply({
			embed = {
				color = colors.interaction,
				title = ":earth_americas: Quick Translation",
				description = (countryFlags[sourceLanguage] or '') .. "@**" .. sourceLanguage ..
					"**\n```\n" .. content .. "```" .. (countryFlags[targetLanguage] or '') ..
					"@**" .. string.upper(targetLanguage) .. "**\n```\n" .. translatedText .. "```"
			}
		})
	end
}