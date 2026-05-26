import SwiftUI

struct StaticAirplaneBanner: View {
    let title: String
    let subtitle: String

    private let airplaneWidth: CGFloat = 130
    private let bannerWidth: CGFloat = 460

    var body: some View {
        HStack(spacing: 0) {
            AirplaneShape()
                .frame(width: airplaneWidth, height: 90)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 2, y: 4)

            BannerCanvas(title: title, subtitle: subtitle)
                .frame(width: bannerWidth, height: 100)
        }
        .frame(width: airplaneWidth + bannerWidth, height: 120, alignment: .topLeading)
    }
}

struct AirplaneShape: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: 80, height: 8)
                .offset(y: 38)

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.82, green: 0.86, blue: 0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 32)

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.35, green: 0.55, blue: 0.78))
                        .frame(width: 14, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.35, green: 0.55, blue: 0.78))
                        .frame(width: 10, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.35, green: 0.55, blue: 0.78))
                        .frame(width: 10, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.35, green: 0.55, blue: 0.78))
                        .frame(width: 10, height: 8)
                }
                .offset(x: -25, y: -4)

                Triangle()
                    .fill(Color(red: 0.78, green: 0.18, blue: 0.22))
                    .frame(width: 18, height: 28)
                    .rotationEffect(.degrees(-90))
                    .offset(x: -64, y: 0)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.88, blue: 0.93), Color(red: 0.68, green: 0.72, blue: 0.78)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 70, height: 16)
                    .offset(x: 5, y: 14)

                Triangle()
                    .fill(Color(red: 0.78, green: 0.18, blue: 0.22))
                    .frame(width: 24, height: 26)
                    .offset(x: 50, y: -22)

                Ellipse()
                    .fill(Color(red: 0.78, green: 0.78, blue: 0.84))
                    .frame(width: 32, height: 10)
                    .offset(x: 52, y: -2)

                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .offset(x: -72, y: 0)
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 2, height: 28)
                    .offset(x: -72, y: 0)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct BannerCanvas: View {
    let title: String
    let subtitle: String

    var body: some View {
        Canvas { context, size in
            let bannerPath = makeBannerPath(in: CGRect(origin: .zero, size: size))

            context.fill(
                bannerPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.98, green: 0.32, blue: 0.36),
                        Color(red: 0.86, green: 0.20, blue: 0.26)
                    ]),
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                )
            )
            context.stroke(bannerPath, with: .color(.white.opacity(0.85)), lineWidth: 2)

            var cordPath = Path()
            cordPath.move(to: CGPoint(x: 0, y: 50))
            cordPath.addQuadCurve(
                to: CGPoint(x: 30, y: 55),
                control: CGPoint(x: 15, y: 48)
            )
            context.stroke(cordPath, with: .color(.black.opacity(0.55)), lineWidth: 1.5)

            let titleText = Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            let subtitleText = Text(subtitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            let centerX = size.width / 2 + 12
            context.draw(titleText, at: CGPoint(x: centerX, y: size.height / 2 - 13), anchor: .center)
            context.draw(subtitleText, at: CGPoint(x: centerX, y: size.height / 2 + 17), anchor: .center)
        }
    }

    private func makeBannerPath(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + 25, y: rect.minY + 15))

        path.addCurve(
            to: CGPoint(x: rect.maxX - 10, y: rect.minY + 10),
            control1: CGPoint(x: rect.width * 0.35, y: rect.minY + 5),
            control2: CGPoint(x: rect.width * 0.65, y: rect.minY + 18)
        )

        path.addLine(to: CGPoint(x: rect.maxX - 25, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY - 10))

        path.addCurve(
            to: CGPoint(x: rect.minX + 25, y: rect.maxY - 15),
            control1: CGPoint(x: rect.width * 0.65, y: rect.maxY - 18),
            control2: CGPoint(x: rect.width * 0.35, y: rect.maxY - 5)
        )

        path.closeSubpath()
        return path
    }
}
