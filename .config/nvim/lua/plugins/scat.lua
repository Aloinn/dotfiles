return {
  {
    url = "ssh://git.amazon.com:2222/pkg/Scat-nvim",
    branch = "mainline",
    enabled = require("utils.host").is_amazon_host,
    event = "VeryLazy",
    dependencies = { "nvim-telescope/telescope.nvim", "sindrets/diffview.nvim" },
    config = function()
      local map = vim.keymap.set
      local scat = require "scat"
      local brazil = require "scat.brazil"
      local brazil_utils = require "scat.brazil.utils"
      local cr = require "scat.cr"
      local local_manager = require "scat.cr.local_manager"
      local paste = require "scat.paste"
      local tiny_url = require "scat.tiny"

      scat.setup {
        cr = { user = "alainlam" },
      }

      -- Code browser links
      map("n", "<leader>ap", brazil.display_current_package_url, { desc = "Scat: current package URL" })
      map("n", "<leader>aP", brazil.display_package_under_cursor_url, { desc = "Scat: package under cursor URL" })
      map("n", "<leader>aR", brazil.display_release_under_cursor_url, { desc = "Scat: release under cursor URL" })
      map({ "n", "x" }, "<leader>af", brazil.display_current_file_url, { desc = "Scat: current file URL" })
      map("n", "<leader>av", brazil.display_current_version_set_url, { desc = "Scat: version set URL" })

      -- Brazil
      map("n", "<leader>al", brazil.list_all_packages, { desc = "Scat: list all packages" })
      map("n", "<leader>ais", brazil.lookup_packages, { desc = "Scat: lookup packages" })
      map("n", "<leader>aij", brazil.install_current_jdt_package, { desc = "Scat: install current JDT package" })
      map("n", "<leader>ab", brazil.build_current_package, { desc = "Scat: build current package" })
      map("n", "<leader>abr", brazil.build_current_package_recursively, { desc = "Scat: build recursively" })
      map("n", "<leader>abc", brazil.run_command_inside_current_package, { desc = "Scat: run command in package" })
      map("n", "<leader>abl", brazil.run_prev_brazil_task, { desc = "Scat: run previous brazil task" })
      map("n", "<leader>ac", brazil_utils.run_checkstyle, { desc = "Scat: checkstyle" })
      map("n", "<leader>aw", brazil.switch_workspace_package_info, { desc = "Scat: switch workspace packageInfo" })

      -- CRUX
      map("n", "<leader>ar", cr.open_cr, { desc = "Scat: open CR" })
      map("n", "<leader>arp", cr.fetch_active_crs, { desc = "Scat: fetch active CRs" })
      map("n", "<leader>aru", cr.update_existing_cr, { desc = "Scat: update existing CR" })
      map("n", "<leader>art", local_manager.toggle_cr_overview, { desc = "Scat: toggle CR overview" })

      -- Paste / tiny
      map({ "n", "x" }, "<leader>as", paste.send_to_pastebin, { desc = "Scat: send to paste" })
      map("n", "<leader>asl", paste.list_my_pastes, { desc = "Scat: list my pastes" })
      map("n", "<leader>ay", tiny_url.shorten_url, { desc = "Scat: tiny URL" })
    end,
  },
}
