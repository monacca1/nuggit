#!/usr/bin/csh

# Add the bin dir to your path
set rootdir = `dirname $0`
set abs_rootdir = `cd $rootdir && pwd`
setenv PATH ${PATH}:${abs_rootdir}/bin
setenv PERL5LIB ${abs_rootdir}/lib:${PERL5LIB}

# Autocomplete (ngt will provide autocomplete responses for itself, when appropriate env variable is set)
complete -C ngt ngt
