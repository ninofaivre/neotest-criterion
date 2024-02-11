local Adapter = require("neotest-criterion.Adapter.base")

Adapter = require("neotest-criterion.Adapter.root")
Adapter = require("neotest-criterion.Adapter.filterDir")
Adapter = require("neotest-criterion.Adapter.isTestFile")
Adapter = require("neotest-criterion.discoverPositions")
Adapter = require("neotest-criterion.buildSpec")

return Adapter
