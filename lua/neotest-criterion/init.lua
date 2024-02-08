local M = {}
local Adapter = { name = "criterion" }

Adapter.root = function (dir)
	return dir
end

Adapter.filter_dir = function (name, rel_path, root)
	return (name == "srcs" or rel_path:find("tests"))
end

Adapter.is_test_file = function (file_path)
	if not file_path:find("/tests/mandatory/") then
		return false
	end
	if not file_path:find(".c$") then
		return false
	end
	return true
end

Adapter.discover_positions = require("neotest-criterion.discoverPositions").discover_positions

Adapter.build_spec = require("neotest-criterion.buildSpec").build_spec

Adapter.results = require("neotest-criterion.results").results

--- @class Settings
local Settings = {
	--- @param root_dir string
	--- @return boolean
	buildSpecHook = function (root_dir)
		return true
	end
}

--- @param settings Settings
M.setup = function (settings)
	assert(type(settings) == "table", "settings should be a table")
	require("neotest-criterion.settings"):set(settings)
	return Adapter
end

return M
