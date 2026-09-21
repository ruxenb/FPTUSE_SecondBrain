# Flutter Testing & Debugging Essentials

**Summary**: Quy trình kiểm thử tự động đa tầng cho ứng dụng Flutter và kỹ thuật gỡ lỗi với Flutter DevTools.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Đảm bảo chất lượng ứng dụng di động trước khi phát hành lên Google Play và Apple App Store:

## Kim tự tháp Kiểm thử trong Flutter
1. **Unit Tests:** Kiểm thử các hàm logic nghiệp vụ, models, dịch vụ độc lập mà không cần dựng giao diện UI (sử dụng package `flutter_test`).
2. **Widget Tests:** Kiểm thử hành vi và khả năng tương tác của một hoặc nhiều Widget trong môi trường giả lập (sử dụng `WidgetTester`, `find.byType`, `tester.tap()`).
3. **Integration Tests:** Kiểm thử toàn diện hành trình người dùng thực tế trên thiết bị thật hoặc máy ảo (sử dụng package `integration_test`).

## Bộ công cụ Flutter DevTools
- **Widget Inspector:** Soi cây widget và điều chỉnh thuộc tính bố cục trực tiếp.
- **Performance Profiler:** Phát hiện hiện tượng giật hình (jank) và tối ưu hóa thời gian vẽ frame.
- **Network Profiler:** Theo dõi chi tiết các cuộc gọi HTTP và tải trọng JSON.

## Related pages

- [[prm393-mobile-programming]]
- [[swt301-software-testing]]
