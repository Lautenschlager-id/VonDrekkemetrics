local discordia = require("discordia")
local discord = discordia.Client({
	cacheAllMembers = true
})
discordia.extensions()

local disclock = discordia.Clock()

local protect = function(f)
	return function(...)
		local success, err = pcall(f, ...)
		if not success then
			discord:getChannel("818016844522586123"):send({
				mention = discord.owner,
				embed = {
					color = 0xCC0000,
					title = "Error",
					description = "```\n" .. err .. "```",
					fields = {
						[1] = {
							name = "Traceback",
							value = "```\n" .. debug.traceback() .. "```",
							inline = false
						}
					},
					timestamp = discordia.Date():toISO()
				}
			})
			return false
		end
		return true
	end
end

return {
	discord = discord,
	discordia = discordia,
	disclock = disclock,
	protect = protect
}