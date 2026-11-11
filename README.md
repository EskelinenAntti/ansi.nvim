# chameleon.nvim 🦎

A standalone Neovim colorscheme plugin that uses the active terminal theme colors, in [Rex](https://www.superlogical.com/rex) and other compatible terminals.

Main features:
- Minimal footprint: no need to install any 3rd party theme plugins separately.
- Supports custom terminal themes out-of-the-box. No additional configuration needed.
- Shares highlight definitions with [omarchy-theme.nvim](https://github.com/EskelinenAntti/omarchy-theme.nvim), with no dependency on Omarchy.
- Works with any plugin manager.

## Requirements

- Neovim 0.12 or later.
- A terminal that supports palette queries using OSC 4.

## Installation with vim.pack (Neovim built-in plugin manager)

Add these two lines to your init.lua file and you are good to go.

```lua
vim.pack.add({"https://github.com/EskelinenAntti/chameleon.nvim"})
vim.cmd.colorscheme("chameleon")
```

<details>
    <summary>Other plugin managers and manual installation</summary>
    <br/>
    <p>
    To use the plugin
    <ol>
        <li>Install the <code>EskelinenAntti/chameleon.nvim</code> plugin following the usual steps of your chosen plugin manager.</li>
        <li>Set colorscheme to "chameleon" with <code>vim.cmd.colorscheme("chameleon")</code>.</li>
    </ol>
    </p>
</details>

### Other terminals

The plugin works in any terminal that answers OSC 4 palette queries. It does not check the terminal name or require Rex. OSC 10 and 11 provide the terminal's default foreground and background when supported.

## Appearance

Keywords, functions, and types use regular weight and distinct syntax colors. Muted line numbers and editor guides keep attention on the code. The active line uses a subtle raised surface color and an accented line number; matching parentheses use an underlined selection surface.

Loading the colorscheme enables `cursorline`. To disable it, set the option after loading the colorscheme:

```lua
vim.cmd.colorscheme("chameleon")
vim.opt.cursorline = false
```

## Changing themes

The palette is read once when the colorscheme loads. After changing your terminal theme, restart Neovim or run `:colorscheme chameleon` to update the colors.

## How it works

The plugin queries the terminal's 16 palette colors using OSC 4, and its default foreground and background using OSC 10 and 11. Neovim's `nvim_ui_send()` sends the queries, and `TermResponse` receives the colors asynchronously. No Rex CLI, configuration files, or additional plugins are needed.

If the terminal does not answer OSC 10 and 11, the plugin uses palette colors 7 and 0 for foreground and background. These can differ from the terminal's actual default colors. UI surfaces and selection colors are derived from the palette; terminal yellow is also used for orange highlights.

The temporary response handlers are removed when the query finishes. There is no watcher or polling. If a complete terminal palette cannot be read, the previous highlights are kept and a warning is shown.

### Derived colors

Surface shades use [Material 3's surface tone spacing](https://github.com/material-components/material-components-android/blob/master/docs/theming/Color.md#using-surface-colors), measured on the CIELAB L* scale (0 is black, 100 is white). The tones are shifted relative to the terminal background:

| Surface | Dark theme offset | Light theme offset |
| --- | --- | --- |
| Recessed | -2 | +2 |
| Raised | +4 | -2 |
| Selection | +16 | -8 |

Dark-theme shadows repeat the recessed step; light-theme shadows use the terminal foreground. This is a Material-inspired adaptation: the terminal background stays unchanged, and the generated shades are mixed in linear RGB. Surface tones are limited to retain 4.5:1 foreground contrast, or the terminal's original contrast if lower.

Comments target [4.5:1 contrast](https://www.w3.org/WAI/WCAG21/Techniques/general/G18) across editor surfaces, and muted UI colors target [3:1](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html). Syntax accents target 4.5:1 on editor and float backgrounds. Readable ANSI colors stay unchanged; weaker accents adjust tone while keeping their original hues. Visual selections use the regular foreground, or inverted terminal colors when the selection surface would otherwise be indistinct. Targets are limited by the terminal foreground's contrast, and the original terminal palette stays unchanged. These targets do not imply WCAG compliance for every highlight group.

Diffs use subtle red, green, and yellow surfaces derived from the palette. Syntax colors remain visible on added and changed lines, with a stronger surface for changed text within a line.

## Development

Palette property names are project-specific semantic roles, not a standardized palette schema. Color derivation and contrast decisions belong in `lua/chameleon/palette.lua`. `lua/chameleon/highlighter.lua` only maps semantic palette roles to Neovim highlight definitions. Public colors describe syntax, diagnostics, and UI purposes; ANSI hue names stay private to palette derivation.

Run the tests with `make test`. Update the highlight snapshot with `make snapshot`.
