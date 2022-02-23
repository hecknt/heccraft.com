#!/usr/bin/make -f

BLOG := $(MAKE) -f $(lastword $(MAKEFILE_LIST)) --no-print-directory
ifneq ($(filter-out help,$(MAKECMDGOALS)),)
include config
endif

# The following can be configured in config
BLOG_DATE_FORMAT_INDEX ?= %x
BLOG_DATE_FORMAT ?= %x %X
BLOG_TITLE ?= blog
BLOG_DESCRIPTION ?= blog
BLOG_URL_ROOT ?= http://localhost/blog
BLOG_FEED_MAX ?= 20
BLOG_FEEDS ?= rss
BLOG_SRC ?= articles


.PHONY: help init build deploy clean

ARTICLES = $(shell ls $(BLOG_SRC)/*.md 2>/dev/null)

help:
	$(info make init|build|deploy|clean)

init:
	mkdir -p $(BLOG_SRC) data templates
	printf '<!DOCTYPE html><html><head><title>$$TITLE</title></head><body>' > templates/header.html
	printf '</body></html>' > templates/footer.html
	printf '' > templates/index_header.html
	printf '<h2>Articles</h2><ul id=artlist>' > templates/article_list_header.html
	printf '<li><a href="$$URL">$$DATE $$TITLE</a></li>' > templates/article_entry.html
	printf '' > templates/article_separator.html
	printf '</ul>' > templates/article_list_footer.html
	printf '' > templates/index_footer.html
	printf '' > templates/article_header.html
	printf '' > templates/article_footer.html
	printf '' > templates/index_article_header.html
	printf '' > templates/index_article_footer.html
	printf 'blog\n' > .git/info/exclude

build: blog/index.html blog/blogs.html $(patsubst $(BLOG_SRC)/%.md,blog/%.html,$(ARTICLES)) $(patsubst %,blog/%.xml,$(BLOG_FEEDS))

deploy: build
	rsync -rLtvz $(BLOG_RSYNC_OPTS) blog/ data/ $(BLOG_REMOTE)

clean:
	rm -rf blog

config:
	printf 'BLOG_REMOTE:=%s\n' \
		'$(shell printf "Blog remote (eg: host:/var/www/html): ">/dev/tty; head -n1)' \
		> $@

blog/index.html: index.md $(ARTICLES) $(addprefix templates/,$(addsuffix .html,header index_header index_article_list_header article_entry article_separator index_article_list_footer index_footer footer))
	mkdir -p blog
	TITLE="$(BLOG_TITLE)"; \
	PAGE_TITLE="$(BLOG_TITLE)"; \
	export TITLE; \
	export PAGE_TITLE; \
	envsubst < templates/header.html > $@; \
	envsubst < templates/index_header.html >> $@; \
	pandoc < index.md >> $@; \
	envsubst < templates/index_article_list_header.html >> $@; \
	first=true; \
	first=true; \
	echo $(ARTICLES); \
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s $(BLOG_DATE_FORMAT_INDEX)" --pretty=format:'%ad%n' -- "$$f"; \
	done | sort -nr | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		"$$first" || envsubst < templates/article_separator.html; \
		URL="`printf '%s' "\$$FILE" | sed 's,^$(BLOG_SRC)/\(.*\).md,\1,'`.html" \
		DATE="$$DATE" \
		TITLE="`head -n1 "\$$FILE" | sed -e 's/^# //g'`" \
		DATE_POSTED="`grep -i '^; *date-posted:' $$FILE | cut -d: -f2- | paste -sd ','`" \
		DATE_EDITED="`grep -i '^; *date-modified:' $$FILE | cut -d: -f2- | paste -sd ','`" \
		envsubst < templates/article_entry.html; \
		first=false; \
	done >> $@; \
	envsubst < templates/index_article_list_footer.html >> $@; \
	envsubst < templates/index_footer.html >> $@; \
	envsubst < templates/footer.html >> $@; \

blog/blogs.html: $(ARTICLES) $(addprefix templates/,$(addsuffix .html,header article_list_header article_entry article_separator article_list_footer footer))
	TITLE="Blogs - $(BLOG_TITLE)"; \
	PAGE_TITLE="Blogs - $(BLOG_TITLE)"; \
	export TITLE; \
	export PAGE_TITLE; \
	envsubst < templates/header.html > $@; \
	envsubst < templates/article_list_header.html >> $@; \
	first=true; \
	first=true; \
	echo $(ARTICLES); \
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		git log -n 1 --diff-filter=A --date="format:%s $(BLOG_DATE_FORMAT_INDEX)" --pretty=format:'%ad%n' -- "$$f"; \
	done | sort -nr | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		"$$first" || envsubst < templates/article_separator.html; \
		URL="`printf '%s' "\$$FILE" | sed 's,^$(BLOG_SRC)/\(.*\).md,\1,'`.html" \
		DATE="$$DATE" \
		TITLE="`head -n1 "\$$FILE" | sed -e 's/^# //g'`" \
		DATE_POSTED="`grep -i '^; *date-posted:' $$FILE | cut -d: -f2- | paste -sd ','`" \
		DATE_EDITED="`grep -i '^; *date-modified:' $$FILE | cut -d: -f2- | paste -sd ','`" \
		envsubst < templates/article_entry.html; \
		first=false; \
	done >> $@; \
	envsubst < templates/article_list_footer.html >> $@; \
	envsubst < templates/footer.html >> $@; \

blog/%.html: $(BLOG_SRC)/%.md $(addprefix templates/,$(addsuffix .html,header article_header article_footer footer))
	mkdir -p blog
	TITLE="$(shell head -n1 $< | sed 's/^# \+//')"; \
	export TITLE; \
	PAGE_TITLE="$${TITLE} - $(BLOG_TITLE)"; \
	export PAGE_TITLE; \
	AUTHOR="$(shell git log --format="%an" -- "$<" | tail -n 1)"; \
	export AUTHOR; \
	DATE_POSTED="$(shell grep -i '^; *date-posted:' "$<" | cut -d: -f2- | paste -sd ',')"; \
	export DATE_POSTED; \
	DATE_EDITED="$(shell grep -i '^; *date-modified:' "$<" | cut -d: -f2- | paste -sd ',')"; \
	export DATE_EDITED; \
	envsubst < templates/header.html > $@; \
	envsubst < templates/article_header.html >> $@; \
	sed -e '/^;/d' < $< | pandoc >> $@; \
	envsubst < templates/article_footer.html >> $@; \
	envsubst < templates/footer.html >> $@; \

blog/rss.xml: $(ARTICLES)
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0">\n<channel>\n<title>%s</title>\n<link>%s</link>\n<description>%s</description>\n' \
		"$(BLOG_TITLE)" "$(BLOG_URL_ROOT)" "$(BLOG_DESCRIPTION)" > $@
	for f in $(ARTICLES); do \
		printf '%s ' "$$f"; \
		grep -i '^; *date-posted-rss:' "$$f"|cut -d: -f2-;  \
	done | sort -k2nr | head -n $(BLOG_FEED_MAX) | cut -d" " -f1,3- | while IFS=" " read -r FILE DATE; do \
		printf '<item>\n<title>%s</title>\n<link>%s</link>\n<guid>%s</guid>\n<pubDate>%s</pubDate>\n<description><![CDATA[%s]]></description>\n</item>\n' \
			"`head -n 1 $$FILE | sed 's/^# //'`" \
			"$(BLOG_URL_ROOT)`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$(BLOG_URL_ROOT)`basename $$FILE | sed 's/\.md/\.html/'`" \
			"$$DATE" \
			"`sed -e '/^;/d' < $$FILE | pandoc`"; \
	done >> $@
	printf '</channel>\n</rss>\n' >> $@
