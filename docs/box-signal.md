## Supporting Signal and Box apis

The Faust box expression

```faust
process = _,3.14 : +;

```


The the c++ box expression

```c++
// c++ level

Box box = boxSeq(boxPar(boxWire(), boxReal(3.14)), boxAdd());
// or abbreviated as:
Box box = boxAdd(boxWire(), boxReal(3.14));
```

Could be represented in python as:

```python

box.add(in1 + 3.14)
```
