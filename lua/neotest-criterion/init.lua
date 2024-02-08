local Settings = require("neotest-criterion.settings")
local Adapter = require("neotest-criterion.Adapter")

local M = {}

M.setup = function (arg)
	local settings = Settings:new(arg or {})
	local adapter = Adapter:new({ settings = settings })

	local mappings = {
		root = Adapter.root,
		filter_dir = Adapter.filterDir,
		is_test_file = Adapter.isTestFile,
		build_spec = Adapter.buildSpec,
		discover_positions = Adapter.discoverPositions,
		results = Adapter.results
	}
	for k, v in pairs(mappings) do
		mappings[k] = function (...) return v(adapter, ...) end
	end

	return vim.tbl_extend("error", mappings, {
		name = "criterion",
		-- allow user to change settings after setup of adapter ???
		settings = settings
	})
end

return M
