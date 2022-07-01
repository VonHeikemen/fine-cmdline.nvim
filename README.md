# The Fine Command Line

Here is the plan: A floating input shows up, you a enter a command and you're done. You can use `<Tab>` completion like the regular `cmdline`, and can also navigate the command history with `<Up>` and `<Down>` arrows. That's it.

My hope is that someone else with more knowledge sees this and inspires them to make a [Telescope](https://github.com/nvim-telescope/telescope.nvim) plugin with the same features.

![A floating input with the text 'Telescope co'.](https://res.cloudinary.com/vonheikemen/image/upload/v1637341165/other/Captura_de_pantalla_de_2021-11-19_12-54-42.png)

> This plugin does not have access to `commandline-mode`, cool features like live previews don't work here.
>
> If you want a UI to execute buffer local search (like with `/`) use [searchbox.nvim](https://github.com/VonHeikemen/searchbox.nvim).

## Getting Started

Make sure you have [Neovim v0.5.1](https://github.com/neovim/neovim/releases/tag/v0.5.1) or greater.

### Dependencies

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

### Installation

Use your favorite plugin manager. For example.

With `vim-plug`

```vim
Plug 'MunifTanjim/nui.nvim'
Plug 'VonHeikemen/fine-cmdline.nvim'
```

With `packer`.

```lua
use {
  'VonHeikemen/fine-cmdline.nvim',
  requires = {
    {'MunifTanjim/nui.nvim'}
  }
}
```

With `paq`

```lua
'MunifTanjim/nui.nvim';
'VonHeikemen/fine-cmdline.nvim';
```

## Usage

The easiest way to use it is calling `FineCmdline`... in a keybinding.

Remap `Enter`.

* **Lua Bindings**

```lua
vim.api.nvim_set_keymap('n', '<CR>', '<cmd>FineCmdline<CR>', {noremap = true})
```

If you'd like to remap `:` instead.

```lua
vim.api.nvim_set_keymap('n', ':', '<cmd>FineCmdline<CR>', {noremap = true})
```

* **Vimscript Bindings**

```vim
nnoremap <CR> <cmd>FineCmdline<CR>
```

If you'd like to remap `:` instead.

```vim
nnoremap : <cmd>FineCmdline<CR>
```

There is also the possibility to setup a default value before it shows up. Say you want to create a keybinding to use `vimgrep`.

```vim
<cmd>FineCmdline vimgrep <CR>
```

### Open from lua

`FineCmdline` is an alias for the `.open()` function in the `fine-cmdline` module. So you could also use this.

```lua
<cmd>lua require("fine-cmdline").open({default_value = ""})<CR>
```

### Visual mode and ranges

The command `FineCmdline` does not support ranges, it means that if you call it from visual mode with the range `'<,'>` you'll get an error.

If you make a keybinding to call it from visual mode, delete the range first. Like this.

```vim
:<C-u>FineCmdline<CR>
```

If you want to add the range in the input use `'<,'>` as the default value.

```vim
:<C-u>FineCmdline '<,'><CR>
```

### Configuration

If you want to change anything from the `ui` or add a "hook" you can use `.setup()`.

These are the defaults.

```lua
require('fine-cmdline').setup({
  cmdline = {
    enable_keymaps = true,
    smart_history = true,
    prompt = ': '
  },
  popup = {
    position = {
      row = '10%',
      col = '50%',
    },
    size = {
      width = '60%',
    },
    border = {
      style = 'rounded',
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    },
  },
  hooks = {
    before_mount = function(input)
      -- code
    end,
    after_mount = function(input)
      -- code
    end,
    set_keymaps = function(imap, feedkeys)
      -- code
    end
  }
})
```

- `cmdline.enable_keymaps`, when set to true use the recommended keybindings. If you set to `false` you will need to do bind the keys in the `set_keymaps` hook.

- `cmdline.smart_history`, when set to true use the string in the input as a search term, then when you navigate the history only the entries that begin with that term will show up. Imagine `PackerSync` is in your command history, just enter the string `Pack` and press `<Up>` to start looking for it.

- `cmdline.prompt` sets the text for the prompt.

- `popup` is passed directly to `nui.popup`. You can check the valid keys in their documentation: [popup.options](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup#options)

- `hooks` must be functions. They will be executed during the "lifecycle" of the input.

*before_mount* and *after_mount* receive the instance of the input, so you can do anything with it.

`set_keymaps`. Why is this even in a "hook"? Funny story, neovim v0.5 still had bugs and limitations that made things very confusing. This hooks provides helper functions to setup keymaps in a reliable way. If you have neovim v0.7 you can ignore it completely.

### Setting keymaps

If you have neovim v0.7 you should setup your keybindings in the `after_mount`, using the `vim.keymap.set` function.

```lua
after_mount = function(input)
  -- make escape go to normal mode
  vim.keymap.set('i', '<Esc>', '<cmd>stopinsert<cr>', {buffer = input.bufnr})
end
```

If you are using neovim v0.6.1 or lower use the `set_keymaps` hook.

With `set_keymaps` you get two parameters. `imap` makes non-recursive mappings in insert mode. `feedkeys` types keys for you (because of reasons).

Let's say you want to create a shortcut (`Alt + s`) for a simple search and replace.

```lua
set_keymaps = function(imap, feedkeys)
  imap('<M-s>', '%s///gc<Left><Left><Left><Left>')
end
```

If you need something more complex you can use a function.

```lua
set_keymaps = function(imap, feedkeys)
  imap('<M-s>', function()
    if vim.fn.pumvisible() == 0 then
      feedkeys('%s///gc<Left><Left><Left><Left>')
    end
  end)
end
```

There are a few utility functions you could use, they are available under `.fn`.

```lua
local fn = require('fine-cmdline').fn
```

- `fn.close`: If completion menu is visible, hide it. Else, unmounts the input.

- `fn.next_item`: Go to the next item in the completion list.

- `fn.previous_item`: Go to the previous item in the completion list.

- `fn.complete_or_next_item`: Shows the completion menu if is not visible. Else, navigates to the next item in the completion list.

- `fn.stop_complete_or_previous_item`: If completion menu is visible go to previous item. Else, stop completion without changing the input text.

- `fn.up_history`: Replaces the text in the input with the previous entry in the command history.

- `fn.down_history`: Replaces the text in the input with the next entry in the command history.

- `fn.up_search_history`: Take the user input, start a search and show the previous entry that start with that prefix.

- `fn.down_search_history`: Take the user input, start a search and show the next entry that start with that prefix.

If you wanted to enable the "smart history" with `Alt + k` and `Alt + j`, then leave `<Up>` and `<Down>` to do simple history navigation.

```lua
set_keymaps = function(imap, feedkeys)
  local fn = require('fine-cmdline').fn

  imap('<M-k>', fn.up_search_history)
  imap('<M-j>', fn.down_search_history)
  imap('<Up>', fn.up_history)
  imap('<Down>', fn.down_history)
end
```

### Integration with completion engines

At the moment only this third-party completion engine works inside the floating input:

* [ddc.vim](https://github.com/Shougo/ddc.vim)

Other popular completion engines don't provide completions for ex-commands outside the built-in command-line.

If you wish to test your completion engine in `fine-cmdline` here is what you need to do:

* Disable the default keybindings.
* Setup your own keybindings.
* Maybe, modify the prompt.
* Perhaps, setup a custom filetype.

Here is a complete example.

```lua
local fineline = require('fine-cmdline')
local fn = fineline.fn

fineline.setup({
  cmdline = {
    -- Prompt can influence the completion engine.
    -- Change it to something that works for you
    prompt = ': ',

    -- Let the user handle the keybindings
    enable_keymaps = false
  },
  popup = {
    buf_options = {
      -- Setup a special file type if you need to
      filetype = 'FineCmdlinePrompt'
    }
  },
  hooks = {
    set_keymaps = function(imap, feedkeys)
      -- Restore default keybindings...
      -- Except for `<Tab>`, that's what everyone uses to autocomplete
      imap('<Esc>', fn.close)
      imap('<C-c>', fn.close)

      imap('<Up>', fn.up_search_history)
      imap('<Down>', fn.down_search_history)
    end
  }
})
```

## Caveats

This is not a special mode. It's just a normal buffer, incremental search will not work here.

You'll find that most limitations on this plugin are because it can't enable `commandline-mode`. When you type in the input your are in `insert mode`.

There is a known issue with [cmdwin](https://neovim.io/doc/user/cmdline.html#cmdwin) (the thing that shows up when you press `q:` by accident). `cmdwin` and `fine-cmdline` have the same goal, execute ex-commands. Problem is `cmdwin` will be the one executing the command, and you will bump into some weird behavior. If for some reason you're in `cmdwin` and call `fine-cmdline`, press `<C-c>` twice (one to close the input, one to close `cmdwin`). Don't try anything else. Just close both.

## Contributing

How nice of you. Keep in mind I want to keep this plugin small. Scope creep is the enemy. This thing already does everything I want.

Bug fixes are welcome. Suggestions to improve defaults. Maybe some tweaks to the lua public api.

If you want to improve the ui it will be better if you contribute to [nui.nvim](https://github.com/MunifTanjim/nui.nvim).

## Support

If you find this tool useful and want to support my efforts, [buy me a coffee ☕](https://www.buymeacoffee.com/vonheikemen).

[![buy me a coffee](https://res.cloudinary.com/vonheikemen/image/upload/v1618466522/buy-me-coffee_ah0uzh.png)](https://www.buymeacoffee.com/vonheikemen)

