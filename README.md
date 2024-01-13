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

### Running Experiments

### Steps to run the run-factorizer.sh script

> These scripts pick the default paths for factorizer, data and configs from `repo-setup.env`. Feel free to change them for your setup, or provide the paths while running the scripts.
> Enable execution for all the scripts using `chmod +x`

1. Change directory to repo root: `cd ..\<repo-path>\bytetok-nmt`
2. Run the `fetch-factorizer` script to download the factorizer models
    ```
        ./fetch-factorizer.sh deu-eng
    ``` 

3. Run the `featch-datasets` script to download the dataset ( supports deu-eng at this moment ). For extending for other language pairs check the commands in deu-eng case. 
    ```
        ./fetch-datasets.sh deu-eng
    ```

4. Setup paths in base config file. These paths are relative to `$repo_root\src`

5. Setup parameters in `run-factorizer.sh`.
6. `chmod +x run-factorizer.sh`
7. `.\run-factorizer.sh`