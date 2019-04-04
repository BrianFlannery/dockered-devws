#!/bin/bash

set -x
sleep 5
ls -lart ~/some/arbitrary/path/bad_news.file
grep 'User ' ~/.ssh/config
