NAME
====

NativeHelpers::iovec - An implementation of the iovec struct

SYNOPSIS
========

```perl6
use NativeHelpers::iovec;

my iovec $iov .= new("Hello World");

say $iov.elems; # 11
```

DESCRIPTION
===========

NativeHelpers::iovec is an implementation of the iovec struct. It supports creating iovecs from Blob and Str objects, or from a Pointer and a number of bytes.

METHODS
=======

elems
-----

Returns the size of the buffer in bytes

base
----

Returns a void Pointer to the start of the memory buffer

free
----

Frees the allocated memory

Blob
----

Returns a new Blob with a copy of the memory buffer

Str(:$enc = 'utf-8')
--------------------

Returns a new Str containing the decoded memory buffer

new(Str, :$enc = 'utf-8')
-------------------------

Create a new iovec containing the encoded string

new(Blob)
---------

Create a new iovec containing the contents of the Blob

new(Pointer:D, Int:D)
---------------------

Create a new iovec with the given Pointer and size

AUTHOR
======

Travis Gibson <TGib.Travis@protonmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Travis Gibson

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

