# 04. TEAM CONVENTIONS, GIT WORKFLOW & DEMO SCRIPT
## Dự án: FPTU SE Knowledge (FPT University - PRM393)

---

## 1. CHIẾN LƯỢC QUẢN LÝ NHÁNH GIT (GITFLOW ĐƠN GIẢN HÓA)

Để tránh tối đa rủi ro hỏng mã nguồn trước ngày bảo vệ, nhóm áp dụng mô hình Git 3 cấp độ:

```
[main]          <─── (Chỉ merge khi hoàn thành MVP, dùng để chấm điểm & demo)
  ▲
  │ (Pull Request vào cuối Tuần 2 & Tuần 3 sau khi test kỹ)
[develop]       <─── (Nhánh tích hợp chung của 4 người, luôn chạy được)
  ▲
  ├────── feature/vault-fs           (Member 1: Filesystem & Sidebar)
  ├────── feature/editor-md          (Member 2: Markdown & Wikilinks)
  ├────── feature/ai-gemini          (Member 3: Gemini AI & Quiz)
  └────── feature/app-shell-graph    (Member 4: Layout Shell & GraphView)
```

### Các nguyên tắc vàng (Golden Rules):
1. **Tuyệt đối KHÔNG commit trực tiếp lên `main` hoặc `develop`**.
2. Mọi tính năng cá nhân đều xuất phát từ `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/ten-tinh-nang
   ```
3. Luôn cập nhật code mới nhất từ `develop` về nhánh cá nhân trước khi mở Pull Request:
   ```bash
   git checkout feature/ten-tinh-nang
   git fetch origin
   git merge origin/develop
   # Giải quyết conflict cục bộ (nếu có), chạy 'flutter run' kiểm tra ok rồi mới push
   git push origin feature/ten-tinh-nang
   ```

---

## 2. QUY ƯỚC ĐẶT TÊN COMMIT & PULL REQUEST

### 2.1. Quy ước Commit (Conventional Commits)
Cấu trúc commit message bắt buộc theo dạng:
```
<loại_thay_đổi>(<phân_hệ>): <mô tả ngắn gọn bằng tiếng Anh hoặc tiếng Việt không dấu>
```

* **`feat`**: Bổ sung một tính năng mới.
  * *Ví dụ:* `feat(vault): add local filesystem tree scanner using dart:io`
  * *Ví dụ:* `feat(ai): integrate gemini 3-question quiz generator`
* **`fix`**: Sửa một lỗi phát sinh.
  * *Ví dụ:* `fix(editor): resolve wikilink regex failing with uppercase titles`
* **`mock`**: Bổ sung hoặc cập nhật dữ liệu giả lập.
  * *Ví dụ:* `mock(contracts): implement MockNoteRepository with 3 sample notes`
* **`ui`**: Tinh chỉnh giao diện hoặc style theme.
  * *Ví dụ:* `ui(shell): adjust sidebar resizable width and dark theme colors`
* **`refactor`**: Cải tiến cấu trúc mã nguồn mà không đổi logic nghiệp vụ.
* **`docs`**: Cập nhật tài liệu kỹ thuật hoặc README.

### 2.2. Quy trình Pull Request & Code Review
* **Tiêu đề PR:** Giống định dạng Conventional Commit (Ví dụ: `[PR-Member-1] feat(vault): complete sidebar explorer with context menu`).
* **Mô tả PR:** Bắt buộc có 3 mục:
  1. *Tính năng đã hoàn thành.*
  2. *Hình ảnh / GIF chụp màn hình chạy thử trên Desktop.*
  3. *Hướng dẫn test nhanh (Ví dụ: Click nút Open Vault -> Chọn thư mục mẫu).*
* **Luật Approve:** Cần ít nhất **1 thành viên khác** bấm Approve thì mới được nhấn nút Merge vào `develop`.

---

## 3. CẨM NANG XỬ LÝ CONFLICT KINH ĐIỂN TRONG FLUTTER DESKTOP

Khi làm việc nhóm trong Flutter Desktop, các xung đột mã nguồn sau đây rất thường gặp:

### 3.1. Xung đột `main.dart`
* **Nguyên nhân:** Cả 4 thành viên cùng đăng ký Provider hoặc import màn hình của mình vào `main.dart`.
* **Cách giải quyết:**
  * Member 4 giữ vai trò chủ trì cấu hình `main.dart`.
  * Các thành viên khác chỉ khai báo sẵn tên Provider và Contract; khi tích hợp thì cùng họp thoại mở file để đối chiếu và giữ lại toàn bộ Provider của nhau.

### 3.2. Xung đột `pubspec.lock`
* **Nguyên nhân:** Thành viên chạy `flutter pub get` ở các phiên bản Flutter SDK khác nhau làm thay đổi mã hash của packages.
* **Cách phòng tránh & giải quyết:**
  * Thêm `pubspec.lock` vào `.gitignore` HOẶC quy ước cả nhóm dùng chung 1 phiên bản Flutter cố định (ví dụ: Flutter 3.22.x).
  * Nếu bị conflict, chạy lệnh:
    ```bash
    git checkout --theirs pubspec.lock
    flutter pub get
    ```

