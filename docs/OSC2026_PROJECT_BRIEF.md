# MoonEcoGuard 项目参赛材料（精简版）

## 1. 项目基本信息

| 项目 | 内容 |
|---|---|
| 项目名称 | MoonEcoGuard |
| 项目方向 | 生态学 + GIS + 数据治理 |
| 开发语言 | MoonBit |
| 项目类型 | CLI 工具 / 生物多样性数据质量检测工具 |
| 仓库地址 | https://github.com/Duan-lang-dev/MoonEcoGuard.git |
| 作者 | Duan-lang-dev |
| 邮箱 | 956327105@qq.com |

## 2. 项目简介

MoonEcoGuard 是一个纯 MoonBit 实现的生物多样性数据治理工具，面向自然保护区、植物园、博物馆和科研调查队。项目聚焦 Darwin Core 风格的野外调查记录，支持 CSV/TSV 导入、字段标准化、生态数据质量检测、基础 GIS 检查、统计报告、GeoJSON/Markdown 导出，以及敏感物种坐标保护。

一句话概括：**MoonEcoGuard 让生态调查数据在公开前更标准、更可信、更安全。**

## 3. 要解决的问题

野外调查数据常以表格形式保存，但实际发布前经常存在以下问题：

- 字段名称不统一，例如“记录编号”“物种名称”“观察时间”和 Darwin Core 字段不一致；
- 经纬度越界、缺失、落在 `0,0`，或疑似经纬度颠倒；
- 日期格式混乱，记录 ID 重复，观察数量异常；
- 物种名称存在空值、拼写错误或属名冲突；
- 濒危植物、珍稀动物等敏感物种不适合公开精确坐标；
- 缺少统一的数据质量报告，难以进入后续 GBIF/IPT 或 GIS 流程。

## 4. 核心功能

### 数据导入与标准化

- 支持 CSV/TSV 物种出现记录导入；
- 支持中文字段和 Darwin Core 风格字段映射；
- 将记录统一转换为内部 occurrence 数据模型。

### 数据质量检测

当前已支持多类规则检查：

- 纬度 `-90..90`、经度 `-180..180` 合法性；
- occurrenceID 缺失与重复；
- ISO 8601 风格日期检查；
- `0,0` 坐标、经纬度疑似反转、调查区域越界；
- 观察数量异常；
- scientificName 为空、属名冲突、常见拼写错误提示；
- 敏感物种仍暴露公开坐标的风险提示。

### 敏感坐标保护

MoonEcoGuard 支持在公开数据前对敏感物种自动处理：

- 坐标降精度；
- 按公里网格模糊化；
- 确定性随机扰动；
- 替换为区域中心点；
- 清理观察者联系方式、巡护路线、内部样点编号等敏感文本。

> 坐标保护只能降低公开数据泄露风险，不能替代专业人员审核和正式的数据发布制度。

### 格式转换与报告

- Markdown 质量报告；
- 数据集统计报告；
- GeoJSON 导出；
- 脱敏 CSV 导出；
- 私有数据与公开数据坐标变化 diff。

## 5. 技术实现

项目采用 MoonBit 多包结构组织：

| 模块 | 作用 |
|---|---|
| `darwincore` | Darwin Core 风格数据模型 |
| `csv_reader` / `ecodata` | CSV/TSV 解析与字段映射 |
| `validation` | 数据质量规则与诊断报告 |
| `geospatial` | 坐标、距离、网格和范围检查 |
| `privacy` | 敏感物种坐标与文本保护 |
| `taxonomy` | 学名格式与拼写辅助检查 |
| `formats` / `statistics` | 报告、GeoJSON、CSV 和统计输出 |
| `cmd/main` | 命令行入口 |

CI 已覆盖：

```text
moon check
moon test
moon fmt --check
```

## 6. 命令行演示

```powershell
# 检查数据质量
moon run cmd/main -- validate examples/occurrence-errors.csv --policy fixtures/sensitive-species.json

# 生成 Markdown 报告
moon run cmd/main -- report examples/occurrence.csv --format markdown

# 保护敏感物种坐标
moon run cmd/main -- protect examples/occurrence.csv --policy fixtures/sensitive-species.json --output public-occurrence.csv

# 导出 GeoJSON
moon run cmd/main -- convert examples/occurrence.csv --format geojson

# 比较脱敏前后变化
moon run cmd/main -- diff examples/occurrence.csv public-occurrence.csv
```

## 7. 创新点

- **跨学科场景明确**：聚焦生态调查、GIS 空间检查和数据治理；
- **敏感物种坐标保护突出**：将坐标脱敏作为核心能力，而不是普通格式转换工具；
- **标准边界清楚**：围绕 Darwin Core 风格数据建模，后续可扩展 Darwin Core Archive；
- **MoonBit 展示面完整**：覆盖解析、建模、规则校验、GIS 计算、CLI、测试和 CI；
- **演示闭环完整**：从原始 CSV 到质量报告、坐标保护、GeoJSON 导出和 diff 对比。

## 8. 当前完成度

当前仓库已完成可运行 MVP：

- 项目结构和模块划分已完成；
- CSV/TSV 导入、校验、统计、脱敏、导出已可运行；
- 示例数据、敏感物种策略和 Darwin Core Archive 夹具已提供；
- 本地测试和 GitHub Actions CI 已配置；
- 提交历史已达到多次有效提交要求。

## 9. 后续计划

- 完善 JSON 策略解析；
- 支持 `meta.xml` 字段映射；
- 增加 Event / MeasurementOrFact 关联校验；
- 支持 `.dwca.zip` 解包与重新打包；
- 增加 GeoJSON Polygon 调查区域检查；
- 增加 Wasm 或浏览器地图演示。

## 10. 总结

MoonEcoGuard 是一个面向真实生态数据治理需求的 MoonBit 项目。它以 Darwin Core 风格数据为基础，围绕野外调查记录、物种分布、空间质量和敏感坐标公开风险构建工具链，既具有实际应用价值，也适合展示 MoonBit 在数据处理与命令行工具开发方面的能力。
