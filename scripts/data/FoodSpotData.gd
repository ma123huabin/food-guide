class_name FoodSpotData
extends Resource

## 城市地图上的美食点（红点标记）。

@export var name: String = ""          # 美食点名称
@export var district: String = ""       # 所属街区
@export var pos_x: float = 0.5         # 在地图上的归一化坐标 0..1
@export var pos_y: float = 0.5
@export var desc: String = ""          # 一句话简介
