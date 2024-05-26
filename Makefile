
.PHONY:
build:
	go build .

install: cmds
	cp ./cmds /usr/local/bin
	cp ./cmds_autocomplete /usr/share/zsh/site-functions/_cmds
