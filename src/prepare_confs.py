import argparse
import os
import copy

from pathlib import Path 
from typing import List, Dict, Tuple

from lib.misc import make_dir, convert_kwarg, ConfBuilder

# create a args2dict_action class
class args2dict_action(argparse.Action):
    # Constructor calling
    def __call__(self, parser, namespace,
                 values, option_string=None):
        setattr(namespace, self.dest, dict())
          
        for value in values:
            # split it into key and value
            key, value = value.split('=')
            if ',' in value:
                value = [convert_kwarg(x) for x in value.split(',')]
            else:
                value = convert_kwarg(value)

            # assign into dictionary
            getattr(namespace, self.dest)[key] = value

def parse_args():
    parser = argparse.ArgumentParser(prog='make_conf', description="Prepares custom config files from base config files")

    parser.add_argument('-c', '--base_file', type=Path, 
                            help='Base config file for preparation of new config files.')
    parser.add_argument('-w', '--work_dir', type=Path, 
                            help='Path to the working directory for storing the prepared config files.')
    parser.add_argument('-n', '--output_filename', type=str)

    parser.add_argument('--kwargs', nargs='*', action=args2dict_action)

    return parser.parse_args()
    
def main():

    print("Parsing args ...")
    args = parse_args()

    # Read Base Confs
    print("Reading configs : ", args.base_file)
    cb = ConfBuilder(args.base_file)
    cb.read()

    if args.kwargs is not None:
        print("Parameters to be updated ...")
        print(args.kwargs)

        # Update Confs
        print("Updating configs ...")
        cb.update_many(args.kwargs)

    # Save Confs
    print("Making Directory : ", args.work_dir)
    make_dir(args.work_dir)

    output_file = args.work_dir / Path(args.output_filename)

    print("Writing configs to : {}".format(str(output_file)))
    cb.save(output_file)

if __name__ == "__main__":
    main()
