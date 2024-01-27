import argparse
import os
import glob

import re
from pathlib import Path 
from typing import List, Dict, Tuple

from lib.misc import make_dir, make_file
from lib.misc import ConfBuilder

def generate_data_kwargs(dataset_dir, src_lang, tgt_lang):
    
    tok_dir = dataset_dir / 'toks'
    
    data_kwargs = dict()
    for datakey in ['train_src', 'train_tgt', 'valid_src', 'valid_tgt']:
        parts = datakey.split('_')
        lang = src_lang if parts[1] == 'src' else tgt_lang
        pth = tok_dir / Path('./{}.{}.tok'.format(parts[0], lang))
        data_kwargs[datakey] = str(pth.resolve())

    data_kwargs['suit'] = dict()
    for file in tok_dir.glob('test*.{}.tok'.format(src_lang)):
        key = os.path.basename(file).split('.')[0]
        data_kwargs['suit'][key] = [str(file.resolve())]

    for key in data_kwargs['suit'].keys():
        ref_file = dataset_dir / Path('{}.{}'.format(key,tgt_lang))
        data_kwargs['suit'][key].append(str(ref_file.resolve()))

    return data_kwargs

def parse_args():
    parser = argparse.ArgumentParser(prog='generate_base_conf', 
                description="Generates base config files for specific language pairs")
    parser.add_argument('-d', '--dataset_dir', type=Path, 
                            help='Path to the dataset directory.')
    parser.add_argument('-c', '--configs_dir', type=Path, 
                            help='Path to the directory for storing generated configs')
    parser.add_argument('-n', '--output_filename', type=str)
    parser.add_argument('-b', '--base_file', type=Path, 
                            help='Path to the base conf file.')
    parser.add_argument('-s', '--src_lang', type=str, 
                            help="Path to the root of the this repository.")
    parser.add_argument('-t', '--tgt_lang', type=str, 
                            help="Path to the root of the this repository.")

    return parser.parse_args()
    
def main():

    print("Parsing args ...")
    args = parse_args()

    # Read Base Confs
    print("Reading configs : ", args.base_file)
    cb = ConfBuilder(args.base_file)
    cb.read()

    # Generate Data Paths
    print("Generate data paths ...")
    data_paths = generate_data_kwargs(args.dataset_dir, args.src_lang, args.tgt_lang)

    # Update Confs
    cb.update_many(data_paths)

    # Save Confs
    print("Making Directory : ", args.configs_dir)
    make_dir(args.configs_dir)

    output_file = args.configs_dir / Path(args.output_filename)

    print("Writing configs to : {}".format(str(output_file)))
    cb.save(output_file)

if __name__ == "__main__":
    main()