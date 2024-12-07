set shell := ["fish", "-c"]
set dotenv-load

perlimports := "perlimports -i --no-preserve-unused --libs lib --ignore-modules-filename ./.perlimports-ignore -f"
perltidy := "perltidier -dws -io -i=2 -pt=2 -bt=2 -pvt=2"

default:
    @just --list

check:
    for i in $(find . -name \*.pm); perl -c $i; end
    for i in $(find . -name \*.t); perl -c $i; end

imports:
    find . -name \*.pm -print0 | xargs -0 {{perlimports}}
    # find . -name \*.t -print0 | xargs -0 {{perlimports}}

tidy:
    find . -name \*.pm -print0 | xargs -0 {{perltidy}} 2>/dev/null
    # find . -name \*.t -print0 | xargs -0 {{perltidy}} 2>/dev/null
    find -name \*bak -delete
    find -name \*.ERR -delete

critic:
    find . -name \*.pm -print0 | xargs -0 perlcritic
    # find . -name \*.t -print0 | xargs -0 perlcritic --theme=tests

test:
    find . -name \*.t -print0 | xargs -0 yath --max-open-jobs=1000
