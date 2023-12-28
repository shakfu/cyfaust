# Api usage variants


Some of the api variants depend on how cyfaust is packaged:

1. single-monolithic module (current)

	Can be statically compiled or a dynamically linked to `libfaust`

	In this case functions must have a prefix such as `box_` or `sig_`

2. package with single-monolithic extension

Can be statically compiled or a dynamically linked to `libfaust`



```
cyfaust/
	.dylibs
	__init__.py
	_cyfaust.so
	interp.py
	box.py
	signal.py
	resources/
		architectures
		libraries
```


3. package-structure with several extension submodule

	Can be statically compiled or a dynamically linked to `libfaust`

```
cyfaust/
	.dylibs
	__init__.py
	interp.so
	box.so
	signal.so
	resources/
		architectures
		libraries
```



## Example 1

original cpp

```c++
Box box = boxPar(boxInt(7), boxReal(3.14));
```

python equivalent (snakecase-ified)

```python
box = box_par(box_int(7), box_real(3.14))
```

python oo

```python
box = Box(7).par(Box(3.14))
```

python hybrid

```python
box = box_par(Box(7), Box(3.14))
```

Alternative api with submodules and specialized Box subclasses

```python
from cyfaust.box import context, par, Int, Float

with context():
	b = par(Int(10), Float(20))
	b.print()
```


## Example 2

```c++
Box box = boxSeq(boxPar(boxWire(), boxReal(3.14)), boxAdd());
```

python equivalent

```python
box = box_seq(box_par(box_wire(), box_real(3.14)), box_add_op())
```

python oo

```python
box = Box().par(Box(3.14)).seq(box_add_op())
```

python hybrid

```python
box = box_seq(Box().par(Box(3.14)), box_add_op())
```


Alternative api with submodules and specialized Box subclasses (functional)

```python
from cyfaust.box import context, seq, par, wire, add, Float

with context():
	b = seq(par(wire(), Float(3.14)), add())
	b.print()
```

Alternative api with submodules and specialized Box subclasses (oo)

```python
from cyfaust.box import context, seq, par, wire, add, Float

with context():
	b = wire().par(Float(3.14)).seq(add())
	b.print()
```

