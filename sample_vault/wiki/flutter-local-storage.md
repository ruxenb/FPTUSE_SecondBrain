# Flutter Local Storage & Offline Persistence

**Summary**: Phương pháp lưu trữ dữ liệu bền vững trên bộ nhớ thiết bị di động sử dụng SharedPreferences, SQLite và Hive.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Lưu trữ cục bộ giúp ứng dụng hoạt động mượt mà khi mất kết nối mạng và duy trì phiên đăng nhập của người dùng:

## Lựa chọn Công nghệ Lưu trữ Cục bộ
- **SharedPreferences:** Thích hợp lưu trữ dữ liệu dạng cặp Key-Value nhỏ như cài đặt giao diện (Dark Mode), cờ `isFirstTimeUser`, hoặc Token xác thực.
- **SQLite (`sqflite`):** Hệ quản trị cơ sở dữ liệu quan hệ cục bộ mạnh mẽ, phù hợp với dữ liệu phức tạp có cấu trúc bảng, khóa ngoại và truy vấn SQL tương tự [[dbi202-database-systems]].
- **Hive:** Cơ sở dữ liệu NoSQL dạng Key-Value cực nhanh viết hoàn toàn bằng Dart, tối ưu cho ứng dụng cần tốc độ đọc ghi tức thì.

## Quy tắc Thiết kế
Dữ liệu cục bộ được cô lập đằng sau tầng Repository trong mô hình [[flutter-clean-architecture]].

## Related pages

- [[prm393-mobile-programming]]
- [[dbi202-database-systems]]
- [[flutter-clean-architecture]]
