return {
  "nvim-neotest/neotest",
    lazy = false,
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "rcasia/neotest-java"
  },
    config = function()
      local neotest = require("neotest")

      -- Setup Neotest with Java adapter
      neotest.setup({
        adapters = {
        ["neotest-java"] = {
          root_dir = function()
            -- Force Neotest to recognize Ant by treating it like Maven
            local cwd = vim.fn.getcwd()
            if vim.fn.filereadable(cwd .. "/build.xml") == 1 then
              print("TEST")
              return cwd
            end
            return require("jdtls.setup").find_root({ "pom.xml", "build.gradle", ".git" }) or cwd
          end,
          ignore_wrapper = true,
          force_test_class = true,
          incremental_build = true,
          extra_args = { "-Dtest=true -Ddomain=test -Djunit.jupiter.execution.parallel.enabled=false" },
        },
      },
      })

      -- Key mappings inside plugin config
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>tn", function() neotest.run.run() end, vim.tbl_extend("force", opts, { desc = "Run nearest Java test" }))
      vim.keymap.set("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, vim.tbl_extend("force", opts, { desc = "Run Java tests in file" }))
      vim.keymap.set("n", "<leader>tl", function() neotest.run.run_last() end, vim.tbl_extend("force", opts, { desc = "Run last Java test" }))
      vim.keymap.set("n", "<leader>ts", function() neotest.summary.toggle() end, vim.tbl_extend("force", opts, { desc = "Toggle Java test summary" }))
      vim.keymap.set("n", "<leader>to", function() neotest.output.open({ enter = true }) end, vim.tbl_extend("force", opts, { desc = "Show Java test output" }))
    end,
 }
