//
//  FlippedUpsideDown.swift
//  chatOpenAi
//
//  Created by Oleksii Mykhalchuk on 2/24/24.
//

import SwiftUI

struct FlippedUpsideDown: ViewModifier {

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle.degrees(180.0))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

extension View {

    func flippedUpsideDown() -> some View {
        self
            .modifier(FlippedUpsideDown())
    }
}
