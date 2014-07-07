local mapdef = {
		[1] = {
			gridlength = 50,          --管理格大小
			toleft = {0,0},           --左上角坐标
			bottomright = {100,100},  --右下角坐标
			radius = 75,              --视距大小
			coli_x = 60,              --寻路地图大小60X60
 			coli_y = 60,
 			coli   = "../map1.coli",   --寻路碰撞文件
 			astar  = nil,
		},
	}


local function init()
	for k,v in ipairs(mapdef) do
		v.astar = GameApp.create_astar(v.coli,v.coli_x,v.coli_y)
	end
end

init()

local function getDefByType(type)
	return mapdef[type]
end

return {
	GetDefByType = GetDefByType,
}
