import os
import sqlite3

os.makedirs("Sources", exist_ok=True)
db_path = os.path.join("Sources", "police_vn.sqlite")

if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE police_units (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level TEXT,
    province_name TEXT,
    district_name TEXT,
    commune_name TEXT,
    unit_name TEXT,
    phone TEXT,
    address TEXT
);
""")

cursor.execute("CREATE INDEX idx_search ON police_units(unit_name);")
cursor.execute("CREATE INDEX idx_loc ON police_units(province_name, district_name);")

data = [
    # Cấp Tỉnh / Thành phố
    ("province", "Hà Nội", "", "", "Công an Thành phố Hà Nội", "0692196777", "87 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội"),
    ("province", "Hồ Chí Minh", "", "", "Công an Thành phố Hồ Chí Minh", "0693187111", "268 Trần Hưng Đạo, Cầu Kho, Quận 1, TP.HCM"),
    ("province", "Đà Nẵng", "", "", "Công an Thành phố Đà Nẵng", "02363822300", "47 Lý Tự Trọng, Thạch Thang, Hải Châu, Đà Nẵng"),
    ("province", "Lâm Đồng", "", "", "Công an Tỉnh Lâm Đồng", "02633822035", "Số 04 Trần Bình Trọng, Phường 4, TP. Đà Lạt"),
    ("province", "Lào Cai", "", "", "Công an Tỉnh Lào Cai", "02143830022", "Đường Hoàng Liên, Cốc Lếu, TP. Lào Cai"),
    ("province", "Khánh Hòa", "", "", "Công an Tỉnh Khánh Hòa", "02583528113", "80 Trần Phú, Lộc Thọ, TP. Nha Trang"),
    ("province", "Đồng Tháp", "", "", "Công an Tỉnh Đồng Tháp", "02773851036", "Số 27 Lý Thường Kiệt, Phường 1, TP. Cao Lãnh"),
    ("province", "Cần Thơ", "", "", "Công an Thành phố Cần Thơ", "0693672113", "Số 9B Trần Phú, Cái Khế, Ninh Kiều, Cần Thơ"),
    ("province", "Hải Phòng", "", "", "Công an Thành phố Hải Phòng", "0692785113", "Số 3 Lê Đại Hành, Minh Khai, Hồng Bàng, Hải Phòng"),
    ("province", "Quảng Ninh", "", "", "Công an Tỉnh Quảng Ninh", "02033835901", "Cột 8, Phường Hồng Hà, TP. Hạ Long"),
    ("province", "Thừa Thiên Huế", "", "", "Công an Tỉnh Thừa Thiên Huế", "02343822305", "Số 27 Trần Cao Vân, Phú Hội, TP. Huế"),
    ("province", "Kiên Giang", "", "", "Công an Tỉnh Kiên Giang", "02973862040", "Số 544 Nguyễn Trung Trực, TP. Rạch Giá"),

    # Cấp Quận / Huyện
    ("district", "Hà Nội", "Hoàn Kiếm", "", "Công an Quận Hoàn Kiếm", "02438285223", "Số 2 Tràng Thi, Hàng Trống, Hoàn Kiếm, Hà Nội"),
    ("district", "Hà Nội", "Ba Đình", "", "Công an Quận Ba Đình", "02438232978", "116 Quán Thánh, Ba Đình, Hà Nội"),
    ("district", "Hồ Chí Minh", "Quận 1", "", "Công an Quận 1", "02838297643", "73 Yersin, Cầu Ông Lãnh, Quận 1, TP.HCM"),
    ("district", "Hồ Chí Minh", "TP. Thủ Đức", "", "Công an Thành phố Thủ Đức", "02838966109", "Số 9 Xa Lộ Hà Nội, Hiệp Phú, TP. Thủ Đức, TP.HCM"),
    ("district", "Đà Nẵng", "Hải Châu", "", "Công an Quận Hải Châu", "02363821372", "183 Phan Châu Trinh, Phước Ninh, Hải Châu, Đà Nẵng"),
    ("district", "Đà Nẵng", "Sơn Trà", "", "Công an Quận Sơn Trà", "02363844439", "216 Nguyễn Công Trứ, An Hải Bắc, Sơn Trà, Đà Nẵng"),
    ("district", "Lâm Đồng", "TP. Đà Lạt", "", "Công an Thành phố Đà Lạt", "02633822055", "53 Hùng Vương, Phường 9, TP. Đà Lạt"),
    ("district", "Lào Cai", "Thị xã Sa Pa", "", "Công an Thị xã Sa Pa", "02143871224", "Đường Điện Biên Phủ, TX. Sa Pa"),
    ("district", "Khánh Hòa", "TP. Nha Trang", "", "Công an Thành phố Nha Trang", "02583510113", "02 Lê Thánh Tôn, Lộc Thọ, TP. Nha Trang"),
    ("district", "Kiên Giang", "TP. Phú Quốc", "", "Công an Thành phố Phú Quốc", "02973846051", "Đường 30 Tháng 4, Dương Đông, TP. Phú Quốc"),
    ("district", "Đồng Tháp", "TP. Cao Lãnh", "", "Công an Thành phố Cao Lãnh", "02773851502", "Số 10 Nguyễn Huệ, Phường 1, TP. Cao Lãnh"),

    # Cấp Xã / Phường / Thị trấn
    ("commune", "Lâm Đồng", "TP. Đà Lạt", "Phường 1", "Công an Phường 1 - TP. Đà Lạt", "02633822055", "01 Lê Đại Hành, Phường 1, TP. Đà Lạt"),
    ("commune", "Lâm Đồng", "TP. Đà Lạt", "Phường 2", "Công an Phường 2 - TP. Đà Lạt", "02633822292", "29 Bùi Thị Xuân, Phường 2, TP. Đà Lạt"),
    ("commune", "Lâm Đồng", "TP. Đà Lạt", "Phường 10", "Công an Phường 10 - TP. Đà Lạt", "02633810113", "Quốc lộ 20, Trại Mát, Phường 10, TP. Đà Lạt"),
    ("commune", "Lào Cai", "Thị xã Sa Pa", "Phường Sa Pa", "Công an Phường Sa Pa", "02143871224", "Phường Sa Pa, TX. Sa Pa, Lào Cai"),
    ("commune", "Hà Nội", "Hoàn Kiếm", "Hàng Bạc", "Công an Phường Hàng Bạc", "02438253457", "44 Hàng Bạc, Hoàn Kiếm, Hà Nội"),
    ("commune", "Hà Nội", "Hoàn Kiếm", "Tràng Tiền", "Công an Phường Tràng Tiền", "02438253744", "02 Hai Bà Trưng, Hoàn Kiếm, Hà Nội"),
    ("commune", "Hồ Chí Minh", "Quận 1", "Bến Nghé", "Công an Phường Bến Nghé", "02838297672", "76 Pasteur, Bến Nghé, Quận 1, TP.HCM"),
    ("commune", "Hồ Chí Minh", "Quận 1", "Phạm Ngũ Lão", "Công an Phường Phạm Ngũ Lão", "02838367981", "102 Bùi Viện, Phạm Ngũ Lão, Quận 1, TP.HCM"),
    ("commune", "Đà Nẵng", "Hải Châu", "Hải Châu 1", "Công an Phường Hải Châu 1", "02363822452", "02 Trần Phú, Hải Châu 1, Hải Châu, Đà Nẵng"),
    ("commune", "Khánh Hòa", "TP. Nha Trang", "Lộc Thọ", "Công an Phường Lộc Thọ", "02583522113", "12 Hùng Vương, Lộc Thọ, TP. Nha Trang"),
    ("commune", "Kiên Giang", "TP. Phú Quốc", "Dương Đông", "Công an Phường Dương Đông", "02973846016", "Đường Nguyễn Trung Trực, Dương Đông, TP. Phú Quốc")
]

cursor.executemany("""
INSERT INTO police_units (level, province_name, district_name, commune_name, unit_name, phone, address)
VALUES (?, ?, ?, ?, ?, ?, ?)
""", data)

conn.commit()
conn.close()
print(f"Khoi tao co so du lieu thanh cong tai: {db_path}")
