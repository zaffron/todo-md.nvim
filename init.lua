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
  if should_sort == nil then
    should_sort = M.config.auto_sort
  end
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

local function setup_priority_highlights()
  vim.api.nvim_set_hl(0, "TodoHighPriority", { fg = "#ff6b6b", bold = true })
  vim.api.nvim_set_hl(0, "TodoMediumPriority", { fg = "#feca57", bold = true })
  vim.api.nvim_set_hl(0, "TodoLowPriority", { fg = "#48cae4", bold = true })
  vim.api.nvim_set_hl(0, "TodoCompletedTask", { fg = "#6c757d", strikethrough = true })
end

local function apply_syntax_highlighting(buf)
  local namespace = vim.api.nvim_create_namespace("TodoMdPriorities")

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    local line_num = i - 1 -- 0-indexed

    -- Highlight completed tasks
    if line:match("^%s*- %[x%]") then
      vim.api.nvim_buf_add_highlight(buf, namespace, "TodoCompletedTask", line_num, 0, -1)
    end

    -- Highlight priority tags
    local high_start, high_end = line:find("%[HIGH%]")
    if high_start then
      vim.api.nvim_buf_add_highlight(buf, namespace, "TodoHighPriority", line_num, high_start - 1, high_end)
    end

    local medium_start, medium_end = line:find("%[MEDIUM%]")
    if medium_start then
      vim.api.nvim_buf_add_highlight(buf, namespace, "TodoMediumPriority", line_num, medium_start - 1, medium_end)
    end

    local low_start, low_end = line:find("%[LOW%]")
    if low_start then
      vim.api.nvim_buf_add_highlight(buf, namespace, "TodoLowPriority", line_num, low_start - 1, low_end)
    end
  end
end

local function create_floating_window()
  local width = M.config.floating_width or math.ceil(vim.o.columns * 0.8)
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

  -- Setup and apply syntax highlighting
  setup_priority_highlights()
  apply_syntax_highlighting(M.floating_buf)

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
  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "n",
    "ZZ",
    "<cmd>lua require('zaffron.todo-md').close_floating_todo()<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "i",
    "<CR>",
    "<cmd>lua require('zaffron.todo-md').handle_enter_insert()<CR>",
    { noremap = true, silent = true }
  )

  -- Date insertion keybindings
  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "i",
    "<C-d>t",
    "<cmd>lua require('zaffron.todo-md').insert_date('today')<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "i",
    "<C-d>m",
    "<cmd>lua require('zaffron.todo-md').insert_date('tomorrow')<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    M.floating_buf,
    "i",
    "<C-d>f",
    "<cmd>lua require('zaffron.todo-md').insert_date('full')<CR>",
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

  -- Auto-refresh syntax highlighting on buffer changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = M.floating_buf,
    callback = function()
      apply_syntax_highlighting(M.floating_buf)
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

