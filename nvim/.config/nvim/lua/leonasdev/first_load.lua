local download_packer = function()
  if vim.fn.input "Download Packer? (y for yes)" ~= "y" then
    return
  end

  local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

  local out = vim.fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })

  print(out)
  print "Downloading packer.nvim..."
  print "( You'll need to restart now )"
  vim.cmd [[qa]]
end

return function()
  if not pcall(require, "packer") then
    download_packer()
    return true
  end

  return false
end
