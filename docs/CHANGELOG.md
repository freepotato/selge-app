# Changelog

## 1.0.0 (2026-10-31)


### Features

* Selge iOS 原生应用 MVP v0.1.0 ([caf7a07](https://github.com/freepotato/selge-app/commit/caf7a07918353e8243736b9e813d92afd4b7f7b5))
* Selge iOS 原生应用 MVP（SwiftUI + SwiftData/CloudKit） ([9930c28](https://github.com/freepotato/selge-app/commit/9930c289e3fa62f1b8e1c7058f54ff040e06ea26))
* 主页/成就改为原生列表，商店金币置顶并改为金色，历险输入可点空白收起键盘 ([632c4a8](https://github.com/freepotato/selge-app/commit/632c4a8c7b60fc067d098cfc40289067060053e6))
* 内置宋体 Logo 字体、去除等级称谓、重做历险页并增强热力图与成就排序 ([51b09e7](https://github.com/freepotato/selge-app/commit/51b09e7b06933591710067727c704102691fe1b5))
* 删除记录后撤销未达成成就，热力图悬浮框常驻，徽章摆动更沉且限 45° ([7ac9ab1](https://github.com/freepotato/selge-app/commit/7ac9ab10fd5828c5acc4159d6a9910c8662b4a87))
* 历险类别改为下拉选择、记录支持左滑修改/删除，热力图恢复自然高度 ([2c10ec1](https://github.com/freepotato/selge-app/commit/2c10ec104c76f4b04dd191e95d78accbb2b6e27f))
* 成就徽章去掉摆动动画，支持左右滑动切换类别页 ([c9ab5d3](https://github.com/freepotato/selge-app/commit/c9ab5d33a7e30c685b7f28771571a5a84f5aa5d9))


### Bug Fixes

* CloudKit 改为 Release 编译期开关，Debug 真机（免费签名）不再崩溃 ([24b2299](https://github.com/freepotato/selge-app/commit/24b22999c05ee2011843c2a4a0b921d0457a098d))
* Debug/Release 双 entitlements 文件，免费签名开箱即用且保留 iCloud 配置 ([802afea](https://github.com/freepotato/selge-app/commit/802afeaa87adc8d1ac5112a5927554b56da597b3))
* 无 iCloud 能力时跳过 CloudKit 初始化，免费个人团队可真机安装 ([1130e56](https://github.com/freepotato/selge-app/commit/1130e565e56b0a193fc08dd233d1011e7be5d6b7))

## Changelog

Selge iOS 更新日志。本文件由 release-please 依据 Conventional Commits 自动生成与维护，
同时也是 App 内「设置 → 更新日志」的数据源（随构建打包）。
