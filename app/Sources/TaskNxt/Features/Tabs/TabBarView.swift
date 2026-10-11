import SwiftUI
import TaskNxtCore

/// Horizontal tab selector shown at the top of the popover: one entry per
/// tab with an active/inactive icon indicator, name, and incomplete-task
/// count, plus a control to add a new tab (spec: tab-management, "Switch
/// between tabs" / "Add a tab").
struct TabBarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAddingTab = false
    @State private var newTabName = ""
    @State private var errorMessage: String?
    @State private var metrics = TabScrollMetrics.Value()
    @State private var viewportWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(appState.store.tabs.sorted(by: { $0.order < $1.order })) { tab in
                            tabButton(for: tab)
                        }
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(
                            key: TabScrollMetrics.self,
                            value: .init(contentWidth: geo.size.width, offset: -geo.frame(in: .named("tabScroll")).minX)
                        )
                    })
                }
                .coordinateSpace(name: "tabScroll")
                .background(GeometryReader { geo in
                    Color.clear.onAppear { viewportWidth = geo.size.width }
                        .onChange(of: geo.size.width) { viewportWidth = $0 }
                })
                .onPreferenceChange(TabScrollMetrics.self) { metrics = $0 }
                // Fade + chevron while more tabs are hidden to the right.
                .overlay(alignment: .trailing) {
                    if metrics.contentWidth - metrics.offset - viewportWidth > 1 {
                        HStack(spacing: 0) {
                            LinearGradient(colors: [.clear, Color(nsColor: .windowBackgroundColor)], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 18)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 2)
                                .background(Color(nsColor: .windowBackgroundColor))
                        }
                        .allowsHitTesting(false)
                        .transition(.opacity)
                    }
                }

                Button {
                    isAddingTab = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(appState.localTabCount >= AppState.maxTabs)
                .help(
                    appState.localTabCount >= AppState.maxTabs
                        ? "Maximum of 4 local tabs reached"
                        : "Add a tab"
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .popover(isPresented: $isAddingTab) {
            VStack(spacing: 8) {
                Text("New Tab").font(.headline)
                TextField("Tab name", text: $newTabName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                Button("Add") {
                    do {
                        try appState.addTab(named: newTabName.isEmpty ? "New Tab" : newTabName)
                        newTabName = ""
                        isAddingTab = false
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isActive = appState.activeTabID == tab.id
        Button {
            appState.setActiveTab(tab.id)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                Text(tab.name)
                Text("\(tab.incompleteCount)")
                    .font(.caption2)
                    .opacity(0.6)
            }
            .font(.callout)
            .fontWeight(isActive ? .semibold : .regular)
            .foregroundStyle(isActive ? Color.accentColor : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                isActive
                    ? Color.secondary.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            // Inactive tabs have a clear background, which `.plain`
            // buttons don't hit-test; make the whole chip clickable.
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

private struct TabScrollMetrics: PreferenceKey {
    struct Value: Equatable {
        var contentWidth: CGFloat = 0
        var offset: CGFloat = 0
    }
    static var defaultValue = Value()
    static func reduce(value: inout Value, nextValue: () -> Value) { value = nextValue() }
}
