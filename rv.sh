#!/bin/sh
# by Szymon Miekina Dec 2025
# requires riscv-none-elf-* toolchain

perr () {
    echo "$1" >&2
}

cc () {
    # invoke gcc
    local flags
    for attr in $3
    do
        case $attr in
        wall) flags="$flags -Wall";;
        link) flags="$flags -T link.ld";;
        optis) flags="$flags -Os";;
        opti0) flags="$flags -O0";;
        opti2) flags="$flags -O2";;
        opti3) flags="$flags -O3";;
        debug) flags="$flags -g";;
        reloc) flags="$flags -c";;
        esac
    done
    perr "cc $flags $1"
    riscv-none-elf-gcc \
        -march=rv32i \
        -mabi=ilp32 \
        -nostdlib \
        -ffreestanding \
        $flags -o $2 $1
}

as () {
    # invoke gas
    local flags
    for attr in $3
    do
        case $attr in
        reloc) flags="$flags -c";;
        esac
    done
    perr "as $flags $1"
    riscv-none-elf-as \
        -march=rv32i \
        -mabi=ilp32 \
        $flags -o $2 $1
}

size () {
    riscv-none-elf-size -A $1
}

skip_mtime () {
    # test if source is newer than target
    # return 0 when $2 is newer
    [ $noskip == 1 ] && return 1
    mtime1=$(date -r $1 +%s 2> /dev/null)
    mtime2=$(date -r $2 +%s 2> /dev/null)
    [ "$mtime1" == "" ] && return 1
    [ "$mtime2" == "" ] && return 1
    [ "$mtime1" -lt "$mtime2" ] && return 0
    return 1
}

to_elf () {
    perr "$2 to .elf format"
    [ "$2" == "@1" ] && { riscv-none-elf-objdump -S $1; return 0; }
    cp $1 $2
    return 0
}

to_riv () {
    # to .riv format
    perr "$2 to .riv format"
    [ "$2" == "@1" ] && { riscv-none-elf-objdump -d $1; return 0; }
    riscv-none-elf-objdump -d $1 > $2
    return 0
}

to_mem () {
    # to .mem format
    perr "$2 to .mem format"
    [ "$2" == "@1" ] && { riscv-none-elf-objdump -d $1 \
                          | grep -Eo ':\s+[0-9a-f]{8}' \
                          | cut -f 2; return 0; }
    riscv-none-elf-objdump -d $1 \
    | grep -Eo ':\s+[0-9a-f]{8}' \
    | cut -f 2 > $2
    return 0
}

help=0
noboot=0
noskip=0
outx="elf"
optim="opti0"
debug="debug"
reloc=""

show_usage () {
    perr "usage: rv srcfiles outfile [-h] [-a] [-e] [-r] [-m] [-n] [-c] [-s]"
    perr "                           [-2] [-3]"
    perr "args:"
    perr "  srcfiles  source files comma-separated list, entry file should be"
    perr "            passed first, after which all dependecies should be"
    perr "            specified: main.c,util.c,assembly.s"
    perr "            (order of files is relevent - dependencies are built"
    perr "             in the same order as passed, followed by entry file)"
    perr "  outfile   output file; special meanings include:"
    perr "              '@1' - output dissasembly to stdout directly, messages"
    perr "                     stay in stderr"
    perr "  -h        show this help message"
    perr "  -b        don't link with boot file (boot.s)"
    perr "  -a        recompile all sources, don't test if output newer than"
    perr "            source file by modification time (mtime)"
    perr "  -e        don't convert output file (output remains formatted"
    perr "            as ELF executable) (default)"
    perr "  -r        convert output to rivctl's upload file format"
    perr "  -m        convert output to Verilog's memdump file format"
    perr "  -n        don't include debug symbols (gcc only)"
    perr "  -c        create relocatable object file"
    perr "  -s        optimize for size (gcc only)"
    perr "  -2        optimize level 2 (gcc only)"
    perr "  -3        optimize level 3 (gcc only)"
    exit 1
}

bad_arg () {
    perr "unknown arg $1" >&2
    show_usage
}

set_pos_arg () {
    [ "$srcl" == "" ] && { srcl="$1"; return 0; }
    [ "$outf" == "" ] && { outf="$1"; return 0; }
    perr "too much pos args" >&2
    show_usage
}

parse_arg () {
    case $1 in
    -h) help=1;;
    -b) noboot=1;;
    -a) noskip=1;;
    -e) outx="elf";;
    -r) outx="riv";;
    -m) outx="mem";;
    -n) debug="";;
    -c) reloc="reloc";;
    -s) optim="optis";;
    -2) optim="opti2";;
    -3) optim="opti3";;
    -*) bad_arg $1;;
    *) set_pos_arg $1;;
    esac
}

for arg
do parse_arg $arg
done

[ $help == 1 ] && show_usage

[ "$srcl" == "" ] && { perr "no srcfiles given"; show_usage; }
[ "$outf" == "" ] && { perr "no outfile given"; show_usage; }

get_src_ext () {
    case $1 in
    *.s) echo "as";;
    *.c) echo "cc";;
    esac
}

objs=""
build_obj () {
    local srcx
    local srcp
    local objf
    srcx=$(get_src_ext $1)
    srcp=$(echo "$1" | grep -o "^.*\.")
    objf="$srcp""o"
    objs="$objs $objf"
    skip_mtime $1 $objf && { perr "up-to-date $objf"; return 0; }
    [ "$srcx" == "" ] && { perr "unknown srcfile ext $1"; show_usage; }
    [ "$srcx" == "as" ] && as $1 $objf "reloc" && return 0
    [ "$srcx" == "cc" ] && cc $1 $objf "$optim $debug reloc" && return 0
    perr "could not build dep $srcf"
    exit 2
}

build_elf () {
    local srcx
    local srcp
    srcx=$(get_src_ext $1)
    srcp=$(echo "$1" | grep -o "^.*\.")
    tmpf="$srcp""tmp.elf"
    skip_mtime $1 $tmpf && { perr "up-to-date _start"; return 0; }
    [ "$srcx" == "" ] && { perr "unknown srcfile ext $1"; show_usage; }
    [ "$srcx" == "as" ] && as "$1 $objs" $tmpf "" && { \
        size "$tmpf"; \
        return 0; }
    [ "$srcx" == "cc" ] && cc "$1 $objs" $tmpf "$optim $debug link" && { \
        size "$tmpf"; \
        return 0; }
    perr "could not build entry $srcf"
    exit 3
}

bootf=""
find_boot () {
    bootf=$(find . -depth -name boot.s -print -quit)
    [ "$bootf" == "" ] && { perr "boot.s not found"; return 1; }
    perr "using $bootf as boot file"
    return 0
}

[ "$reloc" != "" ] && { perr "flag -c (reloc) is currently a noop"; }
[ $noboot == 0 ] && { find_boot; srcl="$srcl,$bootf"; }

# build dependecies
for srcd in $(echo "$srcl" | cut -f 2- -d "," | sed "s/,/ /g")
do build_obj $srcd
done

srce=$(echo "$srcl" | cut -f 1 -d ",")
build_elf $srce

case $outx in
elf) to_elf $tmpf $outf;;
riv) to_riv $tmpf $outf;;
mem) to_mem $tmpf $outf;;
esac

rm $tmpf 2> /dev/null
perr "done"
