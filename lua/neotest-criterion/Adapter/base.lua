local Settings = require("neotest-criterion.settings")

local Adapter = {}

function Adapter:new(init)
	init = vim.tbl_extend("force", {
		settings = Settings:new({})
	}, init)
	setmetatable(init, self)
	self.__index = self
	return init
end

function Adapter:root(dir)
	return dir
end

function Adapter:filterDir(name, rel_path, root)
	return (name == "srcs" or rel_path:find("tests"))
end

function Adapter:isTestFile(file_path)
	if not file_path:find("/tests/mandatory/") then
		return false
	end
	if not file_path:find(".c$") then
		return false
	end
	return true
end

function Adapter:results(...)
	return require("neotest-criterion.results").results(...)
end

return Adapter
