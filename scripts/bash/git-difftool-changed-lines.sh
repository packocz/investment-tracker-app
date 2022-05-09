#!/bin/bash

# Useful for `git difftool`
# `git difftool --extcmd=/path/to/git-difftool-changed-lines.sh`

# Outputs the lines numbers of the new file
# that are not present in the old file and
# Line numbers in the old files that are not
# in the new file

# FORMAT: One file per line
# FILE:LINE_NUMBERS
# Where LINE_NUMBERS is a comma separated list of line numbers


args=(
	# Don't output info for unchanged (context) lines
	--unchanged-group-format=""

	# For deleted, new and changed lines, output one LINE_RANGE per line
    --old-group-format="%dF-%dL%c'\012'" 
	--new-group-format="%dF-%dL%c'\012'"
	--changed-group-format="%dF-%dL%c'\012'"
)


# `git difftool` calls this command as `git-difftool.sh "$LOCAL" "$REMOTE"
# and adds BASE to the environment.
# See https://git-scm.com/docs/git-difftool#Documentation/git-difftool.txt--xltcommandgt

echo -n "$BASE:"

diff "${args[@]}" "$1" "$2" | while IFS=- read -r LINE END; do
	echo -n "$(( LINE++ ))"
	for (( ; LINE  <= END; LINE++ )); do
		echo -n ",$LINE"
	done
	echo
done