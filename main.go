package main

import (
	"context"
	"embed"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"os/signal"

	"github.com/urfave/cli/v3"
	"gopkg.in/yaml.v3"
)

var (
	ConfigDir  = os.ExpandEnv("$XDG_CONFIG_DIR/cmds/")
	ScriptsDir = ConfigDir + "scripts/"
	GraphPath  = ScriptsDir + "graph.yaml"
)

//go:embed scripts/*
var scripts embed.FS

// Our CommandGraph API structure parsed from YAML.
// With this info we can dynamically define a tree of commands.
type CommandGraph struct {
	Commands []struct {
		Name        string   `yaml:"name"`
		Parent      string   `yaml:"parent,omitempty"`
		Path        string   `yaml:"path"`
		Usage       string   `yaml:"usage"`
		Description string   `yaml:"desc"`
		Aliases     []string `yaml:"aliases"`
		Category    string   `yaml:"category,omitempty"`
		Flags       []struct {
			Name     string   `yaml:"name"`
			Usage    string   `yaml:"usage"`
			Aliases  []string `yaml:"aliases"`
			Required bool     `yaml:"required"`
		} `yaml:"flags,omitempty"`
	} `yaml:"commands"`
}

var extractScripts = &cli.Command{
	Name:                  "extract-scripts",
	EnableShellCompletion: true,
	Usage:                 "extracts all embedded scripts to XDG_CONFIG_DIR/cmds/scripts/",
	Action: func(context.Context, *cli.Command) error {
		// attempt to delete config dir
		os.RemoveAll(ConfigDir)

		if err := os.MkdirAll(ConfigDir, 0o755); err != nil {
			return err
		}

		err := fs.WalkDir(scripts, "scripts", func(path string, d fs.DirEntry, err error) error {
			fsPath := ConfigDir + path

			if d.IsDir() {
				if err := os.MkdirAll(fsPath, 0o755); err != nil {
					return err
				}
				return nil
			}

			data, err := scripts.ReadFile(path)
			if err != nil {
				return err
			}

			if err := os.WriteFile(fsPath, data, 0o755); err != nil {
				return err
			}

			return nil
		})
		if err != nil {
			return cli.Exit(err, 1)
		}

		return nil
	},
}

func RunScriptIfExists(ctx context.Context, path string, args []string) error {
	_, err := os.Stat(path)
	if err != nil {
		return err
	}

	// run script in bash
	cmd := exec.CommandContext(ctx, path, args...)

	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin

	err = cmd.Run()
	if err != nil {
		return err
	}
	return nil
}

func parseCommandGraph(g *CommandGraph, app *cli.Command) {
	cmds := map[string]*cli.Command{}

	// keep track of roots, will make stitching the graph together easier.
	roots := map[string]*cli.Command{}

	mkActionFunc := func(cmd *cli.Command, path string, hasFlags bool) cli.ActionFunc {
		scriptPath := ScriptsDir + path
		return func(ctx context.Context, cmd *cli.Command) error {
			args := []string{}

			if hasFlags {
				for _, f := range cmd.Flags {
					args = append(args, cmd.String(f.Names()[0]))
				}
			} else {
				args = cmd.Args().Slice()
			}

			return RunScriptIfExists(
				ctx,
				scriptPath,
				args,
			)
		}
	}

	// Iterate over graph, creating commands
	for _, c := range g.Commands {
		commandID := c.Name + c.Path
		hasFlags := (len(c.Flags) > 0)

		flags := []cli.Flag{}
		for _, f := range c.Flags {
			flags = append(flags, &cli.StringFlag{
				Name:     f.Name,
				Aliases:  f.Aliases,
				Required: f.Required,
				Usage:    f.Usage,
			})
		}

		cmd := &cli.Command{
			Aliases:               c.Aliases,
			Category:              c.Category,
			EnableShellCompletion: true,
			Flags:                 flags,
			HideHelpCommand:       true,
			Name:                  c.Name,
			Usage:                 c.Usage,
			Description:           c.Description,
		}

		if c.Parent == "" {
			roots[commandID] = cmd
		}
		cmds[commandID] = cmd

		// if the command has a script path, we need to generate the action
		// func which runs the script
		if c.Path != "" {
			cmd.Action = mkActionFunc(cmd, c.Path, hasFlags)
		}
	}

	// add our roots to our app
	for _, root := range roots {
		app.Commands = append(app.Commands, root)
	}

	// add sub commands to roots
	for _, c := range g.Commands {
		if c.Parent != "" {
			parentID := c.Parent // parents will never have a c.Path attribute
			parent := cmds[parentID]
			child := cmds[c.Name+c.Path]

			parent.Commands = append(parent.Commands, child)
		}
	}
}

func main() {
	if os.Getenv("XDG_CONFIG_DIR") == "" {
		log.Fatal("XDG_CONFIG_DIR is not set")
	}

	app := &cli.Command{
		Name:                  "cmds",
		EnableShellCompletion: true,
		Commands: []*cli.Command{
			extractScripts,
		},
	}

	graphPath := ConfigDir + "scripts/graph.yaml"

	// parse our the name into our graph
	graph := &CommandGraph{}
	var dec *yaml.Decoder

	f, err := os.Open(graphPath)
	if err != nil {
		log.Println(err)
		goto run
	}

	dec = yaml.NewDecoder(f)
	if err := dec.Decode(graph); err != nil {
		log.Println(err)
		goto run
	}

	parseCommandGraph(graph, app)

run:
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	if err := app.Run(ctx, os.Args); err != nil {
		log.Fatal(err)
	}
}
