#!/usr/bin/env bash

shellcheck --shell=bash --external-sources \
    bin/* --source-path=template/lib/ \
    lib/* \
    scripts/*

shfmt --indent 4 --language-dialect bash --language-dialect bats --diff \
    ./**/*
