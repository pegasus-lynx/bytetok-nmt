# bytetok-nmt


### Things to clarify

- [] Should we use tokenized file for sources ?

### Task Items

- [x] Add configs
- [] Give access.
- [] Add run script.
- [x] Inform about nvidia installs on system.
- [x] Check if we have old data


### Setting up environment
```
python -m venv <path-to-env>
source <path-to-env>\bin\activate
pip install -r requirements.txt
```
One thing to note is, while setting up the environment, many nvidia packages were installed. Please, take a look if they will be needed or not. 
Easiest thing would be to just run pip install and check if it is making some uninstalls, and if it is, then verify if the test is still running or not. This is just for precaution.


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