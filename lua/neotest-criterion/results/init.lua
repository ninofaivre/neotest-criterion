local M = {}

local Lexer = require("neotest-criterion.results.lexing").Lexer
local Parser = require("neotest-criterion.results.parsing").Parser
local Interpreter = require("neotest-criterion.results.interpreting").Interpreter

local statusLevel = { ["running"] = 0, ["skipped"] = 1, ["passed"] = 2, ["failed"] = 3 }

-- could cause an issue if setting is changed during a test (very unlikely)
local function pushNewErrors(pastResult, newErrors, settings)
	if settings.errorMessages.group == false then
		for _, error in ipairs(newErrors) do
			table.insert(pastResult.errors, error)
		end
		return
	end
	for _, error in ipairs(newErrors) do
		local metaId = (error.line or "") .. error.message .. (error.severity or "")
		if pastResult.meta[metaId] == nil then
			table.insert(pastResult.errors, error)
			pastResult.meta[metaId] = { n = 1, i_error = #pastResult.errors }
		else
			local currMeta = pastResult.meta[metaId]
			currMeta.n = currMeta.n + 1
			pastResult.errors[currMeta.i_error].message = error.message .. " (x" .. currMeta.n .. ")"
		end
	end
end

M.asyncResults = function(output, context)
	local lexer = Lexer:new({ output = output })
	local parser = Parser:new({ lexer = lexer })
	local interpreter = Interpreter:new({
		parser = parser,
		context = context
	})

	local pastResults = context.results
	local results = {}

	local result = interpreter:getNextResult()
	while result ~= nil do
		local neotestId = result.test.id
		local aggregatedResult = pastResults[neotestId]
		if aggregatedResult == nil then
			local errors = result.errors
			result.errors = {}
			aggregatedResult = result
			aggregatedResult.meta = {}
			pushNewErrors(aggregatedResult, errors, context.settings)
		else
			if statusLevel[result.status] > statusLevel[aggregatedResult.status] then
				aggregatedResult.status = result.status
			end
			aggregatedResult.short = aggregatedResult.short .. result.short
			pushNewErrors(aggregatedResult, result.errors, context.settings)
		end
		pastResults[neotestId] = aggregatedResult
		results[neotestId] = aggregatedResult

		result = interpreter:getNextResult()
	end

	return results
end

M.results = function(spec, result, tree)
	if result.code ~= 0 then
		for _, node in tree:iter_nodes() do
			local nodeData = node:data()
			spec.context.results[nodeData.id] = { status = "skipped" }
		end
	end
	return spec.context.results
end

return M
