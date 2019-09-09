

# you must cd to this directory (be in bash)
# and then "source" this file


directory="`pwd`"
echo "$directory"
new_path="PATH=$directory:$PATH"
echo $new_path

export $new_path
