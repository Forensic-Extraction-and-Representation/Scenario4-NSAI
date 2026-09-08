#!/bin/bash
# Turn on debugging
set -x
IMAGE1="Narcos-1_ntfs.001"
OUTPUT1="host1_bodyfile.txt"
IMAGE2="Narcos-2_ntfs.001"
OUTPUT2="host2_bodyfile.txt"

# function to create the bodyfile based on the input of input image and output file
create_bodyfile() {
    # Regex for grep to include only files in /Users/ and exclude deleted files and files with 0 size
    INCLUDE_DIRS='\/Users\/[^\/]*/([dD]ocuments|[dD]ownloads|[dD]esktop|[pP]ictures|[vV]ideos)\/'
    EXCLUDE_PATTERN='0\|.*\((\$FILE_NAME|deleted)\)'

    # Run fls
    FLS_OUTPUT=$(fls -r -m / $1 | grep -E "$INCLUDE_DIRS" | grep -Ev "$EXCLUDE_PATTERN")

    # clear the output file if it exists
    > $2

    count=0
    # Create bodyfile with MD5 hashes
    while read L; do
        # Split L into an array based on '|' delimiter
        IFS='|' read -r -a a <<< "$L"
        perms=${a[3]}
        # if perms starts with "d", it's a directory, ignore it and continue
        if [[ $perms == d* ]]; then
            continue
        else
            MD5=($(fcat -f ntfs "${a[1]}" $1 | md5sum))
        fi
        # Add C:/ to the start of the path of L[1]
        echo "${MD5}|C:${a[1]}|${a[2]}|${a[3]}|${a[4]}|${a[5]}|${a[6]}|${a[7]}|${a[8]}|${a[9]}|${a[10]}" >> $2
    done <<< "$FLS_OUTPUT"
}

# Get input argument
if [ "$1" == "-h" ]; then
    if [ "$2" == "1" ]; then
        create_bodyfile $IMAGE1 $OUTPUT1
            
    elif [ "$2" == "2" ]; then  
        create_bodyfile $IMAGE2 $OUTPUT2
    elif [ "$2" == "all" ]; then
        # Run the script for both images
        create_bodyfile $IMAGE1 $OUTPUT1
        create_bodyfile $IMAGE2 $OUTPUT2
        exit 0
    else
        echo "Invalid argument. Usage: $0 -h [1|2|all]"
        exit 1
    fi
fi
