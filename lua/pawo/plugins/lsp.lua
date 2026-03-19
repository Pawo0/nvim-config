return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- Wymuszamy załadowanie słownika domyślnych konfiguracji z nvim-lspconfig
		require("lspconfig")

		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- 1. Setup Mason Tool Installer (Formatters & Linters)
		mason_tool_installer.setup({
			ensure_installed = {
				"prettier",
				"stylua",
				"isort",
				"black",
				"eslint_d",
				"pylint",
			},
		})

		-- Definiujemy listę serwerów
		local servers = {
			"ts_ls",
			"pyright",
			"bashls",
			"dockerls",
			"lua_ls",
		}

		-- 2. Setup Mason LSPConfig
		mason_lspconfig.setup({
			ensure_installed = servers,
			automatic_installation = true,
		})

		-- 3. Konfiguracja w architekturze Neovim 0.11+
		local capabilities = cmp_nvim_lsp.default_capabilities()

		for _, server in ipairs(servers) do
			-- Pobieramy domyślną konfigurację wstrzykniętą przez nvim-lspconfig
			local default_config = vim.lsp.config[server] or {}

			-- Tworzymy tabelę z naszymi nadpisaniami
			local custom_config = {
				capabilities = capabilities,
			}

			-- Specyficzne opcje dla Lua
			if server == "lua_ls" then
				custom_config.settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
					},
				}
			end

			-- Głębokie scalenie tabel (żeby nie skasować domyślnego 'cmd' czy 'filetypes')
			vim.lsp.config[server] = vim.tbl_deep_extend("force", default_config, custom_config)

			-- Natywne uruchomienie serwera
			vim.lsp.enable(server)
		end

		-- 4. LSP Keymaps (załadowane, gdy serwer podepnie się pod plik)
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
				local keymap = vim.keymap.set

				keymap("n", "gR", "<cmd>Telescope lsp_references<CR>", opts, { desc = "Show LSP references" })
				keymap("n", "gd", vim.lsp.buf.definition, opts, { desc = "Go to definition" })
				keymap("n", "K", vim.lsp.buf.hover, opts, { desc = "Show documentation" })
				keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts, { desc = "See available code actions" })
				keymap("n", "<leader>rn", vim.lsp.buf.rename, opts, { desc = "Smart rename" })
				keymap("n", "<leader>d", vim.diagnostic.open_float, opts, { desc = "Show line diagnostics" })
			end,
		})
	end,
}