### 3.3. Xung đột thư mục Native Windows / macOS (`windows/flutter/generated_plugin_registrant.cc`)
* **Nguyên nhân:** Flutter tự động sinh ra các file này khi có plugin native mới (như `file_picker`).
* **Cách giải quyết:** File này do Flutter CLI tự tạo ra dựa trên `pubspec.yaml`. Khi bị conflict, có thể xóa file này đi và chạy lại:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d windows
  ```

---

## 4. KỊCH BẢN DEMO 5 PHÚT BẢO VỆ ĐỒ ÁN (DEFENSE SCRIPT)

Kịch bản được biên soạn chuyên nghiệp để gây ấn tượng mạnh với Giảng viên, chứng minh rõ cả 3 trụ cột kỹ thuật: **Desktop Native Filesystem + Trợ lý AI + UI/UX & Knowledge Graph**.

| Thời gian | Người trình bày & Thao tác | Lời thoại thuyết trình gợi ý (Script) | Mục tiêu chứng minh với Giảng viên |
| :---: | :--- | :--- | :--- |
| **0:00 – 1:00**<br>(1 Phút) | **Member 4 (Chủ tọa):**<br>- Mở ứng dụng từ màn hình Desktop Windows.<br>- Bấm nút `"Open Vault"` và chọn thư mục `FPTU_Study_Vault` thực tế trên ổ đĩa `D:\`.<br>- Thu phóng cửa sổ, kéo dãn các cột (Splitter). | *"Kính chào Thầy/Cô. Nhóm chúng em phát triển 'FPTU SE Knowledge' — hệ thống Second Brain thuần Desktop dành cho sinh viên SE. Điểm đặc biệt là ứng dụng hoạt động 100% trên hệ thống file Markdown cục bộ mà không phụ thuộc bất kỳ database nào, tôn trọng quyền riêng tư dữ liệu của sinh viên."* | - Giao diện Dark Theme chuyên nghiệp, chuẩn Desktop.<br>- Native File Picker hoạt động chuẩn xác. |
| **1:00 – 2:00**<br>(1 Phút) | **Member 1 & Member 2:**<br>- Member 1 nhấp chuột phải trên Sidebar: Tạo thư mục `PRM393`, tạo note `Clean_Architecture.md`.<br>- Member 2 gõ nội dung Markdown, gõ liên kết: `[[Flutter_Provider]]`.<br>- Nhấp chuột vào link `[[Flutter_Provider]]` $\rightarrow$ Ứng dụng tự động điều hướng mở trang mới. | *"Tiếp theo là khả năng quản lý file và liên kết tri thức phi tuyến tính. Bạn có thể tổ chức cây thư mục môn học linh hoạt. Khi sinh viên muốn liên kết kiến thức, chỉ cần dùng cú pháp `[[...]]`. Nhấp vào liên kết, hệ thống tự động nhận diện và mở bài học liên quan, hỗ trợ tính năng tự lưu Auto-save."* | - Cây thư mục (Filesystem) tương tác 2 chiều với ổ đĩa thật.<br>- Parser Markdown và tính năng Wikilinks điều hướng trơn tru. |
| **2:00 – 3:15**<br>(1 Phút 15s) | **Member 3:**<br>- Bấm nút `"⚡ Tóm tắt Note này"` trên AI Panel $\rightarrow$ Chờ 1s $\rightarrow$ AI trả về 3 gạch đầu dòng cô đọng.<br>- Bấm nút `"📝 Tạo 3 câu Quiz ôn tập"` $\rightarrow$ Hiển thị Card câu hỏi trắc nghiệm ôn thi PRM393.<br>- Gõ 1 câu hỏi vào ô chat AI: *"Giải thích sự khác nhau giữa Provider và Cubit?"*. | *"Điểm sáng tạo của nhóm là tích hợp Trợ lý AI học tập thông qua Gemini API. AI tự động đọc ngữ cảnh bài ghi chép sinh viên đang mở để tóm tắt kiến thức cốt lõi trước giờ thi, và tự động tạo 3 câu hỏi trắc nghiệm để sinh viên tự kiểm tra kiến thức ngay tại chỗ."* | - Tích hợp AI có chiều sâu ngữ cảnh (Context-aware), không chỉ là chatbot thông thường.<br>- Xử lý bất đồng bộ mượt mà, không đơ UI. |
| **3:15 – 4:15**<br>(1 Phút) | **Member 4:**<br>- Chuyển sang chế độ **"Knowledge Graph"**.<br>- Dùng chuột kéo rê (Pan) và cuộn chuột (Zoom in/out) đồ thị mạng lưới.<br>- Click vào một Node bất kỳ trên đồ thị $\rightarrow$ Màn hình tự động quay lại mở đúng Note đó trong Editor. | *"Và đây là tính năng đồ thị tri thức (Knowledge Graph). Toàn bộ liên kết `[[...]]` giữa các môn học PRM393, SWE201, CSD201 được biểu diễn trực quan. Khi click vào một điểm nút trên đồ thị, sinh viên có thể nhảy ngay đến bài học đó. Đồ thị giúp nhìn thấy bức tranh toàn cảnh kiến thức đại học."* | - Đồ thị tương tác trực quan cao cấp bằng `graphview`.<br>- Trải nghiệm tương tác hai chiều mượt mà. |
| **4:15 – 5:00**<br>(45 Giây) | **Cả nhóm:**<br>- Mở trang GitHub Insights của Repository.<br>- Trình chiếu biểu đồ Commits và Pull Requests của cả 4 thành viên. | *"Về mặt kỹ thuật, dự án tuân thủ nghiêm ngặt mô hình phân tầng Clean Lean: UI $\rightarrow$ Provider $\rightarrow$ Interface $\rightarrow$ Service. Cả 4 thành viên đều tham gia phát triển song song thông qua Mock Interface từ Day 2 và đóng góp cân bằng xấp xỉ 25% khối lượng công việc trên Git. Nhóm sẵn sàng nhận câu hỏi phản biện từ Thầy/Cô ạ!"* | - Chứng minh kiến trúc chuẩn mực (không viết bẩn, không lẫn lộn tầng).<br>- Minh chứng đóng góp công bằng 25%/người. |
