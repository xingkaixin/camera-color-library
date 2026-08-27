import ColorKit
import OSLog
import SwiftUI

struct EntryDetailView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let entry: LibraryEntry
    @State private var selectedIndex = 0
    @State private var showsShare = false
    @State private var showsEdit = false
    @State private var confirmsDelete = false
    @State private var copiedValue: String?
    @State private var error: String?

    private var current: LibraryEntry { library.entries.first { $0.id == entry.id } ?? entry }
    private var selected: ColorSwatch { current.swatches[selectedIndex] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Label(current.collection, systemImage: "folder").lineLimit(1)
                    Spacer()
                    Text(current.createdAt.formatted(.dateTime.year().month().day()))
                }.font(.system(size: 11)).foregroundStyle(Theme.muted)
                Text(current.title).font(.system(size: 32, weight: .medium, design: .serif))
                VStack(spacing: 0) {
                    EntryImage(entry: current, height: 300)
                    PaletteStrip(swatches: current.swatches, height: 48)
                }.clipShape(RoundedRectangle(cornerRadius: 21))
                HStack {
                    Text("这一刻的颜色").font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Text("\(current.swatches.count) COLORS · sRGB")
                        .font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.muted)
                }
                HStack(spacing: 9) {
                    ForEach(Array(current.swatches.enumerated()), id: \.offset) { index, swatch in
                        Button { selectedIndex = index; copiedValue = nil } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 13).fill(swatch.color.displayColor)
                                    .frame(height: 57)
                                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.ink.opacity(index == selectedIndex ? 1 : 0), lineWidth: 2).padding(-4))
                                Text("\(Int((swatch.weight * 100).rounded()))%")
                                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("选择颜色 \(swatch.color.hex)，占比 \(Int((swatch.weight * 100).rounded()))%")
                    }
                }
                VStack(spacing: 17) {
                    HStack {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(selectedIndex == 0 ? "主色 / DOMINANT" : "配色 / COLOR 0\(selectedIndex + 1)")
                                .font(.system(size: 9, weight: .medium)).tracking(1).foregroundStyle(Theme.muted)
                            Text(selected.color.hex).font(.system(size: 30, weight: .regular, design: .monospaced))
                        }
                        Spacer()
                        Button { copy(selected.color.hex) } label: {
                            Image(systemName: copiedValue == selected.color.hex ? "checkmark" : "doc.on.doc")
                                .frame(width: 44, height: 44).background(Theme.paper, in: Circle())
                        }.accessibilityLabel("复制 HEX").accessibilityIdentifier("copyHexButton")
                    }
                    Rectangle().fill(Theme.line).frame(height: 0.6)
                    HStack {
                        Text("RGB").font(.system(size: 10)).foregroundStyle(Theme.muted)
                        Spacer()
                        Text(selected.color.rgb).font(.system(size: 13, design: .monospaced))
                        Button { copy("rgb(\(selected.color.rgb))") } label: {
                            Image(systemName: "doc.on.doc").font(.system(size: 13)).frame(width: 35, height: 35)
                        }.accessibilityLabel("复制 RGB")
                    }
                    if copiedValue != nil {
                        Text("已复制到剪贴板").font(.system(size: 11)).foregroundStyle(Theme.olive)
                            .accessibilityIdentifier("copyConfirmation")
                    }
                }.padding(20).background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                Text("颜色记录的是当时的光线。\n保留它，也保留看见它时的心情。")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted).lineSpacing(6)
            }.padding(24)
        }
        .background(Theme.paper).foregroundStyle(Theme.ink)
        .navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) { Text("色彩手记").font(.system(size: 15, weight: .medium, design: .serif)) }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("编辑名称与收藏夹", systemImage: "pencil") { showsEdit = true }
                    Button("删除收藏", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 40) }
                    .accessibilityLabel("更多操作")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button { showsShare = true } label: { Label("制作分享卡", systemImage: "square.and.arrow.up") }
                .buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 24).padding(.vertical, 14).background(Theme.paper)
                .accessibilityIdentifier("shareCardButton")
        }
        .sheet(isPresented: $showsShare) { ShareCardView(entry: current) }
        .sheet(isPresented: $showsEdit) { EditEntryView(entry: current) }
        .alert("删除这份色彩记忆？", isPresented: $confirmsDelete) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { delete() }
        } message: { Text("这会删除本地收藏及 App 内的照片副本，无法撤销。系统照片图库不受影响。") }
        .alert("删除失败", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("知道了", role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func copy(_ value: String) {
        UIPasteboard.general.string = value
        copiedValue = value
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func delete() {
        do {
            try library.delete(current)
            dismiss()
        } catch {
            Logger(subsystem: "studio.colorlibrary.app", category: "Library")
                .error("Delete failed: \(error.localizedDescription, privacy: .public)")
            self.error = "未能更新本地收藏，请稍后重试。"
        }
    }
}

private struct EditEntryView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.dismiss) private var dismiss
    let entry: LibraryEntry
    @State private var title: String
    @State private var collection: String
    @State private var showsError = false

    init(entry: LibraryEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _collection = State(initialValue: entry.collection)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                EntryFields(title: $title, collection: $collection, collections: library.collections).padding(24)
            }
            .background(Theme.paper).navigationTitle("编辑色彩记忆").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        do {
                            try library.update(entry, title: title, collection: collection)
                            dismiss()
                        } catch {
                            Logger(subsystem: "studio.colorlibrary.app", category: "Library")
                                .error("Edit failed: \(error.localizedDescription, privacy: .public)")
                            showsError = true
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || collection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("未能保存修改，请稍后再试。", isPresented: $showsError) { Button("知道了", role: .cancel) {} }
        }
    }
}
