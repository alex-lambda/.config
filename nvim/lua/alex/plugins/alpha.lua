return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    local message = {
      type = "text",
      val = '"Nature does not hurry, yet everything is accomplished." - Laozi',
      opts = {
        hl = "Comment", -- Using a subtle color; change to "Statement" for more pop
        position = "center",
      },
    }

    -- Helper function to convert image to ASCII
    local function get_image_header(path)
      -- for spiderlily4 " -c -b --dither -d 100,35"
      -- for butterfly.png " -b --dither -d 50,25"
      -- for koifish.png " -b --height 20"
      -- for ghiblicat.png " -b -d 45,20"
      -- for jellyfish.png " -b -d 100,50"
      local cmd = "ascii-image-converter " .. path .. " -c -b --dither -d 100,35"

      local handle = io.popen(cmd)
      local result = handle:read("*a")
      handle:close()

      local lines = {}
      for line in result:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
      end
      return lines
    end

    -- Path to image
    local image_path = os.getenv("HOME") .. "/.config/nvim/lua/alex/plugins/src_imgs/spiderlily4.jpeg"

    -- Set the header to the output of our function
    dashboard.section.header.val = get_image_header(image_path)

    -- Apply a colorscheme highlight group
    dashboard.section.header.opts.hl = "Statement"
    dashboard.section.buttons.opts.hl = "Number"

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
      dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
      dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
      dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>AutoSession restore<CR>"),
    }

    -- Assemble the layout
    -- Insert the message between the header and the buttons
    dashboard.config.layout = {
      { type = "padding", val = 2 },
      dashboard.section.header,
      message, -- Your new text message
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      dashboard.section.footer,
    }

    -- Send config to alpha
    alpha.setup(dashboard.opts)

    -- Disable folding on alpha buffer
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}
