# Flutter Navigation & Routing

**Summary**: Hệ thống điều hướng màn hình trong ứng dụng Flutter từ ngăn xếp Navigator 1.0 đến Router Navigator 2.0 và Deep Linking.

**Sources**: raw/Semester_8/PRM393_Mobile_Programming_Lập_trình_di_động.md

**Last updated**: 2026-09-20

---

Quản lý luồng di chuyển giữa các màn hình là thành phần trọng tâm của ứng dụng di động:

## Các Cơ chế Điều hướng
1. **Navigator 1.0 (Imperative):**
   - Sử dụng ngăn xếp (Stack) với các lệnh `Navigator.push()` và `Navigator.pop()`.
   - Named Routes: Khai báo bảng định tuyến tĩnh `routes: {'/home': (context) => HomeScreen()}`.
   - Truyền tham số màn hình qua `RouteSettings.arguments`.

2. **Navigator 2.0 (Declarative Router):**
   - Đồng bộ trạng thái URL trên trình duyệt web và desktop với ngăn xếp màn hình.
   - Các thành phần cốt lõi: `RouterDelegate`, `RouteInformationParser`, `BackButtonDispatcher`.

3. **Deep Linking:**
   - Cấu hình Intent-filter trên Android và Universal Links trên iOS để mở thẳng trang chi tiết ứng dụng từ liên kết web.

## Related pages

- [[prm393-mobile-programming]]
- [[flutter-widget-tree]]
