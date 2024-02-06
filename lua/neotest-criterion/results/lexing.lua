local M = {}

local tokenTypes = {
	StatusFail = { "StatusFail" },
	StatusRun = { "StatusRun" },
	StatusSkip = { "StatusSkip" },
	StatusPass = { "StatusPass" },
	StatusDash = { "StatusDash" },
	StatusDoubleDash = { "StatusDoubleDash" },
	StatusWarn = { "StatusWarn" },
	StatusErr = { "StatusErr" },
	Eol = { "Eol" },
	Eof = { "Eof" },
	Whitespaces = { "Whitespaces" },
	Sentence = { "Sentence" },
	FilePath = { "FilePath" },
	Colon = { "Colon" },
	Number = { "Number" },
	TestId = { "TestId" },
	Duration = { "Duration" },
	AssertionFailed = { "AssertionFailed" },
	UnexpectedSignal = { "UnexpectedSignal" },
	Crash = { "Crash" },
	Theory = { "Theory" },
	FailedParameters = { "FailedParameters" },
	Synthesis = { "Synthesis" },
	OpenSquareBracket = { "OpenSquareBracket" },
	CloseSquareBracket = { "CloseSquareBracket" },
	OpenColor = { "OpenColor" },
	CloseColor = { "CloseColor" }
}

-- implicit ^ in front of every regex
-- order matter
local tokenCorrespondenceTable = {
	{
		regex = "$",
		type = tokenTypes.Eol,
		origin = "\n"
	}, {
		regex = "\27%[0;%d+m",
		type = tokenTypes.OpenColor
	}, {
		regex = "\27%[0m",
		type = tokenTypes.CloseColor
	}, {
		regex = "%s+",
		type = tokenTypes.Whitespaces
	}, {
		regex = "%[",
		type = tokenTypes.OpenSquareBracket
	}, {
		regex = "%]",
		type = tokenTypes.CloseSquareBracket
	}, {
		regex = "FAIL",
		type = tokenTypes.StatusFail
	}, {
		regex = "RUN",
		type = tokenTypes.StatusRun
	}, {
		regex = "SKIP",
		type = tokenTypes.StatusSkip
	}, {
		regex = "PASS",
		type = tokenTypes.StatusPass
	}, {
		-- pourquoi je ne dois en matcher que 3 au lieu de 4 ??? wtf ???!!!
		regex = "%-%-%-%-",
		type = tokenTypes.StatusDash
	}, {
		regex = "====",
		type = tokenTypes.StatusDoubleDash
	}, {
		regex = "WARN",
		type = tokenTypes.StatusWarn
	}, {
		regex = "ERR",
		type = tokenTypes.StatusErr
	}, {
		regex = "Assertion Failed",
		type = tokenTypes.AssertionFailed
	}, {
		regex = "Unexpected signal caught below this line!",
		type = tokenTypes.UnexpectedSignal
	}, {
		regex = "CRASH!",
		type = tokenTypes.Crash
	}, {
		regex = "Synthesis",
		type = tokenTypes.Synthesis
	}, {
		regex = "Theory",
		type = tokenTypes.Theory
	}, {
		regex = "failed with the following parameters: %(.*%)",
		type = tokenTypes.FailedParameters
	}, {
		regex = "%(%d+.%d+s%)",
		-- need to find out if time can be
		-- displayed in other unit than sec
		type = tokenTypes.Duration,
		image = function (match)
			return match:sub(2, match:len() - 1)
		end
	}, {
		regex = "%S+/%S+%.c",
		type = tokenTypes.FilePath
	}, {
		regex = ":",
		type = tokenTypes.Colon
	}, {
		regex = "%d+",
		type = tokenTypes.Number,
		image = function (match)
			return tonumber(match)
		end
	}, {
		regex = "%S+::%S+",
		type = tokenTypes.TestId,
		image = function (match)
			return match:find(":$") and match:sub(1, match:len() - 1) or match
		end
	}
}

local Lexer = {}

function Lexer:new(init)
	init = vim.tbl_extend("force", {
		output = {},
		cursor = { 1, 1 }
	}, init)
	setmetatable(init, self)
	self.__index = self
	return init
end

function Lexer:_getLine()
	local line = self.output[self.cursor[1]]
	if line == nil then return nil end
	return line:sub(self.cursor[2])
end

function Lexer:_getRangeAndTokenFromLine()
	local line = self:_getLine()
	if line == nil then
		return nil, { type = tokenTypes.Eof }
	end
	-- vim.notify("On tente de trouver line : |" .. vim.inspect(line) .. '|\n\n')
	local token = nil
	local range = nil
	for _, correspondence in pairs(tokenCorrespondenceTable) do
		range = { line:find("^" .. correspondence.regex) }
		if #range ~= 0 then
			token = {
				type = correspondence.type,
				origin = line:sub(unpack(range))
			}
			if type(correspondence.image) == "function" then
				token.image = correspondence.image(token.origin)
			end
			if correspondence.origin ~= nil then
				token.origin = correspondence.origin
			end
			break ;
		end
	end
	if range ~= nil and token ~= nil then
		return range, token
	end
	return { 0, line:len() }, { type = tokenTypes.Sentence, origin = line }
end

function Lexer:getNextToken()
	local range, token = self:_getRangeAndTokenFromLine()
	if token.type == tokenTypes.Eof then
		return token
	end
	if token.type == tokenTypes.Eol then
		self.cursor[2] = 1
		self.cursor[1] = self.cursor[1] + 1
		return token
	end
	self.cursor[2] = self.cursor[2] + range[2]
	local line = self:_getLine()
	if line == nil then
		return { type = tokenTypes.Eof }
	end
	-- vim.notify("line before going to next char : |" .. vim.inspect(line) .. "|\n\n")
	-- local nextChar = line:find("[%S\27]")
	-- nextChar = nextChar and nextChar - 1
	-- self.cursor[2] = self.cursor[2] + (nextChar or line:len())
	return token
end

M.Lexer = Lexer
M.tokenTypes = tokenTypes
return M
