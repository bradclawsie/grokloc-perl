set shell := ["fish", "-c"]
set dotenv-load := true
set dotenv-filename := 'dotenv-unit'
set dotenv-required := true

with_path := 'set -x PATH local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl'
cpan_dir := 'local'
perlcritic := 'perlcritic --profile .perlcritic'
perlimports := 'perlimports -i --no-preserve-unused --libs lib --ignore-modules-filename ./.perlimports-ignore -f '
perltidy := 'perltidier -i=2 -pt=2 -bt=2 -pvt=2 -b -cs '
yath := 'yath --max-open-jobs=1000'

default:
    @just --list

all:
    just --justfile {{justfile()}} check critic imports tidy test

carton:
    mkdir -p {{cpan_dir}}
    cpanm -l {{cpan_dir}} -n Carton

check:
    for i in $(find lib -name \*.pm); perl -c $i; end
    for i in $(find t -name \*.t); perl -c $i; end

critic:
    find lib -name \*.pm -print0 | xargs -0 {{perlcritic}}
    find t -name \*.t -print0 | xargs -0 {{perlcritic}} --theme=tests

deps: carton
    {{with_path}}; carton install

env:
    {{with_path}}; env

imports:
    {{with_path}}; find lib -name \*.pm -print0 | xargs -0 {{perlimports}}
    {{with_path}}; find t -name \*.t -print0 | xargs -0 {{perlimports}}

repl:
    perl -de 0

test:
    {{with_path}}; find t -name \*.t -print0 | xargs -0 {{yath}}

tidy:
    {{with_path}}; find . -name \*.pm -print0 | xargs -0 {{perltidy}} 2>/dev/null
    {{with_path}}; find . -name \*.t -print0 | xargs -0 {{perltidy}} 2>/dev/null
    find -name \*bak -delete
    find -name \*tdy -delete
    find -name \*.ERR -delete

yath TEST:
    {{with_path}}; {{yath}} {{TEST}}

