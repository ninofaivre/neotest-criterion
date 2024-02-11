local Adapter = require("neotest-criterion.Adapter.base")

local lib = require("neotest.lib")

-- nParams is unused currently but might be useful later
local function getEnrichedPositionForParameterizedTest(position, source, captured_nodes)
	local parametersListNode = captured_nodes["test.parameters.list"]
	if parametersListNode == nil then return position end

	local nParams = 0
	for child in parametersListNode:iter_children() do
		local type = child:type()
		if type ~= '{' and type ~= '}' and type ~= ',' then
			nParams = nParams + 1
		end
	end
	position.nParams = nParams or nil
	return position
end

local function build_position(file_path, source, captured_nodes)
	-- namespaces are not captured currently, they are hand managed
	local match_type = captured_nodes["test.name"] and "test"
	if match_type == nil then return end

	local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
	local suiteName = vim.treesitter.get_node_text(captured_nodes[match_type .. ".suiteName"], source)
	local kind = vim.treesitter.get_node_text(captured_nodes[match_type .. ".kind"], source)
	local definitionNode = captured_nodes[match_type .. ".definition"]

	local position = {
		type = match_type,
		path = file_path,
		name = name,
		suiteName = suiteName,
		kind = kind,
		criterionTarget = suiteName .. '/' .. name,
		criterionId = suiteName .. "::" .. name,
		range = { definitionNode:range() },
	}
	if position.kind == "ParameterizedTest" then
		return getEnrichedPositionForParameterizedTest(position, source, captured_nodes)
	end
	return position
end

local function addNamespaces(tree)
	local suites = {}
	local fileobj = tree:root():data()
	for _, node in tree:iter_nodes() do
		local nodeData = node:data()
		if nodeData.type == "test" then
			nodeData.id = fileobj.path .. '::' .. nodeData.suiteName .. '::' .. nodeData.name
			if not suites[nodeData.suiteName] then
				suites[nodeData.suiteName] = {{
					type = "namespace",
					path = fileobj.path,
					name = nodeData.suiteName,
					range = nil,
					id = fileobj.path .. '::' .. nodeData.suiteName
				}}
			end
			table.insert(suites[nodeData.suiteName], nodeData)
		end
	end
	local list = { fileobj }
	for _, suite in pairs(suites) do
		table.insert(list, suite)
	end
	return require("neotest.types").Tree.from_list(list, function (pos) return pos.id end)
end

function Adapter:discoverPositions (file_path)
	local query = [[
		(
			(expression_statement
				(call_expression
					function: (identifier) @tmp.id (#eq? @tmp.id "ParameterizedTestParameters")
					arguments: (argument_list
						.(identifier) @test.parameters.suiteName
						.(identifier) @test.parameters.name
					)
				)
			)
			. (compound_statement
				(declaration
					declarator: (init_declarator
						value: (initializer_list) @test.parameters.list
					)
				)
			) ?
			(expression_statement
				(call_expression
					function: (identifier) @test.kind (#eq? @test.kind "ParameterizedTest")
					arguments: (argument_list
						.(binary_expression)
						.(identifier) @test.suiteName (#eq? @test.suiteName @test.parameters.suiteName)
						.(identifier) @test.name (#eq? @test.name @test.parameters.name)
					)
				)
			) @test.definition
			. (compound_statement) @test.definition
		)

		(
			(expression_statement
				(call_expression
					function: (identifier) @test.kind (#any-of? @test.kind "Test" "Theory")
					arguments: (argument_list
						.(parenthesized_expression) ? ;; to match Theory, might do the same than parameterized later
						.(identifier) @test.suiteName
						.(identifier) @test.name
					)
				)
			) @test.definition
			. (compound_statement) @test.definition
		)
	]]
	local opts = { build_position = build_position }
	local tree = lib.treesitter.parse_positions(file_path, query, opts)
	return addNamespaces(tree)
end

Adapter.mappings["discover_positions"] = Adapter.discoverPositions

return Adapter
