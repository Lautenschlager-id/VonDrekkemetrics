local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")
local colors = require("../utils/enums/colors")

------------------------------------------- Optimization -------------------------------------------

local countryFlags = require("../utils/enums/country-flags").countryFlags

local discordia_Date = require("../discord").discordia.Date

local encodeUrl = require("../utils/extensions/encode").encodeUrl

local forum = require("../forum").forum
local forum_community = forum.enumerations().community

local str_gsub = string.gsub
local str_sub = string.sub
local str_upper = string.upper

local tbl_concat = table.concat

local tostring = tostring

----------------------------------------------------------------------------------------------------

local htmlToMarkdown = function(str)
	str = string.gsub(str, "&#(%d+);", function(dec) return string.char(dec) end)
	str = string.gsub(str, '<span style="(.-);">(.-)</span>', function(x, content)
		local markdown = ""
		if x == "font-weight:bold" then
			markdown = "**"
		elseif x == "font-style:italic" then
			markdown = '_'
		elseif x == "text-decoration:underline" then
			markdown = "__"
		elseif x == "text-decoration:line-through" then
			markdown = "~~"
		end
		return markdown .. content .. markdown
	end)
	str = string.gsub(str, '<p style="text-align:.-;">(.-)</p>', "%1")
	str = string.gsub(str, '<blockquote.->(.-)<div>(.-)</div></blockquote>', function(name, content)
		local m = string.match(name, "<small>(.-)</small>")
		return (m and ("`" .. m .. "`\n") or "") .. "```\n" .. (#content > 50 and string.sub(content, 1, 50) .. "..." or content) .. "```"
	end)
	str = string.gsub(str, '<a href="(.-)".->(.-)</a>', "[%2](%1)")
	str = string.gsub(str, "<br ?/?>", "\n")
	str = string.gsub(str, "&gt;", '>')
	str = string.gsub(str, "&lt;", '<')
	str = string.gsub(str, "&quot;", "\"")
	str = string.gsub(str, "&laquo;", '«')
	str = string.gsub(str, "&raquo;", '»')
	str = string.gsub(str, '<div class="cadre cadre%-code">(.-)<div class="contenu.-<pre class="colonne%-lignes%-code">(.-)</pre></div></div>', function(language, code)
		language = string.match(language, '<div class="indication%-langage%-code">(.-) code</div><hr/>') or ''
		code = string.gsub(code, "<span .->(.-)</span>", "%1")
		return "```" .. language .. "\n" .. code .. "```"
	end)
	return str
end

return {
	syntax = "topic [`url`]",

	description = "Displays a forum message.",

	usesForum = true,

	execute = function(self, message, parameters)
		parameters = tostring(parameters)

		local data, err = forum.parseUrlData(parameters)
		if #parameters < 45 or not data then
			return utils.sendError(message, "TOPIC", "Invalid or missing parameters.",
				"Use /" .. self.syntax .. ". " .. (err or ""))
		end

		local location = {
			f = data.data.f,
			t = data.data.t,
			p = data.data.p
		}

		local fMessage, err = forum.getMessage(data.num_id, location)
		if not message then
			return utils.sendError(message, "TOPIC", "Message not found.", err)
		end

		local topic, err = forum.getTopic(location, true)
		if not topic then
			return utils.sendError(message, "TOPIC", "Topic not found.", err)
		end

		local internationalFlag = "<:international:458411936892190720>"
		local community = topic.community and forum_community(topic.community)
		community = community and countryFlags[str_upper(community)] or internationalFlag

		local fields = {
			[1] = {
				name = "Author",
				value = community .. " [" .. str_gsub(fMessage.author, "(#%d+)", "`%1`")
					.. "](https://atelier801.com/profile?pr=" .. encodeUrl(fMessage.author) .. ")",
				inline = true
			},
			[2] = {
				name = "Message #" .. data.num_id,
				value = str_sub((fMessage.contentHtml and htmlToMarkdown(fMessage.contentHtml)
					or fMessage.content), 1, 1000),
				inline = false
			}
		}
		if fMessage.prestige ~= 0 then
			fields[3] = fields[2]
			fields[2] = {
				name = "Prestige",
				value = ":heart: " .. fMessage.prestige,
				inline = true
			}
		end

		local navbar = topic.navbar
		for i = 1, #navbar do
			navbar[i] = navbar[i].name
		end

		temporaryObject[message.id] = message:reply({
			embed = {
				color = colors.interaction,
				title = community .. " " .. tbl_concat(navbar, " / ", 2),
				fields = fields,
				thumbnail = { url = fMessage.authorAvatar or "https://i.imgur.com/Lvlrhot.png" },
				timestamp = discordia_Date().fromMilliseconds(fMessage.timestamp):toISO()
			}
		})
	end
}