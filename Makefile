NVIM ?= nvim

test:
	$(NVIM) --headless --clean -i NONE -c "set rtp+=." -l tests/init.lua
