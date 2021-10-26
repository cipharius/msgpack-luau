local msgpack = {}

local band = bit32.band
local bor = bit32.bor
local lshift = bit32.lshift
local extract = bit32.extract
local ldexp = math.ldexp

local parse
function parse(message, offset)
  local byte = message:byte(offset + 1, offset + 1)

  if byte == 0xC0 then     -- nil
    return nil, offset + 1

  elseif byte == 0xC2 then -- false
    return false, offset + 1

  elseif byte == 0xC3 then -- true
    return true, offset + 1

  elseif byte == 0xC4 then -- bin 8
    local length = message:byte(offset + 2)
    return {message:byte(offset + 3, offset + 2 + length)},
           offset + 2 + length

  elseif byte == 0xC5 then -- bin 16
    local i0,i1 = message:byte(offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )

    return {message:byte(offset + 4, offset + 3 + length)},
           offset + 3 + length

  elseif byte == 0xC6 then -- bin 32
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return {message:byte(offset + 6, offset + 5 + length)},
           offset + 5 + length

  elseif byte == 0xC7 then -- ext 8
    local length = message:byte(offset + 2)
    return {
            type = message:byte(offset + 3),
            data = message:sub(offset + 4, offset + 3 + length)
          },
          offset + 3 + length

  elseif byte == 0xC8 then -- ext 16
    local i0,i1 = message:byte(offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )

    return {
             type = message:byte(offset + 4),
             data = message:sub(offset + 5, offset + 4 + length)
           },
          offset + 4 + length

  elseif byte == 0xC9 then -- ext 32
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return {
             type = message:byte(offset + 6),
             data = message:sub(offset + 7, offset + 6 + length)
           },
           offset + 6 + length

  elseif byte == 0xCA then -- float 32
    local f0,f1,f2,f3 = message:byte(offset + 2, offset + 5)
    local f = bor(
      lshift(f0, 24),
      lshift(f1, 16),
      lshift(f2, 8),
      f3
    )

    local exponent = extract(f, 23, 8)
    local sign = 1 - 2 * extract(f, 31)
    if exponent == 0xFF then -- nan or inf
      if band(f, 0x007FFFFF) == 0 then
        return sign * math.huge, offset + 5 -- +/- inf
      else
        return 0 / 0, offset + 5 -- nan
      end
    end

    local sum = 1
    for i=1,23 do
      sum += ldexp(extract(f, 23 - i), -i)
    end

    return ldexp(sign * sum, exponent - 127 ),
           offset + 5

  elseif byte == 0xCB then -- float 64
    local f0,f1,f2,f3,f4,f5,f6,f7 = message:byte(offset + 2, offset + 9)
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

    local exponent = extract(fA, 20, 11)
    local sign = 1 - 2 * extract(fA, 31)
    if exponent == 0x7FF then -- nan or inf
      if fB == 0 and band(fA, 0x000FFFFF) == 0 then
        return sign * math.huge, offset + 9 -- +/- inf
      else
        return 0 / 0, offset + 9 -- nan
      end
    end

    local sum = 1
    for i=1,52 do
      if i <= 20 then
        sum += ldexp(extract(fA, 20 - i), -i)
      else
        sum += ldexp(extract(fB, 52 - i), -i)
      end
    end

    return ldexp(sign * sum, exponent - 1023 ),
           offset + 9

  elseif byte == 0xCC then -- uint 8
    return message:byte(offset + 2),
           offset + 2

  elseif byte == 0xCD then -- uint 16
    local i0,i1 = message:byte(offset + 2, offset + 3)
    return bor(lshift(i0, 8), i1),
           offset + 3

  elseif byte == 0xCE then -- uint 32
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
    return bor(lshift(i0, 24), lshift(i1, 16), lshift(i2, 8), i3),
           offset + 5

  elseif byte == 0xCF then -- uint 64
    error("Luau does not support uint 64")

  elseif byte == 0xD0 then -- int 8
    local i = message:byte(offset + 2)
    if i <= 127 then
      return i, offset + 2
    else
      return i - 0x100, offset + 2
    end

  elseif byte == 0xD1 then -- int 16
    local i0,i1 = message:byte(offset + 2, offset + 3)
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
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
    local i = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    if i0 <= 127 then
      return i, offset + 5
    else
      return i - 0x80000000, offset + 5
    end

  elseif byte == 0xD3 then -- int 64
    error("Luau does not support int 64")

  elseif byte == 0xD4 then -- fixext 1
    return {
             type = message:byte(offset + 2),
             data = message:sub(offset + 3, offset + 3)
           },
           offset + 3

  elseif byte == 0xD5 then -- fixext 2
    return {
             type = message:byte(offset + 2),
             data = message:sub(offset + 3, offset + 4)
           },
           offset + 4

  elseif byte == 0xD6 then -- fixext 4
    return {
             type = message:byte(offset + 2),
             data = message:sub(offset + 3, offset + 6)
           },
           offset + 6

  elseif byte == 0xD7 then -- fixext 8
    return {
             type = message:byte(offset + 2),
             data = message:sub(offset + 3, offset + 10)
           },
           offset + 10

  elseif byte == 0xD8 then -- fixext 16
    return {
             type = message:byte(offset + 2),
             data = message:sub(offset + 3, offset + 18)
           },
           offset + 18

  elseif byte == 0xD9 then -- str 8
    local length = message:byte(offset + 2)
    return message:sub(offset + 3, offset + 2 + length),
           offset + 2 + length

  elseif byte == 0xDA then -- str 16
    local i0,i1 = message:byte(offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )

    return message:sub(offset + 4, offset + 3 + length),
           offset + 3 + length

  elseif byte == 0xDB then -- str 32
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return message:sub(offset + 6, offset + 5 + length),
           offset + 5 + length

  elseif byte == 0xDC then -- array 16
    local i0,i1 = message:byte(offset + 2, offset + 3)
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
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
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
    local i0,i1 = message:byte(offset + 2, offset + 3)
    local length = bor(
      lshift(i0, 8),
      i1
    )
    local dictionary = {}
    local newOffset = offset + 3
    local key

    for _=1,len do
      key, newOffset = parse(message, newOffset)
      dictionary[key], newOffset = parse(message, newOffset)
    end

    return dictionary, newOffset

  elseif byte == 0xDF then -- map 32
    local i0,i1,i2,i3 = message:byte(offset + 2, offset + 5)
    local length = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )
    local dictionary = {}
    local newOffset = offset + 5
    local key

    for _=1,len do
      key, newOffset = parse(message, newOffset)
      dictionary[key], newOffset = parse(message, newOffset)
    end

    return dictionary, newOffset

  elseif byte >= 0xE0 then -- negative fixint
    return 223 - byte, offset + 1

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
    return message:sub(offset + 2, offset + 1 + length),
           offset + 1 + length

  end
end

function msgpack.decode(message)
  if message == "" then return end
  return (parse(message, 0))
end

function msgpack.encode(data)
  error("Stub")
end

return msgpack
