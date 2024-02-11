local defaults = {
  testFileTypes = {
    c = true
  },
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
  if type(init.testDir) == "string" then
    init.testDir = { init.testDir }
  end
  if type(init.excludeTestDir) == "string" then
    init.excludeTestDir = { init.excludeTestDir }
  end
	init = vim.tbl_deep_extend("force", vim.deepcopy(defaults, true), init)
	self.__index = self
	setmetatable(init, self)
	return init
end

return Settings
