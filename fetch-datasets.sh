# Import custom environment variables
source ./repo_setup.env

# Exit on first failure
set -e

sacremoses_code() {
    local lang=$1
    local code=""
    case $lang in
        eng)
            code="en" ;;
        deu)
            code="de" ;;
        ara)
            code="ar" ;;
        fra)
            code="fr" ;;
        zho)
            code="zh" ;;
    esac
    echo $code
}


help() {
    echo
    echo "fetch-datasets : Downloads the factorizer models"
    echo
    echo "Syntax: fetch-datasets [OPTIONS] l1-l2"
    echo
    echo "Options:"
    echo "  -h                 Print this Help."
    echo    
    echo "  -p <value>         Path to directory where factorizer models will be installed"
    echo "                     DEFAULT - ./datasets"
    echo "                     The default value is loaded from repo_setup.env file"
    echo
    echo "  --lang_pair l1-l2 Language pair for downloading the datasets."
    echo "                     This uses mtdata for downloading the datasets, however"
    echo "                          that requires some confgurations."
    echo "                     Here is a list of pairs with preconfigured options :"
    echo "                          deu-eng, eng-deu"
    echo "                     If there is any other name or wrong argument passed, it is ignored"
    echo
    echo "Examples:"
    echo " ./fetch-datasets.sh deu-eng"
    echo " ./fetch-datasets.sh -p ./data deu-eng"
    echo
}

download_dir=$(realpath $DATASET_DIR)
lang_pair=""

while [[ $# -gt 0 ]]
do
    key=$1
    case $key in
        -h)
            help
            exit 0
            ;;
        -p)
            download_dir=$(realpath $2)
            shift 2
            ;;
        --lang_pair)
            lang_pair=$2
            if [ -z $lang_pair ]
            then
                echo "lang_pair cannot be empty"
                exit 1;
            fi
            src=$(echo $lang_pair | cut -d '-' -f 1)
            tgt=$(echo $lang_pair | cut -d '-' -f 2)
            rev_lang_pair="${tgt}-${src}"
            shift 2
            ;;
        *)
            echo "Unexpected parameter $1"
            exit 1;
            ;;
    esac
done

if [[ ! -d $download_dir ]]
then
    echo "mkdir : $download_dir"
    mkdir -p $download_dir
fi

case $lang_pair in
    deu-eng|eng-deu)

        dataset_dir="${download_dir}/deu-eng"
        toks_dir="${dataset_dir}/toks"

        if [[ -f "${dataset_dir}/mtdata.signature.txt" ]]
        then
            echo "$lang_pair dataset is already present"
        else
            mtdata get -l deu-eng --out $dataset_dir --merge --train Statmt-europarl-10-deu-eng Statmt-news_commentary-16-deu-eng --dev Statmt-newstest_deen-2017-deu-eng  --test Statmt-newstest_deen-20{18,19,20}-deu-eng
            ln -s $dataset_dir $download_dir/$rev_lang_pair 
        fi
        ;;
    *)
        echo "$lang_pair not supported."
        echo
        exit 1
        ;;
esac

langs=($src $tgt)

for l in ${langs[@]}; do
    for f in $dataset_dir/*.$l; do
        if [[ -f $f.tok ]]
        then
            echo "Already Tokenized : $f"
            continue
        fi
        echo "$f -> $f.tok"; 
        lcode=$(sacremoses_code $l)
        sacremoses -l $lcode -j 4 tokenize -x -a < $f > $f.tok; 
    done
done

mkdir -p $toks_dir
mv $dataset_dir/*.tok $toks_dir
