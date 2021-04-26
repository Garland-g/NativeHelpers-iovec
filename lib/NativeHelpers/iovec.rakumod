use v6;
use NativeCall;

=begin pod

=head1 NAME

NativeHelpers::iovec - An implementation of the iovec struct

=head1 SYNOPSIS

=begin code :lang<raku>

use NativeHelpers::iovec;

my iovec $iov .= new("Hello World");

say $iov.elems; # 11

say $iov[0].chr; # H

=end code

=head1 DESCRIPTION

NativeHelpers::iovec is an implementation of the iovec struct. It supports
creating iovec objects from Blob and Str objects, or from a number
of bytes.

NativeHelpers::iovec supports CArray methods (elems, list, AT-POS), which all operate
on the buffer.

NativeHelpers::iovec instances must be freed manually. They are not garbage-collected under any circumstance.

=head1 METHODS

=end pod

class iovec:ver<0.0.1>:auth<cpan:GARLANDG> is repr('CStruct') does Positional is export {
  has size_t $!base; # void *
  has size_t $!elems;

  # Work around weird warning when running raku --doc.
  constant LIB = DOC BEGIN { "string" } // %?RESOURCES<libraries/iovechelper>.Str;

  my sub calloc(size_t $n_elems, size_t $size) returns Pointer[void] is native { ... }

  my sub free(Pointer) is native { ... }

  my sub cstr_pointer(Str) returns size_t is native(LIB) { ... }

  multi submethod BUILD(Int:D :$base, Int:D :$elems) {
    $!base = $base;
    $!elems = $elems;
  }

  #| Returns the size of the buffer in bytes
  method elems { $!elems }

  #| Returns a void Pointer to the start of the memory buffer
  method base {
    return Pointer[uint8].new($!base)
  }

  #| Frees the iovec buffer
  method free(iovec:D:) {
    free(Pointer[void].new($!base));
  }

  #| Create an new iovec with a Str
  multi method new(iovec:U: Str $str, :enc($encoding) = 'utf8' --> iovec) {
    my $cstr = explicitly-manage($str, :$encoding);
    my $base = cstr_pointer($cstr);
    self.bless(:$base, elems => $str.encode($cstr.encoding).bytes);
  }

  #| Create an new iovec with a Blob
  multi method new(iovec:U: Blob $blob --> iovec) {
    self.bless(base => cstr_pointer(explicitly-manage($blob.decode('utf8-c8'))), elems => $blob.bytes);
  }

  #| Create a new iovec with $elems elements
  multi method new(iovec:U: Int $elems --> iovec) {
    my $base = +calloc(1, $elems);
    self.bless(:$base, :$elems);
  }

  #| Allocate a new iovec with $elems elements
  #| Same as new(Int $elems)
  multi method allocate(iovec:U: Int $elems --> iovec) {
    my $base = +calloc(1, $elems);
    self.bless(:$base, :$elems);
  }

  #| Return a Blob copy of the buffer
  method Blob(iovec:D:) returns Blob {
    nativecast(Str, Pointer.new($!base)).encode('utf8-c8');
  }

  #| Return the buffer converted into a Str
  method Str(iovec:D:) returns Str {
    return nativecast(Str, Pointer.new($!base));
  }

  #| Return the list of values inside the buffer
  method list returns List {
    return (do for ^$!elems {
      self.AT-POS($_);
    }).list
  }

  method AT-POS(iovec:D: $index) is rw {
    if $index < $!elems {
      return-rw nativecast(CArray[uint8], Pointer[uint8].new($!base))[$index];
    }
    else {
      fail "Index out of range";
    }
  }

  method ASSIGN-POS(iovec:D: $index, $new) {
    if $index < $!elems {
      nativecast(CArray[uint8], Pointer[uint8].new($!base))[$index] = $new;
    }
    else {
      fail "Index out of range";
    }
  }

}

=begin pod

=head1 AUTHOR

Travis Gibson <TGib.Travis@protonmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Travis Gibson

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
