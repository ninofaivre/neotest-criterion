local lib = require("neotest.lib")
local path = require("plenary.path")
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
	self.root = self.settings.root
		or (self.settings.getRoot and self.settings.getRoot(dir))
		or lib.files.match_root_pattern(
			"compile_commands.json",
			".clangd",
			"init.lua",
			"init.vim",
			"build",
			".git",
			"Makefile"
		)(dir)
	return self.root
end

function Adapter:filterDir(name, rel_path, root)
	if self.settings.testDir ~= nil then
		if rel_path:len() >= self.settings.testDir:len() then
			return (rel_path:find("^" .. self.settings.testDir) ~= nil)
		end
		return (self.settings.testDir:find("^" .. rel_path) ~= nil)
	end
	if self.settings.filterDir ~= nil then
		return self.settings.filterDir(name, rel_path, root)
	end
	return true
end

function Adapter:isTestFile(file_path)
	if self.root == nil then
		return false
	end
	if self.settings.testDir ~= nil then
		local normalizedFilePath = path:new(file_path):normalize(self.root)
		local normalizedTestDirPath = path:new(self.root, self.settings.testDir):normalize(self.root)
		if normalizedFilePath:find("^" .. normalizedTestDirPath) == nil then
			return false
		end
	end
	if lib.files.detect_filetype(file_path) ~= "c" then
		return false
	end
	return true
end

function Adapter:results(...)
	return require("neotest-criterion.results").results(...)
end

return Adapter
