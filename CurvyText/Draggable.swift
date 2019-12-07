//
//  Draggable.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI

struct Draggable<Content: View>: View {
    let content: Content
    @Binding var position: CGPoint

    @State private var dragStart: CGPoint?  // Drag based on initial touch-point, not center

    var body: some View {
        content
            .position(position)
            .gesture(
                DragGesture().onChanged {
                    if self.dragStart == nil {
                        self.dragStart = self.position
                    }

                    if let dragStart = self.dragStart {
                        self.position = dragStart + $0.translation
                    }
                }
                .onEnded { _ in
                    self.dragStart = nil
                }
        )
    }
}

extension View {
    func draggable(position: Binding<CGPoint>) -> some View {
        Draggable(content: self, position: position)
    }
}
