local packer = require("packer")
packer.startup(
  function(use)
   -- Packer 可以管理自己本身
  use('wbthomason/packer.nvim')
   -- 你的插件列表...
   --
   -- Colorschemes
   -- tokyonight
   use("folke/tokyonight.nvim")
   -- OceanicNext
   use("mhartington/oceanic-next")
   -- gruvbox
   use({ "ellisonleao/gruvbox.nvim", requires = { "rktjmp/lush.nvim" } })
   -- zephyr 暂时不推荐，详见上边解释
   -- use("glepnir/zephyr-nvim")
   -- nord
   use("shaunsingh/nord.nvim")
   -- onedark
   use("ful1e5/onedark.nvim")
   -- nightfox
   use("EdenEast/nightfox.nvim")
   
   -------------------------- plugins -------------------------------------------
    -- nvim-tree (新增)
    use({ "kyazdani42/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons" })

     -- bufferline (新增)
    use({ "akinsho/bufferline.nvim", requires = { "kyazdani42/nvim-web-devicons", "moll/vim-bbye" }})

    -- lualine (新增)
    use({ "nvim-lualine/lualine.nvim", requires = { "kyazdani42/nvim-web-devicons" } })
    use("arkav/lualine-lsp-progress")


end)
config = {
    -- 并发数限制
    max_jobs = 16,
    
    -- 浮动窗口打开安装列表
    display = {
        open_fn = function()
            return require("packer.util").float({ border = "single" })
        end,
    },
}

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
