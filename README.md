# utilities.lua

## Smart close

`require('utilities').smart_close()` replaces the current buffer while retaining
ordinary split windows. It restores a remembered source buffer, then tries the
alternate buffer, a recently used normal buffer, and finally an empty buffer.
A floating window or a dedicated tab with one regular window closes normally.
Modified buffers are protected unless `force = true` is supplied.

Call `remember_smart_close()` before replacing a window's buffer to restore its
source, cursor/scroll position, and local display options when closing. After
creating a panel split, `remember_smart_close({ source_win = source_win })` can
capture another window's source. `preserve = true` retains an existing return
target during navigation within a panel.

```lua
local utilities = require('utilities')
utilities.smart_close({
  keep_buffer = true, -- hide a reusable panel instead of deleting its buffer
  before = function(ctx)
    -- Return false to cancel, for example after an unsaved-edit prompt.
  end,
  after = function(ctx)
    -- Runs only after a successful close; ctx identifies the original view.
  end,
  close = function(ctx, default_close)
    -- Replace the action for an owned layout, or delegate to the default.
    return default_close()
  end,
  replacement = function(ctx)
    -- Optionally return a buffer ID for each affected window.
  end,
})
```

Context fields are `buf`, `win`, `tab`, and `filetype`. Hooks run synchronously;
`close` returns `true` for success or `false` for cancellation. Errors propagate
to the caller and skip `after`. `before` runs before the modified-buffer guard,
so an owner can save or revert its draft first.

Plugins can also register defaults without changing callers:

```lua
local unregister = utilities.register_smart_close('my-plugin', function(ctx)
  if ctx.filetype == 'my-panel' then
    return { keep_buffer = true, before = function() return confirm_close() end }
  end
  -- nil means this plugin does not handle the current context.
end)
-- unregister() removes this registration.
```

The most recently added matching handler wins. A named registration replaces
its previous callback in place. Returning `false` cancels the close. Explicit
`smart_close()` options override registered defaults. Calling an old unregister
closure cannot remove a newer callback registered under the same name.

Run the standalone checks with
`nvim --headless --clean -u NONE -l tests/smart_close.lua`.
