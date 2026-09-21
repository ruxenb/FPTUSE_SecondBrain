# Flutter Networking & RESTful API Integration

**Summary**: Kỹ thuật giao tiếp mạng, gửi HTTP requests, ánh xạ dữ liệu JSON sang Model và xử lý giao diện bất đồng bộ với FutureBuilder.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Hầu hết các ứng dụng di động hiện đại đều hoạt động dựa trên việc trao đổi dữ liệu với máy chủ backend:

## Các Bước Tích hợp Mạng Chuẩn mực
1. **Gửi HTTP Requests:** Sử dụng thư viện `http` hoặc `dio` để thực hiện các phương thức GET, POST, PUT, DELETE kèm theo Headers và Authentication Token.
2. **JSON Serialization:** Chuyển đổi chuỗi JSON từ server thành các đối tượng Dart Model thông qua hàm `fromJson` và `toJson`.
3. **FutureBuilder Widget:** Quản lý 3 trạng thái của request bất đồng bộ trên giao diện:
   - Đang tải: Hiển thị `CircularProgressIndicator`.
   - Lỗi: Hiển thị giao diện báo lỗi kèm nút Retry.
   - Thành công: Render danh sách dữ liệu với `ListView`.
4. **Retry & Caching Layer:** Lưu trữ tạm thời kết quả gọi mạng để giảm tải băng thông và hỗ trợ hoạt động ngoại tuyến.

## Related pages

- [[prm393-mobile-programming]]
- [[flutter-clean-architecture]]
- [[flutter-local-storage]]
