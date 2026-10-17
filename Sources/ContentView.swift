import SwiftUI
import CoreLocation

// MARK: - Quản lý vị trí GPS
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var addressText: String = "Đang xác định GPS..."

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
        self.addressText = "Chưa bật GPS hoặc không có tín hiệu"
    }
}

// MARK: - Màn hình chính
struct ContentView: View {
    @StateObject private var locManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [PoliceUnit] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Thẻ định vị tọa độ GPS
                    VStack(spacing: 6) {
                        Text("TỌA ĐỘ HIỆN TẠI (ĐỌC CHO CỨU HỘ)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        Text(locManager.addressText)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.black)
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

                    // 4 đầu số khẩn cấp toàn quốc
                    Text("ĐẦU SỐ KHẨN CẤP TOÀN QUỐC")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        QuickCallButton(title: "112 - Cứu nạn", subtitle: "Sự cố, bão lũ, đi rừng", color: .orange, phone: "112")
                        QuickCallButton(title: "115 - Cấp cứu", subtitle: "Y tế, chấn thương", color: .red, phone: "115")
                        QuickCallButton(title: "113 - Công an", subtitle: "An ninh, trộm cắp", color: .blue, phone: "113")
                        QuickCallButton(title: "114 - Cứu hỏa", subtitle: "Cháy nổ, kẹt vực", color: .purple, phone: "114")
                    }

                    // Nút gửi tin nhắn SMS SOS
                    Button(action: sendSOSMessage) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Gửi SMS SOS kèm tọa độ")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // Tra cứu Công an Tỉnh / Huyện / Xã (Offline)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TRA CỨU CÔNG AN TỈNH / HUYỆN / XÃ (OFFLINE)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.top, 8)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Tìm theo tỉnh, quận, huyện, xã (vd: Đà Lạt, Sa Pa...)", text: $searchText)
                                .onChange(of: searchText) { newValue in
                                    if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                        searchResults = []
                                    } else {
                                        searchResults = PoliceDatabase.shared.search(query: newValue)
                                    }
                                }
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        if !searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(searchResults) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.unitName)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text(item.address)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button(action: {
                                            callNumber(item.phone)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "phone.fill")
                                                Text(item.phone)
                                            }
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }
                        } else if !searchText.isEmpty {
                            Text("Không tìm thấy đơn vị phù hợp trong dữ liệu mẫu.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    // Hotline hỗ trợ du lịch trọng điểm
                    Text("ĐƯỜNG DÂY NÓNG HỖ TRỢ DU KHÁCH")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        HotlineCard(place: "Đà Nẵng", phone: "02363550111")
                        HotlineCard(place: "Hà Nội", phone: "1800556896")
                        HotlineCard(place: "TP. Hồ Chí Minh", phone: "1022")
                        HotlineCard(place: "Lâm Đồng (Đà Lạt)", phone: "02633833833")
                        HotlineCard(place: "Lào Cai (Sa Pa)", phone: "02143871975")
                        HotlineCard(place: "Khánh Hòa (Nha Trang)", phone: "02583528000")
                    }
                }
                .padding()
            }
            .navigationTitle("SOS Việt Nam")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func copyLocation() {
        UIPasteboard.general.string = locManager.addressText
    }

    private func sendSOSMessage() {
        guard let loc = locManager.location else { return }
        let msg = "SOS! Toi dang gap nan can cuu ho tai: https://maps.google.com/?q=\(loc.coordinate.latitude),\(loc.coordinate.longitude) (Toa do: \(loc.coordinate.latitude), \(loc.coordinate.longitude))"
        if let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "sms:&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func callNumber(_ phone: String) {
        let cleanNumber = phone.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subviews
struct QuickCallButton: View {
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
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color)
            .cornerRadius(10)
        }
    }
}

struct HotlineCard: View {
    let place: String
    let phone: String

    var body: some View {
        HStack {
            Text(place)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Button(action: {
                let clean = phone.replacingOccurrences(of: " ", with: "")
                if let url = URL(string: "tel://\(clean)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(phone)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
