------------------------------------------- Optimization -------------------------------------------

local rawset = rawset

----------------------------------------------------------------------------------------------------

return setmetatable({ }, {
	__newindex = function(list, index, value)
		if value then
			if value.id then -- Single message
				value = { value }
			end

			-- Only store message IDs to improve memory usage
			for m = 1, #value do
				value[m] = value[m].id
			end

			rawset(list, index, value)
		end
	end
})