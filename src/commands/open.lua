local reactions = require("../utils/enums/reactions")

------------------------------------------- Optimization -------------------------------------------

local coroutine_wrap = coroutine.wrap

local discordChannels = require("../utils/discord-objects").channels

local forum = require("../forum").forum
local forum_displayState = forum.enumerations().displayState

local string_find = string.find

local timer_setTimeout = require("timer").setTimeout

----------------------------------------------------------------------------------------------------

local isTopicOpen = false
local topicLocation = {
	f = 5,
	s = 16,
	t = 788911
}

local changeTopicState = function(message, locked)
	isTopicOpen = not locked

	local reaction = locked and reactions.locked or reactions.unlocked

	local result, err = forum.updateTopic(topicLocation, {
		fixed = true,
		state = (locked and forum_displayState.locked or forum_displayState.active)
	})

	if err or not string_find(result, "\"redirection\"") then
		reaction = reactions.dnd
	end

	message:clearReactions()
	message:addReaction(reaction)
end

return {
	channel = {
		[discordChannels["br-senti"].id] = true,
		[discordChannels["br-modsents"].id] = true
	},

	syntax = "open",

	description = "Opens the [announcements topic](https://atelier801.com/topic?f=5&t=788911).",

	usesForum = true,

	execute = function(self, message, parameters)
		if isTopicOpen then return end

		changeTopicState(message, false)
		timer_setTimeout(20000, coroutine_wrap(changeTopicState), message, true)
	end
}