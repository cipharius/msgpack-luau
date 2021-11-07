--!strict
local msgpack = {}

local band = bit32.band
local bor = bit32.bor
local lshift = bit32.lshift
local extract = bit32.extract
local ldexp = math.ldexp
local frexp = math.frexp
local floor = math.floor
local modf = math.modf
local sign = math.sign
local sbyte = string.byte
local ssub = string.sub
local char = string.char
local concat = table.concat

local function parse(message: string, offset: number): (any, number)
  local byte = sbyte(message, offset + 1, offset + 1)

  if byte == 0xC0 then     -- nil
    return nil, offset + 1

  elseif byte == 0xC2 then -- false
    return false, offset + 1

  elseif byte == 0xC3 then -- true
    return true, offset + 1

  elseif byte == 0xC4 then -- bin 8
    local length = sbyte(message, offset + 2)
    return msgpack.ByteArray.new(ssub(message, offset + 3, offset + 2 + length)),
           offset + 2 + length

  elseif byte == 0xC5 then -- bin 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )

    return msgpack.ByteArray.new(ssub(message, offset + 4, offset + 3 + length)),
           offset + 3 + length

  elseif byte == 0xC6 then -- bin 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return msgpack.ByteArray.new(ssub(message, offset + 6, offset + 5 + length)),
           offset + 5 + length

  elseif byte == 0xC7 then -- ext 8
    local length = sbyte(message, offset + 2)
    return msgpack.Extension.new(
             sbyte(message, offset + 3),
             ssub(message, offset + 4, offset + 3 + length)
           ),
           offset + 3 + length

  elseif byte == 0xC8 then -- ext 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )

    return msgpack.Extension.new(
             sbyte(message, offset + 4),
             ssub(message, offset + 5, offset + 4 + length)
           ),
           offset + 4 + length

  elseif byte == 0xC9 then -- ext 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return msgpack.Extension.new(
             sbyte(message, offset + 6),
             ssub(message, offset + 7, offset + 6 + length)
           ),
           offset + 6 + length

  elseif byte == 0xCA then -- float 32
    local f0,f1,f2,f3 = sbyte(message, offset + 2, offset + 5)
    local f = bor(
      lshift(f0, 24),
      lshift(f1, 16),
      lshift(f2, 8),
      f3
    )

    local mantissa = band(f, 0x007FFFFF)
    local exponent = extract(f, 23, 8)
    local sign = 1 - 2 * extract(f, 31)
    if exponent == 0xFF then
      if mantissa == 0 then
        return sign * math.huge, offset + 5
      else
        return 0 / 0, offset + 5
      end
    elseif exponent == 0 then
      if mantissa == 0 then
        return 0, offset + 5
      else
        return ldexp(sign * mantissa / 0x800000, -126),
               offset + 5
      end
    end

    mantissa = (mantissa / 0x800000) + 1

    return ldexp(sign * mantissa, exponent - 127 ),
           offset + 5

  elseif byte == 0xCB then -- float 64
    local f0,f1,f2,f3,f4,f5,f6,f7 = sbyte(message, offset + 2, offset + 9)
    local fA = bor(
      lshift(f0, 24),
      lshift(f1, 16),
      lshift(f2, 8),
      f3
    )
    local fB = bor(
      lshift(f4, 24),
      lshift(f5, 16),
      lshift(f6, 8),
      f7
    )

    local mantissa = band(fA, 0x000FFFFF) * 0x100000000 + fB
    local exponent = extract(fA, 20, 11)
    local sign = 1 - 2 * extract(fA, 31)
    if exponent == 0x7FF then
      if mantissa == 0 then
        return sign * math.huge, offset + 9
      else
        return 0 / 0, offset + 9
      end
    elseif exponent == 0 then
      if mantissa == 0 then
        return 0, offset + 9
      else
        return ldexp(sign * mantissa / 0x10000000000000, exponent - 1022 ),
               offset + 9
      end
    end

    mantissa = (mantissa / 0x10000000000000) + 1

    return ldexp(sign * mantissa, exponent - 1023 ),
           offset + 9

  elseif byte == 0xCC then -- uint 8
    return sbyte(message, offset + 2),
           offset + 2

  elseif byte == 0xCD then -- uint 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    return bor(lshift(i0, 8), i1),
           offset + 3

  elseif byte == 0xCE then -- uint 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    return bor(lshift(i0, 24), lshift(i1, 16), lshift(i2, 8), i3),
           offset + 5

  elseif byte == 0xCF then -- uint 64
    local i0,i1,i2,i3,i4,i5,i6,i7 = sbyte(message, offset + 2, offset + 97)
    return msgpack.UInt64.new(
             bor(lshift(i0, 24), lshift(i1, 16), lshift(i2, 8), i3),
             bor(lshift(i4, 24), lshift(i5, 16), lshift(i6, 8), i7)
           ),
           offset + 9

  elseif byte == 0xD0 then -- int 8
    local i = sbyte(message, offset + 2)
    if i <= 127 then
      return i, offset + 2
    else
      return i - 0x100, offset + 2
    end

  elseif byte == 0xD1 then -- int 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    local i = bor(
      lshift(i0, 8),
      i1
    )

    if i0 <= 127 then
      return i, offset + 3
    else
      return i - 0x10000, offset + 3
    end

  elseif byte == 0xD2 then -- int 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    local i = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    if i0 <= 127 then
      return i, offset + 5
    else
      return i - 0x100000000, offset + 5
    end

  elseif byte == 0xD3 then -- int 64
    local i0,i1,i2,i3,i4,i5,i6,i7 = sbyte(message, offset + 2, offset + 9)
    return msgpack.Int64.new(
             bor(lshift(i0, 24), lshift(i1, 16), lshift(i2, 8), i3),
             bor(lshift(i4, 24), lshift(i5, 16), lshift(i6, 8), i7)
           ), offset + 9

  elseif byte == 0xD4 then -- fixext 1
    return msgpack.Extension.new(
             sbyte(message, offset + 2),
             ssub(message, offset + 3, offset + 3)
           ),
           offset + 3

  elseif byte == 0xD5 then -- fixext 2
    return msgpack.Extension.new(
             sbyte(message, offset + 2),
             ssub(message, offset + 3, offset + 4)
           ),
           offset + 4

  elseif byte == 0xD6 then -- fixext 4
    return msgpack.Extension.new(
             sbyte(message, offset + 2),
             ssub(message, offset + 3, offset + 6)
           ),
           offset + 6

  elseif byte == 0xD7 then -- fixext 8
    return msgpack.Extension.new(
             sbyte(message, offset + 2),
             ssub(message, offset + 3, offset + 10)
           ),
           offset + 10

  elseif byte == 0xD8 then -- fixext 16
    return msgpack.Extension.new(
             sbyte(message, offset + 2),
             ssub(message, offset + 3, offset + 18)
           ),
           offset + 18

  elseif byte == 0xD9 then -- str 8
    local length = sbyte(message, offset + 2)
    return ssub(message, offset + 3, offset + 2 + length),
           offset + 2 + length

  elseif byte == 0xDA then -- str 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )

    return ssub(message, offset + 4, offset + 3 + length),
           offset + 3 + length

  elseif byte == 0xDB then -- str 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return ssub(message, offset + 6, offset + 5 + length),
           offset + 5 + length

  elseif byte == 0xDC then -- array 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )
    local array = table.create(length)
    local newOffset = offset + 3

    for i=1,length do
      array[i], newOffset = parse(message, newOffset)
    end

    return array, newOffset

  elseif byte == 0xDD then -- array 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )
    local array = table.create(length)
    local newOffset = offset + 5

    for i=1,length do
      array[i], newOffset = parse(message, newOffset)
    end

    return array, newOffset

  elseif byte == 0xDE then -- map 16
    local i0,i1 = sbyte(message, offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )
    local dictionary = {}
    local newOffset = offset + 3
    local key

    for _=1,length do
      key, newOffset = parse(message, newOffset)
      dictionary[key], newOffset = parse(message, newOffset)
    end

    return dictionary, newOffset

  elseif byte == 0xDF then -- map 32
    local i0,i1,i2,i3 = sbyte(message, offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )
    local dictionary = {}
    local newOffset = offset + 5
    local key

    for _=1,length do
      key, newOffset = parse(message, newOffset)
      dictionary[key], newOffset = parse(message, newOffset)
    end

    return dictionary, newOffset

  elseif byte >= 0xE0 then -- negative fixint
    return byte - 256, offset + 1

  elseif byte <= 0x7F then -- positive fixint
    return byte, offset + 1

  elseif byte - 0x80 <= 0x8F - 0x80 then -- fixmap
    local length = band(byte, 0xF)
    local dictionary = {}
    local newOffset = offset + 1
    local key

    for _=1,length do
      key, newOffset = parse(message, newOffset)
      dictionary[key], newOffset = parse(message, newOffset)
    end

    return dictionary, newOffset

  elseif byte - 0x90 <= 0x9F - 0x90 then -- fixarray
    local length = band(byte, 0xF)
    local array = table.create(length)
    local newOffset = offset + 1

    for i=1,length do
      array[i], newOffset = parse(message, newOffset)
    end

    return array, newOffset

  elseif byte - 0xA0 <= 0xBF - 0xA0 then -- fixstr
    local length = byte - 0xA0
    return ssub(message, offset + 2, offset + 1 + length),
           offset + 1 + length

  end

  error("Not all decoder cases are handled")
