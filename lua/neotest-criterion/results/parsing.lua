local M = {}

local lexing = require("neotest-criterion.results.lexing")

local tokenTypes = lexing.tokenTypes
tokenTypes.WildcardDot = { "WildcardDot" }

local repetitionTypes = {
	UntilEol = { "UntilEol" }
}

local Parser = {}

local itemTypes = {
	FailedAssertion = { "FailedAssertion" },
	TheoryParametersFailure = { "TheoryParametersFailure" },
	UnexpectedSignal = { "UnexpectedSignal" },
	Synthesis = { "Synthesis" },
	FailedTestResult = { "FailedTestResult" },
	CrashedTestResult = { "CrashedTestResult" },
	SuccessedTestResult = { "SuccessedTestResult" },
	Run = { "Run" },
	Skip = { "Skip" },
	ErrorLog = { "ErrorLog" },
	WarnLog = { "WarnLog" },
	Log = { "Log" }
}

local function bracketEnclosedToken(tokenType)
	return {
		pattern = { tokenTypes.OpenSquareBracket, tokenType, tokenTypes.CloseSquareBracket }
	}
end

local function repeatTokens(repetition, ...)
	return {
		pattern = { ... },
		repetition = repetition
	}
end

local itemCorrespondenceTable = {
	{
		type = itemTypes.TheoryParametersFailure,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusDash), tokenTypes.Theory, tokenTypes.TestId, tokenTypes.FailedParameters, tokenTypes.Eol
		}
	}, {
		type = itemTypes.FailedAssertion,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusDash), tokenTypes.FilePath, tokenTypes.Colon, tokenTypes.Number, tokenTypes.Colon, tokenTypes.AssertionFailed, tokenTypes.Eol,
			bracketEnclosedToken(tokenTypes.StatusDash), tokenTypes.Eol,
			bracketEnclosedToken(tokenTypes.StatusDash), repeatTokens(repetitionTypes.UntilEol, tokenTypes.WildcardDot), tokenTypes.Eol,
			bracketEnclosedToken(tokenTypes.StatusDash), tokenTypes.Eol
		}
	}, {
		type = itemTypes.UnexpectedSignal,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusDash), tokenTypes.FilePath, tokenTypes.Colon, tokenTypes.Number, tokenTypes.Colon, tokenTypes.UnexpectedSignal, tokenTypes.Eol
		}
	}, {
		type = itemTypes.Synthesis,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusDoubleDash), tokenTypes.Synthesis, repeatTokens(repetitionTypes.UntilEol, tokenTypes.WildcardDot), tokenTypes.Eol,
			tokenTypes.Eof
		}
	}, {
		type = itemTypes.FailedTestResult,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusFail), tokenTypes.TestId, tokenTypes.Duration, tokenTypes.Eol
		}
	}, {
		type = itemTypes.CrashedTestResult,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusFail), tokenTypes.TestId, tokenTypes.Crash, tokenTypes.Eol
		}
	}, {
		type = itemTypes.SuccessedTestResult,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusPass), tokenTypes.TestId, tokenTypes.Duration, tokenTypes.Eol
		}
	}, {
		type = itemTypes.Run,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusRun), tokenTypes.TestId, tokenTypes.Eol
		}
	}, {
		type = itemTypes.Skip,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusSkip), tokenTypes.TestId, repeatTokens(repetitionTypes.UntilEol, tokenTypes.WildcardDot), tokenTypes.Eol
		}
	}, {
		type = itemTypes.ErrorLog,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusErr), tokenTypes.TestId, repeatTokens(repetitionTypes.UntilEol, tokenTypes.WildcardDot), tokenTypes.Eol
		}
	}, {
		type = itemTypes.WarnLog,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusWarn), tokenTypes.TestId, repeatTokens(repetitionTypes.UntilEol, tokenTypes.WildcardDot), tokenTypes.Eol
		}
	}, {
		type = itemTypes.Log,
		pattern = {
			bracketEnclosedToken(tokenTypes.StatusDash), tokenTypes.TestId, repeatTokens(repetitionTypes.UntilEol, tokenTypes.WildcardDot), tokenTypes.Eol
		}
	}
}

function Parser:new(init)
	init = vim.tbl_extend("force", {
		lexer = lexing.Lexer:new({}),
		cursor = 1,
		_tokens = {},
		goToNextLineIfNoCorr = true
	}, init)
	setmetatable(init, self)
	self.__index = self
	return init
end

function Parser:_getTokenAtCursor()
	return self._tokens[self.cursor]
end

function Parser:_loadOneMoreToken()
	local token = self.lexer:getNextToken()
	if token.type == tokenTypes.Eof then
		return nil
	end
	table.insert(self._tokens, token)
	return token
end

function Parser:_getNextToken()
	local token = self:_getTokenAtCursor()
		or self:_loadOneMoreToken()
	if token == nil then return token end
	self.cursor = self.cursor + 1
	return token
end

function Parser:_tryToMatchCorrespondence(correspondence)
	local oldCursor = self.cursor

	local pattern = correspondence.pattern
	local repetition = correspondence.repetition

	local tokens = {}
	local i = 1
	local token = self:_getNextToken()

	while
		token ~= nil and pattern[i] ~= nil and (token.type == pattern[i] or pattern[i] == tokenTypes.WildcardDot or token.type == tokenTypes.OpenColor or token.type == tokenTypes.CloseColor or token.type == tokenTypes.Whitespaces or pattern[i].pattern ~= nil)
	do
		if pattern[i].pattern ~= nil then
			self.cursor = self.cursor - 1
			local tmp = self:_tryToMatchCorrespondence(pattern[i])
			if tmp == nil then
				break ;
			end
			for _, t in ipairs(tmp) do
				table.insert(tokens, t)
			end
			i = i + 1
		else
			table.insert(tokens, token)
			if token.type == pattern[i] or pattern[i] == tokenTypes.WildcardDot then
				i = i + 1
			end
		end
		token = self:_getNextToken()
	end

	if pattern[i] == nil then
		self.cursor = self.cursor - 1
		if repetition == repetitionTypes.UntilEol and token.type ~= tokenTypes.Eol then
			local tokensToAdd = self:_tryToMatchCorrespondence(correspondence)
			if tokensToAdd ~= nil then
				for _, ttt in ipairs(tokensToAdd) do
					table.insert(tokens, ttt)
				end
			end
		end
		return tokens
	end
	self.cursor = oldCursor
	return nil
end

function Parser:_tryToMatchItem()
	for _, correspondence in ipairs(itemCorrespondenceTable) do
		local type = correspondence.type
		local tokens = self:_tryToMatchCorrespondence(correspondence)
		if tokens ~= nil then
			return { type = type, tokens = tokens }
		end
	end
	return nil
end

function Parser:_cursorToNextLine()
	local token = {}
	while token ~= nil and token.type ~= tokenTypes.Eol and token.type ~= tokenTypes.Eof do
		token = self:_getNextToken()
	end
end

function Parser:getNextItem()
	local item = self:_tryToMatchItem()
	while item == nil and self._tokens[self.cursor] ~= nil do
		-- idk if it will be usefull later, the first one has higher perfs
		-- but the second one can match midLine Items
		if self.goToNextLineIfNoCorr == true then
			self:_cursorToNextLine()
		else
			self.cursor = self.cursor + 1
		end
		item = self:_tryToMatchItem()
	end
	return item
end

M.Parser = Parser
M.itemTypes = itemTypes

return M
