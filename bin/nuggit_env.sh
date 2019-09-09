

# you must cd to this directory (be in bash)
# and then "source" this file


directory="`pwd`"
echo "$directory"
new_path="PATH=$directory:/software/git-2.18.0/bin/:$PATH"
echo $new_path

export $new_path
