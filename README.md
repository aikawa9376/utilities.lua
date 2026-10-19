# utilities.lua

## Smart close

`require('utilities').smart_close()` normally closes the current window. A panel
that reused an existing window restores its previous buffer, cursor/scroll, and
local display options instead. Closing one view leaves other views of the same
buffer alive. The last editor window falls back to another or an empty buffer.
Modified buffers are protected unless `force = true` is supplied.

Call `remember_smart_close()` before replacing an existing window's buffer.
For a newly created split or tab, call
`remember_smart_close({ source_win = source_win, created = true })` after creating
it; its window closes on exit. If `created` is omitted, a different `source_win`
implies a new window. `preserve = true` retains this ownership and return target
during navigation within a panel. Floats always close their window. A reused
window remains open even when it is the only window in a preexisting tab.

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
