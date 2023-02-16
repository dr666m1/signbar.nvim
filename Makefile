# you have to specify features to format `goto` statement
.PHONY: install
install:
	./scripts/install.sh

.PHONY: test
test: install
	stylua --check ./lua/

.PHONY: fmt
fmt: install
	stylua ./lua/
