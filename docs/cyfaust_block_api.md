# Box Api examples

Some sketches of different ways the box api can be implemented in cyfaust.

## Example 1

original cpp

```c++
Box box = boxPar(boxInt(7), boxReal(3.14));
```

cyfaust equivalent (snakecase)

```python
box = box_par(box_int(7), box_real(3.14))
```

cyfaust oo

```python
box = Box(7).par(Box(3.14))
```

cyfaust hybrid

```python
box = box_par(Box(7), Box(3.14))
```

numerical extension where numbers are auto-boxed (not yet implemented)

```python
box = box_par(7, 3.14)
```


Alternative api with submodules and specialized Box subclasses

```python
from cyfaust.box import box_context, par, Int, Float

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
(not implemented)

```python
from cyfaust.box import context, seq, par, wire, add_op, 

with context():
	b = seq(par(wire(), 3.14), add_op())
	b.print()
```

Alternative api with submodules and specialized Box subclasses (oo)
(not implemented)

```python
from cyfaust.box import context, seq, par, wire, add_op

with context():
	b = wire().par(3.14).seq(add_op())
	b.print()
```

