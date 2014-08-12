local Map = require "script/map"
local Que = require "script/queue"
local Avatar = require "script/avatar"
local Rpc = require "script/rpc"
local Gate = require "script/gate"

local game = {
	maps,
	freeidx,
}

function game_init()
	game.maps = {}
	local que = Que.Queue()
	for i=1,65535 do
		que:push({v=i,__next=nil})
	end
	game.freeidx = que
end


Rpc.RegisterRpcFunction("EnterMap",function (rpcHandle)
	local param = rpcHandle.param
	local mapid = param[1]
	local maptype = param[2]
	local plys = param[3]
	print("EnterMap " .. mapid .. " " .. maptype)
	print(plys)
	local gameids
	--print("EnterMap1")
	if mapid == 0 then
		--创建实例
		mapid = game.freeidx:pop()
		if not mapid then
			--print("EnterMap2")
			--通知group,gameserver繁忙
			Rpc.RPCResponse(rpcHandle,nil,"busy")
		else
			mapid = mapid.v
			--print("EnterMap3")
			--print(mapid)
			--print(maptype)
			--print(plys)
			local map = Map.NewMap(mapid,maptype)
			game.maps[mapid] = map
			gameids = map:entermap(plys)
			if gameids then
				--通知group进入地图失败
				Rpc.RPCResponse(rpcHandle,nil,"failed")
			end
		end
	else
		--print("EnterMap4")
		local map = game.maps[mapid]
		if not map then
			--TODO 通知group错误的mapid(可能实例已经被销毁)
			Rpc.RPCResponse(rpcHandle,nil,"instance not found")
		else
			gameids = map:entermap(plys)
			if not gameids then
				--通知group进入地图失败
				Rpc.RPCResponse(rpcHandle,nil,"failed")
			end
		end
	end
	--将成功进入的mapid返回给调用方
	Rpc.RPCResponse(rpcHandle,{mapid,gameids},nil)	
end)

Rpc.RegisterRpcFunction("LeaveMap",function (rpcHandle)
	local param = rpcHandle.param
	local mapid = param[1]
	local map = game.maps[mapid]
	if map then
		local plyid = rpk_read_uint16(rpk)
		if map:leavemap(plyid) then
			Rpc.RPCResponse(rpcHandle,mapid,nil)
			if map.plycount == 0 then
				--没有玩家了，销毁地图
				map:clear()
				game.que:push({v=mapid,__next=nil})
				game.maps[mapid] = nil				
			end
		else
			Rpc.RPCResponse(rpcHandle,nil,"failed")
		end
	else
		Rpc.RPCResponse(rpcHandle,nil,"failed")
	end	
end)


Rpc.RegisterRpcFunction("CliReConn",function (rpcHandle)
	local param = rpcHandle.param
	local gameid = param[1]
	local mapid,_ = math.floor(gameid/65536)
	local map = game.maps[mapid]
	if map then
		local plyid = math.fmod(gameid,65536)
		local ply = map.avatars[plyid]
		print(plyid)
		if ply and ply.avattype == Avatar.type_player then
			local gate = Gate.GetGateByName(param[2].name)
			if not gate then
				Rpc.RPCResponse(rpcHandle,nil,"failed")
				return
			end
			ply.gate = {conn=gate.conn,id=param[2].id}
			ply:reconn()
			Rpc.RPCResponse(rpcHandle,nil,nil)	
		else
			Rpc.RPCResponse(rpcHandle,nil,"failed")
		end
	
	else
		Rpc.RPCResponse(rpcHandle,nil,"failed")
	end
end)


local game_net_handler = {}

game_net_handler[CMD_CS_MOV] = function (rpk,conn)
	print("CS_MOV")
	local gameid = rpk_reverse_read_uint32(rpk)
	local mapid,_ = math.floor(gameid/65536)
	local map = game.maps[mapid]
	if map then
		print("map:" .. mapid)		
		local plyid = math.fmod(gameid,65536)
		print("ply:" .. plyid)
		local ply = map.avatars[plyid]
		print(ply)
		if ply and ply.avattype == Avatar.type_player then
			local x = rpk_read_uint16(rpk)
			local y = rpk_read_uint16(rpk)
			ply:mov(x,y)
		end
	end
end

game_net_handler[CMD_GGAME_CLIDISCONNECTED] =  function (rpk,conn)
	print("client disconn")
	local gameid = rpk_reverse_read_uint32(rpk)
	local mapid,_ = math.floor(gameid/65536)
	local map = game.maps[mapid]
	--print("mapid:" .. mapid)
	if map then
		local plyid = math.fmod(gameid,65536)
		print("plyid:" .. plyid)
		--map:leavemap(plyid)
		local ply = map.avatars[plyid]
		if ply and ply.avattype == Avatar.type_player then
			ply.gate = nil
		end		
	end	
end


local function reg_cmd_handler()
	game_init()
	C.reg_cmd_handler(CMD_CS_MOV,game_net_handler)
	C.reg_cmd_handler(CMD_GGAME_CLIDISCONNECTED,game_net_handler)	
end

return {
	RegHandler = reg_cmd_handler,
}


