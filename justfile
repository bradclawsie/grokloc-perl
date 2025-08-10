set shell := ["bash", "-c"]
set dotenv-load := true
set dotenv-filename := 'dotenv-unit'
set dotenv-required := true

with_path := 'PATH=${PWD}/local/bin:${PATH}'
with_perl5lib := 'PERL5LIB=${PWD}/lib:${PWD}/local/lib/perl5'
cpan_dir := 'local'
perlcritic := 'perlcritic --profile ${PWD}/.perlcritic'
perlimports := 'perlimports -i --no-preserve-unused --libs lib --ignore-modules-filename ${PWD}/.perlimports-ignore -f '
perltidy := 'perltidier -i=2 -pt=2 -bt=2 -pvt=2 -b -cs '
yath := 'yath --max-open-jobs=1000'

default:
    @just --list

all:
    just --justfile {{justfile()}} check critic imports tidy test

carton:
    @{{with_path}}; {{with_perl5lib}}; \
    echo $PATH; \
    mkdir -p {{cpan_dir}}; \
    cpanm -l {{cpan_dir}} -n Carton

check:
    @{{with_path}}; {{with_perl5lib}}; \
    for i in `find lib -name \*.pm`; do perl -c $i; done
    @{{with_path}}; {{with_perl5lib}}; \
    for i in `find t -name \*.t`; do perl -c $i; done

critic:
    @{{with_path}}; {{with_perl5lib}}; \
    find lib -name \*.pm -print0 | xargs -0 {{perlcritic}}
    @{{with_path}}; {{with_perl5lib}}; \
    find t -name \*.t -print0 | xargs -0 {{perlcritic}} --theme=tests

deps:
    @{{with_path}}; {{with_perl5lib}}; \
    carton install

env:
    {{with_path}}; {{with_perl5lib}}; \
    env

imports:
    @{{with_path}}; {{with_perl5lib}}; \
    find lib -name \*.pm -print0 | xargs -0 {{perlimports}}
    @{{with_path}}; {{with_perl5lib}}; \
    find t -name \*.t -print0 | xargs -0 {{perlimports}}

repl:
    @{{with_path}}; {{with_perl5lib}}; \
    perl -de 0

test:
    @{{with_path}}; {{with_perl5lib}}; \
    find t -name \*.t -print0 | xargs -0 {{yath}}

tidy:
    @{{with_path}}; {{with_perl5lib}}; \
    find . -name \*.pm -print0 | xargs -0 {{perltidy}} 2>/dev/null
    @{{with_path}}; {{with_perl5lib}}; \
    find . -name \*.t -print0 | xargs -0 {{perltidy}} 2>/dev/null
    @find -name \*bak -delete
    @find -name \*tdy -delete
    @find -name \*.ERR -delete

yath TEST:
    @{{with_path}}; {{with_perl5lib}}; \
    {{yath}} {{TEST}}

