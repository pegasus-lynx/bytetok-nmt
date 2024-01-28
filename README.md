# bytetok-nmt

This repo aims at running NMT experiments using [Factorizer]() models.
We use custom version of [NLCodec] and [RTG] library to run the NMT experiments. 

### Setting Up Environment

First of all, setup a virtual environment using `venv` or `conda` whichever you prefer. I use `venv` for making and managing virtual environments. So, here are the steps you can use to create the environment using `venv` :

```
# Creating a python enviroment
python -m venv <path-to-env>

# Activating the environment
source <path-to-env>\bin\activate
```

Now, that once you have the new environment in place, here is how we can install the python packages required for running the experiments.

#### 1. Using requirements.txt
```
pip install -r requirements.txt
```
**NOTE :** Before running the command above take a look at the nvidia packages that will be installed. It may be possible, that these may be the latest versions and not compatible with the GPUs. However, this should not present any major issues. 


#### 2. Manual Setup
To be completed


### Quickstart

#### Running factorizer266 encoding experiment for eng-deu

Run `chmod +x *.sh` to enable execution for shell scripts before executing the following commands. For customizations, look at the next section.

1. Download the factorizer for english
    ```
    ./fetch-factorizer.sh english
    ```
2. Download the  deu-eng/eng-deu dataset ( both will have the same download folder )
    ```
    ./fetch-datasets.sh deu-eng
    ```
3. Generate base configs for eng-deu language pair
    ```
    ./generate-base-configs.sh --lang_pair deu-eng
    ```
4. Run the experiment using the `run-exp` script
    ```
    ./run-exp.sh --cuda_device 0 --tgt_vcb_size 4000 --src_pieces factorizer266 --lang_pair eng-deu --exp_name fac266-bpe4k
    ```
5. Decode results of training
   ```
    TBD
   ```

#### Repo layout and results for above

Once, you follow the above this is the structure of files that you are going to end with
```
DATASET_DIR
    |
    |- lp1
    |- lp2
    |- ...

FACTORIZER_MODELS
    |
    |- english.dawg
    |- ...

CONFIGS_DIR
    |
    |- lp1
    |   |- base.conf.yml
    |   |- base.prep.yml
    |
    |- lp2
    |   |- ...
    |
    |- ...

EXP_COLL
    |
    |- lp1
    |   |- ...   
    |
    |- lp2
        |- exp_name_1
        |       |- data
        |       |   | - nlcodec.src.model
        |       |   | - nlcodec.tgt.model
        |       |   | - train.db
        |       |   | - ...
        |       |
        |       |- models
        |       |- tensorboard
        |       |- conf.yml, prep.yml
        |       |- _PREPARED, _TRAINED
        |       |- rtg.log
        |
        |- exp_nmae_2
        ...

```

So, basically we are using lp ( language pair ) as part of the path for experiments, base configs, datasets so that the scripts can automatically pull most of that stuff and we need to modify the necessary parameters only.

Also, since we are using full paths in the config files, the requirement for placing things in a certain place is not strict. Making it easier to run the experiments.

### Setting up configs, factorizer models and datasets for running experiments

#### 1. Setting up repo configs

In the root of this repo, we have a ***repo_setup.env*** config file, which consists of the following variables. These variables are used throughout the rest of the scripts by sourcing / loading this config file at the start of the script. Modify any of the parameters as per your requirements ( except REPO_ROOT which shall point to this repos `src` directory ).

> The easiest way is to leave the parameters as it is. 

```bash
# Directory where all the experiment runs will be stored
EXPERIMENT_COLLECTION=./exps

# Directory where all the factorizer models will be downloaded
FACTORIZER_MODELS=./factorizer-models

# Directory where the datasets from mtdata or other sources
# will be downloaded
DATASET_DIR=./datasets

# Directory where the base configs for different language pairs 
# will be stored
CONFIGS_DIR=./configs

# Path to the bytetok-nmt/src directory
REPO_ROOT=./src
```

> **NOTE :** If you are moving scripts to a different location copy the .env file alongwith it or modify the path to source the file correctly.

#### 2. Fetching Factorizer Models

For this you can use the `fetch-factorizer` script, which takes in the list of languages and optionally a path to download the factorizer models.
If you don't provide the path for downloading the models, the script automtically loads a path from the `repo_setup.env`.

> Preferably setup the path in repo_setup.env because it will be used in multiple scripts.

```
./fetch-factorizer.sh -h

fetch-factorizer : Downloads the factorizer models

Syntax: fetch-factorizer [OPTIONS] lang1 lang2 lang3 ...

Options:
  -h                 Print this Help.

  -p <value>         Path to directory where factorizer models will be installed
                     DEFAULT - ./factorizer-models
                     The default value is loaded from repo_setup.env file

  lang*              List of languages for which the pretrained models are
                      to be downloaded. Here is the list of all the pretrained
                      models available :
                          arabic, chinese, czech, english,
                          norwegian, gaelic, turkish
                     If there is any other name or wrong argument passed, it is ignored

Examples:
 ./fetch-factorizer.sh english turkish chinese
 ./fetch-factorizer.sh -p ./factorizers english turkish chinese

```

#### 3.a Fetching Datasets 

We use `mtdata` to download the datasets and then tokenize them using `sacremoses`. Also, there are various configurations that we can do with any of these processes.

In the script `fetch-datasets`, I have tried to combine these processes together with the configuration that we are using for these experiments.. The script only supports downloading `deu-eng` dataset for now. We will add more as we go on.

