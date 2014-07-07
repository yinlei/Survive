local Avatar = require "script/avatar"
local Que = require "script/queue"
local MapConfig = require "script/mapconfig"

local map = {
	maptype,
	mapid,
	astar,
	aoi,
	avatars,
	freeidx,
	plycount,      --地图上玩家的数量
	movingavatar,  --有移动请求的avatar
	movtimer,      --移动处理定时器
}

function map:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function map:init(mapid,maptype)
	self.mapid = mapid
	self.maptype = maptype
	self.freeidx = Que.Queue()
	for i=1,65535 do
		self.freeidx:push({v=i,__next=nil})
	end
	
	local mapdef = MapConfig.GetDefByType(maptype)	
	self.astar = mapdef.astar
	--管理格边长,标准视距,左上角x,左上角y,右下角x,右下角y	
	self.aoi = GameApp.create_aoimap(mapdef.gridlength,
			   mapdef.radius,mapdef.toleft[1],mapdef.toleft[2],mapdef.bottomright[1],mapdef.bottomright[2])
	local m = self
	--注册定时器
	self.movtimer = C.reg_timer(100,{on_timeout = function (_)
										m:process_mov()
										return 1				
									 end})
	return self
end

local function read_player_from_rpk(rpk)
	
end

function map:entermap(rpk)
	local plys = read_player_from_rpk(rpk)
	if self.freeidx:len() < #plys then
		--没有足够的id创建玩家avatar
		return nil
	else
		local gameids = {}
		for _,v in pairs(plys) do
			--TODO 根据信息创建avatar
		end
		
		--通告group进入地图请求完成 
		return gameids
	end
end

function map:leavemap(plyid)
	local ply = self.avatars[plyid]
	if ply and ply.avattype == Avatar.type_player then
		--处理离开地图
		return true
	end
	return false
end

function map:findpath(from,to)
	return GameApp.findpath(self.astar,from[1],from[2],to[1],to[2])
end

--将avatar添加到移动处理列表中
function map:beginMov(avatar)
	if not self.movingavatar[avatar.id] then
		self.movingavatar[avatar.id] = avatar
	end
end

--地图销毁之前的清理操作
function map:clear()
	GameApp.destroy_aoimap(self.aoi)
	C.del_timer(self.movtimer)
end

--处理本地图上的对象移动请求
function map:process_mov()
	local stops = {}
	for k,v in pairs(self.movingavatar) do
		if v:process_mov() then
			table.insert(stops,k)
		end
	end
	
	for k,v in pairs(stops) do
		self.movingavatar[v] = nil
	end
end 

return {
	NewMap = function (mapid,maptype) return map:new():init(mapid,maptype) end,
}
