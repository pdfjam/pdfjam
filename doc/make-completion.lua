#!/usr/bin/env texlua
lfs.chdir(string.gsub(arg[0], "/[^/]*$", ""))
lfs.mkdir("build")
require"run"
build_zsh_complete(require"opts", "zsh-completion.in.sh", "build/_pdfjam")
