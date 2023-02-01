# you have to specify features to format `goto` statement
.PHONY: install
install:
	command -v stylua || cargo install stylua --features lua52

.PHONY: test
test: install
	stylua --check ./lua/

.PHONY: fmt
fmt: install
	stylua ./lua/
