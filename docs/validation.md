# MVP 验证记录

日期：2026-08-27。

## 已完成

- Xcode 27.0 / Swift 6：应用构建成功；全部单元测试及 UI 测试目标编译成功。
- `swift test`：7 个颜色算法与本地持久化测试通过。
- iOS 26.5 / iPhone 17 Pro Max：两张实际示例照片提取、损坏图片拒绝、高清分享卡渲染，3 个测试通过。
- 同一模拟器：无相机降级 → 示例提取 → 保存页，UI 测试通过。
- 收藏创建与重启后读取的 UI 断言通过。
- Mac Catalyst/UIKit 直接运行同一图像处理代码：透明 PNG 保存 JPEG 后保持白色；P3→sRGB 三通道与系统转换差值均为 0；EXIF 旋转后比例正确；分享卡输出 1038 × 1752 像素。
- 分享卡实际渲染结果：`docs/screenshots/share-card.png`。

## 已发现并修正，待 UI 回归

收藏夹点击测试发现示例照片的命中范围超出视觉裁剪区域。运行时无障碍层级显示，205 点高的可见照片仍有 523 点高的图片命中范围，覆盖上方收藏夹。

修正将照片布局收敛到 `PhotoFrame`，明确显示尺寸与点击范围，装饰图片不再单独参与无障碍命中。收藏条目使用独立标识，测试不再依赖与示例重复的标题。修正后的应用与测试目标均编译成功。

随后系统 CoreSimulator 服务无法枚举或创建测试设备，最终 UI 回归尚未完成。未擅自重启共享服务，以免中断其他项目的模拟器任务。因此不能把“收藏夹导航 → 详情 → 系统分享面板”的整条回归标为通过。

## 恢复后执行

```sh
xcodebuild -project ColorLibrary.xcodeproj -scheme ColorLibrary \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build -parallel-testing-enabled NO \
  test CODE_SIGNING_ALLOWED=NO
```

测试包含新增的 P3、透明图片与 EXIF 方向边界。UI 测试使用单独 UUID 目录，不会重置正常收藏。

## 真机验收

- 首次允许和拒绝相机权限，以及从系统设置恢复权限。
- 中央区域与显示取色框一致；改变光线时读数合理稳定。
- 曝光/白平衡锁定与解锁，前后台切换，相机系统中断恢复。
- 从系统照片选择器导入实际 HEIC/JPEG/PNG，取消选择和 iCloud 下载失败。
- 分享卡系统面板、保存到图库及拒绝保存权限。
- 小屏设备和较大辅助字体下的输入、滚动与按钮可达性。

原始日志和结果包位于本机忽略目录 `TestResults` 及 `/tmp/color-library-*.log`，不属于交付源码。
