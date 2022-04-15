local activity = require("../../forum/activity")
local casier = require("../../forum/casier")

local temporaryObject = require("../../utils/temporaryObject")

local utils = require("../../utils/utils")
local colors = require("../../utils/enums/colors")

------------------------------------------- Optimization -------------------------------------------

local forum = require("../../forum").forum

local str_format = string.format

local tbl_concat = table.concat
local tbl_sort = table.sort

local os_date = os.date
local os_time = os.time

----------------------------------------------------------------------------------------------------

local isWorstCaseSanction = function(obj)
	return obj.isPermanent or obj.DurationInt >= 360
end

local sortBySourceDate = function(o1, o2)
	return o1.__sourceDate > o2.__sourceDate
end

local captureAvatarCasier = function(playerName, totalMonths)
	return casier.getForumAvatarCasier(playerName)
end

local processActivityData = function(data, totalMonths)
	local firstDayRange = os_time() - ((30.5 * totalMonths) * (60 * 60 * 24))

	local newData, index = { }, 0

	for dataObj = 1, #data do
		dataObj = data[dataObj]

		dataObj.isWorstCaseSanction = isWorstCaseSanction(dataObj)

		if
			(dataObj.__sourceDate >= firstDayRange or dataObj.isWorstCaseSanction)
			and (not (dataObj.__checkState and activity.ignorableState[dataObj.State])
			and dataObj.Type == "avatar")
		then
			index = index + 1
			newData[index] = dataObj
		end
	end

	tbl_sort(newData, sortBySourceDate)

	return newData
end

local displayAvatarCasier = function(message, playerName, data)
	local embed = {
		embed = {
			title = "<:bugs:964283404336103515> " .. playerName .. "'s avatars casier",
			color = colors.error
		}
	}

	if #data == 0 then
		embed.embed.color = colors.fail
		embed.embed.description = "No avatar sanction found in the last 6 months."

		temporaryObject[message.id] = message:reply(embed)
		return
	end

	local dataObj
	for obj = 1, #data do
		dataObj = data[obj]

		data[obj] = str_format("%s %s %s %s",
			(dataObj.isWorstCaseSanction and '*' or ''),
			os_date("%d/%m/%Y", dataObj.__sourceDate),
			(
				(dataObj.isPermanent and "Perm")
				or
				(str_format("%3d", (dataObj.DurationInt or 0)) .. "h")
			),
			utils.strAutoEllipsis(dataObj.Reason or '', 40)
		)
	end
	data = tbl_concat(data, '\n')

	local response, messages = utils.splitByLine(data, 1500), { }
	for line = 1, #response do
		embed.embed.description = "```\n" .. response[line] .. "```"

		messages[line] = message:reply(embed)

		if line == 1 then
			embed.title = nil
		end
	end

	temporaryObject[message.id] = messages
end

return {
	captureAvatarCasier = captureAvatarCasier,
	processActivityData = processActivityData,
	displayAvatarCasier = displayAvatarCasier
}