end

local function encode(data: any): string
  if data == nil then
    return "\xC0"
  elseif data == false then
    return "\xC2"
  elseif data == true then
    return "\xC3"
  elseif type(data) == "string" then
    local length = #data

    if length <= 31 then
      return char(bor(0xA0, length)) .. data
    elseif length <= 0xFF then
      return "\xD9" .. char(length) .. data
    elseif length <= 0xFFFF then
      return concat({
        "\xDA",
        char(extract(length, 8, 8)),
        char(extract(length, 0, 8)),
        data
      })
    elseif length <= 0xFFFFFFFF then
      return concat({
        "\xDB",
        char(extract(length, 24, 8)),
        char(extract(length, 16, 8)),
        char(extract(length, 8, 8)),
        char(extract(length, 0, 8)),
        data
      })
    end

    error("Too long string")

  elseif type(data) == "number" then
    -- represents NaN, Inf, -Inf as float 32 to save space
    if data == 0 then
      return "\x00"
    elseif data ~= data then -- NaN
      return "\xCA\x7F\x80\x00\x01"
    elseif data == math.huge then
      return "\xCA\x7F\x80\x00\x00"
    elseif data == -math.huge then
      return "\xCA\xFF\x80\x00\x00"
    end

    local integral, fractional = modf(data)
    local sign = sign(data)
    if fractional == 0 then
      if sign > 0 then
        if integral <= 127 then -- positive fixint
          return char(integral)
        elseif integral <= 0xFF then -- uint 8
          return "\xCC" .. char(integral)
        elseif integral <= 0xFFFF then -- uint 16
          return concat({
            "\xCD",
            char(extract(integral, 8, 8)),
            char(extract(integral, 0, 8))
          })
        elseif integral <= 0xFFFFFFFF then -- uint 32
          return concat({
            "\xCE",
            char(extract(integral, 24, 8)),
            char(extract(integral, 16, 8)),
            char(extract(integral, 8, 8)),
            char(extract(integral, 0, 8))
          })
        end
      else
        if integral >= -0x20 then -- negative fixint
          return char(bor(0xE0, extract(integral, 0, 5)))
        elseif integral >= -0x80 then -- int 8
          return "\xD0" .. char(extract(integral, 0, 8))
        elseif integral >= -0x8000 then -- int 16
          return concat({
            "\xD1",
            char(extract(integral, 8, 8)),
            char(extract(integral, 0, 8))
          })
        elseif integral >= -0x80000000 then -- int 32
          return concat({
            "\xD2",
            char(extract(integral, 24, 8)),
            char(extract(integral, 16, 8)),
            char(extract(integral, 8, 8)),
            char(extract(integral, 0, 8))
          })
        end
      end
    end

    -- float 64
    local mantissa, exponent = frexp(sign * data)
    exponent = exponent - 1 + 1023
    local mostSignificantPart, leastSignificantPart = modf(2*(mantissa - 0.5) * 0x1000000)
    leastSignificantPart = floor(leastSignificantPart * 0x10000000)

    return concat({
      "\xCB",
      char(bor(
        lshift((1 - sign)/2, 7),
        extract(exponent, 4, 7)
      )),
      char(bor(
        lshift(extract(exponent, 0, 4), 4),
        extract(mostSignificantPart, 20, 4)
      )),
      char(extract(mostSignificantPart, 12, 8)),
      char(extract(mostSignificantPart, 4, 8)),
      char(bor(
        lshift(extract(mostSignificantPart, 0, 4), 4),
        extract(leastSignificantPart, 24, 4)
      )),
      char(extract(leastSignificantPart, 16, 8)),
      char(extract(leastSignificantPart, 8, 8)),
      char(extract(leastSignificantPart, 0, 8))
    })

  elseif type(data) == "table" then
    local msgpackType = data._msgpackType

    if msgpackType then
      if msgpackType == msgpack.Int64 or msgpackType == msgpack.UInt64 then
        local mostSignificantPart = data.mostSignificantPart
        local leastSignificantPart = data.leastSignificantPart
        return concat({
          if msgpackType == msgpack.UInt64 then "\xCF" else "\xD3",
          char(extract(mostSignificantPart, 24, 8)),
          char(extract(mostSignificantPart, 16, 8)),
          char(extract(mostSignificantPart, 8, 8)),
          char(extract(mostSignificantPart, 0, 8)),
          char(extract(leastSignificantPart, 24, 8)),
          char(extract(leastSignificantPart, 16, 8)),
          char(extract(leastSignificantPart, 8, 8)),
          char(extract(leastSignificantPart, 0, 8)),
        })
      elseif msgpackType == msgpack.Extension then
        local extensionData = data.data
        local extensionType = data.type
        local length = #extensionData

        if length == 1 then
          return "\xD4" .. char(extensionType) .. extensionData
        elseif length == 2 then
          return "\xD5" .. char(extensionType) .. extensionData
        elseif length == 4 then
          return "\xD6" .. char(extensionType) .. extensionData
        elseif length == 8 then
          return "\xD7" .. char(extensionType) .. extensionData
        elseif length == 16 then
          return "\xD8" .. char(extensionType) .. extensionData
        elseif length <= 0xFF then
          return "\xC7" .. char(length)  .. char(extensionType) .. extensionData
        elseif length <= 0xFFFF then
          return concat({
            "\xC8",
            char(extract(length, 8, 8)),
            char(extract(length, 0, 8)),
            char(extensionType),
            extensionData
          })
        elseif length <= 0xFFFFFFFF then
          return concat({
            "\xC9",
            char(extract(length, 24, 8)),
            char(extract(length, 16, 8)),
            char(extract(length, 8, 8)),
            char(extract(length, 0, 8)),
            char(extensionType),
            extensionData
          })
        end

        error("Too long extension data")
      elseif msgpackType == msgpack.ByteArray then
        data = data.data
        local length = #data

        if length <= 0xFF then
          return "\xC4" .. char(length) .. data
        elseif length <= 0xFFFF then
          return concat({
            "\xC5",
            char(extract(length, 8, 8)),
            char(extract(length, 0, 8)),
            data
          })
        elseif length <= 0xFFFFFFFF then
          return concat({
            "\xC6",
            char(extract(length, 24, 8)),
            char(extract(length, 16, 8)),
            char(extract(length, 8, 8)),
            char(extract(length, 0, 8)),
            data
          })
        end

        error("Too long BinaryArray")
      end
    end

    local length = #data
    local encodedValues = table.create(length)
    local mapLength = 0

    for i,value in pairs(data) do
      encodedValues[i] = encode(value)
      mapLength += 1
    end

    if length == mapLength then -- array
      if length <= 15 then
        return char(bor(0x90, length)) .. concat(encodedValues)
      elseif length <= 0xFFFF then
        return concat({
          "\xDC",
          char(extract(length, 8, 8)),
          char(extract(length, 0, 8)),
          concat(encodedValues)
        })
      elseif length <= 0xFFFFFFFF then
        return concat({
          "\xDD",
          char(extract(length, 24, 8)),
          char(extract(length, 16, 8)),
          char(extract(length, 8, 8)),
          char(extract(length, 0, 8)),
          concat(encodedValues)
        })
      end

      error("Too long array")

    else -- map
      local encodedMap = table.create(2*mapLength)

      local i = 1
      for key,value in pairs(encodedValues) do
        encodedMap[i] = encode(key)
        encodedMap[i+1] = value
        i += 2
      end

      if mapLength <= 15 then
        return char(bor(0x80, mapLength)) .. concat(encodedMap)
      elseif mapLength <= 0xFFFF then
        return concat({
          "\xDE",
          char(extract(mapLength, 8, 8)),
          char(extract(mapLength, 0, 8)),
          concat(encodedMap)
        })
      elseif mapLength <= 0xFFFFFFFF then
        return concat({
          "\xDF",
          char(extract(mapLength, 24, 8)),
          char(extract(mapLength, 16, 8)),
          char(extract(mapLength, 8, 8)),
          char(extract(mapLength, 0, 8)),
          concat(encodedMap)
        })
      end

      error("Too long map")
    end
  end

  error("Not all encoder cases are handled")
