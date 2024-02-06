local M = {}

local parsing = require("neotest-criterion.results.parsing")
local tokenTypes = require("neotest-criterion.results.lexing").tokenTypes
local itemTypes = parsing.itemTypes
local settings = require("neotest-criterion.settings")

local function findTokenByTypeInList(list, type, n)
	n = n or 1
	local nt = 0
	for i_token, token in ipairs(list) do
		if token.type == type then
			nt = nt + 1
			if nt == n then
				return token, i_token
			end
		end
	end
	return nil
end

local function getTestIdFromFilePosition(tree, filePosition)
	for _, node in tree:iter_nodes() do
		local nodeData = node:data()
		if nodeData.type == "test" and nodeData.id:find(filePosition.path) then
			local range = nodeData.range
			if range[1] <= filePosition.line - 1 and range[3] >= filePosition.line - 1 then
				return nodeData.id
			end
		end
	end
end

local function getLineContentFromTokens(tokens, start_pos)
	local origins = {}
	while tokens[start_pos].type == tokenTypes.Whitespaces do
		start_pos = start_pos + 1
	end
	while tokens[start_pos].type ~= tokenTypes.Eol do
		if tokens[start_pos].type ~= tokenTypes.OpenColor and tokens[start_pos].type ~= tokenTypes.CloseColor then
			table.insert(origins, tokens[start_pos].origin)
		end
		start_pos = start_pos + 1
	end
	return table.concat(origins, "")
end

local resultCorrespondanceTable = {
	[itemTypes.SuccessedTestResult] = function()
		return { status = "passed" }
	end,
	[itemTypes.FailedTestResult] = function ()
		return { status = "failed" }
	end,
	[itemTypes.CrashedTestResult] = function ()
		local result = {
			status = "failed",
		}
		if settings.get().crashErrorMessage ~= vim.NIL then
			result.errors = {{
				message = settings.get().errorMessages.crash
			}}
		end
		return result
	end,
	[itemTypes.Skip] = function ()
		return { status = "skipped" }
	end,
	[itemTypes.FailedAssertion] = function (item, interpreter)
		local filePath = findTokenByTypeInList(item.tokens, tokenTypes.FilePath).origin
		local lineNumber = findTokenByTypeInList(item.tokens, tokenTypes.Number).image

		local _, i_token = findTokenByTypeInList(item.tokens, tokenTypes.CloseSquareBracket, 3)
		local message = getLineContentFromTokens(item.tokens, i_token + 1)

		local neotestId = getTestIdFromFilePosition(interpreter.tree, { path = filePath, line = lineNumber })
		return {
			neotestId = neotestId,
			errors = {{
				line = lineNumber - 1,
				message = message
			}}
		}
	end,
	[itemTypes.UnexpectedSignal] = function (item, interpreter)
		local filePath = findTokenByTypeInList(item.tokens, tokenTypes.FilePath).origin
		local lineNumber = findTokenByTypeInList(item.tokens, tokenTypes.Number).image
		local neotestId = getTestIdFromFilePosition(interpreter.tree, { path = filePath, line = lineNumber })
		return {
			neotestId = neotestId,
			errors = {{
				line = lineNumber - 1,
				message = settings.get().errorMessages.unexpectedSignal
			}}
		}
	end,
	[itemTypes.TheoryParametersFailure] = function (item)
		local parameter = findTokenByTypeInList(item.tokens, tokenTypes.FailedParameters).origin
		return {
			errors = {{
				message = parameter
			}}
		}
	end,
}

local Interpreter = {}

function Interpreter:new(init)
	init = vim.tbl_extend("force", {
		parser = parsing.Parser:new({}),
		tree = nil
	}, init)
	setmetatable(init, self)
	self.__index = self
	return init
end

function Interpreter:getNextResult()
	local item = self.parser:getNextItem()
	if item == nil then return nil end

	local testIdToken = findTokenByTypeInList(item.tokens, tokenTypes.TestId)

	local corr = resultCorrespondanceTable[item.type]
	local result = {
		status = "running",
		criterionId = testIdToken and testIdToken.image,
		errors = {}
	}
	if corr ~= nil then
		result = vim.tbl_deep_extend("force", result, corr(item, self, result))
	end
	if result.criterionId == nil and result.neotestId == nil then
		return self.parser:getNextItem()
	end
	if result.short == nil then
		local origins = vim.tbl_map(function (token) return token.origin end, item.tokens)
		result.short = table.concat(origins, "")
	end
	return result
end

M.Interpreter = Interpreter

return M
