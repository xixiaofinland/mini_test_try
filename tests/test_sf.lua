local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      child.lua([[M = require('a')]]) -- error here
    end,

    post_once = child.stop,
  },
})

T['lua_get()'] = function()
  child.lua('_G.n = 0')
  eq(child.lua_get('_G.n'), child.lua('return _G.n'))
end

return T
