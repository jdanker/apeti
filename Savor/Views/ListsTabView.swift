//
//  ListsTabView.swift
//  Savor
//

import SwiftUI

/// The Lists tab: overview of every list (user-made and Smart Sort), with create/
/// rename/delete and the Smart Sort trigger. Tapping a list pushes ListDetailView.
/// Navigation carries the list *ID*, not the list value — the pushed view resolves
/// it live from AppState so renames and membership edits show up immediately.
struct ListsTabView: View {
    @Environment(AppState.self) private var state

    @State private var isPresentingNewList = false
    @State private var newListName = ""
    @State private var renamingList: RestaurantList? = nil
    @State private var renameDraft = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SavorBackground()

                if state.lists.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("Your Lists") {
                            ForEach(state.lists) { list in
                                NavigationLink(value: list.id) {
                                    listRow(list)
                                }
                                .contextMenu {
                                    Button("Rename", systemImage: "pencil") {
                                        renameDraft = list.name
                                        renamingList = list
                                    }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        state.deleteList(id: list.id)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                let ids = offsets.map { state.lists[$0].id }
                                for id in ids { state.deleteList(id: id) }
                            }
                        }
                        .textCase(nil)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Lists")
            .navigationDestination(for: UUID.self) { listID in
                ListDetailView(listID: listID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Smart Sort", systemImage: "wand.and.stars") {
                        state.runSmartSort()
                    }
                    .foregroundStyle(SavorTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New List", systemImage: "plus") {
                        newListName = ""
                        isPresentingNewList = true
                    }
                    .foregroundStyle(SavorTheme.accent)
                }
            }
            .alert("New List", isPresented: $isPresentingNewList) {
                TextField("Name", text: $newListName)
                Button("Create") { state.createList(name: newListName) }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Rename List", isPresented: Binding(
                get: { renamingList != nil },
                set: { if !$0 { renamingList = nil } }
            )) {
                TextField("Name", text: $renameDraft)
                Button("Save") {
                    if let list = renamingList {
                        state.renameList(id: list.id, to: renameDraft)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func listRow(_ list: RestaurantList) -> some View {
        HStack(spacing: 12) {
            Image(systemName: list.iconName)
                .foregroundStyle(SavorTheme.accent)
                .frame(width: 28)

            Text(list.name)
                .font(.body.weight(.medium))
                .foregroundStyle(SavorTheme.ink)

            Spacer()

            Text("\(list.restaurantIDs.count)")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Lists Yet", systemImage: "folder")
        } description: {
            Text("Create a list, or let Smart Sort file your saved spots into Coffee, Breakfast, Lunch, Dinner, and Takeout.")
        } actions: {
            Button("Smart Sort", systemImage: "wand.and.stars") {
                state.runSmartSort()
            }
            .buttonStyle(.borderedProminent)
            .tint(SavorTheme.accent)

            Button("New List") {
                newListName = ""
                isPresentingNewList = true
            }
        }
    }
}

#if DEBUG
#Preview {
    ListsTabView()
        .environment(AppState.preview)
}
#endif
