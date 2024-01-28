# Import custom environment variables
source ./repo_setup.env

# Exit on first failure
set -e

help() {
    echo
    echo "generate-base-configs : Generates base config files for "
    echo
    echo "Syntax: generate-base-configs [OPTIONS] l1-l2"
    echo
    echo "Options:"
    echo "  -h                      Print this Help."
    echo    
    echo "  -d <value>              Path to dataset directory"
    echo "                          DEFAULT - ./datasets"
    echo "                          The default value is loaded from repo_setup.env file"
    echo
    echo "  -c <value>              Path to configs directory"
    echo "                          DEFAULT - ./configs"
    echo "                          The default value is loaded from repo_setup.env file"
    echo
    echo "  --base_conf <value>     Path to the base conf.yml file"
    echo "                          We will take this file and modify the data paths"
    echo "                              to generate configs that will be used for"
    echo "                              running NMT experiments for that language pair."
    echo "                          DEFAULT - ./configs/base/base.conf.yml"
    echo
    echo "  --base_prep <value>     Path to the base prep.yml file"
    echo "                          We will take this file and modify the data paths"
    echo "                              to generate configs that will be used for"
    echo "                              preparing data for NMT experiments."
    echo "                          DEFAULT - ./configs/base/base.prep.yml"
    echo
    echo "  --lang_pair l1-l2       Language pair for downloading the datasets."
    echo "                          This uses mtdata for downloading the datasets, however"
    echo "                              that requires some confgurations."
    echo "                          Here is a list of pairs with preconfigured options :"
    echo "                              deu-eng, eng-deu"
    echo "                          If there is any other name or wrong argument passed, it is ignored"
    echo
    echo "Examples:"
    echo " ./generate-base-configs.sh --lang_pair deu-eng"
    echo " ./generate-base-configs.sh -p ./data --lang_pair deu-eng"
    echo
}

repo_root=$(realpath $REPO_ROOT)
dataset_dir=$(realpath $DATASET_DIR)
configs_dir=$(realpath $CONFIGS_DIR)

base_conf=$(realpath $repo_root/../configs/base/base.conf.yml)
base_prep=$(realpath $repo_root/../configs/base/base.prep.yml)
lang_pair=""

while [[ $# -gt 0 ]]
do
    key=$1
    case $key in
        -h)
            help
            exit 0
            ;;
        -d)
            dataset_dir=$(realpath $2)
            shift 2
            ;;
        -c)
            configs_dir=$2
            shift 2
            ;;
        --base_conf)
            base_conf=$(realpath $2)
            shift 2
            ;;
        --base_prep)
            base_prep=$(realpath $2)
            shift 2
            ;;
        --lang_pair)
            lang_pair=$2
            src=$(echo $lang_pair | cut -d '-' -f 1)
            tgt=$(echo $lang_pair | cut -d '-' -f 2)
            shift 2
            ;;
        *)
            echo "$1 is not supported"
            exit 1
            ;;
    esac
done

data_dir=""

if ls $dataset_dir | grep -q -F -w "${src}-${tgt}"
then
    data_dir="${dataset_dir}/${src}-${tgt}"
elif ls $dataset_dir | grep -q -F -w "${tgt}-${src}"
then
    data_dir="${dataset_dir}/${tgt}-${src}"
else
    echo "Data dir is not present. Download the dataset first."
    exit 1
fi

conf_dir="${configs_dir}/${lang_pair}"
conf_dir=$(realpath $conf_dir)
mkdir -p $conf_dir

echo "Data Dir : $data_dir"
echo "Config Dir : $conf_dir"

pushd $repo_root > /dev/null

echo "Preparing prep.yml ..."
python -m generate_base_conf -d $data_dir \
        -c $conf_dir -n base.prep.yml \
        -b $base_prep -s $src -t $tgt

echo "Preparing conf.yml ..."
python -m generate_base_conf -d $data_dir \
        -c $conf_dir -n base.conf.yml \
        -b $base_conf -s $src -t $tgt

popd > /dev/null