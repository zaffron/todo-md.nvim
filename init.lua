local M = {}

M.config = {}
M.floating_win = nil
M.floating_buf = nil

local function ensure_todo_file_exists()
  local file_path = M.config.todo_file_path
  local file = io.open(file_path, "r")
  if not file then
    file = io.open(file_path, "w")
    if file then
      file:write("# Todo List\n\n")
      file:close()
    end
  else
    file:close()
  end
end

local function read_todo_file()
  ensure_todo_file_exists()
  local file = io.open(M.config.todo_file_path, "r")
  if not file then
    return {}
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  return lines
end

local function sort_todos(lines)
  local todos = {}
  local non_todos = {}
  
  for _, line in ipairs(lines) do
    if line:match("^%s*- %[[ x]%]") then
      table.insert(todos, line)
    else
      table.insert(non_todos, line)
    end
  end
  
  table.sort(todos, function(a, b)
    local a_completed = a:match("^%s*- %[x%]") ~= nil
    local b_completed = b:match("^%s*- %[x%]") ~= nil
    return not a_completed and b_completed
  end)
  
  local sorted_lines = {}
  for _, line in ipairs(non_todos) do
    table.insert(sorted_lines, line)
  end
  for _, line in ipairs(todos) do
    table.insert(sorted_lines, line)
  end
  
  return sorted_lines
end

local function write_todo_file(lines, should_sort)
  if should_sort == nil then should_sort = M.config.auto_sort end
  if should_sort then
    lines = sort_todos(lines)
  end
  
  local file = io.open(M.config.todo_file_path, "w")
  if not file then
    vim.notify("Failed to open todo file for writing", vim.log.levels.ERROR)
    return false
  end

  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()
  return true
end

local function create_floating_window()
  local width = math.ceil(vim.o.columns * 0.8)
  local height = math.ceil(vim.o.lines * 0.8)

  local col = math.ceil((vim.o.columns - width) / 2)
  local row = math.ceil((vim.o.lines - height) / 2 - 1)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " Todo List ",
    title_pos = "center",
  }

  ensure_todo_file_exists()

  if M.floating_buf and vim.api.nvim_buf_is_valid(M.floating_buf) then
    vim.api.nvim_buf_delete(M.floating_buf, { force = true })
  end

  M.floating_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(M.floating_buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(M.floating_buf, "bufhidden", "wipe")

  local lines = read_todo_file()
  vim.api.nvim_buf_set_lines(M.floating_buf, 0, -1, false, lines)

  M.floating_win = vim.api.nvim_open_win(M.floating_buf, true, opts)

  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "n",
    "q",
    "<cmd>lua require('zaffron.todo-md').close_floating_todo()<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "n",
    "<Esc>",
    "<cmd>lua require('zaffron.todo-md').close_floating_todo()<CR>",
    { noremap = true, silent = true }
  )

  local group = vim.api.nvim_create_augroup("TodoMdFloating", { clear = false })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = M.floating_buf,
    callback = function()
      local buf_lines = vim.api.nvim_buf_get_lines(M.floating_buf, 0, -1, false)
      write_todo_file(buf_lines)
    end,
  })
end

local function open_todo_file()
  ensure_todo_file_exists()
  vim.cmd("edit " .. M.config.todo_file_path)
end

local function open_todo_floating()
  if M.floating_win and vim.api.nvim_win_is_valid(M.floating_win) then
    vim.api.nvim_set_current_win(M.floating_win)
  else
    create_floating_window()
  end
end

function M.close_floating_todo()
  if M.floating_win and vim.api.nvim_win_is_valid(M.floating_win) then
    local buf_lines = vim.api.nvim_buf_get_lines(M.floating_buf, 0, -1, false)
    write_todo_file(buf_lines)
    vim.api.nvim_win_close(M.floating_win, true)
    M.floating_win = nil
  end
end

local function add_todo_item()
  vim.ui.input({
    prompt = "Enter todo item: ",
  }, function(input)
    if not input or input == "" then
      return
    end

    local lines = read_todo_file()
    table.insert(lines, "- [ ] " .. input)
    write_todo_file(lines)
    vim.notify("Todo item added: " .. input, vim.log.levels.INFO)
  end)
end

local function toggle_todo_on_line()
  local current_line = vim.api.nvim_get_current_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  if current_line:match("^%s*- %[ %]") then
    local new_line = current_line:gsub("^(%s*- )%[ %]", "%1[x]")
    vim.api.nvim_set_current_line(new_line)
    vim.notify("Todo marked as completed", vim.log.levels.INFO)
  elseif current_line:match("^%s*- %[x%]") then
    local new_line = current_line:gsub("^(%s*- )%[x%]", "%1[ ]")
    vim.api.nvim_set_current_line(new_line)
    vim.notify("Todo marked as incomplete", vim.log.levels.INFO)
  elseif current_line:match("^%s*- ") then
    local new_line = current_line:gsub("^(%s*- )", "%1[ ] ")
    vim.api.nvim_set_current_line(new_line)
    vim.notify("Converted to todo checkbox", vim.log.levels.INFO)
  else
    vim.notify("Current line is not a todo item", vim.log.levels.WARN)
  end
