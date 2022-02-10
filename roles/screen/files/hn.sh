#!/bin/sh

# it doesn't seem possible to transform (upcase) text in the screen
# caption so we instead use backtick substitution

hostname | tr '[:lower:]' '[:upper:]'
