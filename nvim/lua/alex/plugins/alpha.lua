return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Each image keeps the flags/dimensions it was hand-tuned with. The
    -- dimensions are only used as an aspect ratio now -- the art is re-rendered
    -- at whatever size the window currently is.
    local images = {
      spiderlily4 = { file = "spiderlily4.jpeg", flags = { "-c", "-b", "--dither" }, base = { 100, 35 } },
      butterfly = { file = "butterfly.png", flags = { "-b", "--dither" }, base = { 50, 25 } },
      koifish = { file = "koifish.png", flags = { "-b" }, base = { 57, 20 } },
      ghiblicat = { file = "ghiblicat.png", flags = { "-b" }, base = { 45, 20 } },
      jellyfish = { file = "jellyfish.png", flags = { "-b" }, base = { 100, 50 } },
    }

    local image = images.spiderlily4
    local image_path = os.getenv("HOME") .. "/.config/nvim/lua/alex/plugins/src_imgs/" .. image.file
    local aspect = image.base[1] / image.base[2]

    -- Lines the rest of the layout needs: padding 2 + padding 2 +
    -- 5 buttons with spacing 1 (9) + footer 1, plus a little breathing room.
    local CHROME = 16
    local MIN_WIDTH, MAX_WIDTH = 24, 120

    -- How big should the art be, given the space we have?
    local function target_dims(win)
      local cols = vim.api.nvim_win_get_width(win)
      local rows = vim.api.nvim_win_get_height(win)

      local w = math.min(math.floor(cols * 0.8), cols - 2, MAX_WIDTH)
      local h = math.floor(w / aspect + 0.5)

      local avail_h = rows - CHROME
      if h > avail_h then
        h = avail_h
        w = math.floor(h * aspect + 0.5)
      end

      if w < MIN_WIDTH or h < 4 then
        return nil -- too cramped for art
      end
      return w, h
    end

    local cache = {}
    local generation = 0

    local function split_lines(out)
      local lines = {}
      for line in out:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
      end
      -- gmatch yields a trailing empty capture after the final newline
      while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
      end
      return lines
    end

    local function cmd_for(w, h)
      local argv = { "ascii-image-converter", image_path }
      vim.list_extend(argv, image.flags)
      vim.list_extend(argv, { "-d", w .. "," .. h })
      return argv
    end

    -- Blocking render, used once at startup so the first draw isn't empty.
    local function render_sync(w, h)
      local key = w .. "x" .. h
      if cache[key] then
        return cache[key]
      end
      local handle = io.popen(table.concat(vim.tbl_map(vim.fn.shellescape, cmd_for(w, h)), " "))
      if not handle then
        return {}
      end
      local out = handle:read("*a")
      handle:close()
      cache[key] = split_lines(out)
      return cache[key]
    end

    local function alpha_win()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "alpha" then
          return win
        end
      end
    end

    -- Swap in art sized for `win`. Cache hits apply immediately; misses render
    -- in the background so dragging a tmux border never blocks the UI.
    local function resize_to(win, redraw)
      local w, h = target_dims(win)
      if not w then
        dashboard.section.header.val = {}
        if redraw then
          alpha.redraw()
        end
        return
      end

      local key = w .. "x" .. h
      if cache[key] then
        dashboard.section.header.val = cache[key]
        if redraw then
          alpha.redraw()
        end
        return
      end

      generation = generation + 1
      local mine = generation
      vim.system(cmd_for(w, h), { text = true }, function(obj)
        if obj.code ~= 0 then
          return
        end
        vim.schedule(function()
          cache[key] = split_lines(obj.stdout)
          -- A newer resize already won; don't clobber it with stale art.
          if mine ~= generation or not alpha_win() then
            return
          end
          dashboard.section.header.val = cache[key]
          alpha.redraw()
        end)
      end)
    end

    -- Initial header, sized for the window we're about to open in.
    local w, h = target_dims(0)
    dashboard.section.header.val = w and render_sync(w, h) or {}

    -- Apply a colorscheme highlight group
    dashboard.section.header.opts.hl = "Statement"
    dashboard.section.buttons.opts.hl = "Number"

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
      dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
      dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
      dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>AutoSession restore<CR>"),
    }

    -- Assemble the layout
    dashboard.config.layout = {
      { type = "padding", val = 2 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      dashboard.section.footer,
    }

    -- Send config to alpha
    alpha.setup(dashboard.opts)

    -- alpha re-centers itself on resize; this re-renders the art at the new size.
    local group = vim.api.nvim_create_augroup("AlphaResponsiveHeader", { clear = true })
    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
      group = group,
      callback = function()
        local win = alpha_win()
        if win then
          resize_to(win, true)
        end
      end,
    })

    -- Size correctly when alpha opens into a window we haven't measured yet.
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "AlphaReady",
      callback = function()
        local win = alpha_win()
        if win then
          resize_to(win, true)
        end
      end,
    })

    -- Disable folding on alpha buffer
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}
