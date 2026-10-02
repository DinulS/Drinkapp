//
//  ContentView.swift
//  IT21260438
//
//  Created by Janith Kavinda on 2026-09-27.
//

import CoreData
import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case history
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "drop.fill"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selection: AppTab = .home
    @AppStorage(AppSettings.Key.remindersEnabled) private var remindersEnabled = true
    @AppStorage(AppSettings.Key.didAskNotifications) private var didAskNotifications = false

    var body: some View {
        VStack(spacing: 0) {
            TopTabBar(selection: $selection)

            TabView(selection: $selection) {
                HomeView()
                    .tag(AppTab.home)
                HistoryView()
                    .tag(AppTab.history)
                SettingsView()
                    .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.white)
        .task { await setUpReminders() }
    }

    /// Asks for notification permission once, then makes sure the reminder schedule is current.
    private func setUpReminders() async {
        if !didAskNotifications {
            didAskNotifications = true
            remindersEnabled = await NotificationManager.shared.requestAuthorization()
        }
        NotificationManager.shared.rescheduleReminders()
    }
}

/// Blue top tab bar with an animated underline, as in the design.
struct TopTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(selection == tab ? 1 : 0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)

                        ZStack {
                            if selection == tab {
                                Rectangle()
                                    .fill(.white)
                                    .matchedGeometryEffect(id: "underline", in: namespace)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selection)
        .background(Theme.primary.ignoresSafeArea(edges: .top))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
