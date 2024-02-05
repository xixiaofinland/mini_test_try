local U = require('sf.ts');
local Sf = {}

--- It stores the last executed Apex test command so we can re-run by `require('sf.term').repeat_last_tests()`.
Sf.last_tests = ''

--- It's meant to be used by statusline (like lualine) to display target_org information.
Sf.target_org = ''

-- Module functionality =======================================================
--- Return `target_org` field value or throw error when it's empty
---
---@return string
Sf.get = function()
  Sf.target_org = 'hello'

  return Sf.target_org
end

return Sf
