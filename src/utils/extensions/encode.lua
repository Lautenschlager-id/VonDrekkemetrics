------------------------------------------- Optimization -------------------------------------------

local str_byte = string.byte
local str_format = string.format
local str_gmatch = string.gmatch
local str_upper = string.upper

local tbl_concat = table.concat

----------------------------------------------------------------------------------------------------

local encodeUrl = function(url)
	local out, counter = { }, 0

	for letter in str_gmatch(url, '.') do
		counter = counter + 1
		out[counter] = str_upper(str_format("%02x", str_byte(letter)))
	end

	return '%' .. tbl_concat(out, '%')
end

return {
	encodeUrl = encodeUrl
}