local Adapter = require("neotest-criterion.Adapter.base")

local path = require("plenary.path")
local lib = require("neotest.lib")

function Adapter:isFileInTestDir(filePath)
  for _, dir in ipairs(self.settings.testDir or {}) do
    local absoluteTestDirPath = path:new(self.root, dir):absolute()
    if filePath:find("^" .. absoluteTestDirPath) ~= nil then
      return true
    end
  end
  return false
end

function Adapter:isTestFileType(filePath)
  local fileType = lib.files.detect_filetype(filePath)
  return (self.settings.testFileTypes[fileType] == true)
end

function Adapter:isTestFile(filePath)
	if self.root == nil then return false end
  if self.settings.isTestFile ~= nil then
    return self.settings.isTestFile(filePath, self)
  end
	if self.settings.testDir ~= nil and self:isFileInTestDir(filePath) == false then
    return false
	end
  if self:isTestFileType(filePath) == false then
    return false
  end
	return true
end

Adapter.mappings["is_test_file"] = Adapter.isTestFile

return Adapter
