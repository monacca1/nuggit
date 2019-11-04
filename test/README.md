Tests will place temporary files at /tmp/testrepo, or location can be overridden with "--root tmpdir"

Pre-requisites for test:  cpan install File::pushd File::Slurp IPC::Run3 Test::Most
Or using cpanm (local repository management):
    curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm
    ./cpanm $LIST_OF_DEPS_FROM_ABOVE
    - ./cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

# Usage:
   From root repo, run "prove" without arguments to execute all tests in standard test harness
   To run manually, simply run the desired script.
   See GetOptions below for available parameters


