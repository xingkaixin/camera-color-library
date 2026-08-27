import ColorKit
import SwiftUI

struct LibraryHomeView: View {
    private enum Filter: String, CaseIterable { case all = "全部", palettes = "配色", colors = "色卡" }
    @Environment(LibraryStore.self) private var library
    @State private var flow = CaptureFlow()
    @State private var showsCamera = false
    @State private var showsAbout = false
    @State private var showsSearch = false
    @State private var showsCollections = false
    @State private var query = ""
    @State private var filter = Filter.all
    @State private var collection: String?

    private var visibleEntries: [LibraryEntry] {
        library.entries.filter {
            $0.matches(query) && (collection == nil || $0.collection == collection)
                && (filter == .all || (filter == .colors ? $0.isSingleColor : !$0.isSingleColor))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 27) {
                    header
                    introduction
                    HStack(spacing: 12) {
                        Button { showsCamera = true } label: {
                            Label("捕捉色彩", systemImage: "viewfinder")
                        }.buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("captureButton")
                        PhotoImportButton(flow: flow)
                    }
                    if let error = library.loadError {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(error).font(.subheadline)
                            Button("重新读取") { library.reload() }
                        }.padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if showsCollections { collectionList } else { libraryContent }
                    inspirations
                    Label("只属于你 · 本地保存 · 无需账号", systemImage: "lock.shield")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 24)
            }
            .background(Theme.paper.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            .navigationDestination(for: LibraryEntry.self) { entry in EntryDetailView(entry: entry) }
            .sheet(isPresented: $showsCamera) { CameraView() }
            .sheet(isPresented: $showsAbout) { AboutView() }
            .capturePresentation(flow)
        }
    }

    private var header: some View {
        HStack {
            BrandMark()
            Spacer()
            Button { showsAbout = true } label: { RoundIcon(symbol: "info") }
                .accessibilityLabel("关于色彩手记")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                Text("给日常，\n一点色彩。")
                    .font(.system(size: 36, weight: .medium, design: .serif)).lineSpacing(5)
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(String(format: "%02d", library.entries.count))
                        .font(.system(size: 43, weight: .light, design: .serif)).foregroundStyle(Theme.olive)
                    Text("份色彩记忆").font(.system(size: 11)).foregroundStyle(Theme.muted)
                }.padding(.bottom, 5)
            }
            Text("从真实世界，收藏属于你的配色。")
                .font(.system(size: 14)).foregroundStyle(Theme.muted)
        }
    }

    @ViewBuilder private var libraryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(collection ?? "我的收藏").font(.system(size: 19, weight: .semibold))
                if collection != nil {
                    Button { collection = nil } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("清除收藏夹筛选")
                }
                Spacer()
                Button { withAnimation { showsSearch.toggle() }; if !showsSearch { query = "" } } label: {
                    Image(systemName: "magnifyingglass").frame(width: 44, height: 32)
                }.accessibilityLabel("搜索收藏")
            }
            if showsSearch {
                TextField("搜索名称、收藏夹或 HEX", text: $query)
                    .font(.subheadline).padding(14)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("librarySearch")
            }
            if library.entries.isEmpty {
                HStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up").font(.system(size: 27, weight: .light))
                        .foregroundStyle(Theme.olive).frame(width: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("第一份心动，从这里开始").font(.system(size: 14, weight: .medium))
                        Text("拍下眼前的颜色，或试试下方的灵感。")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            } else {
                HStack(spacing: 10) {
                    ForEach(Filter.allCases, id: \.self) { item in
                        Button { filter = item } label: {
                            Text(item.rawValue).font(.system(size: 12, weight: .medium)).padding(.horizontal, 19).padding(.vertical, 9)
                                .foregroundStyle(filter == item ? .white : Theme.muted)
                                .background(filter == item ? Theme.olive : Theme.card, in: Capsule())
                        }
                    }
                }
                if visibleEntries.isEmpty {
                    Text("没有找到匹配的收藏").font(.subheadline).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 25)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                    ForEach(visibleEntries) { entry in
                        NavigationLink(value: entry) { EntryCard(entry: entry) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("libraryEntry-" + entry.id.uuidString)
                    }
                }
            }
        }
    }

    private var collectionList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("我的收藏夹").font(.system(size: 19, weight: .semibold))
                Spacer()
                Text("\(library.collections.count) 个").font(.caption).foregroundStyle(Theme.muted)
            }
            if library.collections.isEmpty {
                Text("保存色卡时，为它起一个收藏夹名字。\n旅行、日常、某一家咖啡馆，都可以。")
                    .font(.subheadline).lineSpacing(7).foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(22)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
            }
            ForEach(library.collections, id: \.self) { name in
                let entries = library.entries.filter { $0.collection == name }
                Button {
                    collection = name
                    filter = .all
                    showsCollections = false
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: "folder").font(.title2).frame(width: 42)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(name).font(.system(size: 16, weight: .medium))
                            Text("\(entries.count) 份色彩记忆").font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        HStack(spacing: -5) {
                            ForEach(Array(entries.flatMap(\.swatches).prefix(3).enumerated()), id: \.offset) { _, swatch in
                                Circle().fill(swatch.color.displayColor).frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Theme.card, lineWidth: 2))
                            }
                        }
                        Image(systemName: "chevron.right").font(.caption)
                    }.padding(18).background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain).accessibilityIdentifier("collection-" + name)
            }
        }
    }

    private var inspirations: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("灵感，从身边开始").font(.system(size: 19, weight: .semibold))
                Spacer()
                Text("THE EVERYDAY EDIT").font(.system(size: 8, weight: .medium)).tracking(1).foregroundStyle(Theme.muted)
            }
            ForEach(Inspiration.samples) { sample in
                Button { Task { await flow.openSample(sample) } } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        PhotoFrame(image: Image(sample.asset), height: 205)
                            .overlay(alignment: .topLeading) {
                                Text("示例 · 点击提取配色").font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Theme.paper.opacity(0.94), in: Capsule()).padding(15)
                            }
                        PaletteStrip(swatches: sample.swatches, height: 28)
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(sample.title).font(.system(size: 17, weight: .medium, design: .serif))
                                Text(sample.caption).font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.system(size: 17, weight: .light))
                        }.padding(17)
                    }
                    .background(Theme.card).clipShape(RoundedRectangle(cornerRadius: 20))
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("sample-" + sample.asset)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button { showsCollections = false; collection = nil } label: {
                Label("色彩库", systemImage: showsCollections ? "square.stack" : "square.stack.fill")
                    .font(.system(size: 13, weight: showsCollections ? .regular : .semibold))
                    .foregroundStyle(showsCollections ? Theme.muted : Theme.olive).frame(maxWidth: .infinity, minHeight: 48)
            }
            Rectangle().fill(Theme.line).frame(width: 1, height: 20)
            Button { showsCollections = true } label: {
                Label("收藏夹", systemImage: showsCollections ? "folder.fill" : "folder")
                    .font(.system(size: 13, weight: showsCollections ? .semibold : .regular))
                    .foregroundStyle(showsCollections ? Theme.olive : Theme.muted).frame(maxWidth: .infinity, minHeight: 48)
            }.accessibilityIdentifier("collectionsTab")
        }
        .padding(.top, 7).padding(.horizontal, 24)
        .background(Theme.paper.shadow(color: .black.opacity(0.04), radius: 15, y: -5))
        .overlay(alignment: .top) { Theme.line.frame(height: 0.6) }
    }
}