end

msgpack.Int64 = {}

function msgpack.Int64.new(mostSignificantPart: number, leastSignificantPart: number): Int64
  return {
    _msgpackType = msgpack.Int64,
    mostSignificantPart = mostSignificantPart,
    leastSignificantPart = leastSignificantPart
  }
end

msgpack.UInt64 = {}

function msgpack.UInt64.new(mostSignificantPart: number, leastSignificantPart: number): UInt64
  return {
    _msgpackType = msgpack.UInt64,
    mostSignificantPart = mostSignificantPart,
    leastSignificantPart = leastSignificantPart
  }
end

msgpack.ByteArray = {}

function msgpack.ByteArray.new(blob: string): ByteArray
  return {
    _msgpackType = msgpack.ByteArray,
    data = blob
  }
end

msgpack.Extension = {}

function msgpack.Extension.new(extensionType: number, blob: string): Extension
  return {
    _msgpackType = msgpack.Extension,
    type = extensionType,
    data = blob
  }
end

function msgpack.decode(message: string): any
  if message == "" then
    error("Message is too short")
  end
  return (parse(message, 0))
end

function msgpack.encode(data: any): string
  return encode(data)
end

export type Int64     = { _msgpackType: typeof(msgpack.Int64), mostSignificantPart: number, leastSignificantPart: number }
export type UInt64    = { _msgpackType: typeof(msgpack.UInt64), mostSignificantPart: number, leastSignificantPart: number }
export type Extension = { _msgpackType: typeof(msgpack.Extension), type:number, data: string }
export type ByteArray = { _msgpackType: typeof(msgpack.ByteArray), data: string }

return msgpack
