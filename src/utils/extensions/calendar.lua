------------------------------------------- Optimization -------------------------------------------

local tonumber = tonumber

local os_date = os.date
local os_time = os.time

----------------------------------------------------------------------------------------------------

local getMonth = function(value)
	if value then
		value = tonumber(value)
		value = (value >= 1 and value <= 12 and value or nil)
	end
	return value or os_date("%m")*1
end

local getYear = function(value)
	local currentYear = os_date("%Y")*1
	if value then
		value = tonumber(value)
		value = (value >= currentYear-2 and value or nil)
	end
	return value or currentYear
end

local getMonthRange = function(month, year)
	local firstDayRange = os_time({
		day = 1,
		month = month,
		year = year
	})

	local nextMonth = month % 12 + 1
	if nextMonth < month then
		year = year + 1
	end

	local lastDayRange = os_time({
		day = 1,
		month = nextMonth,
		year = year,
		hour = 0,
		min = 0,
		sec = -1
	})

	return firstDayRange, lastDayRange
end

return {
	getMonth = getMonth,
	getYear = getYear,
	getMonthRange = getMonthRange
}