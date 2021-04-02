table.add = function(src, add)
	local len = #src
	for i = 1, #add do
		src[len + i] = add[i]
	end
end

table.arrayRange = function(arr, i, j)
	i = i or 1
	j = j or #arr

	local newArray = { }
	if i > j then
		return newArray
	end

	local counter = 0
	for v = i, j do
		counter = counter + 1
		newArray[counter] = arr[v]
	end

	return newArray
end

table.addSet = function(src, set)
	for k, v in next, set do
		src[k] = v
	end
end