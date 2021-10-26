# MessagePack for Luau (v0.0.1)

A pure MessagePack binary serialization format implementation in Luau.

# Goals

* Fulfill as much of MessagePack specification, as Luau allows
* Be on par with HttpService's `JSONEncode` and `JSONDecode` performance wise
* Keep code readable as long as it does not get in the way of prior goals

## State of project

Currently only decoding is implemented.
Not thoroughly tested.

## Usage

Decoding:
```lua
local msgpack = require(path.to.msgpack)
local message = "\x92\xA5hello\xA5world"

print(msgpack.decode(message))
```
