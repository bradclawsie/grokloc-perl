set shell := ["bash", "-c"]
set dotenv-load := true
set dotenv-filename := 'dotenv-unit'
set dotenv-required := true

with_perl5lib := 'PERL5LIB=${PWD}/lib:${PWD}/local/lib/perl5'
perlcritic := 'local/bin/perlcritic --profile ${PWD}/.perlcritic'
perlimports := 'local/bin/perlimports -i --no-preserve-unused --libs lib --ignore-modules-filename ${PWD}/.perlimports-ignore -f '
perltidy := 'local/bin/perltidier -i=2 -pt=2 -bt=2 -pvt=2 -b -cs '
yath := 'local/bin/yath --max-open-jobs=1000'

default:
    @just --list

all:
    just --justfile {{justfile()}} check critic imports tidy test

carton:
    mkdir -p local;
    env -u PERL5LIB cpanm -l local -n -f Carton

check:
    @{{with_perl5lib}}; \
    for i in `find lib -name \*.pm`; do perl -c $i; done
    @{{with_perl5lib}}; \
    for i in `find t -name \*.t`; do perl -c $i; done

critic:
    @{{with_perl5lib}}; \
    find lib -name \*.pm -print0 | xargs -0 {{perlcritic}}
    @{{with_perl5lib}}; \
    find t -name \*.t -print0 | xargs -0 {{perlcritic}} --theme=tests

deps:
    @{{with_perl5lib}}; \
    local/bin/carton install

imports:
    @{{with_perl5lib}}; \
    find lib -name \*.pm -print0 | xargs -0 {{perlimports}}
    @{{with_perl5lib}}; \
    find t -name \*.t -print0 | xargs -0 {{perlimports}}

repl:
    @{{with_perl5lib}}; \
    perl -de 0

test:
    @{{with_perl5lib}}; \
    find t -name \*.t -print0 | xargs -0 {{yath}}

tidy:
    @{{with_perl5lib}}; \
    find . -name \*.pm -print0 | xargs -0 {{perltidy}} 2>/dev/null
    @{{with_perl5lib}}; \
    find . -name \*.t -print0 | xargs -0 {{perltidy}} 2>/dev/null
    @find -name \*bak -delete
    @find -name \*tdy -delete
    @find -name \*.ERR -delete

yath TEST:
    @{{with_perl5lib}}; \
    {{yath}} {{TEST}}

