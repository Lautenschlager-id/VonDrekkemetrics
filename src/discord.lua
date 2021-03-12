local discordia = require("discordia")
local discord = discordia.Client({
	cacheAllMembers = true
})
discordia.extensions()

return {
	discord = discord,
	discordia = discordia,
	disclock = discordia.Clock()
}