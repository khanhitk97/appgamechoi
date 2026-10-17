import SwiftUI
import CoreLocation
import AVFoundation

// MARK: - Trình quản lý GPS & Tự Động Phân Giải Tên Địa Phương
class EmergencyLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var location: CLLocation?
    @Published var wardName: String = "Đang định vị..."
    @Published var districtName: String = "Đang tìm quận/huyện..."
    @Published var provinceName: String = ""
    @Published var accuracyMeters: Int = 0
    @Published var isReady: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.location = loc
        self.accuracyMeters = max(5, Int(loc.horizontalAccuracy))

        // Dịch tọa độ sang tên địa bàn hành chính Việt Nam (Phường/Xã, Quận/Huyện, Tỉnh)
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, error in
            guard let self = self, let p = placemarks?.first, error == nil else { return }
            DispatchQueue.main.async {
                let ward = p.subLocality ?? p.thoroughfare ?? ""
                let district = p.subAdministrativeArea ?? ""
                let province = p.administrativeArea ?? ""

                if !ward.isEmpty { self.wardName = ward }
                if !district.isEmpty { self.districtName = district }
                if !province.isEmpty { self.provinceName = province }
                self.isReady = true
            }
        }
    }
}

// MARK: - Giao Diện Chính
struct ContentView: View {
    @StateObject private var locManager = EmergencyLocationManager()

    // Dữ liệu đơn vị công an được chọn (mặc định lấy theo GPS hoặc chọn thủ công)
    @State private var selectedWardName: String = "Đà Lạt"
    @State private var selectedWardPhone: String = "02633822055"
    @State private var selectedDistrictName: String = "TP. Đà Lạt"
    @State private var selectedDistrictPhone: String = "02633822055"

    // Quản lý thông tin liên hệ người thân (ICE) lưu vĩnh viễn trong máy
    @AppStorage("iceContactName") private var iceName: String = "Mẹ"
    @AppStorage("iceContactPhone") private var icePhone: String = "0900000000"

    // Điều khiển Sheet và Alert
    @State private var showingChangeLocationSheet = false
    @State private var showingEditICEAlert = false
    @State private var tempIceName = ""
    @State private var tempIcePhone = ""
    @State private var isFlashlightOn = false

    var body: some View {
        ZStack {
            // Nền đen chuẩn OLED
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    
                    // 1. THANH TIÊU ĐỀ (HEADER)
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.red)
                            Text("Gọi Khẩn")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Nút bật/tắt đèn pin báo hiệu khẩn cấp
                        Button(action: toggleFlashlight) {
                            ZStack {
                                Circle()
                                    .fill(isFlashlightOn ? Color.yellow.opacity(0.25) : Color(white: 0.16))
                                    .frame(width: 44, height: 44)
                                Image(systemName: isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(isFlashlightOn ? .yellow : .white)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)

                    // 2. THẺ VỊ TRÍ GPS HIỆN TẠI
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.8))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(locManager.isReady ? locManager.wardName : selectedWardName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Text("GPS ±\(locManager.accuracyMeters > 0 ? "\(locManager.accuracyMeters)m" : "20m") · vừa xong")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            showingChangeLocationSheet = true
                        }) {
                            Text("Chạm để đổi")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(white: 0.12))
                    .cornerRadius(16)

                    // 3. THẺ ĐỎ HERO: CÔNG AN PHƯỜNG / XÃ HIỆN TẠI
                    Button(action: {
                        callNumber(selectedWardPhone)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CA \(selectedWardName)")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(formatPhoneNumber(selectedWardPhone))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            Spacer()

                            Image(systemName: "phone.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.trailing, 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color(red: 0.74, green: 0.12, blue: 0.11))
                        .cornerRadius(20)
                    }

                    // Dòng nhắc nhở nghiệp vụ
                    Text("Khi gọi: nói rõ địa điểm và sự việc.")
                        .font(.system(size: 13.5))
                        .foregroundColor(Color(white: 0.55))
                        .padding(.top, 2)
                        .padding(.bottom, 2)

                    // 4. HÀNG 3 ĐẦU SỐ CỨU NẠN TOÀN QUỐC (113, 114, 115)
                    HStack(spacing: 10) {
                        QuickCallCard(number: "113", label: "Cảnh sát")
                        QuickCallCard(number: "114", label: "Chữa cháy")
                        QuickCallCard(number: "115", label: "Cấp cứu")
                    }

                    // 5. THẺ TRỰC BAN CÔNG AN HUYỆN / QUẬN
                    Button(action: {
                        callNumber(selectedDistrictPhone)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Trực ban CA \(selectedDistrictName)")
                                    .font(.system(size: 16.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(formatPhoneNumber(selectedDistrictPhone))
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "phone.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(Color(white: 0.12))
                        .cornerRadius(16)
                    }

                    // 6. THẺ LIÊN HỆ NGƯỜI THÂN (ICE)
                    HStack(spacing: 14) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 28)

                        Button(action: {
                            callNumber(icePhone)
                        }) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(iceName.isEmpty ? "Người thân" : iceName)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)

                                Text(formatPhoneNumber(icePhone))
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.gray)
