class_name CityData
extends Resource

## 单个城市的静态数据。可作为资源在编辑器中创建，
## 或由 GameData 在运行时通过代码实例化。

## 热门美食与地图美食点类型见 PopularFoodData / FoodSpotData（独立的 class_name 脚本）。

@export var city_id: String = ""
@export var display_name: String = ""
@export var emoji: String = "🏙️"
@export var theme_color: Color = Color("#F5A623")
@export var locked: bool = false
@export var map_texture: Texture2D
@export var center_lat: float = 30.69      # 城市中心纬度（用于定位判定）
@export var center_lng: float = 111.29     # 城市中心经度
@export var radius_km: float = 25.0        # 判定「在市内」的半径
@export var popular_foods: Array[PopularFoodData] = []
@export var food_spots: Array[FoodSpotData] = []
