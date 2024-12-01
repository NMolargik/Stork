//
//  MainView.swift
//
//
//  Created by Nick Molargik on 11/28/24.
//

#if !SKIP
import SwiftUI
#else
import SkipUI
#endif

public struct MainView: View {
    @AppStorage("selectedTab") var selectedTab = Tab.hospitals
    @State private var navigationPath: [String] = []
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // HOME
            VStack {
                NavigationStack(path: $navigationPath) {
                    Text("Home")
                    .navigationTitle("Stork")
                    .navigationDestination(for: String.self) { value in
                        if value == "ProfileView" {
                            Text("Shared Profile View")
                        } else {
                            Text("Other View: \(value)")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                withAnimation {
                                    navigationPath.append("ProfileView")
                                }
                            }, label: {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                            })
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .tabItem {
                Label(Tab.home.title, systemImage: Tab.home.icon)
            }
            .tag(Tab.home)
            
            // Deliveries
            VStack {
                NavigationStack(path: $navigationPath) {
                    List {
//                        NavigationLink("Go to Details", destination: Text("A different details view"))
                        
                        Button("Go to shared profile view") {
                            navigationPath.append("ProfileView")
                        }
                    }
                    .navigationTitle("Deliveries")
                    .navigationDestination(for: String.self) { value in
                        if value == "ProfileView" {
                            Text("Shared Profile View")
                        } else {
                            Text("Other View: \(value)")
                        }
                    }
                }
            }
            .tabItem {
                Label(Tab.deliveries.title, systemImage: Tab.deliveries.icon)
            }
            .tag(Tab.deliveries)

            
            // Hospitals
            HospitalListView(navigationPath: $navigationPath)
            .tabItem {
                Label(Tab.hospitals.title, systemImage: Tab.hospitals.icon)
            }
            .tag(Tab.hospitals)
            
            // Muster
            MusterTabView(navigationPath: $navigationPath)
            .tabItem {
                Label(Tab.muster.title, systemImage: Tab.muster.icon)
            }
            .tag(Tab.muster)
            
            // Settings
            VStack {
                NavigationStack(path: $navigationPath) {
                    List {
//                        NavigationLink("Go to Details", destination: Text("Jesus, another details view?"))
                        
                        Button("Go to shared profile view") {
                            navigationPath.append("ProfileView")
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationDestination(for: String.self) { value in
                        if value == "ProfileView" {
                            Text("Shared Profile View")
                        } else {
                            Text("Other View: \(value)")
                        }
                    }
                }
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)

        }
        #if !SKIP
        .accentColor(Color.indigo)
        #endif
    }
}

#Preview {
    MainView()
}
