------------------------------------------- Optimization -------------------------------------------

local next = next

local str_gmatch = string.gmatch
local str_lower = string.lower
local str_split = string.split
local str_sub = string.sub
local str_trim = string.trim

local tonumber = tonumber

----------------------------------------------------------------------------------------------------

local tableParameterPatterns = { "(%S+)%s*=%s*([^%[]%S*)", "(%S+)%s*=%s*(%b[])" }

----------------------------------------------------------------------------------------------------

local getParametersTableSplitByEqualsSign = function(parameters)
	local list = { }

	-- Bad code pls
	for _, regex in next, tableParameterPatterns do
		for arg, value in str_gmatch(parameters, regex) do
			if str_sub(value, 1, 1) == '[' then
				value = str_split(str_sub(value, 2, -2), ',', true)
				for v = 1, #value do
					value[v] = str_trim(value[v])
				end
			else
				value = tonumber(value) or value
			end
			list[str_lower(arg)] = value
		end
	end

	return list
end

return {
	getParametersTableSplitByEqualsSign = getParametersTableSplitByEqualsSign
}