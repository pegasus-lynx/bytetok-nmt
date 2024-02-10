import gzip
import json
import re

import shutil
from datetime import datetime
from pathlib import Path
from typing import List, Union, Dict, Iterator

from nlcodec.utils import IO as IO_nlcodec

# Defining commonly used types
Filepath = Union[Path,str]

def convert_kwarg(value):
    if value == '':
        return None
    if value in ['True', 'true']:
        return True
    if value in ['False', 'false']:
        return False
    if re.fullmatch("-?\d+", value):
        return int(value)
    if re.fullmatch("-?\d+\.\d*", value):
        return float(value)
    return value

def log(text, ntabs=0):
    print(f"{'    '*ntabs} > {text}")

def get_now():
    datetime_str = datetime.now().isoformat()
    datetime_str = datetime_str.replace('T', ' ')
    pos = datetime_str.index('.')
    return datetime_str[:pos]

def make_dir(path:Filepath):
    path = Path(path)
    if not path.exists():
        path.mkdir(parents=True)
        log(f'>> Making Directory {path.name}',1)    
    return path

def read_conf(conf_file:Filepath, conf_type:str='yaml'):
    conf_file = Path(conf_file)
    if conf_type in ['yaml', 'yml']:
        from ruamel.yaml import YAML
        yaml = YAML(typ='safe')
        return yaml.load(conf_file)
    if conf_type == 'json':
        fr = open(conf_file, 'r')
        return json.load(fr)
    return None

def write_conf(configs_dict:Dict, output_file:Filepath, conf_type:str='yaml'):
    output_file=Path(output_file)
    with open(output_file, 'w') as fw:
        if conf_type in ['yaml', 'yml']:
            from ruamel.yaml import YAML
            yaml = YAML()
            yaml.dump(configs_dict, fw)
        if conf_type == 'json':
            json.dump(configs_dict, fw)
    return None

def eval_file(detok_hyp:Path, ref:Path, lowercase=True):
    from sacrebleu import corpus_bleu, corpus_chrf, BLEU

    detoks = [x for x in IO.get_lines(detok_hyp)]
    refs = [x for x in IO.get_lines(ref)]
    
    bleu = corpus_bleu(detoks, [refs], lowercase=lowercase)
    chrf2 = corpus_chrf(detoks, [refs], beta=2)

    return bleu, chrf2
    # bleu_str = bleu.format()
    # log(f'BLEU {detok_hyp} : {bleu_str}',2)
    # return f'BLEU {detok_hyp} : {bleu_str}'

def make_file(destination,source=None):
    if source is None:
        fw = open(destination, 'w')
        fw.close()
    else:
        shutil.copy2(source,destination)

def uniq_reader_func(*args) -> Iterator[str]:
    recs = set()
    for fpath in args:
        with IO_nlcodec.reader(fpath) as fr:
            for line in fr:
                line = line.strip()
                recs.add(line)
    return recs

class ConfBuilder(object):

    def __init__(self, conf_file:Filepath, conf_type:str='yaml'):
        self.conf_file = Path(conf_file)
        self.conf_type = conf_type
        self.configs = None

    def read(self):
        if self.conf_type in ['yml', 'yaml']:
            self._read_yaml()

        if self.conf_type in ['json']:
            self._read_json()

        if self.configs is None:
            self.configs = dict()
        
        return

    def save(self, out_file:Filepath, conf_type:str=None):
        out_path = Path(out_file)

        if conf_type is None:
            conf_type = self.conf_type

        if conf_type in ['yml', 'yaml']:
            self._save_yaml(out_path)
            return

        if conf_type in ['json']:
            self._save_json(out_path)
            return

        return

    def update(self, key, val):
        keys = [key]
        kwargs = { key:val }
        self.configs = ConfBuilder._dfs_update(self.configs, kwargs, keys)

    def update_many(self, kwargs):
        keys = set(kwargs.keys())
        self.configs = ConfBuilder._dfs_update(self.configs, kwargs, keys)

    def _save_yaml(self, out_path:Path):
        from ruamel.yaml import YAML
        yaml = YAML()
        with open(out_path, 'w') as fw:
            yaml.dump(self.configs, fw)

    def _save_json(self, out_path:Path):
        with open(out_path, 'w') as fw:
            json.dump(self.configs, fw)

    def _read_yaml(self):
        from ruamel.yaml import YAML
        yaml = YAML(typ='safe')
        self.configs = yaml.load(self.conf_file)

    def _read_json(self):
        with open(self.conf_file, 'r') as fr:
            self.configs = json.load(fr)

    @staticmethod
    def remove_nones(configs):
        trimmed = copy.deepcopy(configs)
        for key in configs.keys():
            val = configs[key]
            if type(val) is dict and len(val) != 0:
                trimmed[key] = ConfBuilder.remove_nones(val)
            val = trimmed[key]
            if type(val) is dict or type(val) is list:
                if len(val) == 0:
                    del trimmed[key]
            else:
                if val is None:
                    del trimmed[key]
        return trimmed
    
    @staticmethod
    def _dfs_update(configs, kwargs, keys):
        for key in configs.keys():
            if key in keys:
                configs[key] = kwargs[key]
            elif type(configs[key]) is dict:
                configs[key] = ConfBuilder._dfs_update(configs[key], kwargs, keys)

            # if type(configs[key]) is dict:
            #     configs[key] = _dfs_update(configs[key], kwargs, keys)
            # elif key in keys:
            #     if type(configs[key]) is dict:
            #         configs[key] = _dfs_update(configs[key], kwargs, keys)
            #     else:
            #         configs[key] = kwargs[key]
        return configs
        

