# Wiki Change Log

Nhật ký ghi lại lịch sử Ingest, cập nhật trang khái niệm và điều chỉnh trong kho tri thức Second Brain.

## 2026-09-20 (Batch Ingest Toàn Khóa 9 Học kỳ SE)
- **Source**: `raw/Semester_1` đến `raw/Semester_9` (98 tệp tài liệu giáo trình FLM)
- **Changes**: 
  - Khởi tạo trang lộ trình tổng thể [[fptu-se-curriculum]] kết nối toàn bộ 5 giai đoạn đào tạo.
  - Tạo 9 trang Hub học kỳ: [[semester-1]], [[semester-2]], [[semester-3]], [[semester-4]], [[semester-5]], [[semester-6]], [[semester-7]], [[semester-8]], [[semester-9]].
  - Ingest và tạo các trang môn học cốt lõi với chuỗi liên kết tiên quyết (Pre-requisites): [[prf192-programming-fundamentals]], [[pro192-object-oriented-programming]], [[csd201-data-structures-and-algorithms]], [[dbi202-database-systems]], [[prj301-java-web-development]], [[swe201c-software-engineering]], [[swp391-software-development-project]], [[swt301-software-testing]], [[ojt202-on-the-job-training]], [[swd392-software-architecture-and-design]], [[prm393-mobile-programming]], [[sep490-se-capstone-project]].
  - Tạo các trang khái niệm chuyên môn kỹ thuật sâu: [[object-oriented-programming]], [[software-engineering-lifecycle]], [[software-architecture-and-design-patterns]], [[dart-programming]], [[flutter-widget-tree]], [[flutter-navigation]], [[flutter-state-management]], [[flutter-networking-rest-api]], [[flutter-local-storage]], [[flutter-testing-debugging]].
  - Kết nối mạng lưới liên kết hai chiều toàn diện giữa các môn học và khái niệm.
  - Đồng bộ cập nhật toàn bộ danh mục tại [[index]].

## 2026-09-20 (Khởi tạo Hệ thống Second Brain)
- **Source**: `sample_vault/`
- **Changes**: 
  - Thiết lập kho `wiki/` với định dạng trang chuẩn hóa (Summary, Sources, Last updated, Related pages).
  - Tạo các trang khái niệm ban đầu: [[flutter-clean-architecture]], [[provider-pattern]], [[agile-scrum]].
  - Tạo [[index]] và [[log]].
  - Chuẩn hóa kho tài liệu gốc thành `raw/` (chứa 10 kỳ học từ FLM).
