# neotest-criterion

## !WIP!
neotest adapter for Criterion (C/C++ unit-test framework)

This is a very early realease, bug are to be expected. Currently it needs a patched consumer for diagnostics.
So you need to disable the default diagnostic consumer. The patched one should be fairly compatible with the
default one so others adapters should be okay. If it's not the case then you can replace it on a per project
setting basis.

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
            color = true,
            errorMessages = {
                crash = "CRASH",
                unexpectedSignal = "Unexpected signal caught below this line!",
                group = false
            },
            criterionLogErrorFailTest = false,
            noUnexpectedSignalAtStartOfTest = false,
            buildCommand = {},
            executable = "./test",
            executableEnv = {}
        })
    }
})
```

## TODO :

- [ ] update Readme
    - [ ] exemples
    - [ ] explaining settings
    - [ ] correcting my bad English
- [x] isTestFile
- [x] isTestDir
- [x] buildCommand
