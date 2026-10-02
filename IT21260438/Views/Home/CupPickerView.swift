//
//  CupPickerView.swift
//  IT21260438
//

import SwiftUI
import UIKit

/// Lets the user choose how much one tap on the drink button adds.
struct CupPickerView: View {
    @Binding var cupSize: Int

    @Environment(\.dismiss) private var dismiss
    @State private var customText = ""
    @FocusState private var customFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    private var customValue: Int? {
        guard let value = Int(customText), AppSettings.cupRange.contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AppSettings.cupSizes, id: \.self) { size in
                            cupOption(size)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom size")
                            .font(.headline)
                        HStack(spacing: 12) {
                            TextField("e.g. 330", text: $customText)
                                .keyboardType(.numberPad)
                                .focused($customFocused)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                            Text("ml")
                                .foregroundStyle(.secondary)
                            Button("Use") {
                                if let customValue { select(customValue) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.primary)
                            .disabled(customValue == nil)
                        }
                        Text("Between \(AppSettings.cupRange.lowerBound) and \(AppSettings.cupRange.upperBound) ml.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Switch cup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if !AppSettings.cupSizes.contains(cupSize) { customText = "\(cupSize)" }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func cupOption(_ size: Int) -> some View {
        let isSelected = size == cupSize
        let fill = 0.25 + 0.65 * CGFloat(size - 100) / 500
        return Button {
            select(size)
        } label: {
            VStack(spacing: 6) {
                CupIcon(size: 40, showPlus: false, fillLevel: min(max(fill, 0.2), 0.9))
                Text("\(size) ml")
                    .font(.subheadline)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(isSelected ? Theme.primaryLight : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Theme.primary : .clear, lineWidth: 2))
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func select(_ size: Int) {
        cupSize = size
        customFocused = false
        dismiss()
    }
}

#Preview {
    CupPickerView(cupSize: .constant(200))
}
