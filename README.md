# chameleon.nvim 🦎

A small Neovim colorscheme that follows your terminal's palette. No dependencies or configuration.

Requires **Neovim 0.12+** and a terminal that answers OSC 4 color queries, such as [Rex](https://www.superlogical.com/rex).

```lua
vim.pack.add({ "https://github.com/EskelinenAntti/chameleon.nvim" })
vim.cmd.colorscheme("chameleon")
```

With another plugin manager, install `EskelinenAntti/chameleon.nvim` and load the `chameleon` colorscheme.

The theme keeps your terminal background and foreground, uses its six ANSI accents for syntax, and derives a quiet surface for the cursor line, floats, and menus. Accents are adjusted for readable, consistent contrast. Comments are muted, selections invert the default colors, and diffs use subtle accent tints. Neovim's built-in highlight links carry these colors into Treesitter, LSP, and plugins that use standard groups.

Cursor line visibility follows your own setting. To enable it:

```lua
vim.opt.cursorline = true
```

After changing your terminal theme, run `:colorscheme chameleon` to read it again.

## How it works

On load, Chameleon reads the terminal's 16 ANSI colors with OSC 4 and its default foreground/background with OSC 10/11. It waits for the UI to attach when loaded from `init.lua`. Queries run asynchronously; their timer and event handlers are removed on completion or when you switch colorschemes. There is no watcher, polling, or palette cache.

Terminals without OSC 10/11 support fall back to ANSI 7/0 after one second. An incomplete ANSI palette leaves existing highlights intact and shows a warning. A `ColorScheme` event is emitted after the colors arrive so plugins can refresh.

Color derivation uses relative luminance in linear RGB. The shared surface retains at least 4.5:1 foreground contrast, limited by the terminal's own contrast. Muted text and accents target the same contrast on the default and shared surfaces; faint guides target 3:1. The terminal's original colors are preserved for embedded terminals.

## Development

The implementation has three parts: terminal queries, palette derivation, and highlight assignments, connected by `colors/chameleon.lua`. Most syntax and diagnostic variants inherit through Neovim's default links.

Run `make test` with Neovim 0.12+ on your PATH. The tests exercise terminal events, query cleanup, colorscheme switching, and readability across dark, light, and low-contrast palettes.
