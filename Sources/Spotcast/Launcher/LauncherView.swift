import SpotcastPluginKit
import SwiftUI

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let onClose: () -> Void

    @FocusState private var isSearchFocused: Bool
    @State private var hoveredActionID: String?

    var body: some View {
        Group {
            if let session = viewModel.pluginFormSession {
                PluginFormView(
                    session: session,
                    onCancel: {
                        viewModel.dismissPluginForm()
                    },
                    onSubmit: { values in
                        let shouldClose = viewModel.submitPluginForm(values: values)
                        if shouldClose {
                            onClose()
                        }
                    }
                )
            } else {
                VStack(spacing: 0) {
                    TextField("Search apps and commands...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .medium))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .focused($isSearchFocused)
                        .onSubmit {
                            let shouldClose = viewModel.executeSelected()
                            if shouldClose {
                                onClose()
                            }
                        }
                        .onReceive(viewModel.$query) { query in
                            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.revealResultsForTyping()
                            }
                        }

                    if viewModel.isResultsVisible {
                        Divider()

                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    if viewModel.filteredActions.isEmpty {
                                        Text("No results")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(16)
                                    } else {
                                        ForEach(viewModel.filteredActions, id: \.id) { action in
                                            actionRow(
                                                action,
                                                selected: viewModel.selectedActionID == action.id,
                                                hovered: hoveredActionID == action.id
                                            )
                                            .id(action.id)
                                            .contentShape(Rectangle())
                                            .onHover { hovering in
                                                if hovering {
                                                    hoveredActionID = action.id
                                                } else if hoveredActionID == action.id {
                                                    hoveredActionID = nil
                                                }
                                            }
                                            .onTapGesture {
                                                let shouldClose = viewModel.execute(
                                                    actionID: action.id)
                                                if shouldClose {
                                                    onClose()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .onReceive(viewModel.$scrollTargetActionID) { selectedActionID in
                                guard let selectedActionID else {
                                    return
                                }
                                withAnimation(.easeInOut(duration: 0.12)) {
                                    proxy.scrollTo(selectedActionID, anchor: .center)
                                }
                                viewModel.consumeScrollTarget()
                            }
                        }
                        .frame(height: 298)

                        Divider()

                        statusBar
                    }
                }
            }
        }
        .frame(
            width: 700,
            height: (viewModel.pluginFormSession != nil || viewModel.isResultsVisible) ? 404 : 88,
            alignment: .top
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.12), value: viewModel.isResultsVisible)
        .onAppear {
            isSearchFocused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
        }
        .onExitCommand {
            if viewModel.handleEscape() {
                onClose()
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.statusMessage {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    @ViewBuilder
    private func actionRow(_ action: LauncherAction, selected: Bool, hovered: Bool) -> some View {
        HStack(spacing: 12) {
            if let icon = action.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            } else if let path = action.appIconPath {
                Image(nsImage: AppIconCache.shared.icon(for: path))
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.quaternary)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(action.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            (selected || hovered) ? Color.accentColor.opacity(selected ? 0.16 : 0.10) : .clear)
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            if let selected = viewModel.filteredActions.first(where: {
                $0.id == viewModel.selectedActionID
            }) {
                Text(selected.title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            } else {
                Text("Ready")
                    .font(.system(size: 11, weight: .semibold))
            }

            Spacer(minLength: 8)

            Text("↑↓ Navigate")
            Text("↩ Open")
            Text("Esc Close")
        }
        .font(.system(size: 11, weight: .regular))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 34)
    }
}
