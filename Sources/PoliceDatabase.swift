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
        if let path = Bundle.main.path(forResource: "police_vn", ofType: "sqlite") {
            if sqlite3_open(path, &db) != SQLITE_OK {
                print("Lỗi: Không thể mở file SQLite.")
            }
        } else {
            print("Lỗi: Không tìm thấy file police_vn.sqlite trong App Bundle.")
        }
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    func search(query: String) -> [PoliceUnit] {
        guard let db = db, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        var results: [PoliceUnit] = []
        let sql = """
        SELECT id, level, province_name, district_name, commune_name, unit_name, phone, address
        FROM police_units
        WHERE unit_name LIKE ? OR province_name LIKE ? OR district_name LIKE ? OR commune_name LIKE ?
        ORDER BY CASE level WHEN 'commune' THEN 1 WHEN 'district' THEN 2 ELSE 3 END
        LIMIT 60;
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            let pattern = "%\(query)%"
            let cPattern = (pattern as NSString).utf8String

            sqlite3_bind_text(stmt, 1, cPattern, -1, nil)
            sqlite3_bind_text(stmt, 2, cPattern, -1, nil)
            sqlite3_bind_text(stmt, 3, cPattern, -1, nil)
            sqlite3_bind_text(stmt, 4, cPattern, -1, nil)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int(stmt, 0)
                let level = String(cString: sqlite3_column_text(stmt, 1))
                let province = String(cString: sqlite3_column_text(stmt, 2))
                let district = String(cString: sqlite3_column_text(stmt, 3))
                let commune = String(cString: sqlite3_column_text(stmt, 4))
                let unitName = String(cString: sqlite3_column_text(stmt, 5))
                let phone = String(cString: sqlite3_column_text(stmt, 6))
                let address = String(cString: sqlite3_column_text(stmt, 7))

                results.append(PoliceUnit(
                    id: id,
                    level: level,
                    province: province,
                    district: district,
                    commune: commune,
                    unitName: unitName,
                    phone: phone,
                    address: address
                ))
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
}
