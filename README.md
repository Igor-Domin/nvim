

<p align="center">Just a repo for my shitty config :)</p>


<p align="center"><strong>Shortcuts</strong></p>


```

[Find / Search]
<Space>fw     (N)  →  Find Word Under Cursor     - telescope.grep_string
<Space>fa     (N)  →  Find All (Live Grep)       - telescope.live_grep
<Space>ff     (N)  →  Find File                  - telescope.find_files
<Space>fg     (N)  →  Find Git File              - telescope.git_files (fallback)
<Space>fd     (N)  →  Find Definition            - vim.lsp.buf.definition
<Space>fr     (N)  →  Find References            - vim.lsp.buf.references
<Space>fs     (N)  →  Find Symbol (workspace)    - vim.lsp.buf.workspace_symbols

[Editing]
<Space>re     (N)  →  Rename Symbol              - vim.lsp.buf.rename
<Space>rs     (N)  →  Replace Word Under Cursor
<Space>rs     (V)  →  Replace Selection
<A-j>     (N/I/V)  →  Move Line Down
<A-k>     (N/I/V)  →  Move Line Up
J             (N)  →  Join Lines (keep cursor)

[Clipboard]
<Space>y      (N)  → Yank Line to Clipboard
<Space>Y      (N)  → Yank Whole File
<Space>y      (V)  → Yank Selection

[Misc]
<Space>fe     (N)  → File Explorer               - :Ex
<Space>u      (N)  → Toggle UndoTree
<C-h>         (I)  → Signature Help              - vim.lsp.buf.signature_help
K             (N)  → Hover Documentation         - vim.lsp.buf.hover

[Diagnostics]
<Space>d      (N)  → Show Diagnostic Float
[d / ]d       (N)  → Previous / Next Diagnostic
[D / ]D       (N)  → First / Last Diagnostic

[Harpoon]
<Space>a      (N)  → Add File
<Space>A      (N)  → Move File to Top
<Space>q      (N)  → Toggle Harpoon Menu
<C-h>         (N)  → Jump to File 1
<C-j>         (N)  → Jump to File 2
<C-k>         (N)  → Jump to File 3
<C-l>         (N)  → Jump to File 4
<C-S-p>       (N)  → Previous Harpoon Entry
<C-S-n>       (N)  → Next Harpoon Entry

[Run / Build]
<Space>cr     (N)  → Run (runghc)
<Space>cb     (N)  → Build + Run (compiled)
<Space>cR     (N)  → Run Compiled Binary

[Git]
<Space>gs     (N)  → Git Status (Fugitive)
:GitMe        (C)  → Configure Repo (user, editor, diff, rebase)

```

These GLOBAL keymaps are created unconditionally when Nvim starts:
"gra" (Normal and Visual mode) is mapped to vim.lsp.buf.code_action()
"gri" is mapped to vim.lsp.buf.implementation()
"grn" is mapped to vim.lsp.buf.rename()
"grr" is mapped to vim.lsp.buf.references()
"grt" is mapped to vim.lsp.buf.type_definition()
"gO" is mapped to vim.lsp.buf.document_symbol()
CTRL-S (Insert mode) is mapped to vim.lsp.buf.signature_help()
"an" and "in" (Visual and Operator-pending mode) are mapped to outer and inner incremental selections, respectively, using vim.lsp.buf.selection_range()
K is mapped to vim.lsp.buf.hover() unless 'keywordprg' is customized or a custom keymap for K exists.


These diagnostic keymaps are created unconditionally when Nvim starts:
]d jumps to the next diagnostic in the buffer. ]d-default
[d jumps to the previous diagnostic in the buffer. [d-default
]D jumps to the last diagnostic in the buffer. ]D-default
[D jumps to the first diagnostic in the buffer. [D-default
<C-w>d shows diagnostic at cursor in a floating window. CTRL-W_d-default
