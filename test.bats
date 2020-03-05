#!/usr/bin/bats
# vim: filetype=bash:
GIT_ARCHIVE_ALL="$(pwd)/git-archive-all"

repo_files()
{
	local repo="$1"
	local prefix="$2"
	cat<<-EOF
	${prefix}${repo}_1.txt
	${prefix}${repo}_2.txt
	${prefix}${repo}_folder/${repo}_1.txt
	${prefix}${repo}_folder/${repo}_2.txt
	EOF
}

create_repo()
{
	local repo="$1"
	echo "+++ creating repo $repo"
	mkdir "$repo"
	for file in $(repo_files "$repo" "$repo/")
	do
		mkdir -p "$(dirname "$file")"
		echo $RANDOM > "$file"
	done
	git -C "$repo" init
	git -C "$repo" add .
	git -C "$repo" commit -m "Initial commit"
}

add_submodule()
{
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
	"$GIT_ARCHIVE_ALL" "$@"
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

check_tar_content()
{
	local tarfile="$1"
	shift
	local IFS=$'\n'
	local expected_files=($(sort <<<"$*"))
	unset IFS
	set -- "${expected_files[@]}"
	while read filename
	do
		[[ "$filename" != */ ]] || continue  # skip directories
		[[ $# -gt 0 ]] || (echo>&2 "More files than expected: '$filename'"; return 1) 
		[[ "$filename" == "$1" ]] || (echo>&2 "File mismatch: expected '$filename', got '$1'"; return 1)
		shift
	done < <(tar taf "$tarfile" | sort)
	[[ $# -eq 0 ]] || (echo>&2 "Missing files: $@"; return 1)
	return 0
}

@test "test simple archive without submodules" {
	create_repo alpha
	cd alpha
	run_git_archive_all -o test.tar
	check_tar_content test.tar $(repo_files alpha)
	run_git_archive_all -o test.tar --prefix=prefix/
	check_tar_content test.tar $(repo_files alpha prefix/)
	run_git_archive_all -o test.tar --prefix=prefix/ HEAD alpha_folder/
	check_tar_content test.tar $(repo_files alpha prefix/ | grep ^prefix/alpha_folder/)
	! run_git_archive_all -o test.tar HEAD beta
}

@test "test archive with submodule" {
	create_repo alpha
	create_repo beta
	add_submodule alpha beta
	cd alpha
	echo "+++ testing git-archive-all"
	run_git_archive_all -o test.tar
	check_tar_content test.tar $(repo_files alpha) $(repo_files beta beta/) .gitmodules
	run_git_archive_all -o test.tar --prefix=prefix/
	check_tar_content test.tar $(repo_files alpha prefix/) $(repo_files beta prefix/beta/) prefix/.gitmodules
	run_git_archive_all -o test.tar --prefix=prefix/ HEAD alpha_folder
	check_tar_content test.tar $(repo_files alpha prefix/ | grep ^prefix/alpha_folder/)
	run_git_archive_all -o test.tar --prefix=prefix/ HEAD beta
	check_tar_content test.tar $(repo_files beta prefix/beta/ | grep ^prefix/beta/)
}

@test "test archive with recursive submodules" {
	create_repo alpha
	create_repo beta
	create_repo gamma
	add_submodule beta gamma
	add_submodule alpha beta
	cd alpha
	echo "+++ testing git-archive-all"
	! run_git_archive_all -o test.tar --fail-missing
	run_git_archive_all -o test.tar
	check_tar_content test.tar $(repo_files alpha) $(repo_files beta beta/) .gitmodules beta/.gitmodules
	git submodule update --init --recursive
	run_git_archive_all -o test.tar --no-recursive
	check_tar_content test.tar $(repo_files alpha) $(repo_files beta beta/) .gitmodules beta/.gitmodules
	run_git_archive_all -o test.tar
	check_tar_content test.tar $(repo_files alpha) $(repo_files beta beta/) $(repo_files gamma beta/gamma/) .gitmodules beta/.gitmodules
	run_git_archive_all -o test.tar HEAD^
	check_tar_content test.tar $(repo_files alpha)
	run_git_archive_all -o test.tar HEAD beta
	check_tar_content test.tar $(repo_files beta beta/) $(repo_files gamma beta/gamma/) beta/.gitmodules
}

