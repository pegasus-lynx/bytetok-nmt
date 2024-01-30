
source ./repo_setup.env

initvars() {
    repo_root=$(realpath $REPO_ROOT)
    exp_coll=$(realpath $EXPERIMENT_COLLECTION)
    factorizer_dir=$(realpath $FACTORIZER_MODELS)
    dataset_dir=$(realpath $DATASET_DIR)
    configs_dir=$(realpath $CONFIGS_DIR)
    exp_name=""
    lang_pair=""
    src_pieces=bpe
    tgt_pieces=bpe
    src_factorizer=""
    tgt_factorizer=""
    src_vcb_size=8000
    tgt_vcb_size=8000
    cuda_device=0

    # Used for function return values
    _vcb_size=0
    _factorizer=""
}

help() {
    echo
    echo "run-fac-enc : Run NMT experiment with Factorizer encoders"
    echo
    echo "Syntax: run-fac-enc [OPTIONS]"
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
    echo "  --src_pieces <value>        Scheme used for creating src vocab"
    echo "                              DEFAULT : bpe"
    echo "                              VALUES : [ char, word, bpe, factorizer, factorizer266 ]"
    echo
    echo "  --tgt_pieces <value>        Scheme used for creating tgt vocab"
    echo "                              DEFAULT : bpe"
    echo "                              VALUES : [ char, word, bpe, factorizer, factorizer266 ]"
    echo
    echo "  --src_vcb_size <value>      Size of the src vocab."
    echo "                                  Not used if factorizer* is the scheme"
    echo "                              REQUIRED if src_pieces != factorizer* "
    echo
    echo "  --tgt_vcb_size <value>      Size of the tgt vocab."
    echo "                                  Not used if factorizer* is the scheme"
    echo "                              REQUIRED if tgt_pieces != factorizer* "
    echo
    echo "  --cuda_device <value>       CUDA device to be used for training"
    echo "                              DEFAULT : 0"
    echo "                              VALUES : [ -1, 0, 1, 2, ... ]"
    echo "                                  -1 means no cuda_device is present"
    echo
    echo " Examples : "
    echo "      .\run-exp.sh --exp_name fac266-bpe8k --lang_pair eng-deu \\"
    echo "          --src_pieces factorizer266 --tgt_pieces bpe --tgt_vcb_size 8000" 
    echo
}

printvars() {
    echo
    echo "Experiment Parameters :"
    echo
    echo "exp_dir : $exp_dir"
    echo "lang_pair : $lang_pair"
    echo "base_prep : $base_prep"
    echo "base_conf : $base_conf"
    echo "src_pieces : $src_pieces"
    echo "tgt_pieces : $tgt_pieces"
    echo "src_factorizer : $src_factorizer"
    echo "tgt_factorizer : $tgt_factorizer"
    echo "src_vcb_size : $src_vcb_size"
    echo "tgt_vcb_size : $tgt_vcb_size"
    echo "cuda_device : $cuda_device"  
    echo  
}

get_factorizer() {
    local lang=$1
    case $lang in
        en|eng)
            _factorizer="english.dawg"
            ;;
        ar|ara)
            _factorizer="arabic.dawg"
            ;;
        gd|gla)
            _factorizer="gaelic.dawg"
            ;;
        tr|tur)
            _factorizer="turkish.dawg"
            ;;
        no|nor)
            _factorizer="norwegian.dawg"
            ;;
        cs|ces)
            _factorizer="czech.dawg"
            ;;
        zh|zho)
            _factorizer="chinese.dawg"
            ;;
        *)
            echo "Factorizer not avaiable for ${lang}"
            exit 1
            ;;
    esac
}

get_vcb_size() {
    local piece=$1
    case $piece in 
        factorizer)
            _vcb_size=794
            ;;
        factorizer266)
            _vcb_size=266
            ;;
    esac
}

parseargs() {

    if [ -z $exp_name ]
    then
        echo "Experiment name ( exp_name ) cannot be empty"
        exit 1;
    fi

    exp_dir="${exp_coll}/${lang_pair}/${exp_name}"
    
    conf_dir="${configs_dir}/${lang_pair}"
    
    if [[ ! -d $conf_dir ]]
    then
        echo "Conf Dir : ${conf_dir} not available"
        exit 1;
    fi

    base_conf="${conf_dir}/base.conf.yml"
    base_prep="${conf_dir}/base.prep.yml"

    if [[ ! -f $base_conf ]]
    then
        echo "base.conf.yml is not present"
        exit 1;
    fi

    if [[ ! -f $base_prep ]]
    then
        echo "base.prep.yml is not present"
        exit 1;
    fi

    if [[ ! $(echo ${pieces_options[@]} | grep -F -w $src_pieces) ]]
    then
        echo "${src_pieces} not available"
        echo "Available options for src_pieces :"
        echo "      ${pieces_options[@]}"
        exit 1;
    fi

    if [[ ! $(echo ${pieces_options[@]} | grep -F -w $tgt_pieces) ]]
    then
        echo "${tgt_pieces} not available"
        echo "Available options for tgt_pieces :"
        echo "      ${pieces_options[@]}"
        exit 1;
    fi

    if [[ $src_pieces == factor* ]]
    then
        get_factorizer $src
        get_vcb_size $src_pieces
        src_factorizer="${factorizer_dir}/${_factorizer}"
        src_vcb_size=$_vcb_size
    fi

    if [[ $tgt_pieces == factor* ]]
    then
        get_factorizer $tgt
        get_vcb_size $tgt_pieces
        tgt_factorizer="${factorizer_dir}/${_factorizer}"
        tgt_vcb_size=$_vcb_size
    fi

}

#################   SCRIPT START   #####################
pieces_options=("char" "word" "bpe" "byte" "factorizer" "factorizer266")

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
        --src_pieces)
            src_pieces=$2
            shift 2
            ;;
        --tgt_pieces)
            tgt_pieces=$2
            shift 2
            ;;
        --src_vcb_size)
            src_vcb_size=$2
            shift 2
            ;;
        --tgt_vcb_size)
            tgt_vcb_size=$2
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

# Verify and compute language specific args
parseargs

printvars

# Create exp_dir
if [[ ! -d $exp_dir ]]
then
    echo "Making Directory : $exp_dir"
    mkdir $exp_dir -p
else
    echo "Already Exists : $exp_dir"
fi

pushd $repo_root > /dev/null

# Prepare prep.yml file for exp
python -m prepare_confs -n prep.yml -w $exp_dir -c $base_prep \
        --kwargs src_pieces=$src_pieces tgt_pieces=$tgt_pieces \
            max_src_types=$src_vcb_size max_tgt_types=$tgt_vcb_size \
            src_factorizer=$src_factorizer tgt_factorizer=$tgt_factorizer

# Prepare conf.yml file for exp
python -m prepare_confs -n conf.yml -w $exp_dir -c $base_conf \
        --kwargs src_vocab=$src_vcb_size tgt_vocab=$tgt_vcb_size \
            max_src_types=$src_vcb_size max_tgt_types=$tgt_vcb_size

# Prepare data for exp
python -m prepare_exp -w $exp_dir -c "${exp_dir}/prep.yml"

# Run the exp
if [ $cuda_device -ne -1 ]; then
    CUDA_VISIBLE_DEVICES=$cuda_device, rtg-pipe $exp_dir -G
else
    rtg-pipe $exp_dir
fi

popd > /dev/null