class FileReader(object):
    def __init__(self, filepaths:List[Path], segmented=True):
        self.filepaths = filepaths
        self.segmented = segmented
        self.length = None

    def __iter__(self):
        for filepath in self.filepaths:
            fs = open(filepath, 'r')
            for line in fs:
                line = line.strip()
                if self.segmented:
                    line = line.split()
                yield line

    def __len__(self):
        if self.length is not None:
            return self.length
        self.length = 0
        for filepath in self.filepaths:
            fs = open(filepath, 'r')
            self.length += len(fs.readlines())
        return self.length

    def unique(self):
        flat = set()
        for line in self:
            line = line.strip()
            flat.add(line)
        return flat

class FileWriter(object):

    def __init__(self, filepath, mode='w'):
        self.fw = open(filepath, mode)
        self.tablevel = 0

    def close(self, add_dashline=False):
        if add_dashline:
            self.dashline(txt='=', length=75)
            self.newline()
        self.fw.close()

    def textlines(self, texts:List[Union[str, Path]]):
        for text in texts:
            self.textline(text)

    def heading(self, text):
        self.textline(text)
        self.textline(f'TIME : {get_now()}')
        self.dashline()
        self.newline()

    def time(self):
        text = get_now()
        self.textline(text)

    def textline(self, text):
        self.fw.write(f'{"    "*self.tablevel}{text}\n')

    def dashline(self, txt='-', length=50):
        self.fw.write(f'{txt*length} \n')

    def sectionstart(self, text):
        self.textline(text)
        self.dashline()
        self.tablevel += 1

    def sectionclose(self):
        self.dashline()
        self.newline()
        self.tablevel = max(0, self.tablevel-1)

    def section(self, heading:str, lines:List):
        self.sectionstart(heading)
        self.textlines(lines)
        self.sectionclose()

    def newline(self):
        self.fw.write('\n')

# For backporting purpose only
class IO:
    """File opener and automatic closer"""

    def __init__(self, path, mode='r', encoding=None, errors=None):
        self.path = path if type(path) is Path else Path(path)
        self.mode = mode
        self.fd = None
        self.encoding = encoding if encoding else 'utf-8' if 't' in mode else None
        self.errors = errors if errors else 'replace'

    def __enter__(self):

        if self.path.name.endswith(".gz"):  # gzip mode
            self.fd = gzip.open(self.path, self.mode, encoding=self.encoding, errors=self.errors)
        else:
            if 'b' in self.mode:  # binary mode doesnt take encoding or errors
                self.fd = self.path.open(self.mode)
            else:
                self.fd = self.path.open(self.mode, encoding=self.encoding, errors=self.errors,
                                         newline='\n')
        return self.fd

    def __exit__(self, _type, value, traceback):
        self.fd.close()

    @classmethod
    def reader(cls, path, text=True):
        return cls(path, 'rt' if text else 'rb')

    @classmethod
    def writer(cls, path, text=True, append=False):
        return cls(path, ('a' if append else 'w') + ('t' if text else 'b'))

    @classmethod
    def get_lines(cls, path, col=0, delim='\t', line_mapper=None, newline_fix=True):
        with cls.reader(path) as inp:
            if newline_fix and delim != '\r':
                inp = (line.replace('\r', '') for line in inp)
            if col >= 0:
                inp = (line.split(delim)[col].strip() for line in inp)
            if line_mapper:
                inp = (line_mapper(line) for line in inp)
            yield from inp

    @classmethod
    def get_liness(cls, *paths, **kwargs):
        for path in paths:
            yield from cls.get_lines(path, **kwargs)

    @classmethod
    def write_lines(cls, path: Path, text, addnewline:bool = False):
        if isinstance(text, str):
            text = [text]
        with cls.writer(path) as out:
            for line in text:
                out.write(line)
                if addnewline:
                    out.write('\n')

    @classmethod
    def copy_file(cls, src: Path, dest: Path, follow_symlinks=True):
        log.info(f"Copy {src} → {dest}")
        assert src.resolve() != dest.resolve()
        shutil.copy2(str(src), str(dest), follow_symlinks=follow_symlinks)

    @classmethod
    def maybe_backup(cls, file: Path):
        if file.exists():
            time = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
            dest = file.with_suffix(f'.{time}')
            log.info(f"Backup {file} → {dest}")
            file.rename(dest)

    @classmethod
    def safe_delete(cls, path: Path):
        try:
            if path.exists():
                if path.is_file():
                    log.info(f"Delete file {path}")
                    path.unlink()
                elif path.is_dir():
                    log.info(f"Delete dir {path}")
                    path.rmdir()
                else:
                    log.warning(f"Coould not delete {path}")
        except:
            log.exception(f"Error while clearning up {path}")

class ScriptFuncs(object):

    @staticmethod
    def validate_vocab_files(vocab_files:Dict[str,Union[Path,str]], shared):
        if shared:
            assert 'shared' in vocab_files.keys()
            assert vocab_files['shared'].exists()
        else:
            assert 'src' in vocab_files.keys()
            assert 'tgt' in vocab_files.keys()
            assert vocab_files['src'].exists()
            assert vocab_files['tgt'].exists()

    @staticmethod
    def make_files_dict(file_str:List[str]):
        files = dict()
        for i in range(0, len(file_str), 2):
            files[file_str[i]] = Path(file_str[i+1])
        return files
