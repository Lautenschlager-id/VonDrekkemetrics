local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")
local colors = require("../utils/enums/colors")

local _countryFlags = require("../utils/enums/country-flags")

------------------------------------------- Optimization -------------------------------------------

local countryFlags = _countryFlags.countryFlags
local countryFlagsAliases = _countryFlags.countryFlagsAliases

local http_request = require("coro-http").request

local json_decode = require("json").decode

local str_gsub = string.gsub
local str_lower = string.lower
local str_match = string.match
local str_sub = string.sub
local str_upper = string.upper

local tbl_concat = table.concat

local tonumber = tonumber
local tostring = tostring

----------------------------------------------------------------------------------------------------

local googleHeader = { { "User-Agent","Mozilla/5.0" } }

return {
	syntax = "translate [`country_from`-`country_to` | `country_to`]* [`text`]*",

	description = "Translates a sentence using Google Translate.",

	execute = function(self, message, parameters)
		local syntax = "Use /" .. self.syntax .. "."

		if not parameters or parameters == '' then
			return utils.sendError(message, "TRANSLATE", "Missing parameters.", syntax)
		end

		local language, content = str_match(parameters, "(%S+)[ \n]+(.+)$")
		if not language or not content or content == '' then
			return utils.sendError(message, "TRANSLATE", "Invalid parameters.", syntax)
		end

		if #content == 18 and tonumber(content) then -- by message id
			local msgContent = message.channel:getMessage(content)
			if msgContent then
				msgContent = msgContent.content or
					(msgContent.embed and msgContent.embed.description)
				content = (msgContent and (str_gsub(msgContent, '`', '')) or content)
			end
		end

		language = str_lower(language)
		local sourceLanguage, targetLanguage = str_match(language, "^(..)[%-~]>?(..)$")
		if not sourceLanguage then
			sourceLanguage = "auto"
			targetLanguage = language
		end

		content = str_sub(content, 1, 250)
		local head, body = http_request("GET", "https://translate.googleapis.com/translate_a/\z
			single?client=gtx&sl=" .. sourceLanguage .. "&tl=" .. targetLanguage .. "&dt=t&q=" ..
			utils.encodeUrl(content), googleHeader)
		body = json_decode(tostring(body))

		if not body or body == '' then
			return utils.sendError(message, "TRANSLATE", "Internal Error.", "Couldn't translate \z
				```\n" .. parameters .. "```")
		end

		sourceLanguage = str_upper((sourceLanguage == "auto" and tostring(body[3])
			or sourceLanguage))
		targetLanguage = str_upper(targetLanguage)

		sourceLanguage = countryFlagsAliases[sourceLanguage] or sourceLanguage
		targetLanguage = countryFlagsAliases[targetLanguage] or targetLanguage

		local rawContent = body[1]

		local translatedText = { }
		for word = 1, #rawContent do
			translatedText[word] = rawContent[word][1]
		end
		translatedText = tbl_concat(translatedText, ' ')

		temporaryObject[message.id] = message:reply({
			embed = {
				color = colors.interaction,
				title = ":earth_americas: Quick Translation",
				description = (countryFlags[sourceLanguage] or '') .. "@**" .. sourceLanguage ..
					"**\n```\n" .. content .. "```" .. (countryFlags[targetLanguage] or '') ..
					"@**" .. str_upper(targetLanguage) .. "**\n```\n" .. translatedText .. "```"
			}
		})
	end
}