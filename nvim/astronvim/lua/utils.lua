local M = {}
local is_win = vim.loop.os_uname().version:find "Windows"

function M.write_to_file(file_name, content)
  local file = io.open(file_name, "w")
  if file then
    file:write(content)
    file:close()
  end
end

-- 检查是否已经存在 "--config" 参数
function M.contains_arg(args, arg)
  for _, v in ipairs(args) do
    if v == arg then return true end
  end
  return false
end


function M.copy_file(source_file, target_file)
  local target_file_parent_path = M.get_parent_dir(target_file)
  local cmd = string.format("mkdir -p %s", vim.fn.shellescape(target_file_parent_path))
  os.execute(cmd)
  cmd = string.format("cp %s %s", vim.fn.shellescape(source_file), vim.fn.shellescape(target_file))
  os.execute(cmd)
  vim.schedule(function() vim.notify("File " .. target_file .. " created success.", vim.log.levels.INFO) end)
end

function M.file_exists(filepath) return vim.fn.glob(filepath) ~= "" end

