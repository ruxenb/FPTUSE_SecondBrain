# 03. TASK BREAKDOWN & TEAM CONTRIBUTION MATRIX
## Dự án: FPTU SE Knowledge (FPT University - PRM393 Lab Project)

---

## 1. MỤC TIÊU PHÂN CHIA CÔNG VIỆC (EQUITABLE 25% PER MEMBER)

Để đảm bảo tính công bằng học thuật và đủ bằng chứng bảo vệ điểm số cá nhân trước hội đồng giảng viên FPTU:
* **Mỗi thành viên sở hữu 1 module chuyên biệt** bao gồm cả 3 thành tố: **Model/Interface $\rightarrow$ Service/Provider $\rightarrow$ UI Screen/Widget**.
* **Đóng góp vào Git:** Mỗi thành viên đóng góp xấp xỉ **25% (dao động từ 22% – 28%)** về số lượng Commits, Pull Requests, và Khối lượng mã nguồn (Lines of Code) có ý nghĩa.
* **Quy chuẩn kiểm thử chéo:** Không thành viên nào được tự duyệt PR của chính mình mà phải có ít nhất 1 thành viên khác Review & Approve.

---

## 2. BẢNG PHÂN CÔNG CÔNG VIỆC CHI TIẾT (WORK BREAKDOWN STRUCTURE)

### 📌 THÀNH VIÊN 1: HỆ THỐNG TỆP TIN & KHÁM PHÁ VAULT (MEMBER 1)
* **Trách nhiệm chính:** Quản lý toàn bộ thao tác Filesystem trên ổ đĩa máy tính và Sidebar điều hướng.
* **Thư mục & Tệp phụ trách chính trên `develop`:** `lib/screens/sidebar/`, `lib/models/vault_item.dart`, `lib/contracts/vault_service.dart`, `lib/mocks/mock_vault_service.dart`, `lib/services/local_vault_service.dart`, `lib/providers/vault_provider.dart`.

| Task ID | Nhiệm vụ chi tiết | Deliverables (Sản phẩm đầu ra) | Tiêu chí nghiệm thu (Acceptance Criteria) |
| :--- | :--- | :--- | :--- |
| **T1.1** | Định nghĩa `VaultItem` & `VaultService` contract | `lib/models/vault_item.dart`<br>`lib/contracts/vault_service.dart` | Code sạch, biên dịch không lỗi, có docstring giải thích rõ ràng. |
| **T1.2** | Viết `MockVaultService` | `lib/mocks/mock_vault_service.dart` | Trả về cây thư mục môn học giả lập (PRM393, SWE201...) có độ trễ 200ms. |
| **T1.3** | Xây dựng `VaultProvider` | `lib/providers/vault_provider.dart` | Quản lý state thư mục đang chọn, mở rộng/thu gọn (expand/collapse) các node folder. |
| **T1.4** | Thiết kế UI Sidebar TreeView | `lib/screens/sidebar/sidebar_explorer.dart` | Hiển thị cây thư mục đẹp mắt, icon phân biệt folder và file `.md`, chọn note kích hoạt callback. |
| **T1.5** | Xây dựng Context Menu thao tác | `lib/screens/sidebar/context_menu.dart` | Nhấp chuột phải: Tạo File, Tạo Folder, Đổi tên, Xóa có xác nhận Alert Dialog. |
| **T1.6** | Hiện thực `LocalVaultService` (Real) | `lib/services/local_vault_service.dart` | Quét ổ đĩa thật bằng `dart:io` và `path_provider`/`file_picker`, xử lý an toàn lỗi đường dẫn Windows. |

---

### 📌 THÀNH VIÊN 2: BÀI GHI CHÉP & LIÊN KẾT TRI THỨC (MEMBER 2)
* **Trách nhiệm chính:** Quản lý nội dung Markdown, phân tích cú pháp liên kết hai chiều `[[...]]` và Backlinks.
* **Thư mục & Tệp phụ trách chính trên `develop`:** `lib/screens/editor/`, `lib/models/note.dart`, `lib/contracts/note_repository.dart`, `lib/mocks/mock_note_repository.dart`, `lib/services/local_note_repository.dart`, `lib/providers/note_provider.dart`.

