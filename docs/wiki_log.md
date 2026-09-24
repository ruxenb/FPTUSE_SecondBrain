# Wiki Change Log

Nhật ký ghi lại lịch sử Ingest, cập nhật trang khái niệm và điều chỉnh trong kho tri thức Second Brain.

## 2026-09-21 (Batch Ingest Toàn diện 54 Môn học & Hoàn thiện 100% Khung Đào tạo)
- **Source**: `raw/Semester_0` đến `raw/Semester_9` (54 tệp giáo trình bổ sung, nâng tổng số lên 112 trang wiki)
- **Changes**:
  - Tạo trang Hub `semester-0` cho giai đoạn dự bị và định hướng tân sinh viên.
  - Ingest 10 môn học Kỳ 0: Tuần định hướng `otp101-orientation-and-training`, Thể chất 1 (`cov111-chess-1`, `vov114-vovinam-1`), và 7 môn Nhạc cụ truyền thống dân tộc (`dba103-traditional-instrument-dan-bau`, `dng103-traditional-instrument-dan-nguyet`, `dnh103-traditional-instrument-dan-nhi`, `dsa103-traditional-instrument-sao-truc`, `dtb103-traditional-instrument-dan-ty-ba`, `dtr103-traditional-instrument-dan-tranh`, `trg103-traditional-instrument-trong-dan-toc`).
  - Ingest các môn kỹ năng bổ trợ và thể chất Kỳ 1 & 2: `csi106-introduction-to-computer-science`, `ssl101c-academic-skills`, `ssg104-communication-and-in-group-skills`, `cov121-chess-2`, `vov124-vovinam-2`, `cov131-chess-3`, `vov134-vovinam-3`.
  - Ingest các môn Ngoại ngữ tiếng Nhật & tiếng Hàn: `jpd113-elementary-japanese-1`, `jpd123-elementary-japanese-2`, `jpd133-elementary-japanese-3`, `jpd316-intermediate-japanese-1`, `jis401-japanese-in-software`, `jit401-information-technology-japanese`, `kor311-intermediate-korean-1`.
  - Ingest toàn bộ các môn Chuyên ngành Tự chọn Kỳ 5 (SE_COM_1): `fer202-front-end-web-development`, `prn212-cross-platform-programming-net`, `hsf302-spring-framework`, `prp201c-python-programming`, `pds301m-python-for-applied-data-science`, `iao201c-information-assurance`, `fgu301-fundamental-game-development`, `eci101-electronic-components-and-circuits`.
  - Ingest toàn bộ các môn Chuyên ngành Tự chọn Nâng cao Kỳ 7 (SE_COM_2 & SE_COM_3): `sdn302-server-side-development-nodejs`, `sba301-spring-boot-spa-integration`, `prn222-advanced-cross-platform-programming-net`, `mma301-multiplatform-mobile-app-development`, `ail304m-machine-learning`, `mds301-machine-learning-in-data-science`, `dbm301-data-mining`, `dhv301-data-handling-and-visualization`, `agu301-advanced-game-development`, `pru213-game-programming-with-csharp`, `gdc301-game-design-fundamentals`, `mip201-microcontroller-programming`, `dcd301-digital-circuit-design`.
  - Ingest khối môn Lý luận Chính trị & Tư tưởng: `mln111-marxist-leninist-philosophy`, `mln122-marxist-leninist-political-economy`, `mln131-scientific-socialism`, `hcm202-ho-chi-minh-ideology`, `vnr202-history-of-communist-party`.
  - Ingest các hình thức Đồ án & Khóa luận Tốt nghiệp thay thế Kỳ 9: `set490-se-graduation-thesis`, `exe402-startup-graduation-project`, `pit490-it-interdisciplinary-project`, `grc490-interdisciplinary-graduation-thesis`.
  - Cập nhật toàn bộ các trang Hub học kỳ `semester-1` đến `semester-9` và `fptu-se-curriculum`.
  - Cập nhật danh mục tra cứu toàn diện tại `index`.

## 2026-09-20 (Batch Ingest Toàn Khóa 9 Học kỳ SE)
- **Source**: `raw/Semester_1` đến `raw/Semester_9` (98 tệp tài liệu giáo trình FLM)
- **Changes**: 
  - Khởi tạo trang lộ trình tổng thể `fptu-se-curriculum` kết nối toàn bộ 5 giai đoạn đào tạo.
  - Tạo 9 trang Hub học kỳ: `semester-1`, `semester-2`, `semester-3`, `semester-4`, `semester-5`, `semester-6`, `semester-7`, `semester-8`, `semester-9`.
  - Ingest và tạo các trang môn học cốt lõi với chuỗi liên kết tiên quyết (Pre-requisites): `prf192-programming-fundamentals`, `pro192-object-oriented-programming`, `csd201-data-structures-and-algorithms`, `dbi202-database-systems`, `prj301-java-web-development`, `swe201c-software-engineering`, `swp391-software-development-project`, `swt301-software-testing`, `ojt202-on-the-job-training`, `swd392-software-architecture-and-design`, `prm393-mobile-programming`, `sep490-se-capstone-project`.
  - Tạo các trang khái niệm chuyên môn kỹ thuật sâu: `object-oriented-programming`, `software-engineering-lifecycle`, `software-architecture-and-design-patterns`, `dart-programming`, `flutter-widget-tree`, `flutter-navigation`, `flutter-state-management`, `flutter-networking-rest-api`, `flutter-local-storage`, `flutter-testing-debugging`.
  - Kết nối mạng lưới liên kết hai chiều toàn diện giữa các môn học và khái niệm.
  - Đồng bộ cập nhật toàn bộ danh mục tại `index`.

## 2026-09-20 (Khởi tạo Hệ thống Second Brain)
- **Source**: `sample_vault/`
- **Changes**: 
  - Thiết lập kho `wiki/` với định dạng trang chuẩn hóa (Summary, Sources, Last updated, Related pages).
  - Tạo các trang khái niệm ban đầu: `flutter-clean-architecture`, `provider-pattern`, `agile-scrum`.
  - Tạo `index`.
  - Chuẩn hóa kho tài liệu gốc thành `raw/` (chứa 10 kỳ học từ FLM).
