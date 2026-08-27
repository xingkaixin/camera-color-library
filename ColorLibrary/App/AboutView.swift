import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    BrandMark().padding(.top, 20)
                    Text("世界有很多颜色，\n有些，刚好属于你。")
                        .font(.system(size: 29, weight: .medium, design: .serif)).lineSpacing(8)
                    section("01   发现与收藏", "用镜头捕捉一个颜色，或从照片里提取配色。为它命名、放入收藏夹，再制作一张可以分享的色彩卡。")
                    section("02   诚实地看待颜色", "所有色值统一为 sRGB。相机采样会受环境光、曝光和白平衡影响，不能替代专业色度计。中央区域采样与时间平滑让读数更稳定，但不代表校准后的物体真色。")
                    section("03   只留在你的设备", "照片和收藏保存在 App 本地，不需要账号，不会上传到服务器。导入使用系统照片选择器，只读取你选中的照片。卸载 App 会删除本地收藏，请提前通过分享卡留存重要配色。")
                    section("04   关于灵感示例", "两张灵感摄影由 AI 生成，仅用于体验，不会自动加入收藏。示例预览色带是编辑配色；点击后会重新从图片实际提取颜色。")
                    Text("COLOR LIBRARY · MVP 0.1.0").font(.system(size: 10, design: .monospaced)).tracking(1).foregroundStyle(Theme.muted)
                }.padding(26)
            }
            .background(Theme.paper).foregroundStyle(Theme.ink)
            .navigationTitle("关于色彩手记").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.system(size: 13, weight: .semibold))
            Text(body).font(.system(size: 14)).foregroundStyle(Theme.muted).lineSpacing(7)
        }
    }
}