| Task ID | Nhiệm vụ chi tiết | Deliverables (Sản phẩm đầu ra) | Tiêu chí nghiệm thu (Acceptance Criteria) |
| :--- | :--- | :--- | :--- |
| **T2.1** | Định nghĩa `Note` model & `NoteRepository` | `lib/models/note.dart`<br>`lib/contracts/note_repository.dart` | Có đủ trường `path`, `content`, `outgoingLinks`, `backlinks`. |
| **T2.2** | Viết `MockNoteRepository` | `lib/mocks/mock_note_repository.dart` | Giả lập 3 note môn học có liên kết chéo, hỗ trợ hàm `extractWikilinks()` bằng regex. |
| **T2.3** | Xây dựng `NoteProvider` | `lib/providers/note_provider.dart` | Quản lý `currentNote`, cơ chế Auto-save (Debounce 1s), trạng thái `isDirty`. |
| **T2.4** | Xây dựng UI Note Editor | `lib/screens/editor/note_editor_screen.dart` | TextField hỗ trợ phím tắt, font chữ Monospace, hiển thị số từ, chuyển tab Edit / Preview. |
| **T2.5** | Tích hợp Markdown Preview & Wikilinks | `lib/screens/editor/note_editor_screen.dart` | Render Markdown với `flutter_markdown`. Nhấp vào `[[Link]]` tự động điều hướng hoặc tạo note mới. |
| **T2.6** | Xây dựng Backlinks Panel & Real Repo | `lib/screens/editor/backlinks_panel.dart`<br>`lib/services/local_note_repository.dart` | Quét ổ đĩa thật đọc file `.md`, liệt kê danh sách các note trỏ tới bài hiện tại. |

---

### 📌 THÀNH VIÊN 3: TRỢ LÝ TRÍ TUỆ NHÂN TẠO (MEMBER 3)
* **Trách nhiệm chính:** Tích hợp mô hình Gemini AI, xây dựng khung Chat và tính năng Tóm tắt.
* **Thư mục & Tệp phụ trách chính trên `develop`:** `lib/screens/ai/`, `lib/models/chat_message.dart`, `lib/contracts/ai_service.dart`, `lib/mocks/mock_ai_service.dart`, `lib/services/gemini_ai_service.dart`, `lib/providers/ai_provider.dart`.

| Task ID | Nhiệm vụ chi tiết | Deliverables (Sản phẩm đầu ra) | Tiêu chí nghiệm thu (Acceptance Criteria) |
| :--- | :--- | :--- | :--- |
| **T3.1** | Định nghĩa `ChatMessage` & `AIService` contract | `lib/models/chat_message.dart`<br>`lib/contracts/ai_service.dart` | Định nghĩa rõ các phương thức: `summarizeNote`, `sendChatMessage`. |
| **T3.2** | Viết `MockAIService` | `lib/mocks/mock_ai_service.dart` | Trả về dữ liệu tóm tắt và phản hồi chat mẫu có trễ 800ms để test UI Day 2. |
| **T3.3** | Xây dựng `AIProvider` | `lib/providers/ai_provider.dart` | Quản lý danh sách tin nhắn chat, cờ `isLoading`, xử lý lỗi Exception khi gọi API. |
| **T3.4** | Thiết kế UI Khung Chat AI | `lib/screens/ai/ai_chat_panel.dart` | Giao diện tin nhắn hai phía (User/AI), tự động scroll xuống dưới, khung nhập tin nhắn nhanh. |
| **T3.5** | Xây dựng Nút Tóm tắt & Chat UI | `lib/screens/ai/ai_chat_panel.dart` | Nút thao tác nhanh: "⚡ Tóm tắt Note"; Khung chat tương tác hai chiều. |
| **T3.6** | Hiện thực `GeminiAIService` (Real API) | `lib/services/gemini_ai_service.dart` | Tích hợp thư viện `google_generative_ai`, cấu hình System Prompt tối ưu cho môn học FPTU. |

---

### 📌 THÀNH VIÊN 4: KHUNG GIAO DIỆN SHELL & ĐỒ THỊ LIÊN KẾT (MEMBER 4)
* **Trách nhiệm chính:** Bố cục tổng thể 3 cột Resizable, App Theme, Status Bar và trực quan hóa Knowledge Graph.
* **Thư mục & Tệp phụ trách chính trên `develop`:** `lib/screens/shell_screen.dart`, `lib/screens/graph/`, `lib/providers/graph_provider.dart`, `lib/core/`, `lib/main.dart`.

