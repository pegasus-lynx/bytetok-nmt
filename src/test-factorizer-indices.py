from factorizer import Factorizer


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

# encoding = tokenizer(sentence)

# print(f"INPUT:    {sentence}")
# print(f"SUBWORDS: {' '.join(encoding.tokens)}")
# print(f"INDICES:  {' '.join(str(index) for index in encoding.ids)}")
# print(f"DECODED:  {tokenizer.decode(encoding.ids}")

tokenizer = Factorizer("/home/dipeshkr/factorizer-models/english.dawg", alpha=0.25)
sentence = "The echo of a distant time comes willowing across the sand, and everything is green and submarine."

encoding = tokenizer(sentence)

print(f"INPUT:    {sentence}")
print(f"SUBWORDS: {' '.join(encoding.tokens)}")
print(f"INDICES:  {' '.join(str(index) for index in encoding.ids)}")
print(f"DECODED:  {tokenizer.decode(encoding.ids, skip_special_tokens=False)}")


sentence = "waters"

encoding = tokenizer(sentence)

print(f"INPUT:    {sentence}")
print(f"SUBWORDS: {' '.join(encoding.tokens)}")
print(f"INDICES:  {' '.join(str(index) for index in encoding.ids)}")
print(f"DECODED:  {tokenizer.decode(encoding.ids, skip_special_tokens=False)}")