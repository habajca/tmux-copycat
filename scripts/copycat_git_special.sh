#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PANE_CURRENT_PATH="$1"

source "$CURRENT_DIR/helpers.sh"

prefix_files() {
	local prefix="$1"
	local filter="$2"
	local file_lists="${@:3}"
	for files in $file_lists; do
		while read -r line; do
			if [ ! -z "$filter" ] && [[ $line == $filter* ]]; then
				continue
			fi
			echo "${prefix}${line}"
		done <<< "$files"
	done
}

git_status_files() {
	working_dir="$1"
	prefix="${2-}"
	filter="${3-}"

	staged_files="$(git -C "$working_dir"  diff-index HEAD --cached --ignore-submodules --name-only --relative)"
	unstaged_files="$(git -C "$working_dir"  diff-index HEAD --ignore-submodules --name-only --relative)"
	untracked_files="$(git -C "$working_dir" ls-files --others --exclude-standard)"
	echo "$(prefix_files "$prefix" "$filter" "$staged_files" "$unstaged_files" "$untracked_files")"

	if [ ! -d "$working_dir/.git" ]; then
		parent_files="$(git_status_files "$(dirname "$working_dir")" "../$prefix" "$(basename "$working_dir")")"
		[ ! -z "$parent_files" ] && echo "$parent_files" 
	fi
}

exit_if_no_results() {
	local results="$1"
	if [ -z "$results" ]; then
		display_message "No results!"
		exit 0
	fi
}

concatenate_files() {
	local git_status_files="$(git_status_files "$PANE_CURRENT_PATH")"
	exit_if_no_results "$git_status_files"

	local result=""
	# Undefined until later within a while loop.
	local file_separator
	while read -r line; do
		result="${result}${file_separator}${line}"
		file_separator="|"
	done <<< "$git_status_files"
	echo "$result"
}

# Creates one, big regex out of git status files.
# Example:
# `git status` shows files `foo.txt` and `bar.txt`
# output regex will be:
# `(foo.txt|bar.txt)
git_status_files_regex() {
	local concatenated_files="$(concatenate_files)"
	local regex_result="(${concatenated_files})"
	echo "$regex_result"
}

main() {
	local search_regex="$(git_status_files_regex)"
	# starts copycat mode
	$CURRENT_DIR/copycat_mode_start.sh "$search_regex"
}
main
