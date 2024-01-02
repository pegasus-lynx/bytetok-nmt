
# Experiment directories
repo_root="/home/dipeshkr/repos/bytetok-nmt/src"

# Use this for a group of experiments
base_exp_dir="../temp22/en-de/factorizer-en/"   

# use this for variation within each group of experiments
exp_dir_name="fac266-bpe8k"

# Config files to be used for preparing and running the experiments
base_conf_file="../configs/base/base.conf.yml"
base_prep_file="../configs/base/base.prep.yml"

## Vocab schemes ( char, word, bpe, factorizer )
src_pieces="factorizer266"
tgt_pieces="bpe"

src_factorizer="../factorizer-models/english.dawg"
tgt_factorizer=""

# Target vocab size
src_vcb_size=266
tgt_vcb_size=8000

# Cuda Device for running the experiment
cuda_device="2"

# Change directory to bigram-bpe repo root. This will allow to run the script from outside the repo.
echo "Changing directory to repo_root"
cd $repo_root

exp_dir="${base_exp_dir}/${exp_dir_name}"
mkdir ${exp_dir} -p

# 1. Make prep.yml file
python -m make_conf -n prep.yml -w $exp_dir -c $base_prep_file -r $repo_root \
        --kwargs max_src_types=$src_vcb_size max_tgt_types=$tgt_vcb_size \
                src_pieces=$src_pieces tgt_pieces=$tgt_pieces \
                src_factorizer=$src_factorizer tgt_factorizer=$tgt_factorizer

# 2. Prepare the data
# python -m prepare-exp -w $exp_dir -c "${exp_dir}/prep.yml"

# 3. For baselines only conf.yml is needed.
python -m make_conf -n conf.yml -w $exp_dir -c $base_conf_file -r $repo_root \
                        --kwargs src_vocab=$src_vcb_size tgt_vocab=$tgt_vcb_size \
                                max_src_types=$src_vcb_size max_tgt_types=$tgt_vcb_size

# 4. Running experiments
CUDA_VISIBLE_DEVICES=$cuda_device, rtg-pipe $exp_dir -G
# rtg-pipe $exp_dir



decode_tests_deen () {
    echo 'Decoding Tests'
    res_dir="${1}/results"
    mkdir $res_dir
    suites=(1 2 3)

    for n in ${suites[@]}
    do
        inp_file="../datasets/deu-eng/test${n}.eng"
        out_file="${res_dir}/test${n}.out.tsv"
        ref_file="../datasets/deu-eng/test${n}.deu"
        detok_file="${res_dir}/test${n}.detok"

        CUDA_VISIBLE_DEVICES=$2, nohup rtg-decode $1 -sc -msl 512 -b 8000 -if $inp_file -of $out_file
        cat $out_file | cut -f1 | sed 's/<unk>//g' | sacremoses -l en detokenize > $detok_file
        python -m get_score -d $detok_file -r $ref_file
    done
}

# 5. Decode tests
decode_tests_deen $exp_dir $cuda_device