end

local function delete_todo_on_line()
  local current_line = vim.api.nvim_get_current_line()
  if current_line:match("^%s*- %[") then
    vim.api.nvim_del_current_line()
    vim.notify("Todo item deleted", vim.log.levels.INFO)
  else
    vim.notify("Current line is not a todo item", vim.log.levels.WARN)
  end
end

local function sort_todos_now()
  local lines = read_todo_file()
  local sorted_lines = sort_todos(lines)
  write_todo_file(sorted_lines, false)
  
  if M.floating_win and vim.api.nvim_win_is_valid(M.floating_win) then
    vim.api.nvim_buf_set_lines(M.floating_buf, 0, -1, false, sorted_lines)
  end
  
  vim.notify("Todos sorted by completion status", vim.log.levels.INFO)
end

local function clear_all_todos()
  vim.ui.select(
    { "Clear all todos", "Clear completed todos only", "Cancel" },
    { prompt = "Clear todos:" },
    function(choice)
      if not choice or choice == "Cancel" then
        return
      end
      
      local lines = read_todo_file()
      local new_lines = {}
      
      for _, line in ipairs(lines) do
        if choice == "Clear completed todos only" then
          if not line:match("^%s*- %[x%]") then
            table.insert(new_lines, line)
          end
        elseif not line:match("^%s*- %[[ x]%]") then
          table.insert(new_lines, line)
        end
      end
      
      write_todo_file(new_lines, false)
      
      if M.floating_win and vim.api.nvim_win_is_valid(M.floating_win) then
        vim.api.nvim_buf_set_lines(M.floating_buf, 0, -1, false, new_lines)
      end
      
      vim.notify("Todos cleared: " .. choice, vim.log.levels.INFO)
    end
  )
end

local function mark_all_todos(mark_as_done)
  local lines = read_todo_file()
  local new_lines = {}
  local changed_count = 0
  
  for _, line in ipairs(lines) do
    if line:match("^%s*- %[ %]") and mark_as_done then
      local new_line = line:gsub("^(%s*- )%[ %]", "%1[x]")
      table.insert(new_lines, new_line)
      changed_count = changed_count + 1
    elseif line:match("^%s*- %[x%]") and not mark_as_done then
      local new_line = line:gsub("^(%s*- )%[x%]", "%1[ ]")
      table.insert(new_lines, new_line)
      changed_count = changed_count + 1
    else
      table.insert(new_lines, line)
    end
  end
  
  write_todo_file(new_lines, M.config.auto_sort)
  
  if M.floating_win and vim.api.nvim_win_is_valid(M.floating_win) then
    local final_lines = M.config.auto_sort and sort_todos(new_lines) or new_lines
    vim.api.nvim_buf_set_lines(M.floating_buf, 0, -1, false, final_lines)
  end
  
  local status = mark_as_done and "completed" or "incomplete"
  vim.notify(string.format("Marked %d todos as %s", changed_count, status), vim.log.levels.INFO)
end

local function mark_all_done()
  mark_all_todos(true)
end

local function mark_all_undone()
  mark_all_todos(false)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {
    todo_file_path = vim.fn.expand("~/todo.md"),
    auto_sort = true,
    keybindings = {
      open_todo_floating = "<leader>to",
      open_todo_buffer = "<leader>tO",
      add_todo = "<leader>ta",
      toggle_todo = "<leader>tt",
      delete_todo = "<leader>td",
      sort_todos = "<leader>ts",
      clear_todos = "<leader>tc",
      mark_all_done = "<leader>tD",
      mark_all_undone = "<leader>tU",
    },
  }, opts or {})

  local keybindings = M.config.keybindings

  vim.keymap.set("n", keybindings.open_todo_floating, open_todo_floating, { desc = "Open Todo (Floating)" })
  vim.keymap.set("n", keybindings.open_todo_buffer, open_todo_file, { desc = "Open Todo (Buffer)" })
  vim.keymap.set("n", keybindings.add_todo, add_todo_item, { desc = "Add Todo Item" })
  vim.keymap.set("n", keybindings.toggle_todo, toggle_todo_on_line, { desc = "Toggle Todo Item" })
  vim.keymap.set("n", keybindings.delete_todo, delete_todo_on_line, { desc = "Delete Todo Item" })
  vim.keymap.set("n", keybindings.sort_todos, sort_todos_now, { desc = "Sort Todos" })
  vim.keymap.set("n", keybindings.clear_todos, clear_all_todos, { desc = "Clear Todos" })
  vim.keymap.set("n", keybindings.mark_all_done, mark_all_done, { desc = "Mark All Done" })
  vim.keymap.set("n", keybindings.mark_all_undone, mark_all_undone, { desc = "Mark All Undone" })
end

return M