| Task ID | Nhiệm vụ chi tiết | Deliverables (Sản phẩm đầu ra) | Tiêu chí nghiệm thu (Acceptance Criteria) |
| :--- | :--- | :--- | :--- |
| **T4.1** | Thiết lập App Theme & Constants | `lib/core/theme/app_theme.dart`<br>`lib/core/constants/app_colors.dart` | Bảng màu Dark Slate chuyên nghiệp, căn lề chuẩn Desktop, định nghĩa typography rõ nét. |
| **T4.2** | Xây dựng Shell 3 cột Resizable | `lib/screens/shell_screen.dart` | Phân chia: Cột trái (Sidebar) \| Giữa (Editor) \| Phải (AI & Graph). Cho phép kéo co giãn hoặc ẩn/hiện. |
| **T4.3** | Xây dựng AppBar & Status Bar | `lib/screens/shell_screen.dart` | AppBar hiển thị tên Vault & nút chuyển View; Status Bar hiển thị số từ, đường dẫn file, trạng thái lưu. |
| **T4.4** | Xây dựng `GraphProvider` | `lib/providers/graph_provider.dart` | Biến đổi danh sách Note và liên kết `outgoingLinks` thành tập hợp Nodes & Edges tương thích thư viện Graph. |
| **T4.5** | Hiện thực UI Knowledge Graph | `lib/screens/graph/knowledge_graph_screen.dart` | Vẽ đồ thị mạng lưới bằng `graphview`, hỗ trợ Pan/Zoom, click vào Node thì gọi `NoteProvider` mở bài. |
| **T4.6** | Điều phối Ghép nối & main.dart | `lib/main.dart` | Cấu hình `MultiProvider`, cờ `kUseMock`, điều hướng mượt mà giữa các thành phần của nhóm. |

---

## 3. MA TRẬN TRỌNG SỐ ĐÓNG GÓP (CONTRIBUTION WEIGHT MATRIX)

Bảng này được sử dụng làm căn cứ tự đánh giá (Peer Review) và báo cáo minh bạch cho Giảng viên:

| Thành viên | Phân hệ phụ trách (Module) | Điểm Story Points (Ước lượng) | Tỷ lệ đóng góp mục tiêu | Minh chứng đánh giá (Evidence trên `develop`) |
| :--- | :--- | :---: | :---: | :--- |
| **Member 1** | Filesystem Explorer & Sidebar Tree | 25 SP | **25%** | Các commit cho `lib/screens/sidebar/` và `local_vault_service.dart`. |
| **Member 2** | Markdown Editor & Wikilinks Engine | 25 SP | **25%** | Các commit cho `lib/screens/editor/` và `local_note_repository.dart`. |
| **Member 3** | Gemini AI Assistant & Chat System | 25 SP | **25%** | Các commit cho `lib/screens/ai/` và `gemini_ai_service.dart`. |
| **Member 4** | App Shell Layout & Knowledge Graph | 25 SP | **25%** | Các commit cho `shell_screen.dart`, `knowledge_graph_screen.dart`, theme. |
| **CẢ NHÓM** | **Tích hợp, Test & Demo (Integration)** | **100 SP** | **100%** | **4 thành viên cùng tham gia Test chéo và bảo vệ đồ án.** |

---

## 4. CHECKLIST TÍCH HỢP HỆ THỐNG (CROSS-MEMBER INTEGRATION CHECKLIST)

Quá trình ghép nối từ Mock sang Real diễn ra vào **Tuần 2** theo đúng trình tự sau:

* [ ] **Bước 1 (Day 2 - Skeleton Verification):**
  * Member 4 push layout `ShellScreen` với 3 cột rỗng lên nhánh `develop`.
  * Member 1, 2, 3 cắm màn hình của mình (dùng Mock) vào `ShellScreen`. Verify app chạy mượt, giao diện hài hòa.
* [ ] **Bước 2 (Cuối Tuần 1 - Interface Conformance):**
  * Cả 4 thành viên kiểm tra Real Service của mình có tuân thủ 100% interface trong thư mục `lib/contracts/` không.
* [ ] **Bước 3 (Đầu Tuần 2 - Kết nối Vault & Editor):**
  * Member 1 & Member 2 ngồi cặp (Pair Programming): Khi người dùng click chọn 1 file `.md` trên Sidebar của Member 1 $\rightarrow$ `NoteProvider` của Member 2 phải nhận được đường dẫn và tải nội dung lên Editor.
* [ ] **Bước 4 (Giữa Tuần 2 - Kết nối Editor & AI):**
  * Member 2 & Member 3 phối hợp: Khi bấm nút "Tóm tắt Note" trên AI Panel của Member 3 $\rightarrow$ `AIProvider` đọc nội dung từ `NoteProvider` của Member 2 để gửi lên Gemini API.
* [ ] **Bước 5 (Cuối Tuần 2 - Kết nối Note & Graph):**
  * Member 2 & Member 4 phối hợp: Khi Member 2 thêm mới một liên kết `[[...]]` vào bài note $\rightarrow$ `GraphProvider` của Member 4 tự động cập nhật thêm 1 cạnh (Edge) mới trên đồ thị Knowledge Graph.
* [ ] **Bước 6 (Tuần 3 - End-to-End Testing):**
  * Chạy thử toàn bộ User Flow trên máy tính sạch (chưa từng cài môi trường phát triển) để bảo đảm không lỗi đường dẫn hoặc thiếu file asset.
