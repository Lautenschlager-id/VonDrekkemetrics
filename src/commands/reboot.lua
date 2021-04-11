return {
	isAdminOnly = true,

	syntax = "reboot",

	description = "Reboots the bot.",

	aliases = {
		"reset",
		"refresh"
	},

	execute = function(self, message, parameters)
		os.execute(args[0] .. " " .. args[1])
		os.exit()
	end
}