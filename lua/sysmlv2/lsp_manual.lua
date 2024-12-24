-- lua/sysmlv2/lsp_manual.lua
local M = {}

-- Manually start a Syside LSP client and attach it to the current buffer
function M.start_syside(opts)
  opts = opts or {}
  
  -- Path to the proxy script
  local proxy_path = vim.fn.expand("~/sysmlv2.vim/lsp-proxy.js")
  
  -- Ensure proxy script exists and is executable
  local proxy_content = vim.fn.system({
    "cat", proxy_path
  })
  if proxy_content == "" then
    -- Write proxy script if it doesn't exist
    local f = io.open(proxy_path, "w")
    if f then
      f:write(vim.fn.system({
        "cat", vim.fn.expand("~/sysmlv2.vim/lsp-proxy.js")
      }))
      f:close()
      vim.fn.system({"chmod", "+x", proxy_path})
    end
  end

  -- Define minimal on_attach function for gd
  local function on_attach(client, bufnr)
    -- Enable go to definition
    vim.keymap.set("n", "gd", function()
      vim.lsp.buf.definition()
    end, { noremap = true, silent = true, buffer = bufnr })
  end

  -- Start with minimal client configuration and required handlers
  local client_id = vim.lsp.start_client({
    name = "syside",
    cmd = {
      "node",
      proxy_path,
      vim.fn.expand(opts.syside_server_path or "~/syside-languageserver.js"),
    },
    on_attach = on_attach,  -- Add the on_attach function
    handlers = {
      ["sysml/registerTextEditorCommands"] = function(err, result, ctx, config)
        return vim.NIL
      end,
      ["sysml/findStdlib"] = function(err, result, ctx, config)
        return "/Users/ethanlew/.sysml-2ls"
      end
    },
    capabilities = {
      workspace = {
        configuration = {
          dynamicRegistration = false
        }
      }
    }
  })

  -- Simple attach with error handling
  if client_id then
    local success, err = pcall(vim.lsp.buf_attach_client, 0, client_id)
    if not success then
      vim.notify("[sysmlv2] Failed to attach client: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    vim.notify("[sysmlv2] LSP client started and attached successfully", vim.log.levels.INFO)
  else
    vim.notify("[sysmlv2] Could not start syside client", vim.log.levels.ERROR)
  end
end

return M
