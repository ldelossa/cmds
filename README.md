# CMDS

A *probably over-engineered* CLI wrapper for the more complex shell scripts I
use from day-to-day.

This project started mostly due to two reasons
1. I like writing quick and dirty shell scripts.
2. I forget how these quick and dirty shell scripts work pretty often.

So, I wanted to keep writing quick and dirty shell scripts but also give them
a bit of context such as descriptions, argument names, autocompletion, etc...

This project has a tiny bit of Go code which reads a command graph from the
`scripts/graph.yaml` file and dynamically creates a mirrored command graph using
the `urfave/cli` module.

A whole bunch of shell scripts then exist in `scripts/` and each command in
`graph.yaml` targets one, or none if its just a container sub-command.

All scripts are embedded into the resulting Golang binary and extract into
`XDG_CONFIG_DIR/cmds/scripts` when the `extract-scripts` command is ran.
Therefore, the CLI is self-contained.

