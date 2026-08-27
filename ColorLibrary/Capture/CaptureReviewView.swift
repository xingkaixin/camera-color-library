import ColorKit
import OSLog
import SwiftUI

struct CaptureReviewView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let draft: CaptureDraft
    @State private var title: String
    @State private var collection = "日常灵感"
    @State private var error: String?
    @State private var isSaving = false

    init(draft: CaptureDraft) {
        self.draft = draft
        _title = State(initialValue: draft.suggestedTitle)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("留住这份心动").font(.system(size: 28, weight: .medium, design: .serif))
                        Text("已发现 \(draft.swatches.count) 种颜色 · sRGB")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                    VStack(spacing: 0) {
                        if let image = draft.image {
                            PhotoFrame(image: Image(uiImage: image), height: 260)
                        }
                        PaletteStrip(swatches: draft.swatches, height: 65)
                    }.clipShape(RoundedRectangle(cornerRadius: 20))
                    HStack(spacing: 0) {
                        ForEach(Array(draft.swatches.enumerated()), id: \.offset) { _, swatch in
                            Text(swatch.color.hex).font(.system(size: 9, weight: .medium, design: .monospaced))
                                .frame(maxWidth: .infinity)
                        }
                    }.foregroundStyle(Theme.muted)
                    EntryFields(title: $title, collection: $collection, collections: library.collections)
                    Text("给颜色一个名字，未来再看见它时，\n也能想起此刻的光线和心情。")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted).lineSpacing(6)
                }.padding(24)
            }
            .background(Theme.paper).foregroundStyle(Theme.ink)
            .navigationTitle("新的色彩记忆").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                Button { save() } label: {
                    Label(isSaving ? "正在保存…" : "保存到我的收藏", systemImage: "bookmark")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || collection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .accessibilityIdentifier("saveCaptureButton")
                .padding(24).background(Theme.paper)
            }
            .alert("保存失败", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("知道了", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private func save() {
        isSaving = true
        defer { isSaving = false }
        do {
            let photo: Data?
            if let image = draft.image {
                guard let data = image.jpegData(compressionQuality: 0.88) else { throw CocoaError(.fileWriteUnknown) }
                photo = data
            } else { photo = nil }
            _ = try library.save(title: title, collection: collection, swatches: draft.swatches, photo: photo)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } catch {
            Logger(subsystem: "studio.colorlibrary.app", category: "Library")
                .error("Save failed: \(error.localizedDescription, privacy: .public)")
            self.error = "未能写入收藏，请检查设备存储空间后重试。你的照片仍保留在此页面。"
        }
    }
}

struct EntryFields: View {
    @Binding var title: String
    @Binding var collection: String
    let collections: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 9) {
                Text("为这一刻命名").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.muted)
                TextField("例如：京都，街角的咖啡馆", text: $title)
                    .font(.system(size: 16)).padding(17).background(Theme.card, in: RoundedRectangle(cornerRadius: 13))
                    .accessibilityIdentifier("entryTitleField")
            }
            VStack(alignment: .leading, spacing: 9) {
                Text("放入收藏夹").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.muted)
                HStack {
                    Image(systemName: "folder").foregroundStyle(Theme.olive)
                    TextField("输入已有或新的收藏夹名称", text: $collection)
                        .font(.system(size: 15)).accessibilityIdentifier("collectionField")
                    if !collections.isEmpty {
                        Menu {
                            ForEach(collections, id: \.self) { name in Button(name) { collection = name } }
                        } label: { Image(systemName: "chevron.down").frame(width: 32, height: 32) }
                            .accessibilityLabel("选择已有收藏夹")
                    }
                }.padding(.horizontal, 17).padding(.vertical, 12).background(Theme.card, in: RoundedRectangle(cornerRadius: 13))
            }
        }
    }
}
