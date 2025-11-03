import SwiftUI
import SwiftData

struct MigrationView: View {
    @Environment(MigrationManager.self) private var migrationManager: MigrationManager
    @Environment(UserManager.self) private var userManager: UserManager
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    
    var migrationComplete: () -> Void
    
    @State private var isRunning = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Migrating Your Data")
                        .font(.title3.weight(.semibold))
                    Group {
                        switch migrationManager.status {
                        case .completed:
                            Text("All set! Your deliveries have been migrated to our new iCloud‑backed database.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        case .failed:
                            Text("We couldn’t complete the migration. Please retry while connected to the internet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        default:
                            Text("One sec! We’re moving your deliveries to our new iCloud‑backed database. Keep the app open during migration.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Status / Progress
                Group {
                    switch migrationManager.status {
                    case .idle:
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.9)
                            Text("Preparing…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    case .preparing(let msg):
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.9)
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    case .running(let msg, let p):
                        VStack(alignment: .leading, spacing: 8) {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: p)
                                .progressViewStyle(.linear)
                                .tint(.storkBlue)
                                .animation(.default, value: p)
                        }
                    case .completed:
                        Label("Migration complete.", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    case .failed(let reason):
                        Label(reason, systemImage: "xmark.octagon.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Group {
                    switch migrationManager.status {
                    case .completed:
                        Button {
                            migrationComplete()
                        } label: {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .adaptiveGlass(tint: .storkBlue)
                        .foregroundStyle(.white)
                    case .running(_, let p):
                        ProgressView(value: p)
                            .progressViewStyle(.linear)
                            .tint(.storkBlue)
                            .animation(.default, value: p)
                    case .idle, .preparing:
                        ProgressView()
                    case .failed:
                        Button {
                            Task { await performMigration() }
                        } label: {
                            Text("Retry")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .adaptiveGlass(tint: .storkOrange)
                        .foregroundStyle(.white)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Migration")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await performMigration()
        }
    }
    
    func performMigration() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            try await migrationManager.performMigration(
                userManager: userManager,
                deliveryManager: deliveryManager
            )
            if case .completed = migrationManager.status {
                migrationComplete()
            }
        } catch {
            migrationManager.status = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Schema([Delivery.self, User.self, Baby.self]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let context = ModelContext(container)
    
    MigrationView(migrationComplete: {})
        .environment(MigrationManager())
        .environment(UserManager(context: context))
        .environment(DeliveryManager(context: context))
}
