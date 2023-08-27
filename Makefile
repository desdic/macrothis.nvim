.PHONY: all

all: lint

fmt:
	stylua lua/ --config-path=.stylua.toml

lint:
	luacheck lua/telescope

deps:
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init_doc.lua -c "lua require('mini.doc').generate()" -c "qa!"

documentation-ci: deps documentation
