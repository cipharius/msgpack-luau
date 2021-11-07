local msgpack = require(game.ReplicatedStorage.msgpack)

local httpService = game:GetService("HttpService")
local msgpackDecode = msgpack.decode
local msgpackEncode = msgpack.encode

local jsonMessage = require(game.ServerStorage.JsonMessage)
local msgpackMessage = require(game.ServerStorage.MsgpackMessage)

return {

  ParameterGenerator = function() end,

  Functions = {
    ["JSONDecode & JSONEncode"] = function(Profiler)
      httpService:JSONEncode(httpService:JSONDecode(jsonMessage))
    end,

    ["msgpack.decode & msgpack.encode"] = function(Profiler)
      msgpackEncode(msgpackDecode(msgpackMessage))
    end
  }

}
