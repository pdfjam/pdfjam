./pdfjam --vanilla --help | sed -En 's/=true,$//; s/="(.*)",$/=\1/; s/^ \["([^"]*)"\]/\1/p'
