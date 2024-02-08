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

local Settings = {}

function Settings:new(init)
	init = vim.tbl_deep_extend("force", vim.deepcopy(defaults, true), init)
	self.__index = self
	setmetatable(init, self)
	return init
end

return Settings
