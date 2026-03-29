PREFIX := $(HOME)/bin

.PHONY: install setup uninstall

install:
	@mkdir -p $(PREFIX)
	@install -m 755 bin/setup-maven-publishing $(PREFIX)/setup-maven-publishing
	@install -m 755 bin/publish-maven $(PREFIX)/publish-maven
	@install -m 755 bin/setup-maven-claude-md $(PREFIX)/setup-maven-claude-md
	@echo "Installed to $(PREFIX)/"
	@echo ""
	@case "$$PATH" in \
		*"$(PREFIX)"*) \
			echo "$(PREFIX) is already in your PATH." ;; \
		*) \
			echo "WARNING: $(PREFIX) is not in your PATH."; \
			echo "Add this to your shell config (~/.zshrc or ~/.bashrc):"; \
			echo ""; \
			echo '  export PATH="$$HOME/bin:$$PATH"'; \
			echo ""; \
			echo "Then restart your shell." ;; \
	esac

setup: install
	@setup-maven-publishing

uninstall:
	@rm -f $(PREFIX)/setup-maven-publishing
	@rm -f $(PREFIX)/publish-maven
	@rm -f $(PREFIX)/setup-maven-claude-md
	@echo "Uninstalled from $(PREFIX)/"
