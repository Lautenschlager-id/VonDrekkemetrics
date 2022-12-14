local _discord = require("../discord")

local colors = require("../utils/enums/colors")

------------------------------------------- Optimization -------------------------------------------

local discord, disclock, protect = _discord.discord, _discord.disclock, _discord.protect

local channels = require("../utils/discord-objects").channels

local http_request = require("coro-http").request

local json_decode = require("json").decode

local next = next

local str_sub = string.sub

local os_date = os.date

local tbl_concat = table.concat

local tostring = tostring

----------------------------------------------------------------------------------------------------

local alertChannels = {
	"int-breach"
}

local maximumLookupMessages = 15

local getNewBreaches = function()
	local _, lookupChannel = next(alertChannels)

	local lastBreaches = { }
	for message in channels[lookupChannel]:getMessages(maximumLookupMessages):iter() do
		if message.embed and message.embed.thumbnail then
			lastBreaches[message.embed.thumbnail.url] = true
		end
	end

	local today = os_date("%Y-%m-%d")

	local _, breaches = http_request("GET", "https://haveibeenpwned.com/api/v2/breaches")
	breaches = json_decode(breaches)

	local newBreaches, totalNewBreaches = { }, 0
	for breach = 1, #breaches do
		breach = breaches[breach]

		if str_sub(breach.AddedDate, 1, 10) == today and not lastBreaches[breach.LogoPath] then
			totalNewBreaches = totalNewBreaches + 1
			newBreaches[totalNewBreaches] = {
				embed = {
					color = colors.error,

					thumbnail = {
						url = breach.LogoPath
					},

					title = "**" .. breach.Name .. " HAS BEEN PWNED!**",

					description = "**" .. breach.Title .. " | " .. breach.Domain .. "**\n\n\z
						Verified: " .. tostring(breach.IsVerified),

					fields = {
						[1] = {
							name = "What has been compromised?",
							value = "• " .. tbl_concat(breach.DataClasses, "\n• "),
							inline = true
						},
						[2] = {
							name = "Affected accounts",
							value = breach.PwnCount .. "+",
							inline = true
						},
						[3] = {
							name = "Is Sensitive",
							value = tostring(breach.IsSensitive),
							inline = true
						},
						[4] = {
							name = "Happened in",
							value = tostring(breach.BreachDate),
							inline = true
						},
						[5] = {
							name = "Detected in",
							value = tostring(breach.AddedDate),
							inline = true
						}
					}
				}
			}
		end
	end

	return newBreaches, totalNewBreaches
end

discord:once("ready", protect(function()
	p("[LOAD] Data Breaches")
	disclock:start()
	disclock:emit("hour")
end))

disclock:on("hour", protect(function()
	p("[BREACHES] Checking breaches")
	local newBreaches, totalNewBreaches = getNewBreaches()
	if totalNewBreaches == 0 then return end

	for channel = 1, #alertChannels do
		channel = channels[alertChannels[channel]]

		for breach = 1, totalNewBreaches do
			channel:send(newBreaches[breach])
		end
	end
end))