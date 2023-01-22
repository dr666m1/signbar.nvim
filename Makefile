.PHONY: test
test:
	stylua --check ./lua/

.PHONY: fmt
fmt:
	stylua ./lua/
