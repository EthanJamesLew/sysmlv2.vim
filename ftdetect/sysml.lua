-- Force reload filetype detection
vim.cmd([[
    augroup filetypedetect
        au! BufRead,BufNewFile *.sysml setfiletype sysml
    augroup END
]])
