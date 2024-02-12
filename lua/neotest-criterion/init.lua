local Settings = require("neotest-criterion.settings")
local Adapter = require("neotest-criterion.Adapter")

---@brief [[
---*neotest-criterion.txt*  a criterion adapter for the neotest plugin
---@brief ]]
---@mod neotest-criterion

local M = {}

---@class Settings.ErrorMessages
---@field crash string|vim.NIL|nil default `"CRASH"`
---@field unexpectedSignal string|vim.NIL|nil default `"Unexpected signal caught below this line!"`
---@field group boolean default `false`

---nil field will be set to default
---vim.NIL fields will disable the corresponding option (only for vim.NIL(able) fields ofc)
---@class Settings
---@field testFileTypes table<string, boolean>|nil default `{ "c" = true }`
---@field color boolean|nil default `true`
---@field errorMessages Settings.ErrorMessages|nil
---@field criterionLogErrorFailTest boolean|nil default `false`
---@field noUnexpectedSignalAtStartOfTest boolean|nil default `false`
---@field executable string default `"./test"`
---@field executableEnv string[]|nil default `{}`
---@field buildCommand string[]|nil default `{}`

---@param arg Settings|nil
M.setup = function (arg)
	local settings = Settings:new(arg or {})
	local adapter = Adapter:new({ settings = settings })

  local mappings = {}
	for k, v in pairs(Adapter.mappings) do
		mappings[k] = function (...) return v(adapter, ...) end
	end

	return vim.tbl_extend("error", mappings, {
		name = "criterion",
		-- allow user to change settings after setup of adapter ???
		settings = settings
	})
end

return M
