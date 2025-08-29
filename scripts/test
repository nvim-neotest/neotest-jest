#!/bin/bash

tempfile=".test_output.tmp"

if [[ -n $1 ]]; then
	nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile $1" | tee "${tempfile}"
else
	nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" | tee "${tempfile}"
fi

# Plenary doesn't emit exit code 1 when tests have errors during setup
errors=$(sed 's/\x1b\[[0-9;]*m//g' "${tempfile}" | awk '/(Errors|Failed) :/ {print $3}' | grep -v '0')

rm "${tempfile}"

if [[ -n $errors ]]; then
	echo "Tests failed"
	exit 1
fi

exit 0
