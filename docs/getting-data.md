

### Process for getting the data for the experiments

The general process is to use `mtdata` by Thamme Gowda to download the datasets. Therefore before running any of these commands, run the following command to install the tool:

```bash
pip install mtdata
```
Now, once you have the tool installed, run the following commands to download the datasets.

#### deu-eng data

```bash
mtdata get -l deu-eng --out ./datasets/deu-eng --merge --train Statmt-europarl-10-deu-eng Statmt-news_commentary-16-deu-eng --dev Statmt-newstest_deen-2017-deu-eng  --test Statmt-newstest_deen-20{18,19,20}-deu-eng
```

Here is the output of the the command above:

```
2023-12-11 02:59:32 data.add_train_entries:186 INFO:: Train stats:
{
  "selected": 2206240,
  "total": 2206240,
  "counts": {
    "total": {
      "Statmt-news_commentary-16-deu-eng": 388482,
      "Statmt-europarl-10-deu-eng": 1817758
    },
    "dupes_skips": {},
    "test_overlap_skips": {},
    "selected": {
      "Statmt-news_commentary-16-deu-eng": 388482,
      "Statmt-europarl-10-deu-eng": 1817758
    }
  }
}
2023-12-11 02:59:32 data.prepare:115 INFO:: Created references at datasets/deu-eng/references.bib
2023-12-11 02:59:32 main.get_data:48 INFO:: Dataset is ready at datasets/deu-eng
2023-12-11 02:59:32 main.get_data:49 INFO:: mtdata args for reproducing this dataset:
 mtdata get -l deu-eng -tr Statmt-europarl-10-deu-eng Statmt-news_commentary-16-deu-eng -ts Statmt-newstest_deen-2018-deu-eng Statmt-newstest_deen-2019-deu-eng Statmt-newstest_deen-2020-deu-eng -dv Statmt-newstest_deen-2017-deu-eng --merge -o <out-dir>
mtdata version 0.3.7
```