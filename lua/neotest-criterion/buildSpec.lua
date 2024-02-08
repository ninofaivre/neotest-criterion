local Adapter = require("neotest-criterion.Adapter.base")

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

function Adapter:buildSpec(args)
	local tree = args.tree

	local context = {
		results = {},
		tree = tree,
		oldTree = vim.deepcopy(tree, false),
		settings = self.settings
	}

	return {
		command = table.concat(self.settings.buildCommand, " ") .. "&&" .. table.concat({
				self.settings.executable,
				'--verbose',
				self.settings.color and '--color=always' or '--color=never',
				'--always-succeed',
				'--filter', "'" .. criterionFilterBuilder.build(tree) .. "'"
			}, " "),
		env = self.settings.executableEnv,
		stream = function (output_stream)
			return function()
				return Results.asyncResults(output_stream(), context)
			end
		end,
		context = context
	}
end

return Adapter
