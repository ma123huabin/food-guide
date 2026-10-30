# Generated art provenance

## travel_covers.png · 城市封面图（2026-10-30）

Tool: built-in image_gen; saved to `assets/art/travel_covers.png`. One 7-column, 3-row raster atlas of 21 square tiles, no gutters, no text or borders. Richly detailed warm painterly Chinese tourism illustrations with recognizable landmarks, nature and architecture, consistent with the travel game cards. Exact row-major order:

1. Quanzhou paired Kaiyuan Temple pagodas; Beijing Temple of Heaven; Shanghai Oriental Pearl and Bund at dusk; Xian Giant Wild Goose Pagoda and city wall; Hangzhou West Lake and Leifeng Pagoda; Suzhou classical garden moon gate; Nanjing Confucius Temple and Qinhuai River.
2. Wuhan Yellow Crane Tower; Changsha Orange Isle stone statue and river; Zhangjiajie sandstone pillars; Guilin Li River karst peaks; Xiamen Gulangyu buildings and sea; Fuzhou Three Lanes Seven Alleys; Qingdao Zhanqiao pavilion and sea.
3. Dalian Xinghai Square sea bridge; Harbin Saint Sophia Cathedral in snow; Kunming Green Lake red gulls; Dali Three Pagodas and Cangshan; Lijiang old town and Jade Dragon mountain; Sanya palms and beach; Luoyang Longmen Grottoes.

The atlas is for `cover_image`, used only by big cards and collected thumbnails. It is never a fallback for the separate `flat_map_image` used on the detail page. Runtime atlas columns/rows/index are maintained in `assets/data/cities.json`.

Tool: built-in `image_gen.imagegen`, opaque backgrounds. All three final images are copied into this project's `assets/art/` and referenced from Godot. Reference direction: supplied 首页.png / 详情页.jpeg layouts, green Chinese regional food map and Yichang watercolor map. Original files are retained in `img/`.

## cities.png

Use case: illustration-story. Asset type: a single 2x2 atlas of four Chinese city travel card illustrations for a 2D food exploration game. Perfectly equal four square quadrants with NO gutters, NO text, NO letters, NO watermark, NO card borders. Top left Yichang: turquoise Yangtze river gorge, mountains, Three Gorges dam and riverboat, noodle bowl in foreground. Top right Chengdu: traditional red Chinese street gate, panda, bamboo and modern skyline, hotpot in foreground. Bottom left Chongqing: Hongya Cave illuminated layered architecture over river, arch bridge, red chili hotpot foreground. Bottom right Guangzhou: Canton Tower, Lingnan arcade architecture, river, bamboo dim sum basket foreground. Rich detailed Chinese watercolor gouache illustration on ivory paper, warm gold highlights, jade foliage, delicate ink lines, celebratory travel souvenir aesthetic. Each quadrant one cohesive composition filling the square, architecture centered and food along bottom, visually distinct recognizable city landmarks. High quality finished game art.

## maps.png

Use case: illustration-story. Asset type: one seamless four-panel 2x2 atlas, equal square quadrants, of hand painted city food travel maps for interactive game. No text or lettering anywhere, no symbols that look like text, no pins or red dots (added by game), no watermark. Top left Yichang map: winding blue Yangtze River vertically, mountains at top, dam, river cruise boats, small pagodas, tree lined paths, noodle bowl, dumpling dish and fish pot as tiny vignettes. Top right Chengdu map: winding jade river, Chinese park, traditional red gates and pagodas, panda and bamboo grove, tiny hotpot and noodles. Bottom left Chongqing map: two winding rivers confluence, hill contours, iconic multi tiered red buildings, bridges and cablecar, hotpot dishes. Bottom right Guangzhou map: river islands, slim Canton Tower, Lingnan traditional buildings, arch bridge, dim sum basket and roast duck. Each quadrant is a finished compact bird's eye illustrated MAP on warm ivory parchment, not a landscape perspective. Delicate cream road network with light ochre outlines, watercolor jade greens and turquoise water, miniature recognizable architecture, hand drawn Chinese travel journal aesthetic inspired by finely illustrated regional food maps. Consistent style with readable negative spaces to overlay interactive food pins. Fill each square but keep quiet margins.

## foods.png

A production game asset atlas, perfectly regular 4 by 4 grid of 16 square watercolor Chinese food illustrations, each isolated centrally on warm ivory background with equal generous padding, no text, no lettering, no borders, no shadows crossing cells, no watermark. Read left to right top to bottom. Row 1: chili oil noodle bowl; golden fried radish dumplings on plate; fish hotpot in dark pot; white steamed fish cake slices on plate. Row 2: spicy Sichuan hotpot; bamboo skewers in spicy soup; dandan noodle bowl; wonton bowl. Row 3: Chongqing noodle bowl; nine-compartment spicy hotpot; glass noodles in red sour soup; crispy chili chicken on plate. Row 4: steamed shrimp dumplings in bamboo basket; Cantonese roast duck slices on plate; silky rice noodle rolls on plate; congee bowl. Consistent rich detailed hand painted gouache and watercolor style, appetizing detailed dishes viewed at 45 degrees from above, orange-red chili, jade green garnish, cream porcelain, elegant Chinese travel game illustration. All 16 complete dishes fully inside their cells, exact uniform 4x4 grid.

## 首批城市地图与美食待审核图

使用内置 imagegen 生成北京、上海、西安、杭州地图各一张，并生成每城2×2美食源图集。美食源图集仅按等分格提取为独立文件，没有重绘内容。

新版地图提示词：参考用户提供的泉州地图作为风格，3:2横幅，明亮黄绿色平原、圆润层叠绿山、蓝色河湖、奶油白道路、微缩地标、红色城区标牌、金色景点标签。无大标题、无标题框、无美食插图、无菜名、无页脚。按每城实际的主要山水与地标相对关系绘制。旧版带标题/食物的地图留档为历史版本；新版放在 img/城市美食地图/待审核/。

美食提示词：暖米色背景上的水彩食物插画，45度俯视，正确食材与器皿；2×2等分格，无文字、无边框，依 cities.json 中的四道美食顺序排列。独立图放在 img/美食图片/待审核/。城市、菜名、审核路径见数据表。
