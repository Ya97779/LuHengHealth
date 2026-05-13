//
//  NewColourWheel.swift
//  LuHengHeath
//
//  Created by macios on 2025/7/18.
//


//
//  NewColourWheel.swift
//  Colour Wheel
//
//  Created by Christian P on 11/6/20.
//

import SwiftUI

/// The actual colour wheel view.
struct NewColourWheel: View {
    
    /// Draws at a specified radius.
    var radius: CGFloat
    
    /// The RGB colour. Is a binding as it can change and the view will update when it does.
    /// /// 拖动实时预览颜色
    @Binding var previewColour: RGB

    /// 拖动结束后生效的颜色
    @Binding var rgbColour: RGB
    
    var body: some View {
        
        /// Geometry reader so we can know more about the geometry around and within the view.
        GeometryReader { geometry in
            ZStack {
                
                /// The colour wheel. See the definition.
                AngularGradientHueView(radius: self.radius)
                    /// Smoothing out of the colours.
                    .blur(radius: 10)
                    /// The outline.
                    .overlay(
                        Circle()
                            .size(CGSize(width: self.radius, height: self.radius))
                            .stroke(Color("Outline"), lineWidth: 10)
                            /// Inner shadow.
                            .shadow(color: Color("ShadowInner"), radius: 8)
                    )
                    /// Clip inner shadow.
                    .clipShape(
                        Circle()
                            .size(CGSize(width: self.radius, height: self.radius))
                    )
                    /// Outer shadow.
                    .shadow(color: Color("ShadowOuter"), radius: 15)
                
                /// This *is* required for the saturation scale of the wheel. It actually makes the gradient less "accurate" but looks nicer. It's basically just a white radial gradient that blends the colours together nicer.
                RadialGradient(gradient: Gradient(colors: [.white, Color.black.opacity(0.8)]), center: .center, startRadius: 0, endRadius: self.radius/2 - 10)
                    .blendMode(.screen)

                /// The little knob that shows selected colour.
                Circle()
                    .frame(width: 5, height: 5)
                    .offset(x: (self.radius/2 - 10) * self.previewColour.hsv.s)
                    .rotationEffect(.degrees(-Double(self.previewColour.hsv.h)))
                
            }
            /// The gesture so we can detect taps and drags on the wheel.
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        
                        /// Work out angle which will be the hue.
                        let y = geometry.frame(in: .global).midY - value.location.y
                        let x = value.location.x - geometry.frame(in: .global).midX
                        
                        /// Use `atan2` to get the angle from the center point then convert than into a 360 value with custom function(find it in helpers).
                        let hue = atan2To360(atan2(y, x))
                        
                        /// Work out distance from the center point which will be the saturation.
                        let center = CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY)
                        
                        /// Maximum value of sat is 1 so we find the smallest of 1 and the distance.
                        let saturation = min(distance(center, value.location)/(self.radius/2), 1)
                        
                        /// Convert HSV to RGB and set the colour which will notify the views.
                        previewColour = HSV(h: hue, s: saturation, v: 1).rgb
//                        self.rgbColour = HSV(h: hue, s: saturation, v: 1).rgb
                    }
                    .onEnded { _ in
                                            /// 拖动结束时才更新最终颜色
                                            rgbColour = previewColour
                                        }
                
            )
        }
        /// Set the size.
        .frame(width: self.radius, height: self.radius)
    }
}

struct NewColourWheel_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }

    struct PreviewWrapper: View {
        @State var prec = RGB(r: 0, g: 1, b: 1)
        @State var rgbc = RGB(r: 0, g: 1, b: 1)

        var body: some View {
            NewColourWheel(radius: 300,
                           previewColour: $prec,
                           rgbColour: $rgbc)
        }
    }
}



//
//  ColourStructs.swift
//  color wheel
//
//  Created by Christian P on 9/6/20.
//  Copyright © 2020 Christian P. All rights reserved.
//


/// This was all taken from here and only slightly edited. -> https://gist.github.com/FredrikSjoberg/cdea97af68c6bdb0a89e3aba57a966ce

/// Struct that holds red, green and blue values. Also has a `hsv` value that converts it's values to hsv.
struct RGB : Equatable {

    var r: CGFloat // Percent [0,1]
    var g: CGFloat // Percent [0,1]
    var b: CGFloat // Percent [0,1]
    
    static func toHSV(r: CGFloat, g: CGFloat, b: CGFloat) -> HSV {
        let min = r < g ? (r < b ? r : b) : (g < b ? g : b)
        let max = r > g ? (r > b ? r : b) : (g > b ? g : b)
        
        let v = max
        let delta = max - min
        
        guard delta > 0.00001 else { return HSV(h: 0, s: 0, v: max) }
        guard max > 0 else { return HSV(h: -1, s: 0, v: v) } // Undefined, achromatic grey
        let s = delta / max
        
        let hue: (CGFloat, CGFloat) -> CGFloat = { max, delta -> CGFloat in
            if r == max { return (g-b)/delta } // between yellow & magenta
            else if g == max { return 2 + (b-r)/delta } // between cyan & yellow
            else { return 4 + (r-g)/delta } // between magenta & cyan
        }
        
        let h = hue(max, delta) * 60 // In degrees
        
        return HSV(h: (h < 0 ? h+360 : h) , s: s, v: v)
    }
    
    var hsv: HSV {
        return RGB.toHSV(r: self.r, g: self.g, b: self.b)
    }
}

/// Struct that holds hue, saturation, value values. Also has a `rgb` value that converts it's values to hsv.
struct HSV {
    var h: CGFloat // Angle in degrees [0,360] or -1 as Undefined
    var s: CGFloat // Percent [0,1]
    var v: CGFloat // Percent [0,1]
    
    static func toRGB(h: CGFloat, s: CGFloat, v: CGFloat) -> RGB {
        if s == 0 { return RGB(r: v, g: v, b: v) } // Achromatic grey
        
        let angle = (h >= 360 ? 0 : h)
        let sector = angle / 60 // Sector
        let i = floor(sector)
        let f = sector - i // Factorial part of h
        
        let p = v * (1 - s)
        let q = v * (1 - (s * f))
        let t = v * (1 - (s * (1 - f)))
        
        switch(i) {
        case 0:
            return RGB(r: v, g: t, b: p)
        case 1:
            return RGB(r: q, g: v, b: p)
        case 2:
            return RGB(r: p, g: v, b: t)
        case 3:
            return RGB(r: p, g: q, b: v)
        case 4:
            return RGB(r: t, g: p, b: v)
        default:
            return RGB(r: v, g: p, b: q)
        }
    }
    
    var rgb: RGB {
        return HSV.toRGB(h: self.h, s: self.s, v: self.v)
    }
    
}
