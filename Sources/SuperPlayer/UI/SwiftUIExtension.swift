//
//  SwiftUIExtension.swift
//  Source
//
//  Created by Andrey Yoshua on 09/08/21.
//

import UIKit
import SwiftUI

public struct UIViewRepresented<UIViewType>: UIViewRepresentable where UIViewType: UIView {
    let makeUIView: (Context) -> UIViewType
    let updateUIView: (UIViewType, Context) -> Void
    
    public init(makeUIView: @escaping (Context) -> UIViewType, updateUIView: @escaping (UIViewType, Context) -> Void = { _, _ in }) {
        self.makeUIView = makeUIView
        self.updateUIView = updateUIView
    }
    
    public func makeUIView(context: Context) -> UIViewType {
        self.makeUIView(context)
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        self.updateUIView(uiView, context)
    }
}
