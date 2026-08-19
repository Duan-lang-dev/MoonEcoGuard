// Minimal wasm-gc file I/O compatibility layer for MoonEcoGuard CLI.
//
// It uses the same moonrun host imports as moonbitlang/x/fs, but keeps this
// project self-contained so CI does not depend on resolving moonbitlang/x from
// the registry.

///|
pub(all) suberror IOError {
  IOError(String)
} derive(Debug)

///|
#external
priv type XStringCreateHandle

///|
#external
priv type XStringReadHandle

///|
#external
priv type XExternString

///|
#external
priv type XByteArrayCreateHandle

///|
#external
priv type XByteArrayReadHandle

///|
#external
priv type XExternByteArray

///|
fn begin_create_string() -> XStringCreateHandle = "__moonbit_fs_unstable" "begin_create_string"

///|
fn string_append_char(handle : XStringCreateHandle, ch : Char) = "__moonbit_fs_unstable" "string_append_char"

///|
fn finish_create_string(handle : XStringCreateHandle) -> XExternString = "__moonbit_fs_unstable" "finish_create_string"

///|
fn begin_read_string(s : XExternString) -> XStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///|
fn string_read_char(handle : XStringReadHandle) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
fn finish_read_string(handle : XStringReadHandle) = "__moonbit_fs_unstable" "finish_read_string"

///|
fn begin_read_byte_array(s : XExternByteArray) -> XByteArrayReadHandle = "__moonbit_fs_unstable" "begin_read_byte_array"

///|
fn byte_array_read_byte(handle : XByteArrayReadHandle) -> Int = "__moonbit_fs_unstable" "byte_array_read_byte"

///|
fn finish_read_byte_array(handle : XByteArrayReadHandle) = "__moonbit_fs_unstable" "finish_read_byte_array"

///|
fn begin_create_byte_array() -> XByteArrayCreateHandle = "__moonbit_fs_unstable" "begin_create_byte_array"

///|
fn byte_array_append_byte(handle : XByteArrayCreateHandle, ch : Int) = "__moonbit_fs_unstable" "byte_array_append_byte"

///|
fn finish_create_byte_array(
  handle : XByteArrayCreateHandle,
) -> XExternByteArray = "__moonbit_fs_unstable" "finish_create_byte_array"

///|
fn get_error_message_ffi() -> XExternString = "__moonbit_fs_unstable" "get_error_message"

///|
fn get_file_content_ffi() -> XExternByteArray = "__moonbit_fs_unstable" "get_file_content"

///|
fn read_file_to_bytes_ffi(path : XExternString) -> Int = "__moonbit_fs_unstable" "read_file_to_bytes_new"

///|
fn write_bytes_to_file_ffi(
  path : XExternString,
  content : XExternByteArray,
) -> Int = "__moonbit_fs_unstable" "write_bytes_to_file_new"

///|
fn string_to_extern(s : String) -> XExternString {
  let handle = begin_create_string()
  for i = 0; i < s.length(); i = i + 1 {
    string_append_char(handle, UInt16::unsafe_to_char(s.code_unit_at(i)))
  }
  finish_create_string(handle)
}

///|
fn string_from_extern(e : XExternString) -> String {
  let buf = StringBuilder::new()
  let handle = begin_read_string(e)
  while true {
    let ch = string_read_char(handle)
    if ch == -1 {
      break
    } else {
      buf.write_char(Int::unsafe_to_char(ch))
    }
  }
  finish_read_string(handle)
  buf.to_string()
}

///|
fn byte_array_to_extern(s : Bytes) -> XExternByteArray {
  let handle = begin_create_byte_array()
  for i = 0; i < s.length(); i = i + 1 {
    byte_array_append_byte(handle, s[i].to_int())
  }
  finish_create_byte_array(handle)
}

///|
fn byte_array_from_extern(e : XExternByteArray) -> Bytes {
  let buf : Array[Byte] = []
  let handle = begin_read_byte_array(e)
  while true {
    let ch = byte_array_read_byte(handle)
    if ch == -1 {
      break
    } else {
      buf.push(ch.to_byte())
    }
  }
  finish_read_byte_array(handle)
  Bytes::from_array(buf)
}

///|
fn utf16_pair_to_codepoint(high : Int, low : Int) -> Int {
  ((high - 0xD800) << 10) + (low - 0xDC00) + 0x10000
}

///|
fn mbt_string_to_utf8_bytes(str : String) -> Bytes {
  let res : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str.code_unit_at(i).to_int()
    if c >= 0xD800 && c <= 0xDBFF && i + 1 < len {
      i = i + 1
      c = utf16_pair_to_codepoint(c, str.code_unit_at(i).to_int())
    }
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xC0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3F)).to_byte())
    } else if c < 0x10000 {
      res.push((0xE0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3F)).to_byte())
      res.push((0x80 + (c & 0x3F)).to_byte())
    } else {
      res.push((0xF0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3F)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3F)).to_byte())
      res.push((0x80 + (c & 0x3F)).to_byte())
    }
    i = i + 1
  }
  Bytes::from_array(res)
}

///|
fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String {
  let res : Array[Char] = []
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    if c < 0x80 {
      res.push(Int::unsafe_to_char(c))
      i = i + 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.push(Int::unsafe_to_char(c))
      i = i + 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.push(Int::unsafe_to_char(c))
      i = i + 3
    } else {
      if i + 3 >= len {
        break
      }
      c = ((c & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3F) << 12) |
        ((bytes[i + 2].to_int() & 0x3F) << 6) |
        (bytes[i + 3].to_int() & 0x3F)
      c = c - 0x10000
      res.push(Int::unsafe_to_char((c >> 10) + 0xD800))
      res.push(Int::unsafe_to_char((c & 0x3FF) + 0xDC00))
      i = i + 4
    }
  }
  String::from_array(res)
}

///|
fn get_error_message() -> String {
  string_from_extern(get_error_message_ffi())
}

///|
pub fn read_file_to_bytes(path : String) -> Bytes raise IOError {
  let res = read_file_to_bytes_ffi(string_to_extern(path))
  guard res != -1 else { raise IOError(get_error_message()) }
  byte_array_from_extern(get_file_content_ffi())
}

///|
pub fn read_file_to_string(
  path : String,
  encoding? : String = "utf8",
) -> String raise IOError {
  guard encoding == "utf8" else {
    raise IOError("Unsupported encoding: " + encoding)
  }
  utf8_bytes_to_mbt_string(read_file_to_bytes(path))
}

///|
pub fn write_bytes_to_file(
  path : String,
  content : Bytes,
) -> Unit raise IOError {
  let res = write_bytes_to_file_ffi(
    string_to_extern(path),
    byte_array_to_extern(content),
  )
  guard res != -1 else { raise IOError(get_error_message()) }
}

///|
pub fn write_string_to_file(
  path : String,
  content : String,
  encoding? : String = "utf8",
) -> Unit raise IOError {
  guard encoding == "utf8" else {
    raise IOError("Unsupported encoding: " + encoding)
  }
  write_bytes_to_file(path, mbt_string_to_utf8_bytes(content))
}
