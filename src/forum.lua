local secrets = require("./secrets")

local fromage = require("fromage")
local forum = fromage()

forum.heartbeatOrReconnect = function()
	p("[FORUM] CHECKING CONNECTION")
	if not forum.isConnectionAlive() then
		p("[FORUM] CONNECTING")
		repeat
			forum.connect(secrets.FORUM_LOGIN, secrets.FORUM_PASSWORD)
		until forum.isConnected()
		p("[FORUM] CONNECTED")
	end
end

return {
	forum = forum,
	fromage = fromage
}