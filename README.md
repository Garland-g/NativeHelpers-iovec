NAME
====

NativeHelpers::iovec - An implementation of the iovec struct

SYNOPSIS
========

```raku
use NativeHelpers::iovec;

my iovec $iov .= new("Hello World");

say $iov.elems; # 11

say $iov[0].chr; # H
```

DESCRIPTION
===========

NativeHelpers::iovec is an implementation of the iovec struct. It supports creating iovec objects from Blob and Str objects, or from a number of bytes.

NativeHelpers::iovec supports CArray methods (elems, list, AT-POS), which all operate on the buffer.

NativeHelpers::iovec instances must be freed manually. They are not garbage-collected under any circumstance.

METHODS
=======

### method elems

```perl6
method elems() returns Mu
```

Returns the size of the buffer in bytes

### method base

```perl6
method base() returns Mu
```

Returns a void Pointer to the start of the memory buffer

### method free

```perl6
method free() returns Mu
```

Frees the iovec buffer

### multi method new

```perl6
multi method new(
    Str $str,
    :enc($encoding) = "utf8"
) returns iovec
```

Create an new iovec with a Str

### multi method new

```perl6
multi method new(
    Blob $blob
) returns iovec
```

Create an new iovec with a Blob

### multi method new

```perl6
multi method new(
    Int $elems
) returns iovec
```

Create a new iovec with $elems elements

### multi method allocate

```perl6
multi method allocate(
    Int $elems
) returns iovec
```

Allocate a new iovec with $elems elements Same as new(Int $elems)

### method Blob

```perl6
method Blob() returns Blob
```

Return a Blob copy of the buffer

### method Str

```perl6
method Str() returns Str
```

Return the buffer converted into a Str

### method list

```perl6
method list() returns List
```

Return the list of values inside the buffer

AUTHOR
======

Travis Gibson <TGib.Travis@protonmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Travis Gibson

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

