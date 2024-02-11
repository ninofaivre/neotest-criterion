local Adapter = require("neotest-criterion.Adapter.base")

local lib = require("neotest.lib")

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

Adapter.mappings["root"] = Adapter.root

return Adapter
