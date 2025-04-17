#!/usr/bin/env bash

shfmt --indent 4 --language-dialect bash --language-dialect bats --write \
    ./**/*
