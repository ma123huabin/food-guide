extends Node

## 全局事件总线：用于首页与详情页之间的解耦通信。
## 仅放置真正跨场景的事件信号，不要在总线里写玩法逻辑。

signal request_open_city(city_id: String)
signal request_home
signal city_lit(city_id: String)
