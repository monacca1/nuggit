#!/bin/bash

#sed '/path/d' .gitmodules | sed '/url/d' | sed 's/\[submodule \"//' | sed 's/\"\]//'
#grep submodule .gitmodules | sed 's/\[submodule \"//' | sed 's/\"\]//'

if test -f ".gitmodules" ; then
grep path .gitmodules | sed 's/path//' | sed 's/\=//' | sed 's/ //g'  | sed 's/\t//g'
fi
