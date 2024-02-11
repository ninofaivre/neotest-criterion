local Settings = require("neotest-criterion.settings")

local Adapter = {
  mappings = {}
}

function Adapter:new(init)
	init = vim.tbl_extend("force", {
		settings = Settings:new({})
	}, init)
	setmetatable(init, self)
	self.__index = self
	return init
end

function Adapter:results(...)
	return require("neotest-criterion.results").results(...)
end

Adapter.mappings["results"] = Adapter.results

return Adapter
