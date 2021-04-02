------------------------------------------- Optimization -------------------------------------------

local next = next

local tbl_sort = table.sort

----------------------------------------------------------------------------------------------------

local pairsByIndexes = function(list, f)
	local out, counter = { }, 0
	for index in next, list do
		counter = counter + 1
		out[counter] = index
	end
	tbl_sort(out, f)

	local i = 0
	return function()
		i = i + 1
		if out[i] ~= nil then
			return out[i], list[out[i]]
		end
	end
end

return {
	pairsByIndexes = pairsByIndexes
}