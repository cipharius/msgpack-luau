# MessagePack for Luau

A pure MessagePack binary serialization format implementation in Luau.

# Goals

* Fulfill as much of MessagePack specification, as Luau allows
* Be on par with HttpService's `JSONEncode` and `JSONDecode` performance wise
* Keep code readable as long as it does not get in the way of prior goals

## Usage

Decoding:
```lua
local msgpack = require(path.to.msgpack)
local message = "\x92\xA5hello\xA5world"

print(msgpack.decode(message))
```
## State of project

- [ ] Decoding
  - [x] Nil
    - [ ] Unit test
  - [x] Boolean
    - [ ] Unit test
  - [x] Int
    - [ ] Unit test
  - [x] Float
    - [ ] Unit test
  - [x] String
    - [ ] Unit test
  - [x] ByteArray (binary data)
    - [ ] Unit test
  - [x] Array
    - [ ] Unit test
  - [x] Map (dictionary)
    - [ ] Unit test
  - [x] Extension
    - [ ] Unit test
  - [ ] Timestamp extension
    - [ ] Unit test
- [ ] Encoding
  - [ ] Nil
    - [ ] Unit test
  - [ ] Boolean
    - [ ] Unit test
  - [ ] Int
    - [ ] Unit test
  - [ ] Float
    - [ ] Unit test
  - [ ] String
    - [ ] Unit test
  - [ ] ByteArray (binary data)
    - [ ] Unit test
  - [ ] Array
    - [ ] Unit test
  - [ ] Map (dictionary)
    - [ ] Unit test
  - [ ] Extension
    - [ ] Unit test
  - [ ] Timestamp extension
    - [ ] Unit test