> For customizing the download location, preferably setup the path in repo_setup.env because it will be used in multiple scripts.

```
./fetch-datasets.sh -h

fetch-datasets : Downloads the factorizer models

Syntax: fetch-datasets [OPTIONS] l1-l2

Options:
  -h                 Print this Help.

  -p <value>         Path to directory where factorizer models will be installed
                     DEFAULT - ./factorizer-models
                     The default value is loaded from repo_setup.env file

  l1-l2              Language pair for downloading the datasets.
                     This uses mtdata for downloading the datasets, however
                          that requires some confgurations.
                     Here is a list of pairs with preconfigured options :
                          deu-eng, eng-deu
                     If there is any other name or wrong argument passed, it is ignored

Examples:
 ./fetch-datasets.sh deu-eng
 ./fetch-datasets.sh -p ./data deu-eng
```

#### 3.b Generating language pair base configs

Once, we have the datasets downloaded, we will generate configs `base.conf.yml` and `base.prep.yml` which have the paths to the downloaded dataset. These configs will be used for generating config files for the each experiment run.

This script shall be run hand in hand once we download the dataset for any language pair.

```
./generate-base-configs.sh -h

generate-base-configs : Generates base config files for

Syntax: generate-base-configs [OPTIONS] l1-l2

Options:
  -h                      Print this Help.

  -d <value>              Path to dataset directory
                          DEFAULT - ./datasets
                          The default value is loaded from repo_setup.env file

  -c <value>              Path to configs directory
                          DEFAULT - ./configs
                          The default value is loaded from repo_setup.env file

  --base_conf <value>     Path to the base conf.yml file
                          We will take this file and modify the data paths
                              to generate configs that will be used for
                              running NMT experiments for that language pair.
                          DEFAULT - ./configs/base/base.conf.yml

  --base_prep <value>     Path to the base prep.yml file
                          We will take this file and modify the data paths
                              to generate configs that will be used for
                              preparing data for NMT experiments.
                          DEFAULT - ./configs/base/base.prep.yml

  --lang_pair l1-l2       Language pair for downloading the datasets.
                          This uses mtdata for downloading the datasets, however
                              that requires some confgurations.
                          Here is a list of pairs with preconfigured options :
                              deu-eng, eng-deu
                          If there is any other name or wrong argument passed, it is ignored

Examples:
 ./generate-base-configs.sh --lang_pair deu-eng
 ./generate-base-configs.sh -p ./data --lang_pair deu-eng
```


### Running Experiments

There are multiple scripts for running the experiments, however `run-exp.sh` is the latest one that works with the current setup.

#### Using run-exp.sh script

Like the other scripts, run-exp is parameterized and fetches the default parameters ( repo_root, exp_coll, factorizer_dir, ... ) from the repo_setup.env file.

We only need to provide exp_name, language_pair ( order matters ), vocab pieces ( types, default = bpe ) and vocab sizes along with which cuda_device to use.

When we use factorizer* as a piece, we don't need to specify the vocab size.

```
./run-exp.sh -h

run-fac-enc : Run NMT experiment with Factorizer encoders

Syntax: run-fac-enc [OPTIONS]
Options:
  -h                          Print this Help.

  --repo_root <value>         Path to bytetok-nmt repos src directory
                              DEFAULT : ./src

  --exp_coll <value>          Path to the directory where you want to store
                                  different variations of all the experiments.
                              DEFAULT = ./exps

  --factorizer_dir <value>    Path to the directory where you want to store
                                  different variations of all the experiments.
                              DEFAULT = ./factorizer-models

  --configs_dir <value>       Path to the directory where you want to store
                                  different variations of all the experiments.
                              DEFAULT = ./configs

  --exp_name <value>          Name of the experiment. We will create a directory
                                  exp_coll/exp_name where we will store
                                  the experiment vocab, configs, results.
                              REQUIRED

  --lang_pair l1-l2           Language pair for downloading the datasets.
                              This uses mtdata for downloading the datasets, however
                                  that requires some confgurations.
                              Here is a list of pairs with preconfigured options :
                                  deu-eng, eng-deu

  --src_pieces <value>        Scheme used for creating src vocab
                              DEFAULT : bpe
                              VALUES : [ char, word, bpe, factorizer, factorizer266 ]

  --tgt_pieces <value>        Scheme used for creating tgt vocab
                              DEFAULT : bpe
                              VALUES : [ char, word, bpe, factorizer, factorizer266 ]

  --src_vcb_size <value>      Size of the src vocab.
                                  Not used if factorizer* is the scheme
                              REQUIRED if src_pieces != factorizer*

  --tgt_vcb_size <value>      Size of the tgt vocab.
                                  Not used if factorizer* is the scheme
                              REQUIRED if tgt_pieces != factorizer*

  --cuda_device <value>       CUDA device to be used for training
                              DEFAULT : 0
                              VALUES : [ -1, 0, 1, 2, ... ]
                                  -1 means no cuda_device is present

 Examples :
      .\run-exp.sh --exp_name fac266-bpe8k --lang_pair eng-deu \
          --src_pieces factorizer266 --tgt_pieces bpe --tgt_vcb_size 8000
```

#### Other scripts

- `run-fac-enc.sh` : This is the parameterized version of `run-factorizer-enc` script. **NOT TESTED**
- `run-factorizer-enc.sh` : This is the script that we have been using earlier. This requires modifying the parameters in the script itself before running. This script is the one still used in tag version `bytetok-v1.*`
- `run-factorizer.sh` : This does not work