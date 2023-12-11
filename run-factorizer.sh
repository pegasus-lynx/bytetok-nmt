
# Experiment directories
repo_root="/home/dipeshkr/repos/bytetok-nmt/src"

# Use this for a group of experiments
base_exp_dir="../temp3/en-de/factorizer-en/"   

# use this for variation within each group of experiments
exp_dir_name="fac770-bpe8k"

# Config files to be used for preparing and running the experiments
base_conf_file="../configs/base/base.conf.yml"
base_prep_file="../configs/base/base.prep.yml"

# If the vocab is shared
shared=0

## Vocab schemes ( char, word, bpe, factorizer )
# Use for shared
pieces="bpe"

src_pieces="factorizer"
tgt_pieces="bpe"

src_factorizer="../factorizer-models/english.dawg"
tgt_factorizer=""

# Target vocab size
vocab_size=8000

# Cuda Device for running the experiment
cuda_device="2"

decode_tests_deen () {
    echo 'Decoding Tests'
    res_dir="${1}/results"
    mkdir $res_dir
    suites=(4 8 9)

    for n in ${suites[@]}
    do
        inp_file="../data/de-en/tests/newstest201${n}_deen.eng"
        out_file="${res_dir}/newstest201${n}.out.tsv"
        ref_file="../data/de-en/tests/newstest201${n}_deen.deu"
        detok_file="${res_dir}/newstest201${n}.detok"

        CUDA_VISIBLE_DEVICES=$2, nohup rtg-decode $1 -sc -msl 512 -b 8000 -if $inp_file -of $out_file
        cat $out_file | cut -f1 | sed 's/<unk>//g' | sacremoses -l en detokenize > $detok_file
        python -m get_score -d $detok_file -r $ref_file
    done
}

# Change directory to bigram-bpe repo root. This will allow to run the script from outside the repo.
cd $repo_root
echo "Current Path"
pwd

exp_dir="${base_exp_dir}/${exp_dir_name}"
mkdir ${exp_dir} -p

# 1. For preparing the experiment data before hand
if [ $shared -eq 1 ]; then
    # python -m make_conf -n prep.yml -w $exp_dir -c $base_prep_file -r $repo_root \
            # --kwargs pieces=$pieces
    echo "shared vocab not supported"
else
    # echo "Tested Earlier"
    python -m make_conf -n prep.yml -w $exp_dir -c $base_prep_file -r $repo_root \
            --kwargs max_src_types=$sz max_tgt_types=$sz \
                    src_pieces=$src_pieces tgt_pieces=$tgt_pieces \
                    src_factorizer=$src_factorizer tgt_factorizer=$tgt_factorizer
fi

# 2. Prepare the data
python -m prepare-exp -w $exp_dir -c "${exp_dir}/prep.yml"

# 3. For baselines only conf.yml is needed.
if [ $shared -eq 1 ]; then
    # python -m make_conf -n conf.yml -w $exp_dir -c $base_conf_file -r $repo_root --kwargs tgt_vocab=$vocab_size max_types=$vocab_size
    echo "shared vocab not supported"
else
    # echo "Tested Earlier"
    python -m make_conf -n conf.yml -w $exp_dir -c $base_conf_file -r $repo_root --kwargs tgt_vocab=$vocab_size max_tgt_types=$vocab_size
fi

# 4. Running experiments
# CUDA_VISIBLE_DEVICES=$cuda_device, rtg-pipe $exp_dir -G
# rtg-pipe $exp_dir -G

# # 5. Decode tests

# if [ $shared -eq 1 ]; then
#     decode_tests_deen $exp_dir $cuda_device
# else
#     decode_tests_hien $exp_dir $cuda_device
# fi

