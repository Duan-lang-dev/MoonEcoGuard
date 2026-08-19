# MoonEcoGuard 项目参赛说明

## 一、项目基本信息

| 项目 | 内容 |
|---|---|
| 项目名称 | MoonEcoGuard |
| 项目定位 | 面向生物多样性调查数据的标准化、质量检测与敏感坐标保护工具 |
| 开发语言 | MoonBit |
| 项目类型 | CLI 工具 / 数据治理工具 / 生态学 + GIS 交叉项目 |
| 代码仓库 | https://github.com/Duan-lang-dev/MoonEcoGuard.git |
| 作者 | Duan-lang-dev |
| 邮箱 | 956327105@qq.com |

## 二、项目简介

MoonEcoGuard 是一个纯 MoonBit 实现的生物多样性数据治理工具，面向自然保护区、植物园、博物馆、大学实验室和野外科研调查队。项目聚焦 Darwin Core / Darwin Core Archive 风格的生态调查数据，支持对物种出现记录、采样事件、地点坐标和测量数据进行导入、标准化、质量校验、统计分析、格式转换和敏感物种坐标保护。

项目不处理基因序列，不构建通用数据库，也不与软件工程诊断、图书馆编目或地震数据处理方向重复。MoonEcoGuard 的核心目标是让常见的野外调查 CSV/TSV 表格能够被更可靠地整理成可审查、可共享、可脱敏、可进入后续 GBIF/IPT 或 GIS 流程的数据资产。

## 三、项目背景与问题

生态调查数据通常来自多个团队、多个样区和多次野外采样，数据来源真实但格式不统一。常见问题包括：

- 字段名称不一致，例如“记录编号”“物种名称”“观察时间”和 Darwin Core 字段之间缺少映射；
- 经纬度可能越界、缺失、落在 `0,0`，或者出现经纬度颠倒；
- 日期格式混乱，无法稳定进入后续数据发布流程；
- 物种名称存在拼写错误、大小写不规范、属名和学名冲突等问题；
- 同一记录或同一观测可能被重复录入；
- 采样事件和物种记录之间的关系容易丢失；
- 濒危植物、珍稀动物、洞穴生物等敏感物种不适合公开精确坐标；
- CSV 文件虽然可以打开，但缺少统一的数据质量报告和审查依据。

MoonEcoGuard 通过规则化的数据模型、校验器、GIS 工具函数和隐私保护策略，帮助数据管理人员在公开发布前发现问题、修正问题并降低坐标泄露风险。

## 四、核心功能

### 1. Darwin Core 风格数据导入

项目支持从 CSV/TSV 导入物种出现记录，并将常见中文字段和 Darwin Core 风格字段统一映射到内部数据模型中。当前 MVP 已覆盖：

- occurrenceID / 记录编号；
- scientificName / 物种名称；
- eventDate / 观察时间；
- decimalLatitude / 纬度；
- decimalLongitude / 经度；
- recordedBy / 观察者；
- individualCount / 数量；
- locality / 地点；
- remarks / 备注。

### 2. 数据质量检测

MoonEcoGuard 提供面向生态调查场景的规则校验器，输出带有规则编号的质量报告。当前已支持：

- 纬度范围检查：`-90..90`；
- 经度范围检查：`-180..180`；
- 记录 ID 缺失检查；
- 重复 occurrenceID 检查；
- ISO 8601 风格日期检查；
- 负数或异常大的观察数量检查；
- `0,0` 坐标警告；
- 经纬度疑似颠倒提示；
- 指定调查区域矩形边界检查；
- 敏感物种仍暴露公开坐标提示；
- 疑似重复观测检查；
- 科学名为空、属名冲突和常见拼写错误提示。

### 3. 敏感物种坐标保护

项目内置敏感物种保护策略，支持在公开数据前自动处理高风险物种坐标和相关文本字段：

- 坐标降精度；
- 网格化到指定公里尺度；
- 确定性随机扰动；
- 替换为区域中心点；
- 移除公开坐标；
- 清理观察者联系方式、巡护路线、内部样点编号等敏感文本。

项目文档中明确声明：坐标保护只能降低公开数据泄露风险，不能替代专业人员审核和正式的数据发布制度。

### 4. 基础 GIS 能力

MoonEcoGuard 提供轻量级 GIS 工具函数，用于生态调查数据的空间质量检测：

- 经纬度合法性判断；
- Haversine 球面距离计算；
- 点是否落入矩形调查范围；
- 指定公里尺度的网格中心计算；
- 经纬度反转检测；
- 坐标精度统计辅助。

### 5. 格式转换与报告输出

当前项目已支持：

- Markdown 校验报告；
- 数据集统计报告；
- JSON 风格文本输出；
- GeoJSON 输出；
- 脱敏后的 CSV 输出；
- 私有数据与公开数据的坐标变化 diff。

## 五、命令行示例

