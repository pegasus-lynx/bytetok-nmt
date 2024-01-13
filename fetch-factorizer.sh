
# Import custom environment variables
source ./repo_setup.env

help() {
    echo
    echo "fetch-factorizer : Downloads the factorizer models"
    echo
    echo "Syntax: fetch-factorizer [OPTIONS] lang1 lang2 lang3 ..."
    echo
    echo "Options:"
    echo "  -h                 Print this Help."
    echo    
    echo "  -p <value>         Path to directory where factorizer models will be installed"
    echo "                     DEFAULT - ./factorizer-models"
    echo "                     The default value is loaded from repo_setup.env file"
    echo
    echo "  lang*              List of languages for which the pretrained models are"
    echo "                      to be downloaded. Here is the list of all the pretrained"
    echo "                      models available :"
    echo "                          arabic, chinese, czech, english,"
    echo "                          norwegian, gaelic, turkish"
    echo "                     If there is any other name or wrong argument passed, it is ignored"
    echo
    echo "Examples:"
    echo " ./fetch-factorizer.sh english turkish chinese"
    echo " ./fetch-factorizer.sh -p ./factorizers english turkish chinese"
    echo
}


pretrained=("arabic" "chinese" "czech" "english" "norwegian" "gaelic" "turkish")
base_uri="https://github.com/ltgoslo/factorizer/releases/download/v1.0.0/"
languages=()

download_dir=$(realpath $FACTORIZER_MODELS)

if [ "$1" == "-h" ]
then
    help
    exit 0;
fi

if [ "$1" == "-p" ]
then
    download_dir=$(realpath $2)
    shift
    shift
fi

if [[ ! -d $download_dir ]]
then
    mkdir -p $download_dir
fi

while [[ $# -gt 0 ]]
do
    lang="$1"

    if [[ ! $(echo ${pretrained[@]} | grep -F -w $lang) ]]
    then
        echo "${lang} not available" 
        echo "Available Pretrained Factorizers : "
        echo "      ${pretrained[@]}"
        echo
        shift
        continue
    fi

    uri="${base_uri}/${lang}.dawg"
    file_path="${download_dir}/${lang}.dawg"

    if [[ -f $file_path ]]
    then
        echo "${lang}.dawg is already present in the directory ${download_dir}"
        shift
        continue 
    fi

    wget -P $download_dir $uri
    shift
done