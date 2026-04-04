# Box API Examples

Design sketches showing different ways the Faust Box API can be used in cyfaust.

Note: the Faust interpreter does not support vectorization, parallel code, or
scheduler code.

## Example 1

Original C++:

```c++
Box box = boxPar(boxInt(7), boxReal(3.14));
```

Functional (snake_case):

```python
box = box_par(box_int(7), box_real(3.14))
```

Object-oriented:

```python
box = Box(7).par(Box(3.14))
```

Hybrid:

```python
box = box_par(Box(7), Box(3.14))
```

With auto-boxing of numeric literals (not yet implemented):

```python
box = box_par(7, 3.14)
```

## Example 2

Original C++:

```c++
Box box = boxSeq(boxPar(boxWire(), boxReal(3.14)), boxAdd());
```

Functional:

```python
box = box_seq(box_par(box_wire(), box_real(3.14)), box_add_op())
```

Object-oriented:

```python
box = Box().par(Box(3.14)).seq(box_add_op())
```

Hybrid:

```python
box = box_seq(Box().par(Box(3.14)), box_add_op())
```
