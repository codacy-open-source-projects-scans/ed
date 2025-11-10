#!/usr/bin/env bash

# Author: Alex Baranowski
# License: MIT

set -euo pipefail

# Logger functions
print_info(){
    echo -e "\e[34m[info] $1\e[0m"
}
print_error(){
    echo -e "\e[31m[error] $1\e[0m"
    exit 1
}


# GLOBAL VARIABLES

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DL_URL=https://download.savannah.gnu.org/releases/ed/
# Expected number of older versions for each file type
TAR_GZ_EXP_NUMER=2
TAR_BZ2_EXP_NUMER=9
# The third type is tar.lz, which is not expected to be present in the older versions
# also if number of files is not equal to the sum of the expected number of files for each type
# then there is a new file type

print_info "Checking number of files"

FILES_ALL_NUMBER=$(curl https://download.savannah.gnu.org/releases/ed/ -s | grep -o '>ed-.*<' | tr -d '<>' | grep -cv '\.sig') # removes signatures NOTE that this contains some trash data as well
TAR_GZ_NUMBER=$(curl https://download.savannah.gnu.org/releases/ed/ -s | grep -o '>ed-.*tar.gz<' | tr -d '<>' | wc -l)
TAR_BZ2_NUMBER=$(curl https://download.savannah.gnu.org/releases/ed/ -s | grep -o '>ed-.*tar.bz2<' | tr -d '<>' | wc -l)
TAR_LZ_NUMBER=$(curl https://download.savannah.gnu.org/releases/ed/ -s | grep -o '>ed-.*tar.lz<' | tr -d '<>' | wc -l)



extract_version(){
  filename="$1"
  version="${filename#ed-}"
  version="${version%.tar.lz}"
  echo "$version"
}


backup_self_code(){
    cp "$SCRIPT_DIR/update-repository.sh" "$SCRIPT_DIR/../update-repository.sh.bak"
    cp "$SCRIPT_DIR/README-EXTRA.md" "$SCRIPT_DIR/../README-EXTRA.md.bak"
}

restore_self_code(){
    cp "$SCRIPT_DIR/../update-repository.sh.bak" "$SCRIPT_DIR/update-repository.sh"
    cp "$SCRIPT_DIR/../README-EXTRA.md.bak" "$SCRIPT_DIR/README-EXTRA.md"
}

check_if_git_tag_exists(){
    version=$1
    if git tag | grep -q "^$version$"; then
        echo "[INFO] Tag $version already exists"
        return 1
    fi
    return 0
}

download_and_repack_to_tmp(){
    filename=$1
    temp_dir=$(mktemp -d)
    # NOTE curl -O will produce empty file because of the redirect so -L is needed
    dl_url=$DL_URL/$filename
    print_info "Downloading $filename from $dl_url"
    curl -LO $dl_url
    print_info "Entering xtrace mode"
    set -x
    print_info "Extracting $filename to $temp_dir"
    [ -d $temp_dir ] || mkdir -p $temp_dir # gh actions problem with /tmp ...
    [ -f ./$filename ] || print_error "File $filename does not exist!"
    tar -xvf ./$filename -C $temp_dir
    rm $filename
    backup_self_code
    rm -rf $SCRIPT_DIR/*
    mv  $temp_dir/ed-*/* $SCRIPT_DIR/
    rm -rf $temp_dir
    set +x
    restore_self_code
}

prepare_files_for_commit_gh_actions(){
    version=$1
    rl_filename=$2
    echo "Import $rl_filename" > /tmp/commit-message
    echo "$version" > /tmp/commit-tag
}


if [ $TAR_GZ_NUMBER -ne $TAR_GZ_EXP_NUMER ]; then
  print_error "[FAIL] Number of tar.gz files does not match the expected number"
fi

if [ $TAR_BZ2_NUMBER -ne $TAR_BZ2_EXP_NUMER ]; then
  print_error "[FAIL] Number of tar.bz2 files does not match the expected number"
fi

if [ $((TAR_GZ_NUMBER+TAR_BZ2_NUMBER+TAR_LZ_NUMBER)) -ne $FILES_ALL_NUMBER ]; then
  print_error "Number of all files does not match the expected number! There might be new tar file type!"
fi

print_info "File based checks passed"

#
filenames=$(curl https://download.savannah.gnu.org/releases/ed/ | grep -o '>ed-.*tar.lz<' | tr -d '<>')

print_info "Git tags ->"
git tag
print_info "Git tags end"

IFS=$'\n' sorted_filenames=($(sort -V <<< "$(for f in $filenames; do echo "$(extract_version "$f") $f"; done)"))
IFS=' '

# Print sorted filenames
for filename in "${sorted_filenames[@]}"; do
  echo "$filename"
done

for filename in "${sorted_filenames[@]}"; do
    # careful rl_filename and filename! Spend 10 minutes debugging reusing the
    # name...
    print_info "Processing $filename"
    rl_filename=$(echo $filename | awk '{print $2}')
    version=$(echo $filename | awk '{print $1}')
    print_info "Processing $rl_filename with version $version"
    
    if check_if_git_tag_exists "$version"; then
        download_and_repack_to_tmp "$rl_filename"
        prepare_files_for_commit_gh_actions "$version" "$rl_filename"
        print_info "Exiting with success, each GH action should be responsible for the single commit"
        exit 0 # only one version should be imported at the time!
    else
        print_info "Skipping $rl_filename -> $version as it already exists in the repository!"
    fi
done

