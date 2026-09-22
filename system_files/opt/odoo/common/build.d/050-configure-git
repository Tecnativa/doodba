#!/bin/bash

git config --system credential.https://github.com.helper \
    '!f() { [ -n "$GITHUB_TOKEN" ] || return 1; echo username=x-access-token; echo password="$GITHUB_TOKEN"; }; f'
git config --system pull.rebase false
git config --system init.defaultBranch main
