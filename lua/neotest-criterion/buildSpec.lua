local M = {}

local Results = require("neotest-criterion.results")

-- TODO clean this shit
local criterionFilterBuilder = {
	atPatternList = {}
}

criterionFilterBuilder.atPatternList.build = function (list)
	local pattern = table.concat(list, '|')
	if #list > 1 then
		pattern = '@(' .. pattern .. ')'
	end
	return pattern
end

criterionFilterBuilder.build = function (tree)
	local suites = {}
	for _, node in tree:iter_nodes() do
		local nodeData = node:data()
		if (nodeData.type == "test") then
			if not suites[nodeData.suiteName] then
				suites[nodeData.suiteName] = {}
			end
			table.insert(suites[nodeData.suiteName], nodeData.name)
		end
	end
	local subPatterns = {}
	for suiteName, suite in pairs(suites) do
		local subPattern = criterionFilterBuilder.atPatternList.build(suite)
		subPattern = suiteName .. '/' .. subPattern
		table.insert(subPatterns, subPattern)
	end
	return criterionFilterBuilder.atPatternList.build(subPatterns)
end

M.build_spec = function(args)
	local tree = args.tree
	local root = args.tree:root()
	local buildCommand = 'make -j8 test &>/dev/null'
	-- local command = 'LD_LIBRARY_PATH="./Criterion/build/src" ./test --verbose --color=never --filter ' .. criterionFilterBuilder.build(tree)

	local context = {
		results = {},
		tree = tree,
		buildSpecHookStatus = true
	}

	local settings = require("neotest-criterion.settings").get()

	return {
		command = table.concat(settings.buildCommand, " ") .. "&&" .. table.concat({
				settings.executable,
				'--verbose',
				settings.color and '--color=always' or '--color=never',
				'--always-succeed',
				'--filter', "'" .. criterionFilterBuilder.build(tree) .. "'"
			}, " "),
		env = settings.executableEnv,
		stream = function (output_stream)
			return function()
				return Results.asyncResults(output_stream(), context)
			end
		end,
		context = context
	}
end

return M
