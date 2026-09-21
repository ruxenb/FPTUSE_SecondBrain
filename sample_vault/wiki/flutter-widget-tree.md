# Flutter Widget Tree & UI Composition

**Summary**: Nguyên lý xây dựng giao diện người dùng trong Flutter theo triết lý 'Mọi thứ đều là Widget' và cây thành phần.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Trong Flutter, giao diện người dùng được biểu diễn dưới dạng cây cấu trúc các đối tượng Widget:

## Phân loại Widget
- **StatelessWidget:** Đại diện cho các phần tử UI bất biến, phụ thuộc hoàn toàn vào cấu hình đầu vào.
- **StatefulWidget:** Quản lý trạng thái có thể biến đổi theo thời gian thông qua đối tượng `State` và hàm `setState()`.

## Bố cục Giao diện (Layouts)
- **Cấu trúc Cơ sở:** `Scaffold`, `AppBar`, `Drawer`, `BottomNavigationBar`.
- **Flex Layout:** `Row` (ngang) và `Column` (dọc), kết hợp với `Expanded` và `Flexible` để quản lý tỷ lệ co giãn.
- **Danh sách & Lưới:** `ListView.builder` và `GridView.builder` hiển thị dữ liệu lớn với cơ chế tái sử dụng ô nhớ.
- **Responsive Layout:** Sử dụng `LayoutBuilder` và `MediaQuery` để điều chỉnh giao diện thích ứng từ điện thoại đến máy tính bảng và màn hình desktop.

## Tích hợp
Giao diện kết nối trực tiếp với tầng dữ liệu thông qua [[flutter-state-management]] và [[provider-pattern]].

## Related pages

- [[prm393-mobile-programming]]
- [[flutter-state-management]]
- [[flutter-clean-architecture]]
