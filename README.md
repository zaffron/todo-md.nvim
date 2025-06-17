# Todo-MD Plugin for Neovim

A lightweight, floating window todo plugin for Neovim that manages markdown-based todo lists with advanced sorting and bulk operations.

## Features

- **Floating Window Interface** - Opens todos in a beautiful floating window that doesn't disrupt your workflow
- **Dual Display Modes** - Choose between floating window or regular buffer
- **Auto-Sorting** - Automatically sorts todos with incomplete items first
- **Bulk Operations** - Mark all todos as done/undone, clear completed items
- **Smart Persistence** - Auto-saves changes when closing floating window
- **Customizable** - Configure file path and all keybindings
- **Markdown Format** - Uses standard markdown checkbox format `- [ ]` and `- [x]`

## Installation

### Using lazy.nvim

Add this to your Neovim configuration:

```lua
-- In lua/plugins/todo-md.lua or your plugin configuration
return {
  {
    "zaffron/todo-md.nvim",
    opts = {
      todo_file_path = vim.fn.expand("~/todo.md"), -- Customize your todo file location
      auto_sort = true, -- Auto-sort todos by completion status
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
    },
    config = function(_, opts)
      require("zaffron.todo-md").setup(opts)
    end,
    keys = {
      { "<leader>to", desc = "Open Todo (Floating)" },
      { "<leader>tO", desc = "Open Todo (Buffer)" },
      { "<leader>ta", desc = "Add Todo Item" },
      { "<leader>tt", desc = "Toggle Todo Item" },
      { "<leader>td", desc = "Delete Todo Item" },
      { "<leader>ts", desc = "Sort Todos" },
      { "<leader>tc", desc = "Clear Todos" },
      { "<leader>tD", desc = "Mark All Done" },
      { "<leader>tU", desc = "Mark All Undone" },
    },
  },
}
```

### Installation Steps

1. Add the plugin configuration to your `lua/plugins/` directory
2. Restart Neovim and run `:Lazy sync` to install the plugin

## Usage

### Default Keybindings

| Key          | Action               | Description                                   |
| ------------ | -------------------- | --------------------------------------------- |
| `<leader>to` | Open Todo (Floating) | Open todo list in floating window             |
| `<leader>tO` | Open Todo (Buffer)   | Open todo list in regular buffer              |
| `<leader>ta` | Add Todo Item        | Add new todo via input prompt                 |
| `<leader>tt` | Toggle Todo Item     | Toggle completion status of current line      |
| `<leader>td` | Delete Todo Item     | Delete todo item on current line              |
| `<leader>ts` | Sort Todos           | Manually sort todos by completion status      |
| `<leader>tc` | Clear Todos          | Clear todos with options (all/completed only) |
| `<leader>tD` | Mark All Done        | Mark all todos as completed                   |
| `<leader>tU` | Mark All Undone      | Mark all todos as incomplete                  |

### Commands

For users who prefer commands over keybindings, all functions are available as Neovim commands:

| Command              | Equivalent Key | Description                              |
| -------------------- | -------------- | ---------------------------------------- |
| `:TodoOpen`          | `<leader>to`   | Open todo list in floating window        |
| `:TodoBuffer`        | `<leader>tO`   | Open todo list in regular buffer         |
| `:TodoAdd`           | `<leader>ta`   | Add new todo item via input prompt       |
| `:TodoToggle`        | `<leader>tt`   | Toggle completion status of current line |
| `:TodoDelete`        | `<leader>td`   | Delete todo item on current line         |
| `:TodoSort`          | `<leader>ts`   | Sort todos by completion status          |
| `:TodoClear`         | `<leader>tc`   | Clear todos with interactive options     |
| `:TodoMarkAllDone`   | `<leader>tD`   | Mark all todos as completed              |
| `:TodoMarkAllUndone` | `<leader>tU`   | Mark all todos as incomplete             |
| `:TodoClose`         | `q` or `Esc`   | Close floating todo window               |

**Note:** Commands work the same as keybindings. You can use either method or mix both approaches based on your preference.

### Floating Window Controls

When in the floating window:

- `q` or `Esc` - Close and save
- Normal vim editing commands work
- Auto-saves on `:w` (write)

### Workflow Examples

1. **Quick Todo Entry**: Press `<leader>ta` or use `:TodoAdd` anywhere to add a new todo
2. **Review & Edit**: Press `<leader>to` or use `:TodoOpen` to open floating todo window
3. **Toggle Completion**: Navigate to any todo line and press `<leader>tt` or use `:TodoToggle`
4. **Bulk Operations**: Use `<leader>tD` (`:TodoMarkAllDone`) to mark all as done, `<leader>tc` (`:TodoClear`) to clear completed
5. **Organization**: `<leader>ts` (`:TodoSort`) to sort todos, or enable `auto_sort` for automatic sorting

## Configuration

### File Location

```lua
opts = {
  todo_file_path = vim.fn.expand("~/Documents/my-todos.md"), -- Custom location
}
```

### Auto-Sorting

```lua
opts = {
  auto_sort = false, -- Disable automatic sorting
}
```

### Custom Keybindings

```lua
opts = {
  keybindings = {
    open_todo_floating = "<C-t>", -- Use Ctrl+t instead
    add_todo = "<leader>+",
    -- ... customize any keybinding
  },
}
```

## Todo Format

The plugin uses standard markdown checkbox format:

```markdown
# Todo List

- [ ] Incomplete todo item
- [x] Completed todo item
- [ ] Another incomplete item

## Work Tasks

- [ ] Review pull request
- [ ] Update documentation
```

## Advanced Features

### Auto-Sorting

When enabled, todos are automatically sorted with:

1. Non-todo content (headers, text) at the top
2. Incomplete todos `- [ ]` next
3. Completed todos `- [x]` at the bottom

### Clear Options

The clear function (`<leader>tc`) provides three options:

- **Clear all todos** - Removes all todo items
- **Clear completed todos only** - Removes only completed items
- **Cancel** - No action

### Smart Updates

- Floating window automatically updates when using bulk operations
- File changes are saved immediately when closing floating window
- All operations provide user feedback via notifications

## Troubleshooting

### Plugin Not Loading

- Ensure the plugin directory structure is correct
- Run `:Lazy sync` to install
- Check `:Lazy` for any error messages

### Keybindings Not Working

- Verify your leader key is set: `vim.g.mapleader = " "`
- Check for keybinding conflicts with `:map <your-key>`
- Customize keybindings in the configuration if needed

### File Not Found

- Check that the todo file path exists and is writable
- The plugin will create the file automatically if the directory exists

## Contributing

This is a personal plugin, but feel free to fork and modify for your needs. The code is structured to be easily extensible for additional features.

