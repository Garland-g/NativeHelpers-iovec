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

my iovecs $iovecs .= new(2);

$iovecs[0] = iovec.new("Hello ");
$iovecs[1] = iovec.new("World\n");

say $iovecs[0].Str ~ $iovecs[1].Str; # "Hello World\n"

=end code

=head1 DESCRIPTION

NativeHelpers::iovec is an implementation of the iovec struct. It supports
creating iovec objects from Blob and Str objects, or from a number
of bytes.

NativeHelpers::iovec supports CArray methods (elems, list, AT-POS), which all operate
on the buffer.

NativeHelpers::iovec instances must be freed manually. They are not garbage-collected under any circumstance.

NativeHelpers::iovecs objects are for scatter-gather io operations, which require *iovec. It supports CArray methods
which all operate on the set of iovecs.

=head1 METHODS

=end pod

my sub calloc(size_t $n_elems, size_t $size) returns Pointer[void] is native { ... }

my sub free(Pointer) is native { ... }

class iovec:ver<0.0.1>:auth<cpan:GARLANDG> is repr('CStruct') does Positional is export {
  has size_t $!base; # void *
  has size_t $!elems;

  # Work around weird warning when running raku --doc.
  constant LIB = DOC BEGIN { "string" } // %?RESOURCES<libraries/iovechelper>.Str;

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

#| Array of iovec
class iovecs:ver<0.0.1>:auth<cpan:GARLANDG> is repr('CPointer') is export {
  #| Allocate space for a new set of iovecs
  method new(Int $elems --> iovecs) {
    my $self := nativecast(iovecs, calloc($elems, nativesizeof(iovec)));
    $self.^set_name("iovecs[$elems]");
    $self
  }

  #| Allocate space for a new set of iovecs
  method allocate(Int $elems --> iovecs) {
    my $self := nativecast(iovecs, calloc($elems, nativesizeof(iovec)));
    $self.^set_name("iovecs[$elems]");
    $self
  }

  #| Get the number of elements in this set of iovecs (using a side-channel via .^name)
  method elems(iovecs:D: --> Int()) { self.^name ~~ /\d+/ }

  method ASSIGN-POS(iovecs:D: $index, $new) {
    fail "Requires an iovec" unless $new ~~ iovec;
    if $index < self.elems {
      my $arr = nativecast(CArray[size_t], self);
      $arr[2 * $index] = +$new.base;
      $arr[2 * $index + 1] = $new.elems;
    }
    else {
      fail "Index out of range"
    }
  }

  method AT-POS(iovecs:D: $index) is raw {
    if $index < self.elems {
      my $ptr = nativecast(Pointer[size_t], self).add(2 * $index);
      if $ptr.deref == 0 {
        iovec:U
      }
      else {
        nativecast(iovec, $ptr);
      }
    }
    else {
      fail "Index out of range"
    }
  }

  #| Get the list of iovecs
  method list(iovecs:D: --> List) {
    return (do for ^self.elems {
      self.AT-POS($_);
    }).list;
  }

  #| Free all contained iovecs and the iovecs object itself
  method free returns Nil {
    my $ptr = nativecast(Pointer[size_t], self);
    for ^self.elems {
      nativecast(iovec, $ptr).free if $ptr.deref != 0;
      $ptr .= add(2);
    }
    free(nativecast(Pointer, self));
    Nil
  }
}

=begin pod

=head1 AUTHOR

Travis Gibson <TGib.Travis@protonmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Travis Gibson

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
