#!/bin/sh
sed -n "/sudo/d; /run: '/{s/''/’/g; s/'//g; s/’/'/g}; s/ *run: //p" .github/workflows/code-check.yml|sh
