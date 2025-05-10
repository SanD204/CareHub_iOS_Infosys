//
//  PickerComponent.swift
//  Carehub
//
//  Created by user@87 on 23/04/25.
//

import Foundation
import SwiftUI

struct IntPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let title: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(value) \(unit)")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Picker("", selection: $value) {
                ForEach(Array(range), id: \.self) { num in
                    Text("\(num)")
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 120)
        }
    }
}

struct DecimalPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Int>
    let title: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f %@" : "%.1f %@", value, unit))
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            HStack(spacing: 0) {
                Picker("", selection: Binding(
                    get: { Int(value) },
                    set: { value = Double($0) + (value - Double(Int(value))) }
                )) {
                    ForEach(Array(range), id: \.self) { num in
                        Text("\(num)")
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 100)
                
                Text(".")
                    .font(.title2.bold())
                
                Picker("", selection: Binding(
                    get: { Int((value - Double(Int(value))) * 10) },
                    set: { value = Double(Int(value)) + Double($0) / 10.0 }
                )) {
                    ForEach(0..<10, id: \.self) { num in
                        Text("\(num)")
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 80)
            }
            .frame(height: 120)
        }
    }
}
