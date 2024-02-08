source ./repo_setup.env

initvars() {
    repo_root=$(realpath $REPO_ROOT)
    exp_coll=$(realpath $EXPERIMENT_COLLECTION)
    factorizer_dir=$(realpath $FACTORIZER_MODELS)
    dataset_dir=$(realpath $DATASET_DIR)
    configs_dir=$(realpath $CONFIGS_DIR)
    exp_name=""
    lang_pair=""
    cuda_device=0    
}

help() {
    echo
    echo "run-tests : Runs test and gets score for the trained experiments"
    echo
    echo "This script assumes that the test sc"
    echo "Syntax: run-tests [OPTIONS]"
    echo "Options:"
    echo "  -h                          Print this Help."
    echo
    echo "  --repo_root <value>         Path to bytetok-nmt repos src directory"
    echo "                              DEFAULT : ./src"
    echo
    echo "  --exp_coll <value>          Path to the directory where you want to store"
    echo "                                  different variations of all the experiments."
    echo "                              DEFAULT = ./exps"
    echo
    echo "  --factorizer_dir <value>    Path to the directory where you want to store"
    echo "                                  different variations of all the experiments."
    echo "                              DEFAULT = ./factorizer-models"
    echo
    echo "  --configs_dir <value>       Path to the directory where you want to store"
    echo "                                  different variations of all the experiments."
    echo "                              DEFAULT = ./configs"
    echo
    echo "  --exp_name <value>          Name of the experiment. We will create a directory"
    echo "                                  exp_coll/exp_name where we will store"
    echo "                                  the experiment vocab, configs, results."
    echo "                              REQUIRED"
    echo
    echo "  --lang_pair l1-l2           Language pair for downloading the datasets."
    echo "                              This uses mtdata for downloading the datasets, however"
    echo "                                  that requires some confgurations."
    echo "                              Here is a list of pairs with preconfigured options :"
    echo "                                  deu-eng, eng-deu"
    echo
    echo "  --cuda_device <value>       CUDA device to be used for training"
    echo "                              DEFAULT : 0"
    echo "                              VALUES : [ -1, 0, 1, 2, ... ]"
    echo "                                  -1 means no cuda_device is present"
    echo
    echo " Examples : "
    echo "      .\run-tests.sh --exp_name fac266-bpe8k --lang_pair eng-deu \\"
    echo "          --cuda_device 0" 
    echo
}

parseargs() {

    if [ -z $exp_name ]
    then
        echo "Experiment name ( exp_name ) cannot be empty"
        exit 1;
    fi

    exp_dir="${exp_coll}/${lang_pair}/${exp_name}"
    data_dir=$dataset_dir/$lang_pair
}

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

#################   SCRIPT START   #####################

# Initialize Variables
initvars

# Parsing all the command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --repo_root)
            repo_root=$(realpath $2)
            shift 2
            ;;
        --exp_coll)
            exp_coll=$(realpath $2)
            shift 2
            ;;
        --factorizer_dir)
            factorizer_dir=$(realpath $2)
            shift 2
            ;;
        --dataset_dir)
            dataset_dir=$(realpath $2)
            shift 2
            ;;       
        --configs_dir)
            configs_dir=$(realpath $2)
            shift 2
            ;;       
        --exp_name)
            exp_name=$2
            shift 2
            ;;
        --lang_pair)
            lang_pair=$2
            src=$(echo $lang_pair | cut -d '-' -f 1)
            tgt=$(echo $lang_pair | cut -d '-' -f 2)
            shift 2
            ;;
        --cuda_device)
            cuda_device=$2
            shift 2
            ;;
        -h)
            help
            exit 0
            ;;
        *)
            echo "Unknown key: $1 . Exiting script"
            exit 1
            ;;
    esac
done

parseargs

if [[ ! -d $exp_dir ]]
then
    echo "Experiment Directory : $exp_dir does not exist"
    exit 1
fi

if [[ ! -f $exp_dir/_TRAINED ]]
then
    echo "Experiment is not completely trained."
    echo "Run run-exp again"
    exit 1
fi

if [[ ! -d $data_dir ]]
then
    echo "Data dir does not exist"
    echo
    exit 1
fi

tok_dir="${data_dir}/toks"
if [[ ! -d $tok_dir ]]
then
    echo "Tok dir does not exist"
    echo
    exit 1
fi

results_dir="${exp_dir}/results-tok"

if [[ ! -d $results_dir ]]
then
    mkdir -p $results_dir
fi

pushd $repo_root > /dev/null

for f in $tok_dir/test*.$src.tok; do
    fname=$(basename $f)
    fbase=$(echo $fname | cut -d '.' -f 1)
    fstem=$(echo $fbase | cut -d '-' -f 1)

    inp_file="${tok_dir}/${fbase}.${src}.tok"
    ref_file="${data_dir}/${fstem}.${tgt}"
    out_file="${results_dir}/${fbase}.out.tsv"
    detok_file="${results_dir}/${fbase}.detok"

    if [ $cuda_device -ne -1 ]; then
        CUDA_VISIBLE_DEVICES=$2, nohup rtg-decode $exp_dir -sc -msl 512 -b 8000 -if $inp_file -of $out_file
    else
        nohup rtg-decode $exp_dir -sc -msl 512 -b 8000 -if $inp_file -of $out_file
    fi

    lcode=$(sacremoses_code $tgt)
    cat $out_file | cut -f1 | sed 's/<unk>//g' | sacremoses -l $lcode detokenize > $detok_file
    python -m get_score -d $detok_file -r $ref_file
done

popd > /dev/null


