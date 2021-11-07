# MessagePack for Luau

A pure MessagePack binary serialization format implementation in Luau.

# Goals

* Fulfill as much of MessagePack specification, as Luau allows
* Be on par with HttpService's `JSONEncode` and `JSONDecode` performance wise
* Keep code readable as long as it does not get in the way of prior goals

## Example usage

```lua
local msgpack = require(path.to.msgpack)
local message = msgpack.encode({"hello", "world", 123, key="value"})

print(msgpack.decode(message))
```

## API

* `msgpack.encode(data: any): string`
  Encodes any pure Luau datatype in MessagePack binary string format.
  It does not currently handle any Roblox specific datatypes.

* `msgpack.decode(message: string): any`
  Decodes MessagePack binary string as pure Luau value.

* `msgpack.ByteArray.new(blob: string): msgpack.ByteArray`
  Wraps a string value in order to represent MessagePack `bin` datatype.

* `msgpack.Extension.new(extensionType: number, blob: string): msgpack.Extension`
  Create MessagePack extension type, which is used for custom datatype serialization purposes.
  First argument `extensionType` must be an integer.

* `msgpack.Int64.new(mostSignificantPart: number, leastSignificantPart: number): msgpack.Int64`
  Represents 64-bit signed integer, which is too large to to represent as Luau integer.
  Both arguments must be integers.

* `msgpack.UInt64.new(mostSignificantPart: number, leastSignificantPart: number): msgpack.UInt64`
  Represents 64-bit unsigned integer, which is too large to to represent as Luau integer.
  Both arguments must be integers.

## Performance

One of the project goals is to match or exceed the performance of Roblox offered data serialization and deserialization methods (HttpService's `JSONEncode` and `JSONDecode`).
To ensure fulfilment of this goal the module's methods need to be benchmarked.

To benchmark message decoding performance an approximately 210KB large JSON encoded payload has been chosen.
This JSON is then used as input for `HttpService:JSONEncode()` method and also encoded in MessagePack format so that it can be used as input for `msgpack.decode()` function.
For MessagePack encoding [an online msgpack-lite encoder](https://kawanet.github.io/msgpack-lite/) was used.

As visible in the [boatbomber's benchmarker plugin](https://devforum.roblox.com/t/benchmarker-plugin-compare-function-speeds-with-graphs-percentiles-and-more/829912) results, `msgpack.decode` considerably exceeds `JSONDecode` performance:
![Figure with JSONDecode and msgpack.decode benchmark results](./assets/decode-benchmark.png)

To benchmark module's encoding performance same data is used as previously.
It is first decoded as table structure then both `msgpack.encode` and `JSONEncode` encode it with the following results:
![Figure with JSONEncode and msgpack.encode benchmark results](./assets/encode-benchmark.png)

MessagePack encoder currently slower than JSONEncode, although they remain pretty close.
Here is another benchmark which combines both decoding and encoding steps:
![Figure with "JSONEncode & JSONDecode" and "msgpack.encode & msgpack.decode" benchmark results](./assets/decode-encode-benchmark.png)

For more details on the benchmark setup, look into `./benchmark` directory.
To construct the benchmarking place, the following shell command was used: `rojo build -o benchmark.rbxl benchmark.project.json`

## State of project

Encoding and decoding fully works, extensions are currently not specially treated.
