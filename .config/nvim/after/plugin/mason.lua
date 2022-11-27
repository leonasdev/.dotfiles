local status, mason = pcall(require, 'mason')
if (not status) then
  print("mason not installed")
  return
end

local status2, mason_lspconfig = pcall(require, 'mason-lspconfig')
if (not status2) then
  print("mason not installed")
  return
end

mason.setup()

mason_lspconfig.setup {
  ensure_installed = {
    "sumneko_lua",
    "clangd",
    "tsserver",
    "volar"
  }
}
