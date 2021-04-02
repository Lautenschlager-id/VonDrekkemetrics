require("./extensions/table")

local utils = { }

table.addSet(utils, require("./extensions/string"))
table.addSet(utils, require("./extensions/iterator"))
table.addSet(utils, require("./extensions/encode"))
table.addSet(utils, require("./extensions/error"))
table.addSet(utils, require("./extensions/calendar"))
table.addSet(utils, require("./extensions/player"))
table.addSet(utils, require("./extensions/commands"))

return utils