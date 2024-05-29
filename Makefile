.DEFAULT_GOAL:=help
MAKEFILE_DIR:=$(shell basename $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
THIS_NAME=$(shell echo $(MAKEFILE_DIR) | tr '[:lower:]' '[:upper:]')

PANDOC=pandoc
RELEASE_FILE=index.html
INPUT_README_MD=README.md
PANDOC_TEMPLATE=exres/pandoc/md2html.html
OUTPUT_README_HTML=exres/readme/_readme.html
OUTPUT_README_HTML_BODY=exres/readme/_readme.body.html
OUTPUT_README_HTML_CSS=exres/readme/_readme.css

.phony: help
help: ## ヘルプを表示する
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

$(OUTPUT_README_HTML): $(INPUT_README_MD) $(PANDOC_TEMPLATE)
	$(PANDOC) \
		-f markdown -t html \
		--template=$(PANDOC_TEMPLATE) \
		--metadata title="$(THIS_NAME)" \
		$(INPUT_README_MD) \
		> $(OUTPUT_README_HTML)

$(OUTPUT_README_HTML_BODY): $(OUTPUT_README_HTML)
	cat $(OUTPUT_README_HTML) \
		| sed \
			-n '/<body>/,/<\/body>/p' \
		| tail -n +2 | head -n -1 \
		> $(OUTPUT_README_HTML_BODY)

$(OUTPUT_README_HTML_CSS): $(OUTPUT_README_HTML) $(PANDOC_TEMPLATE)
	cat $(OUTPUT_README_HTML) \
		| sed \
			-n '/<style>/,/<\/style>/p' \
		| tail -n +2 | head -n -1 \
			| sed \
				-e 's/^[ \t]*//g; s/[ \t]*$$//g;' \
				-e 's/\([:{;,]\) /\1/g;' \
				-e 's/ {/{/g;' \
				-e 's/\/\*.*\*\///g;' \
				-e '/^$$/d' \
			| sed -e :a -e '$$!N; s/\n\(.\)/\1/; ta' \
		> $(OUTPUT_README_HTML_CSS)

$(RELEASE_FILE): $(OUTPUT_README_HTML_BODY)
	sed \
		-z \
		-i \
		-e 's/\(<!-- README -->\).*\(\n[^\n][^\n]*<!-- \/README -->\)/\1\2/' \
		-e 's/\(\/\* HELP_CSS \*\/\).*\(\n[^\n][^\n]*\/\* \/HELP_CSS \*\/\)/\1\2/' \
		$(RELEASE_FILE)
	sed \
		-i \
		-e '/<!-- README -->/r $(OUTPUT_README_HTML_BODY)' \
		-e '/\/\* HELP_CSS \*\//r $(OUTPUT_README_HTML_CSS)' \
		$(RELEASE_FILE)

.phony: renew
renew: $(RELEASE_FILE) ## READMEを反映した最終版HTMLを生成する
