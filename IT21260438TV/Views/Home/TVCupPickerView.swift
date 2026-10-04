//
//  TVCupPickerView.swift
//  IT21260438TV
//

import SwiftUI

/// Lets the user choose how much one click on the gauge adds. Press Menu / Back on the remote to close.
struct TVCupPickerView: View {
    @Binding var cupSize: Int

    @Environment(\.dismiss) private var dismiss
    @State private var customSize: Int
    @FocusState private var focusedSize: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 40), count: 4)

    init(cupSize: Binding<Int>) {
        _cupSize = cupSize
        _customSize = State(initialValue: cupSize.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            Text("Switch cup")
                .font(.title.bold())
                .foregroundStyle(.black)

            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(AppSettings.cupSizes, id: \.self) { size in
                    cupOption(size)
                }
            }

            HStack(alignment: .bottom, spacing: 60) {
                TVAdjuster(
                    title: "Custom size",
                    value: "\(customSize) ml",
                    onDecrease: { customSize = max(customSize - 10, AppSettings.cupRange.lowerBound) },
                    onIncrease: { customSize = min(customSize + 10, AppSettings.cupRange.upperBound) }
                )
                Button("Use \(customSize) ml") { select(customSize) }
                Spacer()
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
        .defaultFocus($focusedSize, cupSize)
    }

    private func cupOption(_ size: Int) -> some View {
        let isSelected = size == cupSize
        let fill = 0.25 + 0.65 * CGFloat(size - 100) / 500
        return Button {
            select(size)
        } label: {
            VStack(spacing: 14) {
                CupIcon(size: 80, showPlus: false, fillLevel: min(max(fill, 0.2), 0.9))
                Text("\(size) ml")
                    .font(.headline)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(isSelected ? Theme.primaryLight : Color.clear)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                        .padding(14)
                }
            }
        }
        .buttonStyle(.card)
        .focused($focusedSize, equals: size)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select(_ size: Int) {
        cupSize = size
        dismiss()
    }
}

#Preview {
    TVCupPickerView(cupSize: .constant(200))
}
