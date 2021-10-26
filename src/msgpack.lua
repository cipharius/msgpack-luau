local MsgPack = {}

local band = bit32.band
local bor = bit32.bor
local lshift = bit32.lshift

local parse
function parse(str, ofs)
  local b = str:byte(ofs + 1, ofs + 1)

  if b == 0xC0 then     -- nil
    return nil, ofs + 1

  elseif b == 0xC2 then -- false
    return false, ofs + 1

  elseif b == 0xC3 then -- true
    return true, ofs + 1

  elseif b == 0xC4 then -- bin 8
    local len = str:byte(ofs + 2)
    return {str:byte(ofs + 3, ofs + 2 + len)}, ofs + 2 + len

  elseif b == 0xC5 then -- bin 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    local len = bor(
      lshift(i0, 8),
      i1
    )

    return {str:byte(ofs + 4, ofs + 3 + len)}, ofs + 3 + len

  elseif b == 0xC6 then -- bin 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    local len = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return {str:byte(ofs + 6, ofs + 5 + len)}, ofs + 5 + len

  elseif b == 0xC7 then -- ext 8
    local len = str:byte(ofs + 2)
    return {
      type = str:byte(ofs + 3),
      data = str:sub(ofs + 4, ofs + 3 + len)
    }, ofs + 3 + len

  elseif b == 0xC8 then -- ext 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    local len = bor(
      lshift(i0, 8),
      i1
    )

    return {
      type = str:byte(ofs + 4),
      data = str:sub(ofs + 5, ofs + 4 + len)
    }, ofs + 4 + len

  elseif b == 0xC9 then -- ext 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    local len = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return {
      type = str:byte(ofs + 6),
      data = str:sub(ofs + 7, ofs + 6 + len)
    }, ofs + 6 + len

  elseif b == 0xCA then -- float 32
    error("Stub")

  elseif b == 0xCB then -- float 64
    error("Stub")

  elseif b == 0xCC then -- uint 8
    return str:byte(ofs + 2), ofs + 2

  elseif b == 0xCD then -- uint 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    return bor(
      lshift(i0, 8),
      i1
    ), ofs + 3

  elseif b == 0xCE then -- uint 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    return bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    ), ofs + 5

  elseif b == 0xCF then -- uint 64
    error("Luau does not support uint 64")

  elseif b == 0xD0 then -- int 8
    local i = str:byte(ofs + 2)
    if i <= 127 then
      return i, ofs + 2
    else
      return i - 256, ofs + 2
    end

  elseif b == 0xD1 then -- int 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    local i = bor(
      lshift(i0, 8),
      i1
    )

    if i0 <= 127 then
      return i, ofs + 3
    else
      return i - 65536, ofs + 3
    end

  elseif b == 0xD2 then -- int 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    local i = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    if i0 <= 127 then
      return i, ofs + 5
    else
      return i - 2147483648, ofs + 5
    end

  elseif b == 0xD3 then -- int 64
    error("Roblox does not support int 64")

  elseif b == 0xD4 then -- fixext 1
    return {
      type = str:byte(ofs + 2),
      data = str:sub(ofs + 3, ofs + 3)
    }, ofs + 3

  elseif b == 0xD5 then -- fixext 2
    return {
      type = str:byte(ofs + 2),
      data = str:sub(ofs + 3, ofs + 4)
    }, ofs + 4

  elseif b == 0xD6 then -- fixext 4
    return {
      type = str:byte(ofs + 2),
      data = str:sub(ofs + 3, ofs + 6)
    }, ofs + 6

  elseif b == 0xD7 then -- fixext 8
    return {
      type = str:byte(ofs + 2),
      data = str:sub(ofs + 3, ofs + 10)
    }, ofs + 10

  elseif b == 0xD8 then -- fixext 16
    return {
      type = str:byte(ofs + 2),
      data = str:sub(ofs + 3, ofs + 18)
    }, ofs + 18

  elseif b == 0xD9 then -- str 8
    local len = str:byte(ofs + 2)
    return str:sub(ofs + 3, ofs + 2 + len), ofs + 2 + len

  elseif b == 0xDA then -- str 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    local len = bor(
      lshift(i0, 8),
      i1
    )

    return str:sub(ofs + 4, ofs + 3 + len), ofs + 3 + len

  elseif b == 0xDB then -- str 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    local len = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )

    return str:sub(ofs + 6, ofs + 5 + len), ofs + 5 + len

  elseif b == 0xDC then -- array 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    local len = bor(
      lshift(i0, 8),
      i1
    )
    local t = table.create(len)
    local newOfs = ofs + 3

    for i=1,len do
      t[i], newOfs = parse(str, newOfs)
    end

    return t, newOfs

  elseif b == 0xDD then -- array 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    local len = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )
    local t = table.create(len)
    local newOfs = ofs + 5

    for i=1,len do
      t[i], newOfs = parse(str, newOfs)
    end

    return t, newOfs

  elseif b == 0xDE then -- map 16
    local i0, i1 = str:byte(ofs + 2, ofs + 3)
    local len = bor(
      lshift(i0, 8),
      i1
    )
    local t = {}
    local newOfs = ofs + 3
    local key

    for _=1,len do
      key, newOfs = parse(str, newOfs)
      t[key], newOfs = parse(str, newOfs)
    end

    return t, newOfs

  elseif b == 0xDF then -- map 32
    local i0, i1, i2, i3 = str:byte(ofs + 2, ofs + 5)
    local len = bor(
      lshift(i0, 24),
      lshift(i1, 16),
      lshift(i2, 8),
      i3
    )
    local t = {}
    local newOfs = ofs + 5
    local key

    for _=1,len do
      key, newOfs = parse(str, newOfs)
      t[key], newOfs = parse(str, newOfs)
    end

    return t, newOfs

  elseif b >= 0xE0 then -- negative fixint
    return 223 - b, ofs + 1

  elseif b <= 0x7F then -- positive fixint
    return b, ofs + 1

  elseif b - 0x80 <= 0x8F - 0x80 then -- fixmap
    local len = band(b, 0xF)
    local t = {}
    local newOfs = ofs + 1
    local key

    for _=1,len do
      key, newOfs = parse(str, newOfs)
      t[key], newOfs = parse(str, newOfs)
    end

    return t, newOfs

  elseif b - 0x90 <= 0x9F - 0x90 then -- fixarray
    local len = band(b, 0xF)
    local t = table.create(len)
    local newOfs = ofs + 1

    for i=1,len do
      t[i], newOfs = parse(str, newOfs)
    end

    return t, newOfs

  elseif b - 0xA0 <= 0xBF - 0xA0 then -- fixstr
    local len = b - 0xA0
    return str:sub(ofs + 2, ofs + 1 + len), ofs + 1 + len

  end
end

function MsgPack.decode(str)
  if str == "" then return end
  return (parse(str, 0))
end

function MsgPack.encode(t)
  error("Stub")
end

return MsgPack
