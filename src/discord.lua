local discordia = require("discordia")

------------------------------------------- Optimization -------------------------------------------

local discordia_Date = discordia.Date

local dbg_traceback = debug.traceback

----------------------------------------------------------------------------------------------------

discordia.extensions()

local discord = discordia.Client({
	cacheAllMembers = true
})

local disclock = discordia.Clock()

----------------------------------------------------------------------------------------------------

local protect = function(f)
	return function(...)
		local success, err = pcall(f, ...)
		if not success then
			p("[ERROR]")
			discord:getChannel("818016844522586123"):send({
				mention = discord.owner,
				embed = {
					color = 0xCC0000,
					title = "Error",
					description = "```\n" .. err .. "```",
					fields = {
						[1] = {
							name = "Traceback",
							value = "```\n" .. dbg_traceback() .. "```",
							inline = false
						}
					},
					timestamp = discordia_Date():toISO()
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