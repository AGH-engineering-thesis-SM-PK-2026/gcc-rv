#!/bin/sh
# by Szymon Miekina Dec 2025
# requires riscv-none-elf-* toolchain

cc () {
    # invoke gcc
    local flags
    for attr in $3
    do
        case $attr in
        wall) flags="$flags -Wall";;
        optis) flags="$flags -Os";;
        opti0) flags="$flags -O0";;
        opti2) flags="$flags -O2";;
        opti3) flags="$flags -O3";;
        debug) flags="$flags -g";;
        reloc) flags="$flags -c";;
        esac
    done
    echo "cc $flags $1"
    riscv-none-elf-gcc \
        -march=rv32i \
        -mabi=ilp32 \
        -nostdlib \
        -ffreestanding \
        -T link.ld \
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
    echo "as $flags $1"
    riscv-none-elf-as \
        -march=rv32i \
        -mabi=ilp32 \
        $flags -o $2 $1
}

test_mtime () {
    # test if source is newer than target
    # return 0 when newer
    mtime1=$(date -r $1 +%s 2> /dev/null)
    mtime2=$(date -r $2 +%s 2> /dev/null)
    [ "$mtime1" == "" ] && return 0
    [ "$mtime2" == "" ] && return 0
    [ "$mtime1" -lt "$mtime2" ] && return 1
    return 0
}

to_elf () {
    echo "$2 to .elf format"
    cp $1 $2
}

to_lst () {
    # to .lst format
    echo "$2 to .lst format"
    riscv-none-elf-objdump -d $1 > $2
}

to_mem () {
    # to .mem format
    echo "$2 to .mem format"
    riscv-none-elf-objdump -d $1 | grep -Eo ':\s+[0-9a-f]{8}' | cut -f 2 > $2
}

help=0
outx="lst"
optim="opti0"
debug="debug"
reloc=""

show_usage () {
    echo "usage: rv srcfile outfile [-h] [-e] [-m] [-n] [-c] [-s] [-2] [-3]"
    echo "args:"
    echo "  srcfile  source file, with .c or .s extension"
    echo "  outfile  output file as a disassembly listing"
    echo "  -h       show this help message"
    echo "  -e       output file in ELF format"
    echo "  -m       output memdump file"
    echo "  -n       don't include debug symbols (only gcc)"
    echo "  -c       create relocatable object"
    echo "  -s       optimize size (only gcc)"
    echo "  -2       optimize level 2 (only gcc)"
    echo "  -3       optimize level 3 (only gcc)"
    exit 1
}

bad_arg () {
    echo "unknown arg $1"
    show_usage
}

set_pos_arg () {
    [ "$srcf" == "" ] && { srcf="$1"; return 0; }
    [ "$outf" == "" ] && { outf="$1"; return 0; }
    echo "too much pos args"
    show_usage
}

parse_arg () {
    case $1 in
    -h) help=1;;
    -e) outx="elf";;
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

[ "$srcf" == "" ] && { echo "no srcfile given"; show_usage; }
[ "$outf" == "" ] && { echo "no outfile given"; show_usage; }

srcx=""
case $srcf in
*.s) srcx="as";;
*.c) srcx="cc";;
esac
echo "$srcf -> $outf"

[ "$reloc" == "reloc" ] && { outx="elf"; echo "reloc, ovrd to ELF format"; }
attrs="$optim $debug $reloc"
tmpf=".tmp.out"

if [ "$srcx" == "as" ]
then
    echo "using as"
    as $srcf $tmpf "$attrs"
fi

if [ "$srcx" == "cc" ]
then
    echo "using as+cc"
    boots="boot.s"
    booto="boot.o"
    test_mtime $boots $booto && as $boots $booto "reloc"
    cc "$booto $srcf" $tmpf "$attrs"
fi

[ "$srcx" == "" ] && { echo "unknown srcfile ext"; show_usage; }

case $outx in
elf) to_elf $tmpf $outf;;
lst) to_lst $tmpf $outf;;
mem) to_mem $tmpf $outf;;
esac

rm $tmpf 2> /dev/null
echo "done"
