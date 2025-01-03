-- lua/sysmlv2/lsp_manual.lua
local M = {}

-- Manually start a Syside LSP client and attach it to the current buffer
function M.start_syside(opts)
  opts = opts or {}
  
  -- Check if Node.js is installed
  local node_check = vim.fn.system("node -v")
  if node_check:match("not found") then
    vim.notify("[sysmlv2] Node.js is not installed. Please install Node.js to use the Syside LSP client.", vim.log.levels.ERROR)
    return
  end

  -- Get the directory of the current script
  local script_dir = debug.getinfo(1, "S").source:match("@?(.*/)")
  
  -- Path to the proxy script
  local proxy_path = script_dir .. "../../syside/lsp-proxy.js"

  -- Ensure proxy script exists and is executable
  local proxy_content = vim.fn.system({
    "cat", proxy_path
  })
  if proxy_content == "" then
    -- Write proxy script if it doesn't exist
    local f = io.open(proxy_path, "w")
    if f then
      f:write(vim.fn.system({
        "cat", script_dir .. "../../syside/lsp-proxy.js"
      }))
      f:close()
      vim.fn.system({"chmod", "+x", proxy_path})
    end
  end

  -- Define on_attach function with common LSP navigation commands
  local function on_attach(client, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    -- Enable go to definition
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    -- Enable hover
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    -- Enable go to usages
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  end

  -- Start with minimal client configuration and required handlers
  local client_id = vim.lsp.start_client({
    name = "syside",
    cmd = {
      "node",
      proxy_path,
      script_dir .. "../../syside/syside-languageserver.js",
    },
    on_attach = on_attach,  -- Add the on_attach function
    handlers = {
      ["sysml/registerTextEditorCommands"] = function(err, result, ctx, config)
        return vim.NIL
      end,
      ["sysml/findStdlib"] = function(err, result, ctx, config)
        return script_dir .. "../../sysml.library" 
      end
    },
    -- root dir is the cwd of the vim instance
    root_dir = vim.fn.getcwd(),
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
    -- vim.notify("[sysmlv2] LSP client started and attached successfully", vim.log.levels.INFO)
  else
    vim.notify("[sysmlv2] Could not start syside client", vim.log.levels.ERROR)
  end
end

return M
