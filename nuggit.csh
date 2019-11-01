#!/bin/csh

set self = `/usr/sbin/lsof +p $$ | grep -oE /.\*nuggit.csh`
set rootdir = `dirname $self`
set abs_rootdir = `cd $rootdir && pwd`

# Add the bin dir to your path
setenv PATH ${PATH}:${abs_rootdir}/bin

# And lib to lib
setenv PERL5LIB ${abs_rootdir}/lib:${PERL5LIB}

# Autocomplete (ngt will provide autocomplete responses for itself, when appropriate env variable is set)
complete -C ngt ngt