```powershell
# 检查普通 CSV 数据
moon run cmd/main -- validate examples/occurrence.csv

# 检查包含错误的演示数据
moon run cmd/main -- validate examples/occurrence-errors.csv --policy fixtures/sensitive-species.json

# 输出 Markdown 质量报告
moon run cmd/main -- report examples/occurrence.csv --format markdown

# 按敏感物种策略生成公开版本
moon run cmd/main -- protect examples/occurrence.csv --policy fixtures/sensitive-species.json --output public-occurrence.csv

# 导出 GeoJSON
moon run cmd/main -- convert examples/occurrence.csv --format geojson

# 查看数据集统计
moon run cmd/main -- stats examples/occurrence.csv --policy fixtures/sensitive-species.json

# 检查空间异常
moon run cmd/main -- geo-check examples/occurrence-errors.csv --bounds 20,100,35,120

# 比较脱敏前后的坐标变化
moon run cmd/main -- diff examples/occurrence.csv public-occurrence.csv
```

## 六、技术实现

项目采用 MoonBit 多包结构组织，各模块职责清晰：

| 模块 | 作用 |
|---|---|
| `darwincore` | Darwin Core 风格核心数据模型 |
| `csv_reader` | CSV/TSV 解析器 |
| `ecodata` | 字段映射与数据集导入 |
| `validation` | 质量规则、诊断项和报告生成 |
| `geospatial` | 坐标合法性、距离、网格和范围检查 |
| `privacy` | 敏感物种坐标和文本脱敏策略 |
| `taxonomy` | 学名格式、属名一致性和拼写提示 |
| `formats` | Markdown、JSON、GeoJSON、CSV 输出 |
| `statistics` | 数据集统计指标 |
| `dwca` / `metadata` | Darwin Core Archive 元数据模型雏形 |
| `fs_compat` | 自包含文件读写兼容层，避免 CI 依赖外部 registry 包 |
| `cmd/main` | 命令行入口 |

当前 CI 已覆盖：

```text
moon check
moon test
moon fmt --check
```

## 七、创新点

1. **生态学 + GIS + 数据治理结合**：项目不是通用 CSV 工具，而是围绕生物多样性调查数据的字段、坐标、分类和公开发布风险设计。
2. **敏感物种坐标保护**：将濒危物种坐标模糊化、网格化和文本脱敏作为核心功能，而不是附属功能。
3. **Darwin Core 方向明确**：基于生物多样性数据共享领域常见标准进行建模，后续可继续扩展 Darwin Core Archive。
4. **适合 MoonBit 展示**：覆盖文本解析、数据建模、规则校验、GIS 数学计算、CLI、格式转换和测试体系。
5. **可演示性强**：通过一份含错误的样例数据即可展示导入、校验、报告、脱敏、导出和 diff 的完整流程。

## 八、当前完成度

当前仓库已完成一个可运行 MVP：

- 项目结构已搭建；
- CSV/TSV 导入可用；
- Darwin Core 风格 occurrence 模型可用；
- 数据质量校验可用；
- 分类名称辅助检查可用；
- 坐标保护策略可用；
- GeoJSON、Markdown、CSV 输出可用；
- CLI 命令可运行；
- 示例数据和敏感物种策略文件已提供；
- GitHub Actions CI 已配置；
- 提交历史已达到比赛展示所需的多次有效提交。

## 九、后续计划

短期计划：

- 使用更完整的 JSON 解析替换当前轻量策略解析器；
- 增加 `meta.xml` 字段映射解析；
- 支持 Event 与 Occurrence 的关联校验；
- 增加 MeasurementOrFact 扩展记录读取；
- 输出更完整的 Darwin Core Archive 文件结构；
- 增加更多生态数据规则码和测试样例。

中期计划：

- 支持 `.dwca.zip` 解包和重新打包；
- 增加 GeoJSON Polygon 调查区域检查；
- 增加浏览器或 Wasm 地图展示 Demo；
- 支持更细粒度的敏感字段策略；
- 增加数据质量评分和批量报告汇总。

## 十、比赛展示方案

现场演示可以使用 `examples/occurrence-errors.csv` 和 `fixtures/sensitive-species.json`：

1. 导入包含错误和敏感物种的生态调查 CSV；
2. 执行 `validate`，展示经纬度越界、日期格式错误、重复 ID、`0,0` 坐标、敏感坐标暴露等诊断；
3. 执行 `geo-check`，展示调查区域范围外坐标；
4. 执行 `protect`，自动生成公开版本数据；
5. 执行 `convert --format geojson`，导出地图可视化数据；
6. 执行 `diff`，展示脱敏前后坐标变化数量；
7. 展示 Markdown 报告和项目模块结构。

该流程能够体现项目从“原始调查数据”到“质量检测”再到“安全公开数据”的完整产品闭环。

## 十一、风险与边界

- MoonEcoGuard 不宣称能够自动完成权威物种鉴定；
- 项目首版不联网查询外部分类数据库；
- 坐标保护只能降低公开泄露风险，不能替代专家审核；
- 当前 Darwin Core Archive 支持仍处于模型和夹具阶段，完整 `.dwca.zip` 解析与导出属于后续增强方向；
- 对于真实保护区数据，仍需要结合机构制度、法律要求和人工审查流程。

## 十二、总结

MoonEcoGuard 是一个面向真实生态数据治理问题的 MoonBit 项目。它以 Darwin Core 风格数据为边界，围绕野外调查记录、物种分布、采样事件和地理坐标隐私构建工具链。项目既能展示 MoonBit 在文本解析、规则校验、数据建模、GIS 计算和 CLI 工具方面的能力，也具备清晰的现实应用价值和比赛展示效果。

一句话概括：MoonEcoGuard 让生态调查数据在公开之前更标准、更可信、更安全。
