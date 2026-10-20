# BalanceHub

多厂商官方 API 余额聚合工具，面向 Windows / Linux / Android 三端。

> **AI 辅助声明**：本项目的代码与文档在开发过程中使用了 AI 辅助工具，所有内容均由维护者审阅后提交。

## 当前状态

- v1 MVP 已实现：DeepSeek / Kimi（Moonshot）/ 硅基流动余额查询、账户增删改、启动自动刷新 + 可配置定时轮询、余额卡片总览
- v1.1 规划：无 API 厂商手动余额录入、实验性 WebView 读取
- v2 / v3 规划：签名类厂商（阿里百炼、火山方舟）、阈值告警、快照历史与趋势曲线

## 支持的厂商

| 厂商 | 余额接口 | 鉴权 | 计划 |
|---|---|---|---|
| DeepSeek | `GET https://api.deepseek.com/user/balance` | Bearer Key | v1 |
| Kimi / Moonshot | `GET https://api.moonshot.cn/v1/users/me/balance` | Bearer Key | v1 |
| 硅基流动 | `GET https://api.siliconflow.cn/v1/user/info` | Bearer Key | v1 |
| 智谱 bigmodel.cn | 官方未公开余额 API | — | v1.1 手动录入 |
| 阿里百炼 | 阿里云 BSS `QueryAccountBalance` | AccessKey 签名 | v2 |
| 火山方舟 | 火山费用中心 `QueryBalanceAcct` | AK/SK 签名 | v2 |

三家 v1 厂商返回字段各异，均含赠送/现金拆分，币种均为 CNY。

## 使用

1. 在「账户管理」点右下角加号，选择厂商、填写备注并粘贴 API Key
2. 回到「总览」，启动时会自动刷新一次，之后默认每 10 分钟刷新；右上角计时器菜单可改为 5/15/30 分钟或关闭，也可随时点刷新按钮
3. 各账户并行刷新，单家失败不影响其他账户；失败时卡片保留上次成功余额并标注原因，Key 无效、限流、网络与解析异常会分别提示

API Key 仅写入系统安全存储（Windows DPAPI / Android Keystore / Linux libsecret），账户元数据以 JSON 保存在应用支持目录。

## 架构

```
lib/
├─ core/          纯 Dart：模型、适配器接口与实现、仓库接口
│  ├─ models/
│  ├─ providers/
│  └─ repository/
├─ data/          安全存储与仓库实现
└─ ui/            Flutter 界面
```

- 余额统一归一化为 `BalanceSnapshot`（主余额、币种、明细拆分、拉取时间）
- 厂商适配器实现 `ProviderAdapter`，并行拉取，单家失败不影响其他账户
- 账户元数据与 API Key 分离：Key 只写入系统安全存储（Windows DPAPI / Android Keystore / Linux libsecret）

## 开发

环境要求：Flutter 3.47+、Dart 3.13+。

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows   # 或 linux / android
```

### 平台准备

- **Windows**：需要 Visual Studio，安装「使用 C++ 的桌面开发」工作负载
- **Linux**：构建需 `libsecret-1-dev`，运行时需 `libsecret-1-0` 及可用的 Keyring 服务
- **Android**：minSdk 24，使用 SDK 36 编译

## 测试

- `core` 层单测：三家适配器解析、200/401/429/超时/解析失败分支
- 数据与状态测试：账户 JSON 仓库、控制器增删改与并行刷新
- widget 测试：导航壳、总览卡片三态（未刷新/正常/错误）
- CI 在 ubuntu 上执行 `flutter analyze` 与 `flutter test`

## dev 预发布构建

- 触发：push 到 `dev` 且提交信息含 `[build]`，或在 Actions 中手动 dispatch
- 产物：Windows x64 便携 zip、Android 通用 APK（调试签名）、Linux x64 / arm64 tar.gz，附 `SHA256SUMS.txt`
- 发布位置：固定 tag `dev-build` 的 pre-release，每次构建先删后建覆盖
- 正式发版流水线待 `main` 分支建立后再补

