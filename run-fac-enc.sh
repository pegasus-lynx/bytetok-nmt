
# Import custom environment variables
source ./repo_setup.env


#### Functions

# Setup Default Values
initvars() {
    repo_root=$(realpath $REPO_ROOT)
    exp_coll_dir=$(realpath $EXPERIMENT_COLLECTION)
    exp_name=""
    base_prep_file=$(realpath ./configs/base/base.prep.yml)
    base_conf_file=$(realpath ./configs/base/base.conf.yml)
    src_pieces=bpe
    tgt_pieces=bpe
    src_factorizer=""
    tgt_factorizer=""
    src_vcb_size=8000
    tgt_vcb_size=8000
    cuda_device=0
}

parseargs() {
    echo
    echo " parseargs : To be implemented"
    echo
}

printvars() {
    echo
    echo "Printing Variables :"
    echo
    echo "repo_root : $repo_root"
    echo "exp_coll_dir : $exp_coll_dir"
    echo "exp_name : $exp_name"
    echo "base_prep_file : $base_prep_file"
    echo "base_conf_file : $base_conf_file"
    echo "src_pieces : $src_pieces"
    echo "tgt_pieces : $tgt_pieces"
    echo "src_factorizer : $src_factorizer"
    echo "tgt_factorizer : $tgt_factorizer"
    echo "src_vcb_size : $src_vcb_size"
    echo "tgt_vcb_size : $tgt_vcb_size"
    echo "cuda_device : $cuda_device"  
    echo  
}

# Script Usage 
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
    echo "  --exp_coll_dir <value>      Path to the directory where you want to store"
    echo "                                  different variations of all the experiments."
    echo "                              REQUIRED"
    echo
    echo "  --exp_name <value>          Name of the experiment. We will create a directory"
    echo "                                  exp_coll_dir/exp_name where we will store"
    echo "                                  the experiment vocab, configs, results."
    echo "                              REQUIRED"
    echo
    echo "  --base_prep_file <value>    Path to the base prep.yml file."
    echo "                                  We load this file, modify the parameters"
    echo "                                  and save it in exp_dir. This is then used to "
    echo "                                  prepare data for your experiment."
    echo "                              DEFAULT : ./configs/base/base.prep.yml"
    echo
    echo "  --base_conf_file <value>    Path to the base conf.yml file."
    echo "                                  Similar to prep.yml, but this is used by"
    echo "                                  rtg to train and decode."
    echo "                                  NOTE : prep section of this file is ignored as"
    echo "                                          we prepare data ourselves"
    echo "                              DEFAULT : ./configs/base/base.conf.yml"
    echo
    echo "  --src_pieces <value>        Scheme used for creating src vocab"
    echo "                              DEFAULT : bpe"
    echo "                              VALUES : [ char, word, bpe, factorizer, factorizer266 ]"
    echo
    echo "  --tgt_pieces <value>        Scheme used for creating tgt vocab"
    echo "                              DEFAULT : bpe"
    echo "                              VALUES : [ char, word, bpe, factorizer, factorizer266 ]"
    echo
    echo "  --src_factorizer <value>    Path of the factorizer model to be used for src vocab"
    echo "                              REQUIRED if src_pieces == factorizer* "
    echo
    echo "  --tgt_factorizer <value>    Path of the factorizer model to be used for tgt vocab"
    echo "                              REQUIRED if tgt_pieces == factorizer* "
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
    echo "      .\run-fac-enc.sh --exp_coll_dir ~/factorizer-exps/de-en --exp_name fac266-bpe8k "
    echo "          --src_pieces factorizer --tgt_pieces bpe --tgt_vcb_size 8000" 
    echo
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
            repo_root="$2"
            shift
            shift
            ;;
        --exp_coll_dir)
            exp_coll_dir="$2"
            shift
            shift
            ;;
        --exp_name)
            exp_name="$2"
            shift
            shift
            ;;
        --base_prep_file)
            base_prep_file="$2"
            shift
            shift
            ;;
        --base_conf_file)
            base_conf_file="$2"
            shift
            shift
            ;;
        --src_pieces)
            src_pieces="$2"
            shift
            shift
            ;;
        --tgt_pieces)
            tgt_pieces="$2"
            shift
            shift
            ;;
        --src_factorizer)
            src_factorizer="$2"
            shift
            shift
            ;;
        --tgt_factorizer)
            tgt_factorizer="$2"
            shift
            shift
            ;;
        --src_vcb_size)
            src_vcb_size="$2"
            shift
            shift
            ;;
        --tgt_vcb_size)
            tgt_vcb_size="$2"
            shift
            shift
            ;;
        --cuda_device)
            cuda_device="$2"
            shift
            shift
            ;;
        -h)
            help
            shift
            exit 0
            ;;
        *)
            echo "Unknown key: $1 . Exiting script"
            shift
            exit 1
            ;;
    esac
done

printvars

# Computed variables
$exp_dir = "${exp_coll_dir}/${exp_name}"
if [[ ! -d $exp_dir ]]
then
    echo "Making Directory : $exp_dir"
    mkdir $exp_dir -p
else
    echo "Already Exists : $exp_dir"
fi


# Prepare prep.yml file for exp
python -m make_conf -n prep.yml -w $exp_dir -c $base_prep_file -r $repo_root \
        --kwargs max_src_types=$src_vcb_size max_tgt_types=$tgt_vcb_size \
                src_pieces=$src_pieces tgt_pieces=$tgt_pieces \
                src_factorizer=$src_factorizer tgt_factorizer=$tgt_factorizer

# Prepare conf.yml file for exp
python -m make_conf -n conf.yml -w $exp_dir -c $base_conf_file -r $repo_root \
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

# Decode the results