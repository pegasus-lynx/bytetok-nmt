from factorizer import Factorizer

tokenizer = Factorizer("/home/dipeshkr/factorizer-models/english.dawg")

total = 0
lengths = {}
tokenized = []

# with open("/home/dipeshkr/datasets/deu-eng/toks/train.eng.tok", "r+") as fr:
#     for line in fr:
#         encoding = tokenizer(line)
#         tokenized.append(encoding.ids)
#         nindexs = len(encoding.ids)*3
#         if nindexs not in lengths.keys():
#             lengths[nindexs] = 1
#         else:
#             lengths[nindexs] += 1
#         total += 1


# with open("/home/dipeshkr/datasets/deu-eng/toks/train.eng.tok.index", "w+") as fw:
#     for idxlist in tokenized:
#         codelist = []
#         for triplet in idxlist:
#             r,g,b = triplet
#             codelist.append(f"{r} {g} {b}")
#         idstring = " ".join(codelist)
#         fw.write(f"{idstring}\n")

with open("/home/dipeshkr/datasets/deu-eng/toks/train.eng.tok.index", "r+") as fr:
    for line in fr:
        total += 1
        l = len(line.split())
        if l not in lengths.keys():
            lengths[l] = 1
        else:
            lengths[l] += 1

cfreq = 0
cperc = dict()
lengths_set = set(lengths.keys())
lengths_set = list(lengths_set)
lengths_set.sort()
print(min(lengths_set), max(lengths_set))

for l in lengths_set:
    cfreq += lengths[l]
    cperc[l] = cfreq / total
    print(l, cperc[l])


# Max and Min Factorizer Code
# -------------------
# indices = set()
# with open("/home/dipeshkr/datasets/deu-eng/train.eng", "r+") as fr:
#     for line in fr:
#         encoding = tokenizer(line)
#         for triplet in encoding.ids:
#             r,g,b = triplet
#             indices.add(r)
#             indices.add(g)
#             indices.add(b)

# mii = 100000000
# mai = -1
# with open("../temp/factorizer-indices.notok.txt", "w") as fw:
#     for x in indices:
#         mii = min(mii,x)
#         mai = max(mai,x)
#         fw.write(f"{x}\t{mii}\t{mai}\n")




# Sample
# ------------------
# tokenizer = Factorizer("/home/dipeshkr/factorizer-models/english.dawg", alpha=0.25)
# sentence = "The echo of a distant time comes willowing across the sand, and everything is green and submarine."

# encoding = tokenizer(sentence)

# print(f"INPUT:    {sentence}")
# print(f"SUBWORDS: {' '.join(encoding.tokens)}")
# print(f"INDICES:  {' '.join(str(index) for index in encoding.ids)}")
# print(f"DECODED:  {tokenizer.decode(encoding.ids, skip_special_tokens=False)}")


# sentence = "waters"
# encoding = tokenizer(sentence)

# print(f"INPUT:    {sentence}")
# print(f"SUBWORDS: {' '.join(encoding.tokens)}")
# print(f"INDICES:  {' '.join(str(index) for index in encoding.ids)}")
# print(f"DECODED:  {tokenizer.decode(encoding.ids, skip_special_tokens=False)}")