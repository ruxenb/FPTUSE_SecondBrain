# Flutter State Management Strategies

**Summary**: Các chiến lược và giải pháp quản lý trạng thái dữ liệu trong ứng dụng Flutter từ cục bộ đến toàn cục.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Quản lý trạng thái là vấn đề quan trọng nhất quyết định khả năng mở rộng và hiệu năng của ứng dụng Flutter:

## Phân cấp Trạng thái
- **Ephemeral State (Trạng thái cục bộ):** Dữ liệu chỉ nằm trong một widget duy nhất (ví dụ: tab đang chọn, trạng thái đóng mở animation). Xử lý đơn giản bằng `StatefulWidget`.
- **App State (Trạng thái toàn cục):** Dữ liệu được chia sẻ giữa nhiều màn hình (ví dụ: thông tin đăng nhập người dùng, giỏ hàng, danh sách bài viết đã tải).

## Các Giải pháp Quản lý Trạng thái Phổ biến
1. **Provider:** Giải pháp chính thống được Google khuyến nghị cho ứng dụng vừa và nhỏ, xem chi tiết tại [[provider-pattern]].
2. **Bloc / Cubit:** Quản lý state theo luồng sự kiện (Event-driven) và Streams, rất phổ biến trong các dự án doanh nghiệp lớn.
3. **Riverpod:** Thế hệ cải tiến của Provider không phụ thuộc vào `BuildContext` và an toàn tại compile time.

## Tích hợp Kiến trúc
Quản lý state là cầu nối trung gian trong mô hình [[flutter-clean-architecture]].

## Related pages

- [[prm393-mobile-programming]]
- [[provider-pattern]]
- [[flutter-clean-architecture]]
