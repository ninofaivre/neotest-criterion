local Adapter = require("neotest-criterion.Adapter.base")

local path = require("plenary.path")

function Adapter:isDirPathOfTestDir(relDirPath)
  local absoluteDirPath = path:new(self.root, relDirPath):absolute()
  for _, testDir in ipairs(self.settings.testDir or {}) do
    local absoluteTestDirPath = path:new(self.root, testDir):absolute()
    if absoluteDirPath:len() >= absoluteTestDirPath:len() then
      if absoluteDirPath:find("^" .. absoluteTestDirPath) ~= nil then
        return true
      end
    elseif absoluteTestDirPath:find("^" .. absoluteDirPath) ~= nil then
      return true
    end
  end
  return false
end

function Adapter:isTestDirExcluded(relDirPath)
  local absoluteDirPath = path:new(self.root, relDirPath):absolute()
  for _, testDir in ipairs(self.settings.excludeTestDir or {}) do
    local absoluteTestDirPath = path:new(self.root, testDir):absolute()
    if absoluteTestDirPath:sub(absoluteTestDirPath:len()) == "/" then
      absoluteTestDirPath = absoluteTestDirPath:sub(0, absoluteTestDirPath:len() - 1)
    end
    if absoluteDirPath == absoluteTestDirPath then
      return true
    end
  end
  return false
end

function Adapter:filterDir(name, relPath, root)
  if self.root == nil then return false end
	if self.settings.filterDir ~= nil then
		return self.settings.filterDir(name, relPath, root, self)
	end
	if self.settings.testDir ~= nil and self:isDirPathOfTestDir(relPath) == false then
    return false
	end
  if self.settings.excludeTestDir ~= nil and self:isTestDirExcluded(relPath) == true then
    return false
  end
	return true
end

Adapter.mappings["filter_dir"] = Adapter.filterDir

return Adapter
