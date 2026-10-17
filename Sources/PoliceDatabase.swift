import Foundation
import SQLite3

struct PoliceUnit: Identifiable {
    let id: Int32
    let level: String
    let province: String
    let district: String
    let commune: String
    let unitName: String
    let phone: String
    let address: String
}

class PoliceDatabase {
    static let shared = PoliceDatabase()
    private var db: OpaquePointer?

    init() {
        // Tải file SQLite được đóng gói sẵn trong App Bundle
        if let path = Bundle.main.path(forResource: "police_vn", ofType: "sqlite") {
            if sqlite3_open(path, &db) != SQLITE_OK {
                print("Lỗi không thể mở database SQLite")
            }
        }
    }

    deinit {
        sqlite3_close(db)
    }

    // Tìm kiếm nhanh theo từ khóa (Ví dụ: "Đà Lạt", "Sa Pa", "Phường 1")
    func search(query: String) -> [PoliceUnit] {
        var results: [PoliceUnit] = []
        let sql = """
        SELECT id, level, province_name, district_name, commune_name, unit_name, phone, address 
        FROM police_units 
        WHERE unit_name LIKE ? OR province_name LIKE ? OR district_name LIKE ?
        LIMIT 50;
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            let pattern = "%\(query)%"
            sqlite3_bind_text(statement, 1, (pattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (pattern as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (pattern as NSString).utf8String, -1, nil)

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                let level = String(cString: sqlite3_column_text(statement, 1))
                let province = String(cString: sqlite3_column_text(statement, 2))
                let district = String(cString: sqlite3_column_text(statement, 3))
                let commune = String(cString: sqlite3_column_text(statement, 4))
                let unitName = String(cString: sqlite3_column_text(statement, 5))
                let phone = String(cString: sqlite3_column_text(statement, 6))
                let address = String(cString: sqlite3_column_text(statement, 7))

                results.append(PoliceUnit(id: id, level: level, province: province, district: district, commune: commune, unitName: unitName, phone: phone, address: address))
            }
        }
        sqlite3_finalize(statement)
        return results
    }
}
