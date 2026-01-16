-- ~/.config/nvim/lua/treesitter-keymaps.lua

local function get_root(bufnr)
  local ft = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft

  local ok_p, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok_p or not parser then return nil, nil end

  local ok_t, trees = pcall(parser.parse, parser)
  if not ok_t or not trees or not trees[1] then return nil, nil end

  return trees[1]:root(), lang
end

local function has_ancestor(node, wanted_type)
  node = node:parent()
  while node do
    if node:type() == wanted_type then return true end
    node = node:parent()
  end
  return false
end

local function goto_hs_top_def(direction)
  local bufnr = vim.api.nvim_get_current_buf()
  local root, lang = get_root(bufnr)
  if not root or lang ~= "haskell" then return end

  local query = vim.treesitter.query.parse(lang, [[
    (signature) @def
    (function)  @def
    (bind)      @def
  ]])

  local cur = vim.api.nvim_win_get_cursor(0)
  local cur_row, cur_col = cur[1] - 1, cur[2]

  local best_sr, best_sc

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    if node:type() == "bind" and has_ancestor(node, "local_binds") then
      goto continue
    end

    local sr, sc = node:range()

    if direction == "next" then
      local after = (sr > cur_row) or (sr == cur_row and sc > cur_col)
      if after and (not best_sr or sr < best_sr or (sr == best_sr and sc < best_sc)) then
        best_sr, best_sc = sr, sc
      end
    else
      local before = (sr < cur_row) or (sr == cur_row and sc < cur_col)
      if before and (not best_sr or sr > best_sr or (sr == best_sr and sc > best_sc)) then
        best_sr, best_sc = sr, sc
      end
    end

    ::continue::
  end

  if best_sr then
    vim.api.nvim_win_set_cursor(0, { best_sr + 1, best_sc })
    vim.cmd("normal! zv")
  end
end

vim.keymap.set("n", "]f", function() goto_hs_top_def("next") end, { desc = "Next Haskell top-level def" })
vim.keymap.set("n", "[f", function() goto_hs_top_def("prev") end, { desc = "Prev Haskell top-level def" })
