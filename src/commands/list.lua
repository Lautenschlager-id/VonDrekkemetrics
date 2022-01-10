local temporaryObject = require("../utils/temporaryObject")
local utils = require("../utils/utils")

local roleFlags = require("../utils/guild-roles")
local colors = require("../utils/enums/colors")
local reactions = require("../utils/enums/reactions")

------------------------------------------- Optimization -------------------------------------------

local str_gmatch = string.gmatch
local str_lower = string.lower
local str_sub = string.sub
local str_trim = string.trim
local str_upper = string.upper

local tbl_concat = table.concat
local tbl_sort = table.sort

local tonumber = tonumber

----------------------------------------------------------------------------------------------------

local listRoles = function(list)
	local rolesList = { }
	for role = 1, #list do
		rolesList[role] = str_upper(list[role].name)
	end
	return tbl_concat(rolesList, ", ")
end

return {
	syntax = "list [-][`role_name` | `role_index`]*",

	description = "Lists the users with a specific role.",

	execute = function(self, message, parameters)
		local roleFlags = roleFlags[message.guild.id]
		if not roleFlags then
			return utils.sendError(message, "LIST", "Forbidden command.",
				"This server is not ready to use this command.")
		end

		local listFlags = { }
		for r = 1, #roleFlags do
			listFlags[r] = "\t• [" .. r .. "] " .. roleFlags[r].name
		end
		listFlags = tbl_concat(listFlags, "\n")

		local syntax = "Use /" .. self.syntax .. ".\n\nThe available roles are:\n" ..
			listFlags

		if not parameters then
			return utils.sendError(message, "LIST", "Invalid or missing parameters.", syntax)
		end

		parameters = str_lower(parameters)

		local mustHaveRoles, mustNotHaveRoles = { }, { }
		local counterMustHaveRoles, counterMustNotHaveRoles = 0, 0
		local isNotHave, isRoleIndex, role

		for rawRole in str_gmatch(parameters, "[^,]+") do
			rawRole = str_trim(rawRole)

			isNotHave = str_sub(rawRole, 1, 1) == '-'
			if isNotHave then
				counterMustNotHaveRoles = counterMustNotHaveRoles + 1
				rawRole = str_sub(rawRole, 2)
			else
				counterMustHaveRoles = counterMustHaveRoles + 1
			end

			role = roleFlags[tonumber(rawRole)] or roleFlags[rawRole]
			if not role then
				return utils.sendError(message, "LIST", "The role '" .. rawRole .. "' couldn't \z
					be found.", syntax)
			end

			if isNotHave then
				mustNotHaveRoles[counterMustNotHaveRoles] = role
			else
				mustHaveRoles[counterMustHaveRoles] = role
			end
		end

		local filteredRolesInfo = (mustHaveRoles and
			("+(" .. listRoles(mustHaveRoles) .. ")") or '') ..
			(mustNotHaveRoles and ("-(" .. listRoles(mustNotHaveRoles) .. ")") or '')

		local membersList, counterMembersList = { }, 0
		for member in message.guild.members:findAll(function(member)
			for r = 1, #mustHaveRoles do
				if not member:hasRole(mustHaveRoles[r]) then
					return false
				end
			end

			for r = 1, #mustNotHaveRoles do
				if member:hasRole(mustNotHaveRoles[r]) then
					return false
				end
			end

			return true
		end) do
			counterMembersList = counterMembersList + 1
			membersList[counterMembersList] = member
		end

		if counterMembersList == 0 then
			temporaryObject[message.id] = message:reply({
				embed = {
					color = colors.fail,
					title = "<:tribe:458407729736974357> No members found.",
					description = filteredRolesInfo
				}
			})
			return
		end

		tbl_sort(membersList, function(m1, m2)
			return m1.name < m2.name
		end)

		local formattedMembers, member = { }
		for m = 1, counterMembersList do
			member = membersList[m]
			formattedMembers[m] = "<:" .. (reactions[member.status] or ':') .. "> <@" .. member.id
				.. "> " .. member.name
		end

		local lines, messages = utils.splitByLine(tbl_concat(formattedMembers, "\n")), { }
		for line = 1, #lines do
			messages[line] = message:reply({
				embed = {
					color = colors.info,
					title = (line == 1 and ("<:tribe:458407729736974357> Members "
						.. filteredRolesInfo .. " (#" .. counterMembersList .. ")") or nil),
					description = lines[line]
				}
			})
		end
		temporaryObject[message.id] = messages
	end
}