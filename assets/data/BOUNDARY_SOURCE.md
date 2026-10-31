# Administrative boundary source

Source: https://geojson.cn/data/atlas/china

Pinned version: 1.5.1. The source documentation identifies versions before 1.6.0 as WGS84 (1.6.0 changes to GCJ-02). Native Windows and browser GPS coordinates are interpreted as WGS84, without mixing GCJ-02 coordinates.

Downloaded on 2026-10-29:

- https://geojson.cn/api/china/1.5.1/420000.json — extract feature 420500 宜昌市.
- https://geojson.cn/api/china/1.5.1/510000.json — extract feature 510100 成都市.
- https://geojson.cn/api/china/1.5.1/440000.json — extract feature 440100 广州市.
- https://geojson.cn/api/china/1.5.1/500000.json — all 38 重庆 districts/counties, preserving all polygons and holes.

`boundaries.json` retains coordinates without coordinate transformation or additional simplification. Source geometries are for application checks, not cadastral precision. Only the four supported city areas are included. Game artwork does not represent these actual geometries; these data are used solely for local location inclusion tests.

Extraction script and source downloads are retained at `D:/软件安装位置/Codex/food-guide-build/`.

Quanzhou added 2026-10-30: https://geojson.cn/api/china/1.5.1/350000.json; feature 350500, original WGS84 polygons.

Hangzhou added 2026-10-31: https://geojson.cn/api/china/1.5.1/330000.json; feature 330100, original WGS84 polygons including holes. Source download: `food-guide-build/zhejiang-boundary-source.json`.
