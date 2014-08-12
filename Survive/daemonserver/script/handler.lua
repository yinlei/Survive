local Gate = require "script/gate"
local Game = require "script/game"
local Dbmgr = require "script/dbmgr"
local Player = require "script/player"
local Rpc = require "script/rpc"

local forbidwords = {}
table.insert(forbidwords,"共产党")

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
	Player.RegHandler()
	Rpc.RegHandler()
	--C.initwordfilter(forbidwords)
	return Dbmgr.Init(dbconfig)
end


