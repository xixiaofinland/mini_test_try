vim.cmd([[let &rtp.=','.getcwd()]])

if #vim.api.nvim_list_uis() == 0 then
  print('hello\n')
  vim.cmd('set rtp+=deps/mini.nvim')
  vim.cmd('set rtp+=deps/nvim-treesitter.nvim')
  vim.cmd('set rtp+=deps/telescope')

  require('mini.test').setup()
end
