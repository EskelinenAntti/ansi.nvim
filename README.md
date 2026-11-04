# rex-theme.nvim 🎨

A standalone Neovim colorscheme plugin that uses the active [Rex](https://www.superlogical.com/rex) theme colors.

Main features:
- Minimal footprint: no need to install any 3rd party theme plugins separately.
- Supports custom Rex themes out-of-the-box. No additional configuration needed.
- Shares highlight definitions with [omarchy-theme.nvim](https://github.com/EskelinenAntti/omarchy-theme.nvim), with no dependency on Omarchy.
- Works with any plugin manager.

## Requirements

- Neovim 0.12 or later.
- Neovim running in a Rex terminal.

## Installation with vim.pack (Neovim built-in plugin manager)

Add these two lines to your init.lua file and you are good to go.

```lua
vim.pack.add({"https://github.com/EskelinenAntti/rex-theme.nvim"})
vim.cmd.colorscheme("rex")
```

<details>
    <summary>Other plugin managers and manual installation</summary>
    <br/>
    <p>
    To use the plugin
    <ol>
        <li>Install the <code>EskelinenAntti/rex-theme.nvim</code> plugin following the usual steps of your chosen plugin manager.</li>
        <li>Set colorscheme to "rex" with <code>vim.cmd.colorscheme("rex")</code>.</li>
    </ol>
    </p>
</details>

### Other terminals

The plugin only activates when `TERM_PROGRAM` is `rex`. You can safely include it in your Neovim configuration, even if you share it between multiple devices.

To specify a theme to be used outside of Rex, you can simply do

```lua
if require("rex-theme.environment").is_rex() then
    vim.cmd.colorscheme("rex")
else
    vim.cmd.colorscheme("retrobox") -- or whatever colorscheme you prefer outside of Rex
end
```

## Changing themes

The palette is read once when the colorscheme loads. After changing your Rex theme, restart Neovim or run `:colorscheme rex` to update the colors.

## How it works

The plugin queries the terminal's 16 ANSI colors using OSC 4, and its default foreground and background using OSC 10 and 11. Neovim's `nvim_ui_send()` sends the queries, and `TermResponse` receives the colors asynchronously. No Rex CLI, configuration files, or additional plugins are needed.

If the terminal does not answer OSC 10 and 11, the plugin uses ANSI colors 7 and 0 for foreground and background. These can differ from the terminal's actual default colors. UI surfaces and selection colors are derived from the palette; ANSI yellow is also used for orange highlights.

The temporary response handlers are removed when the query finishes. There is no watcher or polling. If a complete ANSI palette cannot be read, the previous highlights are kept and a warning is shown.

## Development

Run the tests with `make test`. Update the highlight snapshot with `make snapshot`.
