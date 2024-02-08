import argparse
import os
import glob

import random
from tqdm import tqdm
from pathlib import Path 
from typing import List, Dict, Tuple
from lib.misc import IO

ADD_OP = 1
DEL_OP = 2
CASE_OP = 3

ADD_DEL_OPS = 2
CASE_ADD_DEL_OPS = 3

case_langs = [ "eng", "deu" ]

def get_fraction(x:float):
    num=x
    den=100

    while num < 1:
        num = num*10
        den = den*10

    frac = num - int(num)
    while frac*100 > num:
        num = num*10
        den = den*10
        frac = num - int(num)

    return (int(num), den) 

def get_rands(fnum, fden, nops):
    char_ids = random.sample(range(1,fden+1), fnum)
    for char_id in char_ids:
        op_id = random.randrange(1,nops+1)
        repeat_times = 0
        if op_id == 1:
            repeat_times = random.randrange(1,4)
        yield (char_id, op_id, repeat_times)

class RandomOp(object):

    def __init__(self, fnum, fden, nops, seed):
        random.seed(a=seed)
        self.fnum = fnum
        self.fden = fden
        self.nops = nops
        
        self.curr = 0
        self.char_ids = []

    def random(self):
        if len(self.char_ids) == 0:
            self.char_ids = random.sample(range(1,self.fden+1), self.fnum)
        
        char_id = self.char_ids[self.curr]
        op_id = random.randrange(1,self.nops+1)
        repeat_times = 0
        if op_id == 1:
            repeat_times = random.randrange(1,4)

        self.curr += 1
        if self.curr == len(self.char_ids):
            self.curr = 0
            self.char_ids = []

        return (char_id, op_id, repeat_times)

def perform_op(ch, op, repeat):

    if op == ADD_OP:
        return ch*repeat
    elif op == DEL_OP:
        return ""
    elif op == CASE_OP:
        return ch.swapcase()
    else:
        raise ValueError

def parse_args():
    parser = argparse.ArgumentParser(prog='add_noise', 
                description="Adds noise to the data file")
    parser.add_argument('-f', '--in_file', type=Path, 
                            help='Path to the data file')
    parser.add_argument('-o', '--outfile_name', type=str, default="", help="Name of the output file")
    parser.add_argument('-l', '--lang', type=Path, 
                            help='Language of the data in the file')
    parser.add_argument('-s', '--seed', type=int,
                            help='Seed value for deterministic generation of the noise')
    parser.add_argument('-p', '--pnoise', type=float, 
                            help='Percentage for adding the noise')

    return parser.parse_args()

def main():
    args = parse_args()

    if args.pnoise < 0.0 or args.pnoise > 100.0:
        print("pnoise is a percentage value and must be between 0.0 - 100.0")
        return

    ops = ADD_DEL_OPS
    if args.lang in case_langs:
        ops = CASE_ADD_DEL_OPS

    random.seed(a=args.seed)

    fnum, fden = get_fraction(args.pnoise)
    rgen = RandomOp(fnum, fden, ops, args.seed)
            
    count = 0
    noisy_lines = []

    char_id, op_id, repeat = rgen.random()
    with IO.reader(args.in_file) as lines:
        for line in tqdm(lines):  
            noisy_line = ""
            for x in line:
                if x == " ":
                    noisy_line += x
                    continue
                count += 1
                if count == char_id:
                    noisy_line += perform_op(x,op_id,repeat)
                else:
                    noisy_line += x
                if count == fden:
                    char_id, op_id, repeat = rgen.random()
                    count = 0
            noisy_lines.append(noisy_line)

    outfile_name = args.outfile_name
    print("Outfile Name : ", outfile_name)
    if outfile_name == "":
        name_parts = args.in_file.name.split('.')
        name_parts[0] = name_parts[0] + f"-p{args.pnoise}-s{args.seed}"
        outfile_name = ".".join(name_parts)
    
    out_file = args.in_file.with_name(outfile_name)
    
    IO.write_lines(out_file, noisy_lines)


if __name__ == "__main__":
    main()