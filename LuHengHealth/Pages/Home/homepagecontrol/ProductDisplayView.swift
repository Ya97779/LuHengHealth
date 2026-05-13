import SwiftUI
import SceneKit

struct ProductDisplayView: View {
    @Binding var modelBackground: Color
    @Binding var modelColor: Color
    var onClose: (() -> Void)? = nil
    @State private var brightnessValue: Double = 1.0

    var body: some View {
        VStack(alignment: .leading) {
            Text("产品展示")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            // 3D Model Display
            Model3DView(ModelColor: $modelColor, brightness: $brightnessValue)
                .frame(height: 250)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.bottom, 10)

            // Product Info (Placeholder)
            HStack {
                Text("智能项链")
                    .font(.headline)
                Spacer()
                Text("¥ 999.00")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)


            Text("一款集健康监测、时尚设计于一体的智能项链，为您带来全新的生活体验。")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.top, 2)
            HStack {
                Spacer()
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct ProductDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDisplayView(modelBackground: .constant(.blue), modelColor: .constant(.red))
    }
}
