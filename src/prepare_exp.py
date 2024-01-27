import argparse
import os
from json import load

from pathlib import Path 
import collections as coll
from typing import List, Dict, Tuple


from nlcodec import Type
from rtg.data.dataset import TSVData, SqliteFile

from lib.misc import read_conf, make_dir, make_file, uniq_reader_func
from nlcodec.codec import get_scheme


def main():
    args = parse_args()
    configs = load_configs(args.conf_file)
    work_dir = make_dir(args.work_dir)

    prep_file = work_dir / Path('prep.yml')
    if not prep_file.exists():
        make_file(prep_file , args.conf_file)
    
    prepare_experiment(configs, work_dir)

def parse_args():
    parser = argparse.ArgumentParser(prog="prep-exp", description="Prepares a single experiment using the conf file")

    ## Parameters : Conf and Dir --------------------------------------------------------------------------------------
    parser.add_argument('-c', '--conf_file', type=Path, 
                            help='Config file for preparation of the experiment')
    parser.add_argument('-w', '--work_dir', type=Path, 
                            help='Path to the working directory for storing the run')
    return parser.parse_args()

def load_configs(conf_file: Path) -> Dict:
    if not conf_file.exists():
        raise FileNotFoundError(f"Config file not found: {conf_file}")
    
    configs = read_conf(conf_file)
    return configs

def prepare_experiment(configs, work_dir):
    data_dir = make_dir(work_dir / 'data')

    shared = configs.get('shared', False)
    vocab_sizes = {
        'src' : configs.get('max_src_types', 0),
        'tgt' : configs.get('max_tgt_types', 0),
        'shared' : configs.get('max_types', 0)
    }

    factorizer_models = {
        'src' : configs.get('src_factorizer', None),
        'tgt' : configs.get('tgt_factorizer', None),
        'share' : configs.get('shared_factorizer', None)
    }

    train_files = { 'src' : Path(configs['train_src']), 
                    'tgt' : Path(configs['train_tgt']) }
    val_files = {   'src' : Path(configs['valid_src']), 
                    'tgt' : Path(configs['valid_tgt']) }

    vocab_files = {
        'src' : data_dir / 'nlcodec.src.model',
        'tgt' : data_dir / 'nlcodec.tgt.model',
        'shared': data_dir / 'nlcodec.shared.model'
    }

    default_scheme = configs.get('pieces', "bpe")
    pieces = { 
        'src':default_scheme, 
        'tgt':default_scheme, 
        'shared':default_scheme 
    }
    if configs.get('src_pieces') is not None:
        pieces['src'] = configs.get('src_pieces')
    if configs.get('tgt_pieces') is not None:
        pieces['tgt'] = configs.get('tgt_pieces')

    vcb_flag = work_dir / Path('_VOCABS')
    if not vcb_flag.exists():
        prepare_vocabs(train_files, vocab_files,
                factorizer_models, pieces,
                shared, vocab_sizes)
        make_file(vcb_flag)

    data_flag = work_dir / Path('_DATA')
    if not data_flag.exists():
        prepare_data(train_files, val_files, vocab_files,
            factorizer_models, pieces, shared,
            configs['src_len'], configs['tgt_len'],
            configs['truncate'], data_dir)
        make_file(data_flag)

    make_file(work_dir / Path('_PREPARED'))

    if data_flag.exists():
        os.remove(data_flag)
    if vcb_flag.exists():
        os.remove(vcb_flag)


def prepare_vocabs(train_files:Dict[str,Path], 
        vocab_files:Dict[str,Path], 
        factorizer_models:Dict[str,int], pieces:Dict[str,str], 
        shared:bool, vocab_sizes:Dict[str,int]):
    
    keys = ['shared'] if shared else ['src', 'tgt']
    for key in keys:
        scheme = get_scheme(pieces[key])
        if key == 'shared':
            corp = uniq_reader_func(*train_files.values())
        else:
            corp = uniq_reader_func(train_files[key])

        vocab = scheme.learn(corp, vocab_size=vocab_sizes[key])
        if pieces[key] in ['factorizer', 'factorizer266'] :
            Type.write_out(vocab, vocab_files[key], scheme=pieces[key], 
                            factorizer_model=factorizer_models[key])
        else:
            Type.write_out(vocab, vocab_files[key], scheme=pieces[key])

def prepare_data(train_files:Dict[str, Path], val_files:Dict[str, Path], 
            vocab_files:Dict[str, Path], factorizer_models:Dict[str,int], 
            pieces:Dict[str, str], shared:bool, src_len:int, tgt_len:int, 
            truncate:bool, work_dir:Path):
    print("Preparing Data")
    codecs = {}
    for key, fpath in vocab_files.items():
        scheme = get_scheme(pieces[key])
        if fpath.exists():
            table, _ = Type.read_vocab(fpath)
            if pieces[key] in ["factorizer", "factorizer266"]:
                codecs[key] = scheme(table=table, 
                                    factorizer_model=factorizer_models[key])
            else:
                codecs[key] = scheme(table)

    src_codec = codecs['shared' if 'shared' in codecs.keys() else 'src']
    tgt_codec = codecs['shared' if 'shared' in codecs.keys() else 'tgt']

    ## For train files
    recs = TSVData.read_raw_parallel_recs(train_files['src'], 
                train_files['tgt'], truncate, src_len, tgt_len,
                src_codec.encode, tgt_codec.encode)
    # TSVData.write_parallel_recs(recs, work_dir / Path('train.tsv'))
    SqliteFile.write(work_dir / Path('train.db'), recs)

    ## For validation files
    recs = TSVData.read_raw_parallel_recs(val_files['src'], 
                val_files['tgt'], truncate, src_len, tgt_len,
                src_codec.encode, tgt_codec.encode)
    TSVData.write_parallel_recs(recs, work_dir / Path('valid.tsv.gz'))

    return

if __name__ == "__main__":
    main()
