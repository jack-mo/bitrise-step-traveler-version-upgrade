#!/bin/bash

# Arguments: $1=module
find_latest_tag() {
    pattern="^($MODULE\-|[^a-z]*)v([0-9]+\.[0-9]+\.[0-9]+)\$"
    for tag in $(git tag -l --sort=v:refname | tac); do
        if [[ "$tag" =~ $pattern ]]; then
            echo $tag
            exit 0
        fi
    done

    echo "No Version found"
}

# Arguments: $1=last_tag
find_latest_semver() {
  pattern="^.*v([0-9]+\.[0-9]+\.[0-9]+)\$"
  version=$([[ "$1" =~ $pattern ]] && echo "${BASH_REMATCH[1]}")
  if [ -z "$version" ]; then
    echo 0.0.0
  else
    echo "$version" | tr '.' ' ' | sort -nr -k 1 -k 2 -k 3 | tr ' ' '.' | head -1
  fi
}

# Arguments: $1=current_tag $2=module
determine_bump_from_commits() {
    MAJOR=0
    MINOR=0
    PATCH=0

    log=$(git log $1..HEAD)
    # Check commit bodies for "BREAKING CHANGE"
    if [[ "$log" =~ (BREAKING CHANGE\($2\):) ]]; then
        MAJOR=1
    fi

    # Check commit heading for commit type
    for commit in $(git log --format="%s" $1..HEAD); do
        if [[ "$commit" =~ feat\($2\): ]]; then
            MINOR=1
        elif [[ "$commit" =~ (fix|chore|docs|perf|refactor|test|style)\($2\): ]]; then
            PATCH=1
        fi
    done

    if [ $MAJOR == 1 ]; then
        echo 3
    elif [ $MINOR == 1 ]; then
        echo 2
    elif [ $PATCH == 1 ]; then
        echo 1
    else echo 0
    fi
}

# Arguments: $1=bump_type(0=nothing, 1=patch, 2=minor, 3=major), $2=current_version
bump() {
    if [ "$1" == "3" ]; then
        echo $2 | awk -F. \
            '{printf("%d.%d.%d", $1+1, 0 , 0)}'
    elif [ "$1" == "2" ]; then
        echo $2 | awk -F. \
            '{printf("%d.%d.%d", $1, $2+1, 0)}'
    elif [ "$1" == "1" ]; then
        echo $2 | awk -F. \
            '{printf("%d.%d.%d", $1, $2 , $3+1)}'
    elif [ "$1" == "0" ]; then
        echo $2
    fi
}

MODULE=$1
LAST_TAG=$(find_latest_tag $MODULE)
LAST_VERSION=$(find_latest_semver $LAST_TAG)
BUMP=$(determine_bump_from_commits $LAST_TAG $MODULE)
echo $(bump $BUMP $LAST_VERSION)
exit 0
