local _discord = require("../discord")

local roleFlags = require("../utils/guild-roles")

local reactions = require("../utils/enums/reactions")

------------------------------------------- Optimization -------------------------------------------

local discord, protect = _discord.discord, _discord.protect

local channels = require("../utils/discord-objects").channels

local os_date = os.date

local str_find = string.find
local str_format = string.format
local str_gsub = string.gsub
local str_match = string.match
local str_split = string.split
local str_sub = string.sub

local tbl_concat = table.concat
local tbl_sort = table.sort
local tonumber = tonumber

----------------------------------------------------------------------------------------------------

local badNameChannel, compromisedAccountsChannel, adminRole

local sortByCreatedAt = function(message1, message2)
	return message1.createdAt > message2.createdAt
end

local getPreviouMessages = function(message)
	local messages = message.channel
		:getMessagesBefore(message.id, 100)
		:toArray()
	tbl_sort(messages, sortByCreatedAt)
	return messages

end

local splitEntryIntoEntries = function(content)
	-- For multiple entries in the same message
	return str_split(content, "\n+")
end

local dataTypes = {
	nickname = "nicknames",
	tribename = "tribenames",
	compromised = "compromised",

	isBad = "bad",

	unknown = "unknown"
}

local dataArgumentPattern = {
	[dataTypes.nickname] = "^(%S+)%s+(%S+)$",
	[dataTypes.tribename] = "^[\"“”]+(.-)[\"“”]+%s+[\"“”]+(.-)[\"“”]+$",
	[dataTypes.compromised] = "^(%S+)$"
}

local dataValidationPattern = {
	nickname = "^(([%a%+])%w[%w_]+)#(%d%d%d%d)$",
	tribename = "^[%w_'%- ][%w_'%- ][%w_'%- ]+$"
}

dataValidationPattern[dataTypes.nickname] = function(value, id)
	local name, firstCharacter, tag = str_match(value, dataValidationPattern.nickname)

	if not name then -- Must be valid
		return false, 1
	end

	if id == 2 then
		if tag * 1 <= 100 then -- Tag must be > 100
			return false, 2
		end
	end

	if #name < (firstCharacter == '+' and 4 or 3) then -- Must have 3 characters, or 4 if starts with +
		return false, 3
	end

	if str_find(name, "__", 3, true) then -- Cannot have double _
		return false, 4
	end

	if str_sub(name, -1) == '_' then -- Cannot end with a _
		return false, 5
	end

	local firstLetter = (firstCharacter == '+' and 2 or 1)
	if not str_find(str_sub(name, firstLetter, firstLetter), '%a') then -- First character must be either a + or a letter
		return false, 6
	end

	return true
end

dataValidationPattern[dataTypes.tribename] = function(value)
	value = str_gsub(value, "[\"“”]+", '"')

	if not str_find(value, dataValidationPattern.tribename) then -- Must be valid
		return false, 1, value
	end

	if #value < 3 or #value > 50 then -- Must be 3 to 50 characters long
		return false, 2, value
	end

	return true, value
end

local identifyBadNameEntryType = function(entry)
	-- For each entry
	local isNickname = str_find(entry, '#', 1, true) and dataTypes.nickname
	local isTribename = str_find(entry, "[\"“”]+") and dataTypes.tribename

	local target = isNickname or isTribename

	if not target then
		return dataTypes.unknown
	end

	local parameters = { str_match(entry, dataArgumentPattern[target]) }
	if #parameters == 0 then
		return dataTypes.unknown
	end

	local isValid, invalidCode, formattedValue
	for id, value in next, parameters do
		isValid, invalidCode, formattedValue = dataValidationPattern[target](value, id)
		entry = formattedValue or entry

		if not isValid then
			p(str_format("[DEBUG] Bad Name: %q %q %q", entry, target, invalidCode))
			return target, true, entry
		end
	end

	return target, false, entry
end

local identifyCompromisedAccountEntryType = function(entry)
	-- For each entry
	local target = dataTypes.compromised

	if not str_find(entry, dataArgumentPattern[target]) then
		return dataTypes.unknown
	end

	local isValid, invalidCode = dataValidationPattern[dataTypes.nickname](entry)
	if not isValid then
		p(str_format("[DEBUG] Compromised account: %q %q", entry, invalidCode))
		return target, true
	end

	return target, false
end

local validateBadName = function()
	local data = {
		[dataTypes.nickname] = {
			_count = 0,
			bad = {
				_count = 0
			}
		},
		[dataTypes.tribename] = {
			_count = 0,
			bad = {
				_count = 0
			}
		},
		[dataTypes.unknown] = {
			_count = 0
		}
	}

	return data, identifyBadNameEntryType
end

local validateCompromisedAccount = function()
	local data = {
		[dataTypes.compromised] = {
			_count = 0,
			bad = {
				_count = 0
			}
		},
		[dataTypes.unknown] = {
			_count = 0
		}
	}

	return data, identifyCompromisedAccountEntryType
end

