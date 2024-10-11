local packer = require('packer')
packer.startup({
    function(use)
        -- Packer 可以管理自己本身
        use('wbthomason/packer.nvim')
        -- 你的插件列表...
        -- git
        use({ 'lewis6991/gitsigns.nvim' })
        -- wakatime
        use('wakatime/vim-wakatime')

        -------------------------- Optimize experience -------------------------------
        -- nvim-autopairs
        use("windwp/nvim-autopairs")
        -- nvim-tree
        use({ 'kyazdani42/nvim-tree.lua', requires = 'nvim-tree/nvim-web-devicons' })
        -- bufferline
        use({ 'akinsho/bufferline.nvim', requires = { 'nvim-tree/nvim-web-devicons', 'moll/vim-bbye' } })
        -- lualine
        use({ 'nvim-lualine/lualine.nvim', requires = { 'nvim-tree/nvim-web-devicons' } })
        use('arkav/lualine-lsp-progress')
        -- telescope
        use({ 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } })
        -- telescope extensions
        use('LinArcX/telescope-env.nvim')
        -- dashboard-nvim
        use({ 
            'nvimdev/dashboard-nvim',
            requires = {'nvim-tree/nvim-web-devicons'}
        })
        -- project
        use('ahmedkhalf/project.nvim')
        -- treesitter
        use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' })
        -- toggle a terminal
        -- use('nvim-toggle-terminal')

        use({
            'akinsho/toggleterm.nvim',
            tag = 'v2.*',
            config = function()
                require('toggleterm').setup()
            end,
        })

        --------------------- Special Function ---------------------------------------
        use({
            "kawre/leetcode.nvim",
            requires = {
              "nvim-telescope/telescope.nvim",
              "nvim-lua/plenary.nvim",
              "MunifTanjim/nui.nvim",
            }
        })

        -------------------------- Themes --------------------------------------------
        -- Colorschemes
        -- Description: This section focuses on the themes of nvim.
        -- tokyonight
        use('folke/tokyonight.nvim')
        -- OceanicNext
        use('mhartington/oceanic-next')
        -- gruvbox
        use({ 'ellisonleao/gruvbox.nvim', requires = { 'rktjmp/lush.nvim' } })
        -- zephyr 因为 zephyr 最近会跟 treesitter 插件冲突，所以暂时不推荐。
        -- use("glepnir/zephyr-nvim")
        -- nord
        use('shaunsingh/nord.nvim')
        -- onedark
        use('ful1e5/onedark.nvim')
        -- nightfox
        use('EdenEast/nightfox.nvim')

        --------------------- LSP --------------------
        -- use('williamboman/nvim-lsp-installer')
        -- Lspconfig
        -- use({ 'neovim/nvim-lspconfig' })
        use {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        }
        -- 补全引擎
        use('hrsh7th/nvim-cmp')
        -- snippet 引擎
        use('hrsh7th/vim-vsnip')
        -- 补全源
        use('hrsh7th/cmp-vsnip')
        use('hrsh7th/cmp-nvim-lsp') -- { name = nvim_lsp }
        use('hrsh7th/cmp-buffer') -- { name = 'buffer' },
        use('hrsh7th/cmp-path') -- { name = 'path' }
        use('hrsh7th/cmp-cmdline') -- { name = 'cmdline' }
        -- 常见编程语言代码段
        use('rafamadriz/friendly-snippets')
        -- ui
        use('onsails/lspkind-nvim')
        -- use('tami5/lspsaga.nvim')
        use('glepnir/lspsaga.nvim')
        -- indent-blankline
        use('lukas-reineke/indent-blankline.nvim')
        -- 代码格式化
        -- use("mhartington/formatter.nvim")
        use({ 'jose-elias-alvarez/null-ls.nvim', requires = 'nvim-lua/plenary.nvim' })
        -- json 增强插件
        use('b0o/schemastore.nvim')
        -- TypeScript 增强
        use({ 'jose-elias-alvarez/nvim-lsp-ts-utils', requires = 'nvim-lua/plenary.nvim' })
    end,
    config = {
        -- 并发数限制
        max_jobs = 16,

        -- 浮动窗口打开安装列表
        display = {
            open_fn = function()
                return require('packer.util').float({ border = 'single' })
            end,
        },
    },
})

-- 每次保存 plugins.lua 自动安装插件
pcall(
    vim.cmd,
    [[
    augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
    augroup end
  ]]
)
