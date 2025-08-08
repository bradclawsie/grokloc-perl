# this justfile assumes arch linux

set shell := ["fish", "-c"]
set dotenv-load

cpan_dir := '~/cpan'
env := '\
set -x PERL5LIB local/lib/perl5:lib; \
set -x PATH local/bin $PATH \
\
'
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
    {{env}}; for i in $(find lib -name \*.pm); perl -c $i; end
    {{env}}; for i in $(find t -name \*.t); perl -c $i; end

critic:
    {{env}}; find lib -name \*.pm -print0 | xargs -0 {{perlcritic}}
    {{env}}; find t -name \*.t -print0 | xargs -0 {{perlcritic}} --theme=tests

deps: carton
    set -x PERL5LIB {{cpan_dir}}/lib/perl5; {{cpan_dir}}/bin/carton install

imports:
    {{env}}; find lib -name \*.pm -print0 | xargs -0 {{perlimports}}
    {{env}}; find t -name \*.t -print0 | xargs -0 {{perlimports}}

# just and fish need to be installed beforehand
os-pkgs:
    sudo pacman --noconfirm -S \
            ca-certificates \
            cpanminus \
            git \
            openssl \
            perl-dbd-pg \
            postgresql \
            postgresql-libs

repl:
    {{env}}; perl -de 0

test:
    {{env}}; find t -name \*.t -print0 | xargs -0 {{yath}}

tidy:
    {{env}}; find . -name \*.pm -print0 | xargs -0 {{perltidy}} 2>/dev/null
    {{env}}; find . -name \*.t -print0 | xargs -0 {{perltidy}} 2>/dev/null
    find -name \*bak -delete
    find -name \*tdy -delete
    find -name \*.ERR -delete

yath TEST:
    {{env}}; {{yath}} {{TEST}}