function M.handle_enter_insert()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  local col = cursor_pos[2]

  -- Check if current line is a todo item
  if current_line:match("^%s*- %[[ x]%]") then
    -- Get the indentation of the current line
    local indent = current_line:match("^(%s*)")
    -- Create new todo checkbox with same indentation
    local new_todo = indent .. "- [ ] "

    -- Insert new line and the new todo
    vim.api.nvim_put({ "" }, "l", true, true)
    vim.api.nvim_set_current_line(new_todo)

    -- Position cursor at the end of the new todo line
    vim.api.nvim_win_set_cursor(0, { row + 1, #new_todo })

    -- Enter insert mode at the end
    vim.cmd("startinsert!")
  else
    -- Default behavior: just insert a new line
    vim.api.nvim_put({ "" }, "l", true, true)
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    vim.cmd("startinsert!")
  end
end

function M.insert_date(format_type)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor_pos[1], cursor_pos[2]
  local current_line = vim.api.nvim_get_current_line()

  local date_str
  if format_type == "today" then
    date_str = os.date("%Y-%m-%d")
  elseif format_type == "tomorrow" then
    date_str = os.date("%Y-%m-%d", os.time() + 24 * 60 * 60)
  elseif format_type == "full" then
    date_str = os.date("%Y-%m-%d %A")
  else
    date_str = os.date("%Y-%m-%d")
  end

  -- Insert date at cursor position
  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)
  local new_line = before .. date_str .. after

  vim.api.nvim_set_current_line(new_line)

  -- Position cursor after the inserted date
  vim.api.nvim_win_set_cursor(0, { row, col + #date_str })

  vim.notify("Inserted date: " .. date_str, vim.log.levels.INFO)
end

local function insert_today()
  M.insert_date("today")
end

local function insert_tomorrow()
  M.insert_date("tomorrow")
end

local function insert_full_date()
  M.insert_date("full")
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
      insert_today = "<leader>tdt",
      insert_tomorrow = "<leader>tdm",
      insert_full_date = "<leader>tdf",
    },
  }, opts or {})

  local keybindings = M.config.keybindings

  -- Set up keybindings
  vim.keymap.set("n", keybindings.open_todo_floating, open_todo_floating, { desc = "Open Todo (Floating)" })
  vim.keymap.set("n", keybindings.open_todo_buffer, open_todo_file, { desc = "Open Todo (Buffer)" })
  vim.keymap.set("n", keybindings.add_todo, add_todo_item, { desc = "Add Todo Item" })
  vim.keymap.set("n", keybindings.toggle_todo, toggle_todo_on_line, { desc = "Toggle Todo Item" })
  vim.keymap.set("n", keybindings.delete_todo, delete_todo_on_line, { desc = "Delete Todo Item" })
  vim.keymap.set("n", keybindings.sort_todos, sort_todos_now, { desc = "Sort Todos" })
  vim.keymap.set("n", keybindings.clear_todos, clear_all_todos, { desc = "Clear Todos" })
  vim.keymap.set("n", keybindings.mark_all_done, mark_all_done, { desc = "Mark All Done" })
  vim.keymap.set("n", keybindings.mark_all_undone, mark_all_undone, { desc = "Mark All Undone" })
  vim.keymap.set("n", keybindings.insert_today, insert_today, { desc = "Insert Today's Date" })
  vim.keymap.set("n", keybindings.insert_tomorrow, insert_tomorrow, { desc = "Insert Tomorrow's Date" })
  vim.keymap.set("n", keybindings.insert_full_date, insert_full_date, { desc = "Insert Full Date" })

  -- Create user commands
  vim.api.nvim_create_user_command("TodoOpen", open_todo_floating, { desc = "Open todo list in floating window" })
  vim.api.nvim_create_user_command("TodoBuffer", open_todo_file, { desc = "Open todo list in buffer" })
  vim.api.nvim_create_user_command("TodoAdd", add_todo_item, { desc = "Add new todo item" })
  vim.api.nvim_create_user_command("TodoToggle", toggle_todo_on_line, { desc = "Toggle todo item on current line" })
  vim.api.nvim_create_user_command("TodoDelete", delete_todo_on_line, { desc = "Delete todo item on current line" })
  vim.api.nvim_create_user_command("TodoSort", sort_todos_now, { desc = "Sort todos by completion status" })
  vim.api.nvim_create_user_command("TodoClear", clear_all_todos, { desc = "Clear todos with options" })
  vim.api.nvim_create_user_command("TodoMarkAllDone", mark_all_done, { desc = "Mark all todos as completed" })
  vim.api.nvim_create_user_command("TodoMarkAllUndone", mark_all_undone, { desc = "Mark all todos as incomplete" })
  vim.api.nvim_create_user_command("TodoClose", function()
    M.close_floating_todo()
  end, { desc = "Close floating todo window" })

  -- Date insertion commands
  vim.api.nvim_create_user_command("TodoInsertToday", insert_today, { desc = "Insert today's date" })
  vim.api.nvim_create_user_command("TodoInsertTomorrow", insert_tomorrow, { desc = "Insert tomorrow's date" })
  vim.api.nvim_create_user_command("TodoInsertFullDate", insert_full_date, { desc = "Insert full date with day name" })
end

return M
