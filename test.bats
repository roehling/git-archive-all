#!/usr/bin/env bats
# vim: filetype=bash:
#
# GIT-ARCHIVE-ALL
#
# Copyright (c) 2019 Timo Röhling
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
GIT_ARCHIVE_ALL="$(pwd)/git-archive-all"

repo_files()
{
	# Creates a list of standard files for a test repository
	local var="$1"
	local repo="$2"
	local prefix="$3"
	eval "${var}=(
		'${prefix}${repo}_1.txt'
		'${prefix}${repo}_2.txt'
		'${prefix}${repo}_folder.txt'
		'${prefix}${repo}_folder/${repo}_1.txt'
		'${prefix}${repo}_folder/${repo}_2.txt'
	)"
}

create_repo()
{
	# Creates a test repository that will contain
	# the standard files and anything passed as
	# additional parameter.
	local repo="$1"
	shift
	echo "+++ creating repo $repo"
	mkdir "$repo"
	local files=()
	repo_files files "$repo" "$repo/"
	for file in "${files[@]}"
	do
		[[ "$file" != */ ]] || continue
		mkdir -p "$(dirname "$file")"
		echo $RANDOM > "$file"
	done
	for file in "$@"
	do
		mkdir -p "$(dirname "$repo/$file")"
		echo $RANDOM > "$repo/$file"
	done
	git -C "$repo" init
	git -C "$repo" add .
	git -C "$repo" commit -m "Initial commit"
}

add_submodule()
{
	# Adds a test repository as submodule to another
	# test repository.
	local repo="$1"
	local submodule="$2"
	local path="${3:-$submodule}"
	echo "+++ adding submodule $submodule to repo $repo"
	git -C "$repo" submodule add ../"$submodule" "$path"
	git -C "$repo" add .
	git -C "$repo" commit -m "add submodule"
}

run_git_archive_all()
{
	echo "+++" "git-archive-all" "$@"
	"$GIT_ARCHIVE_ALL" -v "$@"
}

setup()
{
	MY_TMPDIR="$(mktemp -d --tmpdir="$BATS_TMPDIR")"
	pushd "$MY_TMPDIR" &>/dev/null
}

teardown()
{
	popd &>/dev/null
	rm -rf "$MY_TMPDIR"
}

sort_array()
{
	# Sorts the array. We use 'sort -z' with NUL-terminated strings
	# so we can have arbitrary characters in our array elements
	local tmpfile="$(mktemp)"
	eval 'printf "%s\0" "${'"$1"'[@]}" | sort -z >'"$tmpfile"
	eval "$1"'=()'
	while read -d $'\0' item
	do
		eval "$1"'+=("$item")'
	done < "$tmpfile"
	rm "$tmpfile"
}

filter_array()
{
	local array="$1"
	local prefix="$2"
	local i
	eval 'for i in ${!'"$array"'[@]}; do
		[[ "${'"$array"'[i]}" == "'"${prefix}"'"* ]] || unset '"$array"'[i]
	done'
}

