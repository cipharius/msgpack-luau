return function()
  local msgpack = require(script.Parent.msgpack)

  describe("decode", function()
    it("can decode nil value", function()
      local message = "\xC0"
      expect(msgpack.decode(message)).to.equal(nil)
    end)

    it("can decode false value", function()
      local message = "\xC2"
      expect(msgpack.decode(message)).to.equal(false)
    end)

    it("can decode true value", function()
      local message = "\xC3"
      expect(msgpack.decode(message)).to.equal(true)
    end)
  end)

  describe("encode", function()
  end)
end
