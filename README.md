# neotest-criterion
neotest adapter for Criterion (C/C++ unit-test framework)

This is a very early realease, bug are to be expected. Currently it needs a patched consumer for diagnostics.
So you need to disable the default diagnostic consumer.

default settings :
```lua
			require("neotest").setup({
				diagnostic = {
					enabled = false
				},
				consumers = {
					require("neotest-criterion.patchedDiagnostics")
				},
				adapters = {
					require("neotest-criterion").setup({
						buildCommand = {},
						errorMessages = {
							crash = vim.NIL,
							unexpectedSignal = vim.NIL,
							group = false
						},
						executable = "./test",
						color = true,
						executableEnv = {
						},
					})
				}
			})
```

TODO : update Readme
