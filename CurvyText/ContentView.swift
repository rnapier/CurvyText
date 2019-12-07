//
//  ContentView.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI
import PathText

struct ContentView: View {
    @State var P0 = CGPoint(x: 50, y: 500)
    @State var P1 = CGPoint(x: 300, y: 300)
    @State var P2 = CGPoint(x: 400, y: 700)
    @State var P3 = CGPoint(x: 650, y: 500)

    
    let text: NSAttributedString = {
        let string = NSString("You can display text along a curve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 16)])

        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
        return s
    }()

    var body: some View {

        let path = Path() {
            $0.move(to: P0)
            $0.addCurve(to: P3, control1: P1, control2: P2)
        }

        return ZStack{
            Path() {
                $0.move(to: P0)
                $0.addCurve(to: P3, control1: P1, control2: P2)
            }
            .stroke(Color.blue, lineWidth: 2)

            PathText(text: text, path: path)

            ControlPoint(position: $P0)hte
                .foregroundColor(.green)

            ControlPoint(position: $P1)
                .foregroundColor(.black)

            ControlPoint(position: $P2)
                .foregroundColor(.black)

            ControlPoint(position: $P3)
                .foregroundColor(.red)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ControlPoint: View {
    let size = CGSize(width: 13, height: 13)

    @Binding var position: CGPoint

    var body: some View {
        Rectangle()
            .frame(width: size.width, height: size.height)  // Size of fill
            .frame(width: size.width * 3, height: size.height * 3) // Increase hit area
            .contentShape(Rectangle()) // Make whole area hittable
            .draggable(position: $position)
    }
}
