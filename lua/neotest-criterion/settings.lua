local defaults = {
	color = true,
	errorMessages = {
		crash = "CRASH",
		unexpectedSignal = "Unexpected signal caught below this line!",
		group = false,
	},
	criterionLogErrorFailTest = false,
	noUnexpectedSignalAtStartOfTest = false,
	executable = "./test",
	executableEnv = {},
	buildCommand = {}
}

local Settings = {
	color = defaults.color,
	errorMessages = defaults.errorMessages,
	criterionLogErrorFailTest = defaults.criterionLogErrorFailTest,
	noUnexpectedSignalAtStartOfTest = defaults.noUnexpectedSignalAtStartOfTest,
	executableEnv = defaults.executableEnv,
	executable = defaults.executable,
	buildCommand = defaults.buildCommand
}

function Settings:set(newSettings)
	if newSettings == nil then return end
	local settings = vim.tbl_deep_extend("force", defaults, newSettings)
	for name, setting in pairs(settings) do
		self[name] = setting
	end
end

return Settings
