import SwiftUI
import CoreLocation

// MARK: - Trình quản lý GPS
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var addressText: String = "Đang lấy tọa độ GPS..."

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.location = loc
        self.addressText = String(format: "%.5f° N, %.5f° E", loc.coordinate.latitude, loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.addressText = "Chưa bật vị trí / Không có GPS"
    }
}

// MARK: - Giao diện chính
struct ContentView: View {
    @StateObject private var locManager = LocationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Thẻ tọa độ
                VStack(spacing: 8) {
                    Text("TỌA ĐỘ HIỆN TẠI ĐỂ ĐỌC CỨU HỘ")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(locManager.addressText)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.heavy)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Button(action: copyLocation) {
                        Label("Sao chép tọa độ", systemImage: "doc.on.doc")
                            .font(.footnote)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Đầu số khẩn cấp toàn quốc
                Text("ĐẦU SỐ TOÀN QUỐC")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    EmergencyButton(title: "112 - Cứu nạn", subtitle: "Tai nạn, đi rừng, bão lũ", color: .orange, phone: "112")
                    EmergencyButton(title: "115 - Cấp cứu", subtitle: "Y tế, chấn thương", color: .red, phone: "115")
                    EmergencyButton(title: "113 - Công an", subtitle: "An ninh, trộm cướp", color: .blue, phone: "113")
                    EmergencyButton(title: "114 - Cứu hỏa", subtitle: "Cháy nổ, kẹt vực", color: .purple, phone: "114")
                }

                // Nút SOS nhanh qua tin nhắn
                Button(action: sendSOSMessage) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Soạn SMS SOS kèm tọa độ gửi người thân")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Đường dây nóng hỗ trợ du khách các tỉnh trọng điểm
                Text("HOTLINE HỖ TRỢ DU KHÁCH")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    HotlineRow(region: "Đà Nẵng", phone: "02363550111")
                    HotlineRow(region: "Hà Nội", phone: "1800556896")
                    HotlineRow(region: "TP. Hồ Chí Minh", phone: "1022")
                    HotlineRow(region: "Lâm Đồng (Đà Lạt)", phone: "02633833833")
                    HotlineRow(region: "Lào Cai (Sa Pa)", phone: "02143871975")
                    HotlineRow(region: "Khánh Hòa (Nha Trang)", phone: "02583528000")
                }
            }
            .padding()
        }
    }

    private func copyLocation() {
        UIPasteboard.general.string = locManager.addressText
    }

    private func sendSOSMessage() {
        guard let loc = locManager.location else { return }
        let body = "SOS! Toi gap nan tai toa do: https://maps.google.com/?q=\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
        if let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "sms:&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Component nút bấm
struct EmergencyButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let phone: String

    var body: some View {
        Button(action: {
            if let url = URL(string: "tel://\(phone)") {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct HotlineRow: View {
    let region: String
    let phone: String

    var body: some View {
        HStack {
            Text(region)
                .fontWeight(.medium)
            Spacer()
            Button(action: {
                if let url = URL(string: "tel://\(phone)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(phone)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
