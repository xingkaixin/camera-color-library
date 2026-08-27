# 色彩手记 · Color Library

[English](README.md) · 简体中文

把现实里的颜色，收藏成一本私人画册。原生 SwiftUI iOS MVP，全流程端侧运行，无服务器、无账号、无第三方运行依赖。

## 运行

用 Xcode 打开 `ColorLibrary.xcodeproj`，选择 **ColorLibrary** scheme 和 iPhone 模拟器，点击 Run。最低支持 iOS 17；工程使用 Swift 6，需要 Xcode 16 或更高版本。

真机运行时，在 Signing & Capabilities 中选择自己的 Development Team。仓库没有配置个人签名信息。

工程配置的源文件是 `project.yml`。增删文件后可用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 重新生成：

```sh
xcodegen generate
```

已提交生成后的工程，日常打开运行不需要安装 XcodeGen。

## MVP 范围

- **实时取色**：后置摄像头中央区域采样，剔除局部高光和极暗噪声，通道中位数 + OKLab 时间平滑；支持曝光与白平衡锁定，显示 HEX / RGB。
- **照片配色**：系统照片选择器导入，或对相机视频画面拍摄快照；转为 sRGB，按 OKLab 距离聚类，输出最多 5 种主要颜色及近似面积占比。纯色照片只产生一个颜色，不人为凑满。
- **本地收藏**：名称、收藏夹、色值、日期和照片副本；支持搜索、单色/配色筛选、修改名称/收藏夹、删除。
- **分享卡**：照片 + 色带 + HEX + 标题的原生排版，渲染为 1038 像素宽的图片，通过系统分享面板导出。
- **离线示例**：两张 AI 生成的摄影明确标为示例，不预填用户收藏。点按后运行真实提取算法。

没有加入颜色语义命名、物体反射色估计、P3 输出、审美统计、云同步、设计 token 或商业色库。它们不是首版核心闭环。

## 颜色与隐私边界

数值表示当前影像的 sRGB 颜色，不是经过校准的物体表面色；光源、HDR、白平衡与曝光都会影响结果。照片导入会处理 EXIF 方向，并将广色域内容映射到 sRGB；超出色域的颜色可能被裁剪。配色占比来自降采样聚类，是近似值。相机首版保存 720p 视频帧快照，不承诺全分辨率静态摄影。

照片选择器只提供用户选中的照片，不需要整个图库的读取权限。相机权限仅在进入捕捉页面时请求。生成的分享卡只有用户主动操作系统面板时才会外发。App 本身没有网络请求、广告或分析 SDK。

收藏位于沙盒 `Documents/ColorLibrary`：`library.json` 为唯一元数据源，照片按 UUID 存放。元数据原子写入，成功后才更新内存；删除先提交元数据再清理照片。无法解码的原文件不会被空库覆盖。卸载会删除本地收藏，分享卡不是可恢复的数据库备份。

## 代码结构

```text
Sources/ColorKit/        sRGB / OKLab、提取、稳定采样、收藏数据与持久化
Tests/ColorKitTests/     跨平台可运行的算法与存储测试
ColorLibrary/
  App/                  App 入口与关于页
  Capture/              相机资源、图像处理、导入与保存流程
  Library/              收藏首页、详情、编辑与筛选
  Sharing/              分享卡排版与系统分享面板
  Design/               少量共用视觉组件
  Resources/            离线素材、图标与隐私声明
ColorLibraryTests/       图片解码与分享渲染测试
ColorLibraryUITests/     模拟器端到端测试
```

相机资源只在单一串行队列读写；UI 状态属于 MainActor。图片降采样与聚类在后台任务执行。收藏夹列表、计数、单色/配色类型均从收藏记录推导，不维护第二份状态。

## 验证

应用构建成功，16 项测试通过（7 项核心、7 项图像、2 项 UI）。执行详情与真机验收边界见 [验证记录](docs/validation.md)。

```sh
swift test
xcodebuild -project ColorLibrary.xcodeproj -scheme ColorLibrary \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

UI 测试会使用独立 UUID 目录，不会清空正常收藏。模拟器无摄像头时仍可走通导入/示例、保存、重启读取和分享流程。

真机验收仍需检查：首次允许/拒绝相机权限、曝光锁定、真实光线下取色稳定性、切后台/相机中断恢复、系统分享保存照片。模拟器测试不能代替这些硬件验证。

## 设计与素材

实际界面：[首页](docs/screenshots/home.png) · [分享预览](docs/screenshots/share-preview.png) · [导出卡片](docs/screenshots/share-card.png)。

界面为暖白纸感、墨绿重点色和摄影画册式卡片。图标由 `scripts/make-app-icon.swift` 确定性生成。两张示例摄影通过内置 imagegen 生成，提示词和路径见 [素材说明](docs/assets.md)。

颜色转换使用 [Björn Ottosson 公布的 OKLab 矩阵](https://bottosson.github.io/posts/oklab/)。相机使用 [AVFoundation](https://developer.apple.com/documentation/avfoundation/avcapturesession)，图库导入使用系统 PhotosPicker。
