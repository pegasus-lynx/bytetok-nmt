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


### Setting up Models, Datasets for running experiments

#### Fetching Factorizer Models

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

#### Fetching Datasets 


### Running Experiments

### Steps to run the run-factorizer.sh script

PS: Adding factorizer-models in repo-root is easiest as the config files are already configured to that.

1. Change directory to repo root: `cd ..\<repo-path>\bytetok-nmt`
2. `mkdir factorizer-models`
3. Download the factorizer models:
```
    cd factorizer-models
    wget https://github.com/ltgoslo/factorizer/releases/download/v1.0.0/english.dawg
``` 

4. Setup data directory
```
<!-- For getting new data -->
mtdata get -l deu-eng --out ./datasets/deu-eng --merge --train Statmt-europarl-10-deu-eng Statmt-news_commentary-16-deu-eng --dev Statmt-newstest_deen-2017-deu-eng  --test Statmt-newstest_deen-20{18,19,20}-deu-eng
```

5. Setup paths in base config file. These paths are relative to `$repo_root\src`

6. Setup parameters in `run-factorizer.sh`.
7. `chmod +x run-factorizer.sh`
8. `.\run-factorizer.sh`