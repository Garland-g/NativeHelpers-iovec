use v6;
use NativeCall;

class iovec:ver<0.0.1>:auth<cpan:GARLANDG> is repr('CStruct') is rw is export {
  has Pointer[void] $.base;
  has size_t $.elems;

  sub free(Pointer) is native { ... }

  sub memcpy(Pointer[void], Pointer[void], size_t) returns Pointer[void] is native {...}

  sub malloc(size_t $size) returns Pointer[void] is native { ... }

  submethod BUILD(Pointer:D :$base, Int:D :$elems) {
    $!base := $base;
    $!elems = $elems;
  }

  method free(iovec:D:) {
    free(nativecast(Pointer[void], self));
  }

  multi method new(iovec:U: Str $str, :$enc = 'utf-8' --> iovec) {
    self.new($str.encode($enc));
  }

  multi method new(iovec:U: Blob $blob --> iovec) {
    my $ptr = malloc($blob.bytes);
    memcpy($ptr, nativecast(Pointer[void], $blob), $blob.bytes);
    self.bless(:base($ptr), :elems($blob.bytes));
  }

  multi method new(iovec:U: Pointer:D $base, Int:D $elems) {
    self.bless(:$base, :$elems);
  }

  method Blob(iovec:D:) {
    my blob8 $buf .= allocate($!elems);
    memcpy(nativecast(Pointer[void], $buf), $!base, $!elems);
    $buf;
  }

  method Str(iovec:D: :$enc = 'utf-8') {
    return self.Blob.decode($enc);
  }
}
=begin pod

=head1 NAME

NativeHelpers::iovec - An implementation of the iovec struct

=head1 SYNOPSIS

=begin code :lang<perl6>

use NativeHelpers::iovec;

my iovec $iov .= new("Hello World");

say $iov.elems; # 11

=end code

=head1 DESCRIPTION

NativeHelpers::iovec is an implementation of the iovec struct. It supports
creating iovecs from Blob and Str objects, or from a Pointer and a number
of bytes.

=head1 METHODS

=head2 elems

Returns the size of the buffer in bytes

=head2 base

Returns a void Pointer to the start of the memory buffer

=head2 free

Frees the allocated memory

=head2 Blob

Returns a new Blob with a copy of the memory buffer

=head2 Str(:$enc = 'utf-8')

Returns a new Str containing the decoded memory buffer

=head2 new(Str, :$enc = 'utf-8')

Create a new iovec containing the encoded string

=head2 new(Blob)

Create a new iovec containing the contents of the Blob

=head2 new(Pointer:D, Int:D)

Create a new iovec with the given Pointer and size

=head1 AUTHOR

Travis Gibson <TGib.Travis@protonmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Travis Gibson

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
