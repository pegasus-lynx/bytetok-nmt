# Import custom environment variables
source ./repo_setup.env

# Exit on first failure
set -e

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
    echo "  l1-l2              Language pair for downloading the datasets."
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
            shift 2
            ;;
    esac
done

if [[ ! -d $download_dir ]]
then
    mkdir -p $download_dir
fi

case $langpair in
    deu-eng|eng-deu)
        dataset_dir="${download_dir}/deu-eng"

        if [[ -f "${dataset_dir}/mtdata.signature.txt" ]]
        then
            echo "$langpair dataset is already present"
        else
            mtdata get -l deu-eng --out $dataset_dir --merge --train Statmt-europarl-10-deu-eng Statmt-news_commentary-16-deu-eng --dev Statmt-newstest_deen-2017-deu-eng  --test Statmt-newstest_deen-20{18,19,20}-deu-eng
        fi

        for f in $dataset_dir/*.deu; do 
            if [[ -f $f.tok ]]
            then
                echo "Already Tokenized : $f"
                continue
            fi
            echo "$f -> $f.tok"; 
            sacremoses -l de -j 4 tokenize -x -a < $f > $f.tok; 
        done

        for f in $dataset_dir/*.eng; do 
            if [[ -f $f.tok ]]
            then
                echo "Already Tokenized : $f"
                continue
            fi
            echo "$f -> $f.tok"; 
            sacremoses -l en -j 4 tokenize -x -a < $f > $f.tok; 
        done

        if [[ ! -d $dataset_dir/toks ]]
        then
            mkdir $dataset_dir/toks
        fi
        mv $dataset_dir/*.tok $dataset_dir/toks
        ;;
    *)
        echo "$langpair not supported."
        echo
        exit 1
        ;;
esac