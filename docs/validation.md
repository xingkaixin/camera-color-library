# MVP 验证记录

日期：2026-08-27。最终结果：**16 项自动化测试全部通过**。

## 已完成

- Xcode 27.0、Xcode 26.6 / Swift 6：应用与测试目标均构建成功。最终 UI 回归使用 Xcode 26.6。
- `swift test`：7 个颜色算法与本地持久化测试通过。
- iOS 26.5 / iPhone 17 Pro Max：实际照片提取、损坏图片拒绝、分享渲染、P3 转换、透明像素、EXIF 方向、JPEG 保存一致性，7 个图像测试通过。
- 独立的 Color Library QA 模拟器：2 个端到端 UI 测试通过，覆盖无相机降级、示例提取、保存、重启读取、收藏夹导航、详情复制、分享卡预览，以及系统分享面板中的拷贝操作入口。
- Mac Catalyst/UIKit 直接运行同一图像处理代码：透明 PNG 保存 JPEG 后保持白色；P3→sRGB 三通道与系统转换差值均为 0；EXIF 旋转后比例正确；分享卡输出 1038 × 1752 像素。
- 分享卡实际渲染结果：`docs/screenshots/share-card.png`。

## 运行时发现并修正

收藏夹点击测试发现示例照片的命中范围超出视觉裁剪区域。运行时无障碍层级显示，205 点高的可见照片仍有 523 点高的图片命中范围，覆盖上方收藏夹。

修正将照片布局收敛到 `PhotoFrame`，明确显示尺寸与点击范围，装饰图片不再单独参与无障碍命中。收藏条目使用独立标识，测试不再依赖与示例重复的标题。修正后的导航和点击路径已通过 UI 回归。

相机日志还发现：模拟器判定无摄像头后，系统会延迟投递捕捉会话错误。现在仅活动会话可以进入中断状态，不再覆盖“无镜头”或“权限拒绝”等状态，该降级流程已通过回归。

期间遇到共享 CoreSimulator 服务异常，随后创建独立 QA 设备完成验证，没有重启共享服务或中断其他项目。系统分享操作在当前 iOS 中是 Cell 而不是 Button，测试按实际无障碍角色定位；系统面板已成功展示。

## 重跑测试

```sh
xcodebuild -project ColorLibrary.xcodeproj -scheme ColorLibrary \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build -parallel-testing-enabled NO \
  test CODE_SIGNING_ALLOWED=NO
```

测试包含 P3、透明图片与 EXIF 方向边界。UI 测试使用单独 UUID 目录，不会重置正常收藏。若设备名称不同，请替换 destination；本次使用独立设备 Color Library QA。

## 真机验收

- 首次允许和拒绝相机权限，以及从系统设置恢复权限。
- 中央区域与显示取色框一致；改变光线时读数合理稳定。
- 曝光/白平衡锁定与解锁，前后台切换，相机系统中断恢复。
- 从系统照片选择器导入实际 HEIC/JPEG/PNG，取消选择和 iCloud 下载失败。
- 分享卡系统面板、保存到图库及拒绝保存权限。
- 小屏设备和较大辅助字体下的输入、滚动与按钮可达性。

最终结果包位于本机忽略目录 `TestResults/MVP-ReleaseCheck.xcresult`，构建与测试日志位于 `/tmp/color-library-release-check.log`。测试验证系统分享入口可用，没有自动向第三方发送图片，也没有替用户完成图库授权。
