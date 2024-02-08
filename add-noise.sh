# Import custom environment variables
source ./repo_setup.env

# Exit on first failure
set -e

help() {
    echo
    echo "add-noise : Adds noise to the file"
    echo
    echo "Syntax: add-noise [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h                  Print this Help."
    echo    
    echo "  --in <value>        Path to the file to which the noise is to be added"
    echo
    echo "  --out <value>       Name of output file"
    echo
    echo "  --lang <value>      Language of the data in file"
    echo
    echo "  --pnoise <value>    Percentage for adding the noise"
    echo "                      DEFAULT = 0.5"
    echo
    echo "  --seed <value>      Seed value for deterministic generation of the noise"
    echo "                      DEFAULT = 123"
    echo
    echo "Examples:"
    echo " ./add-noise.sh --in test1.ara"
    echo " ./add-noise.sh --in test1.ara --out test1-noisy.ara"
    echo " ./add-noise.sh --in test1.ara --out test1-noisy.ara --pnoise 1.2 --seed 232"
    echo
}

repo_root=$(realpath $REPO_ROOT)
pnoise=0.5
seed=123
in_file=""
outfile_name=""
lang=""

while [[ $# -gt 0 ]]
do
    key=$1
    case $key in
        -h)
            help
            exit 0
            ;;
        --in)
            in_file=$(realpath $2)
            shift 2
            ;;
        --out)
            outfile_name=$2
            shift 2
            ;;
        --pnoise)
            pnoise=$2
            shift 2
            ;;
        --seed)
            seed=$2
            shift 2
            ;;
        --lang)
            lang=$2
            shift 2
            ;;
        *)
            echo "Unexpected parameter $1"
            exit 1;
            ;;

    esac
done

pushd $repo_root > /dev/null

if [[ -z $outfile_name ]]; then
    echo "Empty outfile"
    python -m add_noise -f $in_file \
        -l $lang -p $pnoise -s $seed
else
    echo "Non empty outfile"
    python -m add_noise -f $in_file -o $outfile_name \
        -l $lang -p $pnoise -s $seed
fi

popd > /dev/null