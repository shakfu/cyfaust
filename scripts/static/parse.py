"""
parser/generator

parses c-headers and generates cython equivalent wrapper

TODO:
	- [ ] check if returntype is void and skip 'return'
	- [ ] split arg types and qualify with a `fi.` prefix if they are not primitives


"""

import hashlib
import re
from pathlib import Path


def to_snake_case(name):
    name = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    name = re.sub('__([A-Z])', r'_\1', name)
    name = re.sub('([a-z0-9])([A-Z])', r'\1_\2', name)
    return name.lower()

def to_camel_case(name):
	return ''.join(word.title() for word in name.split('_'))



class HeaderParser:
	FUNC = re.compile(r"^cdef\s+(.+)\s+(\w+)\((.+)\)")
	DOC = re.compile(r"^\* (?!@)(\w.+)\.?")
	PARAM = re.compile(r"^\*\s+@param (.+)\s-\s(.+)\.?")
	RETURNS = re.compile(r"^\*\s+@return\s+(.+)\.?")

	def __init__(self, path: str | Path):
		self.path = Path(path)
		self.rows = []
		self.entries = []

	def parse_header_entry(self, it):
		try:
			row = next(it)
			if 'doc' in row:
				entry = dict(doc=row['doc'][0])
				row = next(it)
				if 'param' in row:
					entry['params']  = []
				while 'param' in row:
					entry['params'].append(row['param'])
					row = next(it)
				if 'returns' in row:
					entry['returns'] = row['returns'][0]
					row = next(it)
				if 'func' in row:
					entry['func'] = row['func']
					self.entries.append(entry)
			elif 'func' in row:
				entry = dict(func=row['func'])
				self.entries.append(entry)
		except StopIteration:
			return
		self.parse_header_entry(it)


	def process(self):
		with open(self.path) as f:
			lines = f.readlines()
			for i, line in enumerate(lines):
				line = line.strip()

				if self.DOC.match(line):
					m = self.DOC.match(line)
					self.rows.append(dict(doc = m.groups()))

				elif self.PARAM.match(line):
					m = self.PARAM.match(line)
					self.rows.append(dict(param=m.groups()))

				elif self.RETURNS.match(line):
					m = self.RETURNS.match(line)
					self.rows.append(dict(returns=m.groups()))

				elif self.FUNC.match(line):
					m = self.FUNC.match(line)
					self.rows.append(dict(func=m.groups()))

		# for row in self.rows:
		# 	print(row)

		it = iter(p.rows)
		self.parse_header_entry(it) # recursive
		for e in self.entries:
			# print(e)
			# print()

			returntype, fname, args = e['func']
			# snakename = to_snake_case(fname[1:])
			# print(fname)
			snakename = to_snake_case(fname)
			qual_func = f"fs.{fname}"
			params = args.split(',')
			_args = ", ".join(p.split()[-1] for p in params)
			if returntype not in ["int", "bool", "bint", "void", "void *", "void*", "float", "double"]:
				returntype = f"{returntype}"
			func = f"cdef {returntype} {snakename}({args})"

			print(func+":")
			if 'doc' in e:
				docstring = f'''    \"\"\"{e['doc']}\"\"\"'''
				print(docstring)
			print(f"    return {qual_func}({_args})")
			print()

if __name__ == '__main__':
	p = HeaderParser('sigs.pyx')
	p.process()


