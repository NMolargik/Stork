import SwiftUI

struct DeliveryRowView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    
    var delivery: Delivery
    @State private var viewModel: ViewModel
    @State private var isHovered: Bool = false
    
    private var isRegularWidth: Bool {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad { return true }
        #endif
        return hSizeClass == .regular
    }
    
    init(delivery: Delivery) {
        self.delivery = delivery
        self._viewModel = State(wrappedValue: ViewModel(delivery: delivery))
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(viewModel.primaryTitle(useDayMonthYear: useDayMonthYearDates))
                        .font(.subheadline)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                
                HStack {
                    if viewModel.hasSecondary {
                        HStack(alignment: .center, spacing: 8) {
                            sexDots(viewModel.dotSegments)
                            
                            Text(viewModel.babySummary)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 2)
                        )
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if let name = viewModel.nicuSymbolName {
                            Image(systemName: name)
                                .imageScale(.small)
                                .frame(width: 10)
                                .foregroundStyle(viewModel.iconForegroundColor)
                                .padding(6)
                                .background(Circle().fill(viewModel.iconBackgroundColor))
                                .accessibilityLabel("NICU")
                        }
                        if let name = viewModel.epiduralSymbolName {
                            Image(systemName: name)
                                .imageScale(.small)
                                .frame(width: 10)
                                .foregroundStyle(viewModel.iconForegroundColor)
                                .padding(6)
                                .background(Circle().fill(viewModel.iconBackgroundColor))
                                .accessibilityLabel("Epidural")
                        }
                        if let name = viewModel.cSectionSymbolName {
                            Image(systemName: name)
                                .imageScale(.small)
                                .frame(width: 10)
                                .foregroundStyle(viewModel.iconForegroundColor)
                                .padding(6)
                                .background(Circle().fill(viewModel.iconBackgroundColor))
                                .accessibilityLabel("C-section")
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.7))
                .fontWeight(.semibold)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: viewModel.gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onChange(of: delivery.babyCount) { _, _ in
            self.viewModel = ViewModel(delivery: delivery)
        }
        .onChange(of: delivery.babies?.count ?? 0) { _, _ in
            self.viewModel = ViewModel(delivery: delivery)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.accessibilitySummary)
    }
    
    @ViewBuilder
    private func sexDots(_ segments: [DeliveryRowView.ViewModel.DotSegment]) -> some View {
        let total = segments.reduce(0) { $0 + $1.count }
        if total == 0 { EmptyView() } else {
            HStack(spacing: 4) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    ForEach(0..<seg.count, id: \.self) { _ in
                        Circle()
                            .fill(seg.color.gradient)
                            .frame(width: 6, height: 6)
                            .shadow(color: .black.opacity(0.2), radius: 1)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: total)
            .accessibilityLabel("Sex distribution: \(viewModel.maleCount) boys, \(viewModel.femaleCount) girls, \(viewModel.lossCount) losses")
        }
    }
    
    private func metricPill(title: String, value: String, tint: Color, textColor: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(title): \(value)")
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(tint)
                .shadow(color: .black.opacity(0.1), radius: 2)
        )
        .accessibilityLabel("\(title) \(value)")
    }
}

#Preview {
    DeliveryRowView(delivery: Delivery.sample())
        .frame(height: 80)
        .padding(.horizontal)
        .background(Color(.systemBackground))
}
