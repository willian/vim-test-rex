# vim-test-rex

A [vim-test](https://github.com/vim-test/vim-test) strategy that runs tests in a [Rex](https://rex.superlogical.com) pane.

Requires Vim or Neovim, the `rex` CLI, and an editor running inside Rex (`REX_SESSION` and `REX_BLOCK` set).

The first run splits a pane below the editor, in the editor's working directory, without moving focus. Later runs reuse that pane, and a new one is created if it was closed.

## Configuration

For Neovim (LazyVim):

```lua
{
  "vim-test/vim-test",
  dependencies = {
    "willian/vim-test-rex",
  },
  keys = {
    { "<leader>tc", "<CMD>RexCloseRunner<CR>", desc = "Close test runner pane" },
  },
  config = function()
    vim.g["test#strategy"] = "rex"
  end,
}
```

For Vim:

```vim
let g:test#strategy = 'rex'
nnoremap <leader>tc <Cmd>RexCloseRunner<CR>
```

`RexCloseRunner` closes the pane created for test runs.

## Using with a fallback strategy (Vimux)

Use Rex inside a Rex pane and [Vimux](https://github.com/preservim/vimux) otherwise.

For Neovim with LazyVim:

```lua
{
  "vim-test/vim-test",
  dependencies = {
    "preservim/vimux",
    "willian/vim-test-rex",
  },
  keys = {
    {
      "<leader>tc",
      function()
        vim.cmd(vim.env.REX_SESSION and "RexCloseRunner" or "VimuxCloseRunner")
      end,
      desc = "Close test runner pane",
    },
  },
  config = function()
    vim.g["test#strategy"] = vim.env.REX_SESSION and "rex" or "vimux"
  end,
}
```

For Vim:

```vim
if !empty($REX_SESSION)
  let g:test#strategy = 'rex'
  nnoremap <leader>tc :RexCloseRunner<CR>
else
  let g:test#strategy = 'vimux'
  nnoremap <leader>tc :VimuxCloseRunner<CR>
endif
```

## Tests

```sh
tests/smoke.sh
```

It runs the strategy in Neovim and Vim against a fake `rex` that records each call.
