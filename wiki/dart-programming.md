# Dart Programming Language

**Summary**: Ngôn ngữ lập trình hiện đại hướng đối tượng, tĩnh, tối ưu hóa cho giao diện người dùng và nền tảng của Flutter Framework.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Dart là ngôn ngữ lập trình được Google phát triển đặc biệt để xây dựng ứng dụng client nhanh trên mọi nền tảng:

## Đặc tính Nổi bật
- **Sound Null Safety:** Tránh lỗi null pointer exception tại runtime bằng cách phân biệt rõ ràng giữa kiểu dữ liệu non-nullable (`String`) và nullable (`String?`).
- **JIT & AOT Compilation:**
  - JIT (Just-In-Time) hỗ trợ tính năng Hot Reload tức thì khi lập trình.
  - AOT (Ahead-Of-Time) biên dịch thẳng sang mã máy gốc (ARM/x64) cho tốc độ thực thi 60/120fps mượt mà.
- **Lập trình Bất đồng bộ (Async Programming):**
  - Khái niệm Event Loop và Microtask Queue.
  - `Future` và cú pháp `async/await` xử lý tác vụ tốn thời gian.
  - `Stream` và `StreamController` xử lý luồng dữ liệu liên tục theo thời gian.

## Ứng dụng
Được sử dụng làm ngôn ngữ duy nhất trong môn [[prm393-mobile-programming]].

## Related pages

- [[prm393-mobile-programming]]
- [[flutter-widget-tree]]
- [[flutter-clean-architecture]]
