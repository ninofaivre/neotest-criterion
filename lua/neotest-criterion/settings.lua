local M = {}

local baseSettings = {
	color = true,
	errorMessages = {
		crash = "CRASH",
		unexpectedSignal = "Unexpected signal caught below this line!",
		group = false
	},
}

local settings = baseSettings

M.get = function ()
	return settings
end

M.set = function (newSettings)
	settings = vim.tbl_deep_extend("force", baseSettings, newSettings)
end

return M