local validateAllEntries = function(message)
	local data, identifier =
		(message.channel.id == badNameChannel.id and validateBadName
			or validateCompromisedAccount)()

	local messages = getPreviouMessages(message)

	local message, dataType, isBad, entries, entry, dataArr, tmpEntry
	for msg = 1, #messages do
		message = messages[msg]

		if str_sub(message.content, 1, 1) == '/'
			and message.member:hasRole(adminRole) then
				message:addReaction(reactions.checkpoint)
			break
		end

		entries, entry, hasBad = splitEntryIntoEntries(message.content)
		for e = 1, #entries do
			entry = entries[e]

			dataType, isBad, tmpEntry = identifier(entry)

			dataArr = data[dataType]
			if isBad then
				dataArr = dataArr.bad
			end

			dataArr._count = dataArr._count + 1
			dataArr[dataArr._count] = tmpEntry or entry

			if not hasBad then
				hasBad = isBad or dataType == dataTypes.unknown
			end
		end

		coroutine.wrap(message.addReaction)(message,
			hasBad and reactions.thumbsdown or reactions.online)
	end

	return data
end

local getBadNameResponse = function(data)
	return str_format("\z
		**BAD NAME COLLATE** - %s\n\z
		\n\z
		\n\z
		__**Invalid**__\n\z
		`--------\n\z
		%s\n\z
		\n\z
		%s\n\z
		--------`\n\z
		\n\z
		__**Valid**__\n\z
		`--------\n\z
		%s\n\z
		\n\z
		%s\n\z
		--------`\z
	",
		os_date(),
		tbl_concat(data[dataTypes.nickname].bad, '\n'),
		tbl_concat(data[dataTypes.tribename].bad, '\n'),
		tbl_concat(data[dataTypes.nickname], '\n'),
		tbl_concat(data[dataTypes.tribename], '\n')
	)
end

local getCompromisedAccountResponse = function(data)
	return str_format("\z
		**COMPROMISED ACCOUNT COLLATE** - %s\n\z
		\n\z
		\n\z
		__**Invalid**__\n\z
		`--------\n\z
		%s\n\z
		--------`\n\z
		\n\z
		__**Valid**__\n\z
		`--------\n\z
		%s\n\z
		--------`\z
	",
		os_date(),
		tbl_concat(data[dataTypes.compromised].bad, '\n'),
		tbl_concat(data[dataTypes.compromised], '\n')
	)
end

discord:once("ready", protect(function()
	p("[LOAD] Bad Name Validator")
	badNameChannel = channels["int-bad-names"]
	compromisedAccountsChannel = channels["int-compromised-accounts"]

	adminRole = roleFlags[badNameChannel.guild.id]
	adminRole = adminRole and adminRole["admins"]
	adminRole = adminRole and adminRole.id
end))

discord:on("messageCreate", protect(function(message)
	local isBadName = message.channel.id == badNameChannel.id
	local isCompromisedAccount = message.channel.id == compromisedAccountsChannel.id

	if not (isBadName or isCompromisedAccount) then return end
	if message.content == "/collate" then return end

	local identifier = isBadName and identifyBadNameEntryType
		or identifyCompromisedAccountEntryType
	local hasUnknown, hasValid, hasInvalid = false, false, false

	local entries, entry = splitEntryIntoEntries(message.content)
	for e = 1, #entries do
		entry = entries[e]

		dataType, isBad = identifier(entry)

		if dataType == dataTypes.unknown then
			hasUnknown = true
			break
		end

		if isBad then
			hasInvalid = true
		else
			hasValid = true
		end
	end

	message:addReaction(
		1~=1
		or ( hasUnknown and reactions.question )
		or ( hasInvalid and reactions.dnd )
		or ( (hasValid and not hasInvalid) and reactions.idle )
	)

	if isBadName then
		if hasUnknown then
			message.member:send("Hello! Please only use the <#" .. badNameChannel.id .. "> \z
				channel to post names that need changing. If you have any questions or want to \z
				discuss something, you can use #all-discussions (or any other channel that fits). \z
				Thank you!")
		elseif hasInvalid then
			message.member:send("Hello! Something went wrong with the message you sent in \z
				<#" .. badNameChannel.id .. ">. \z
				Please check the instructions and edit your message accordingly. If you need help\z
				, you can ask in <#828236896719208468>.\nYou can find the instructions here: \z
				https://discord.com/channels/162499575939203072/872921934818594826/\z
				872924960983748698")
		end
	else
		if hasUnknown then
			message.member:send("Hello! Please only use the \z
				<#" .. compromisedAccountsChannel.id .. "> channel to post accounts for which \z
				password needs changing. If you have any questions or want to discuss something, \z
				you can use <#828236896719208468> (or any other channel that fits). Thank you!")
		elseif hasInvalid then
			message.member:send("Hello! Something went wrong with the message you sent in \z
				<#" .. compromisedAccountsChannel.id .. ">. Please check the instructions and \z
				edit your message accordingly. If you need help, you can ask in \z
				<#828236896719208468>.\nYou can find the instructions here: \z
				https://discord.com/channels/162499575939203072/872922245645889616/\z
				872926311855845427")
		end
	end
end))

return {
	validateAllEntries = validateAllEntries,
	getBadNameResponse = getBadNameResponse,
	getCompromisedAccountResponse = getCompromisedAccountResponse
}