check_tar_content()
{
	# Check if the contents of a TAR file matches with the expected
	# list of files. File names can have arbitrary characters except
	# NUL (and '/' of course).
	local tarfile="$1"
	shift
	local expected_files=("$@")
	sort_array expected_files
	local actual_files=()
	eval "actual_files=($(tar --quoting-style=shell -taf "$tarfile"))"
	# tar -t also prints folder names, but we don't want them for
	# the file list comparison. Luckily, folder names always end in
	# '/', so we can remove them first.
	for i in ${!actual_files[@]}
	do
		[[ "${actual_files[i]}" != */ ]] || unset actual_files[i]
	done
	sort_array actual_files
	local mismatch=0
	if [[ "${#expected_files[@]}" == "${#actual_files[@]}" ]]
	then
		local i
		for ((i=0; i < ${#expected_files[@]}; i++))
		do
			if [[ "${expected_files[i]}" != "${actual_files[i]}" ]]
			then
				printf>&2" *** MISMATCH %q != %q\n" \
					"${expected_files[i]}" "${actual_files[i]}"
				mismatch=1
				break
			fi
		done
	else
		mismatch=1
	fi
	if [[ "$mismatch" == 1 ]]
	then
		echo>&2 "*** archive has wrong content"
		echo>&2 "*** expected files:"
		printf>&2 "%q " "${expected_files[@]}"
		echo>&2
		echo>&2 "*** actual files:"
		printf>&2 "%q " "${actual_files[@]}"
		echo>&2
	fi
	return $mismatch
}

@test "simple repo" {
	create_repo alpha
	cd alpha
	run_git_archive_all -o test.tar
	local tar_files
	repo_files tar_files alpha
	check_tar_content test.tar "${tar_files[@]}"
}

@test "simple repo, archive with prefix" {
	create_repo alpha
	cd alpha
	run_git_archive_all -o test.tar --prefix=prefix/
	local tar_files
	repo_files tar_files alpha prefix/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "simple repo, archive with prefix and path spec" {
	create_repo alpha
	cd alpha
	run_git_archive_all -o test.tar --prefix=prefix/ HEAD alpha_folder/
	local tar_files
	repo_files tar_files alpha prefix/
	filter_array tar_files prefix/alpha_folder/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "simple repo, fail on missing path spec" {
	create_repo alpha
	cd alpha
	! run_git_archive_all -o test.tar HEAD beta
}

@test "simple repo, file names with non-ASCII characters" {
	create_repo alpha "with space.txt" "with"$'\n'"newline.txt" "with"'$'"dollar.txt" "ÄÖÜäöü.txt" "日本人.txt"
	cd alpha
	run_git_archive_all -o test.tar
	local tar_files
	repo_files tar_files alpha
	tar_files+=("with space.txt" "with"$'\n'"newline.txt" "with"'$'"dollar.txt" "ÄÖÜäöü.txt" "日本人.txt")
	check_tar_content test.tar "${tar_files[@]}"
}

@test "simple repo, archive with newline in prefix" {
	create_repo alpha
	cd alpha
	run_git_archive_all -o test.tar --prefix=pre$'\n'fix/
	local tar_files
	repo_files tar_files alpha pre$'\n'fix/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with submodule" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar
	local tar_files=(.gitmodules)
	repo_files tar_files+ alpha
	repo_files tar_files+ beta beta/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with submodule, gzipped tar archive" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar.gz
	local tar_files=(.gitmodules)
	repo_files tar_files+ alpha
	repo_files tar_files+ beta beta/
	check_tar_content test.tar.gz "${tar_files[@]}"
	file test.tar.gz | grep -q "gzip compressed"
}

@test "repo with submodule, archive with prefix" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar --prefix=prefix/
	local tar_files=(prefix/.gitmodules)
	repo_files tar_files+ alpha prefix/
	repo_files tar_files+ beta prefix/beta/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with submodule, archive with prefix and path spec" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar --prefix=prefix/ HEAD alpha_folder
	local tar_files
	repo_files tar_files alpha prefix/
	filter_array tar_files prefix/alpha_folder/
	check_tar_content test.tar "${tar_files[@]}"
}


@test "repo with submodule, archive with path spec" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar HEAD beta/beta_folder
	local tar_files
	repo_files tar_files beta beta/
	filter_array tar_files beta/beta_folder/
	check_tar_content test.tar "${tar_files[@]}"
	run_git_archive_all -o test.tar HEAD beta
	repo_files tar_files beta beta/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with submodule, file names with non-ASCII characters" {
	create_repo alpha "with space.txt" "with"$'\n'"newline.txt" "with"'$'"dollar.txt" "ÄÖÜäöü.txt" "日本人.txt"
	create_repo beta
	add_submodule alpha beta "space umlaut ÄÖÜäöü"
	cd alpha
	run_git_archive_all -o test.tar
	local tar_files=()
	repo_files tar_files+ alpha
	repo_files tar_files+ beta "space umlaut ÄÖÜäöü"/
	tar_files+=("with space.txt" "with"$'\n'"newline.txt" "with"'$'"dollar.txt" "ÄÖÜäöü.txt" "日本人.txt" .gitmodules)
	check_tar_content test.tar "${tar_files[@]}" 
}

@test "repo with submodule, archive with newline in prefix" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar --prefix=pre$'\n'fix/
	local tar_files=(pre$'\n'fix/.gitmodules)
	repo_files tar_files+ alpha pre$'\n'fix/
	repo_files tar_files+ beta pre$'\n'fix/beta/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with submodule, archive with newline in prefix and path spec" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	run_git_archive_all -o test.tar --prefix=pre$'\n'fix/ HEAD beta/beta_folder
	local tar_files
	repo_files tar_files beta pre$'\n'fix/beta/
	filter_array tar_files pre$'\n'fix/beta/beta_folder/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with submodule, older commits" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	echo $RANDOM > beta/new_file.txt
	git -C beta add .
	git -C beta commit -m "new file"
	git -C alpha/beta pull origin master
	echo $RANDOM > alpha/yet_another_file.txt
	git -C alpha add .
	git -C alpha commit -m "updated submodule"
	cd alpha
	local tar_files=()
	repo_files tar_files+ alpha
	run_git_archive_all -o test.tar --fail-missing HEAD~2
	check_tar_content test.tar "${tar_files[@]}" 
	tar_files+=(.gitmodules)
	repo_files tar_files+ beta beta/
	run_git_archive_all -o test.tar --fail-missing HEAD~1
	check_tar_content test.tar "${tar_files[@]}" 
	run_git_archive_all -o test.tar --fail-missing HEAD
	tar_files+=(beta/new_file.txt yet_another_file.txt)
	check_tar_content test.tar "${tar_files[@]}" 
}

@test "repo with recursive submodules" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing
	local tar_files=(.gitmodules beta/.gitmodules)
	repo_files tar_files+ alpha
	repo_files tar_files+ beta beta/
	repo_files tar_files+ gamma beta/gamma/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with recursive submodules, non-recursive archive" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing --no-recursive
	local tar_files=(.gitmodules beta/.gitmodules)
	repo_files tar_files+ alpha
	repo_files tar_files+ beta beta/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with recursive submodules, sub-submodule not initialized" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	! run_git_archive_all -o test.tar --fail-missing
	run_git_archive_all -o test.tar
	local tar_files=(.gitmodules beta/.gitmodules)
	repo_files tar_files+ alpha
	repo_files tar_files+ beta beta/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with recursive submodules, archive with prefix" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing --prefix=prefix/
	local tar_files=(prefix/.gitmodules prefix/beta/.gitmodules)
	repo_files tar_files+ alpha prefix/
	repo_files tar_files+ beta prefix/beta/
	repo_files tar_files+ gamma prefix/beta/gamma/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with recursive submodules, non-recursive archive, path spec is not in result" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing --no-recursive HEAD beta/gamma/gamma_folder
	local tar_files=()
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with recursive submodules, archive with prefix and pathspec" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing --prefix=prefix/ HEAD beta/gamma/gamma_folder
	local tar_files
	repo_files tar_files gamma prefix/beta/gamma/
	filter_array tar_files prefix/beta/gamma/gamma_folder/
	check_tar_content test.tar "${tar_files[@]}"
	run_git_archive_all -o test.tar --fail-missing --prefix=prefix/ HEAD beta/gamma
	repo_files tar_files gamma prefix/beta/gamma/
	check_tar_content test.tar "${tar_files[@]}"
}
@test "repo with recursive submodules, archive with pathspec" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing HEAD beta/gamma/gamma_folder
	local tar_files
	repo_files tar_files gamma beta/gamma/
	filter_array tar_files beta/gamma/gamma_folder/
	check_tar_content test.tar "${tar_files[@]}"
	run_git_archive_all -o test.tar --fail-missing HEAD beta/gamma
	repo_files tar_files gamma beta/gamma/
	check_tar_content test.tar "${tar_files[@]}"
}

@test "repo with recursive submodules, archive with newline in prefix" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --fail-missing --prefix=pre$'\n'fix/
	local tar_files=(pre$'\n'fix/.gitmodules pre$'\n'fix/beta/.gitmodules)
	repo_files tar_files+ alpha pre$'\n'fix/
	repo_files tar_files+ beta pre$'\n'fix/beta/
	repo_files tar_files+ gamma pre$'\n'fix/beta/gamma/
	check_tar_content test.tar "${tar_files[@]}"
}

