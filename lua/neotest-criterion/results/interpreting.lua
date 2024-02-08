local M = {}

local parsing = require("neotest-criterion.results.parsing")
local tokenTypes = require("neotest-criterion.results.lexing").tokenTypes
local itemTypes = parsing.itemTypes

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

local function getTestFromFilePosition(tree, filePosition)
	for _, node in tree:iter_nodes() do
		local nodeData = node:data()
		if nodeData.type == "test" and nodeData.id:find(filePosition.path) then
			local range = nodeData.range
			if range[1] <= filePosition.line - 1 and range[3] >= filePosition.line - 1 then
				return nodeData
			end
		end
	end
end

local function getRawLineContentFromTokens(tokens, start_pos)
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
	[itemTypes.CrashedTestResult] = function (_, interpreter)
		local result = {
			status = "failed",
		}
		if interpreter.context.settings.errorMessages.crash ~= vim.NIL then
			result.errors = {{
				message = interpreter.context.settings.errorMessages.crash
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
		local message = getRawLineContentFromTokens(item.tokens, i_token + 1)

		local test = getTestFromFilePosition(interpreter.context.oldTree, { path = filePath, line = lineNumber })
		if test == nil then return nil end
		return {
			neotestId = test.id,
			errors = {{
				line = lineNumber - 1,
				message = message
			}}
		}
	end,
	[itemTypes.UnexpectedSignal] = function (item, interpreter)
		local filePath = findTokenByTypeInList(item.tokens, tokenTypes.FilePath).origin
		local lineNumber = findTokenByTypeInList(item.tokens, tokenTypes.Number).image
		local test = getTestFromFilePosition(interpreter.context.oldTree, { path = filePath, line = lineNumber })
		if test == nil then return nil end
		if interpreter.context.settings.noUnexpectedSignalAtStartOfTest == true and (lineNumber - 1) == test.range[1] then
			return nil
		end
		return {
			neotestId = test.id,
			errors = {{
				line = lineNumber - 1,
				message = interpreter.context.settings.errorMessages.unexpectedSignal
			}}
		}
	end,
	[itemTypes.ErrorLog] = function (item, interpreter)
		local _, i_token = findTokenByTypeInList(item.tokens, tokenTypes.TestId)
		local error = getRawLineContentFromTokens(item.tokens, i_token + 1)
		local status = nil
		if interpreter.context.settings.criterionLogErrorFailTest == true then
			status = "failed"
		end

		return {
			errors = {{
				message = error,
				severity = vim.diagnostic.severity.ERROR
			}},
			status = status
		}
	end,
	[itemTypes.WarnLog] = function (item)
		local _, i_token = findTokenByTypeInList(item.tokens, tokenTypes.TestId)
		local warning = getRawLineContentFromTokens(item.tokens, i_token + 1)

		return {
			errors = {{
				message = warning,
				severity = vim.diagnostic.severity.WARN
			}}
		}
	end,
	[itemTypes.Log] = function (item)
		local _, i_token = findTokenByTypeInList(item.tokens, tokenTypes.TestId)
		local log = getRawLineContentFromTokens(item.tokens, i_token + 1)

		return {
			errors = {{
				message = log,
				severity = vim.diagnostic.severity.INFO
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

local function findTestInTree(tree, key, value)
	for _, node in tree:iter_nodes() do
		local nodeData = node:data()
		if nodeData.type == "test" and nodeData[key] == value then
			return nodeData
		end
	end
	return nil
end

function Interpreter:new(init)
	init = vim.tbl_extend("force", {
		parser = parsing.Parser:new({})
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
		local corrResult = corr(item, self, result)
		if corrResult == nil then return self:getNextResult() end
		result = vim.tbl_deep_extend("force", result, corrResult)
	end
	if result.criterionId == nil and result.neotestId == nil then
		return self:getNextResult()
	end
	result.test = (result.neotestId and findTestInTree(self.context.tree, "id", result.neotestId))
		or findTestInTree(self.context.tree, "criterionId", result.criterionId)
	if result.test == nil then return self:getNextResult() end
	if result.short == nil then
		local origins = vim.tbl_map(function (token) return token.origin end, item.tokens)
		result.short = table.concat(origins, "")
	end
	return result
end

M.Interpreter = Interpreter

return M
