# Color Library：把现实世界的颜色收藏成个人色彩库

## 产品概念
使用 iPhone 摄像头捕捉现实世界中的颜色和配色，把“我喜欢这个颜色/这个空间的配色”转换成可以保存、理解和复用的数字色彩。

单纯的 Camera → HEX 只是基础能力，不足以形成产品。更完整的定义是：**Capture colors from the real world, understand them, and build your personal color library.**

## 第一层：实时色卡
摄像头中央提供取色区域，实时显示 HEX、RGB、Display P3/sRGB、Lab/OKLab 等。用户移动手机即可观察颜色，点击后冻结并保存。

但 Camera RGB 不等于物体绝对真实颜色。环境光、白平衡、曝光、HDR、tone mapping、阴影和高光都会改变结果，因此不应轻易宣称自己是专业实体色度计。

## Perceptual Color Capture
为了比简单 pixel picker 更可靠，可以对中央区域采样而非单像素，排除高光和极暗区域，使用 median/cluster color，稳定曝光和白平衡，并在 perceptual color space 中处理。

可以区分：
- **Captured Color**：摄像头实际看到的颜色。
- **Estimated Surface Color**：尝试消除部分光照影响后的估计颜色。

## 第二层：从现实物体提取 Palette
用户真正喜欢的往往不是某一个 HEX，而是一个空间、物体或画面的整体配色。

拍下一家咖啡店、一辆车、一本书、一套衣服或一片秋叶后，App 自动提取 Dominant、Secondary、Accent、Neutral、Dark/Light 等颜色。算法可以主要在端侧完成，例如颜色量化、聚类和 OKLab，不一定需要大模型。

## 第三层：颜色理解 / Color Shazam
把机器数字转换成人类更自然的表达。例如 `#B96F52` 不只是显示 RGB，而是描述为 “Terracotta — warm, muted, earthy, slightly brown”。

产品可以回答“这是什么颜色？”，并给出与公开标准色名或 CSS 色名的近似关系。Pantone 等商业色库需要单独考虑授权和商标问题。

## 第四层：Personal Color Library
真正可能形成留存的不是 Camera，而是长期收藏。

用户不断保存 Tokyo hotel、Coffee shop、Old Porsche、Book cover、Autumn leaves、Interior、Outfit 等现实配色，最终形成 My Colors。

App 可以分析 Warm/Cool、Muted/Saturated、Earth tones、常收藏 hue、常见 palette 关系等，逐渐形成用户自己的“个人色彩审美”。

## 第五层：设计师/开发者模式
对于设计师和开发者，可以把现实 palette 转换为 semantic design tokens：primary、secondary、accent、background、surface、text、muted、border。

进一步支持 Light/Dark Mode 推导、WCAG contrast 检查、色阶生成，并导出 SwiftUI、CSS、Tailwind 等格式。

但开发者模式不一定适合作为最初的主定位，因为“看到咖啡馆 → 生成 App Design System”的发生频率可能较低。普通人的“看到喜欢的颜色 → 收藏下来”反而更自然。

## 典型用户流程
1. 打开 Camera。
2. 实时看到颜色名称和色值。
3. 单点保存某个颜色，或拍照提取整个 palette。
4. App 给出自然语言色彩描述。
5. 保存到某个 Collection。
6. 长期积累形成 My Colors。
7. 需要时导出 palette 或 design tokens。

## 技术实现
核心可以完全 on-device：AVFoundation 负责摄像头，Core Image/Accelerate 负责图像处理，Lab/OKLab 负责感知颜色计算，聚类/量化负责 palette extraction，SwiftUI 负责交互和 Library。

第一版不需要服务器，也不需要 LLM。自然语言描述可以先通过规则和色彩空间计算完成。

## MVP
第一版只做四件事：实时稳定取色、照片 palette extraction、颜色/Palette 收藏、漂亮的分享卡。

第二阶段再考虑自然语言颜色命名、个人审美统计和开发者导出。

## 市场风险
Camera color picker 和 palette generator 是成熟品类。真正的问题不是技术，而是现有 App 是否已经把“取色 → Palette → Library → 理解 → 导出”做得足够成熟。

因此进入开发前应做一次 App Store 竞品和评论研究，重点寻找用户对准确性、收藏体验、色彩命名、设计导出和视觉体验的不满。

## 产品判断
四个概念里技术最确定、开发风险最低、运营成本最低，但也最容易变成一个漂亮的小功能而不是产品。更值得探索的产品核心是：**把现实世界里喜欢的颜色长期收藏下来，最终形成属于用户自己的个人色彩库。**
