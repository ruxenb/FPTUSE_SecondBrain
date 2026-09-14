# 01. SPECIFICATION & SYSTEM REQUIREMENTS
## Dự án: FPTU SE Knowledge (Obsidian-like Second Brain)

---

## 1. TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW)

* **Tên sản phẩm:** FPTU SE Knowledge — Second Brain for Software Engineering Students.
* **Mục tiêu:** Xây dựng một ứng dụng Desktop (Windows / macOS) cá nhân hóa việc quản lý tri thức học tập cho sinh viên ngành Kỹ thuật Phần mềm (Software Engineering) tại Đại học FPT. Ứng dụng mô phỏng triết lý "Second Brain" của Obsidian: ghi chép phi tuyến tính (non-linear note-taking), liên kết 2 chiều (bidirectional linking via `[[WikiLinks]]`), trực quan hóa mạng lưới tri thức (Knowledge Graph), và tích hợp trợ lý AI học tập (Gemini API).
* **Đối tượng sử dụng:** Sinh viên SE cần hệ thống hóa tài liệu các môn học nặng lý thuyết và thực hành (PRM393, PRN231, SWE201, CSD201, OSG202...).

---

## 2. PHẠM VI & RÀNG BUỘC KỸ THUẬT (CONSTRAINTS)

| Tiêu chí | Ràng buộc kỹ thuật | Giải thích & Lý do |
| :--- | :--- | :--- |
| **Nền tảng mục tiêu** | Flutter Desktop | Tối ưu trải nghiệm làm việc đa nhiệm trên màn hình lớn của sinh viên. |
| **Lưu trữ dữ liệu** | 100% File Markdown (`.md`) trên ổ cứng cục bộ | **Zero Database**. Dữ liệu thuộc về người dùng, tương thích với Obsidian/VS Code, di chuyển thư mục dễ dàng. |
| **Quản lý trạng thái** | `Provider` (hoặc `ChangeNotifierProvider`) | Đơn giản, trực quan, phù hợp với người mới học Flutter, tài liệu phong phú. |
| **Mô hình AI** | Google Gemini API (`google_generative_ai`) | Miễn phí tier sinh viên, tốc độ phản hồi nhanh, hỗ trợ tóm tắt ngữ cảnh học tập tốt.

---

## 3. DANH SÁCH YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS - MVP)

### [FR-01] Khởi tạo & Mở Thư mục Lưu trữ (Vault Management)
* **Mô tả:** Người dùng có thể chọn một thư mục bất kỳ trên máy tính để làm "Vault" (kho tri thức). Ứng dụng nhớ đường dẫn Vault gần nhất.
* **Input:** Hộp thoại chọn thư mục (`file_picker`).
* **Process:** Đọc cấu trúc cây thư mục con và các file `.md`. Lưu đường dẫn vào bộ nhớ tạm/cấu hình ứng dụng.
* **Output:** Cây thư mục (Folder Tree) hiển thị đầy đủ trên Sidebar trái.
* **Acceptance Criteria:**
  * Chỉ quét các file `.md` và bỏ qua các thư mục ẩn (ví dụ: `.git`).
  * Xử lý trường hợp thư mục rỗng hoặc đường dẫn không hợp lệ.

---

### [FR-02] Quản lý File & Thư mục (Filesystem Explorer)
* **Mô tả:** Thao tác trực tiếp với hệ thống tệp tin trong Vault từ Sidebar.
* **Input:** Chuột phải (Context Menu) hoặc các nút bấm trên thanh công cụ Sidebar.
* **Chức năng chi tiết:**
  * Tạo Note mới (`.md`).
  * Tạo Thư mục con (Folder).
  * Đổi tên File / Thư mục.
  * Xóa File / Thư mục (có hộp thoại xác nhận).
* **Output:** Cập nhật ngay lập tức cấu trúc cây thư mục trên UI và đồng bộ trên ổ cứng.
* **Acceptance Criteria:**
  * Tên file không được chứa ký tự đặc biệt bị cấm trên Windows (`\ / : * ? " < > |`).
  * Khi đổi tên note, cảnh báo hoặc cập nhật tương đối nếu cần thiết.

---

### [FR-03] Soạn thảo & Xem trước Markdown (Note Editor & Preview)
* **Mô tả:** Trình soạn thảo văn bản Markdown hỗ trợ chia đôi màn hình (Split View) hoặc chuyển đổi nhanh giữa chế độ Edit và Preview.
* **Input:** Bàn phím người dùng gõ cú pháp Markdown chuẩn (Headings `#`, bold `**`, code block ```` ``` ````, list `-`, table).
* **Process:** Render Markdown thời gian thực qua thư viện `flutter_markdown`.
* **Output:** Giao diện xem trước đẹp mắt, căn lề chuẩn, font chữ Monospace/Sans hiện đại.
* **Lưu tự động (Auto-save):** Tự động lưu nội dung xuống file `.md` sau 1 giây người dùng dừng gõ (Debounce) hoặc khi bấm tổ hợp phím `Ctrl + S`.
* **Acceptance Criteria:** Không bị giật/lag khi gõ văn bản dài (>1000 từ). File trên đĩa cập nhật chính xác.

---

### [FR-04] Liên kết 2 chiều (Internal Wikilinks & Backlinks)
* **Mô tả:** Hạt nhân của Second Brain. Người dùng tạo liên kết giữa các bài học bằng cú pháp `[[Tên Note Khác]]`.
* **Quy trình xử lý:**
  1. Khi render preview, regex trích xuất toàn bộ cụm từ nằm trong `[[...]]` và hiển thị dưới dạng Hyperlink màu nổi bật (Accent Color).
  2. **Click Navigation:** Nhấp chuột vào link `[[PRM393_Flutter_Architecture]]`:
     * Nếu note tồn tại $\rightarrow$ Mở ngay note đó trong Editor.
     * Nếu note chưa tồn tại $\rightarrow$ Hiển thị popup hỏi: *"Note chưa tồn tại, bạn có muốn tự động tạo mới?"* $\rightarrow$ Tạo file và mở ra.
  3. **Backlinks Panel:** Ở chân trang hoặc Sidebar phải, hiển thị danh sách các note khác có liên kết trỏ về note hiện tại.
* **Acceptance Criteria:** Quét chính xác các liên kết trong Vault, không phân biệt hoa thường khi so sánh tên note.

---

### [FR-05] Trợ lý AI: Tóm tắt Note hiện tại (AI Note Summary)
* **Mô tả:** Trợ lý AI đọc nội dung của Note đang mở và tóm tắt thành các gạch đầu dòng cô đọng cho việc ôn thi nhanh.
* **Input:** Nhấn nút bấm nhanh `"⚡ Tóm tắt Note này"` trên AI Panel.
* **Process:** Ứng dụng lấy `Note.content`, gửi kèm prompt học thuật đến Gemini API:
  > *"Bạn là giảng viên SE FPTU. Hãy tóm tắt nội dung bài học sau thành 3-5 ý cốt lõi nhất, nhấn mạnh vào các từ khóa thi thực hành/lý thuyết: [NỘI DUNG NOTE]"*
* **Output:** Tin nhắn phản hồi từ AI hiển thị trong AI Panel với định dạng Markdown rõ ràng.
* **Acceptance Criteria:** Có hiệu ứng Loading (Spinner/Skeleton) khi chờ API, thông báo lỗi thân thiện nếu mất mạng hoặc API Key hết hạn.

---

### [FR-06] Trợ lý AI: Tạo Quiz ôn tập 3 câu hỏi (AI Quiz Generator)
* **Mô tả:** Tự động tạo bộ câu hỏi kiểm tra nhanh dựa trên nội dung bài ghi chép.
* **Input:** Nhấn nút `"📝 Tạo 3 câu Quiz ôn tập"`.
* **Process:** Gửi prompt yêu cầu Gemini trả về đúng 3 câu hỏi (trắc nghiệm 4 đáp án A, B, C, D kèm giải thích ngắn gọn).
* **Output:** Render dạng Card Quiz tương tác trực quan trong AI Panel (người dùng có thể nhấn xem đáp án).
* **Acceptance Criteria:** Đảm bảo câu hỏi bám sát nội dung note đang mở, không bịa đặt kiến thức ngoài lề.

---

### [FR-07] Trợ lý AI: Hỏi đáp tự do theo ngữ cảnh (AI Chat Panel)
* **Mô tả:** Khung trò chuyện linh hoạt, cho phép sinh viên hỏi mở rộng về các khái niệm lập trình (Design Patterns, Clean Architecture, giải thích code lỗi).
* **Input:** Ô nhập chat ở cột phải + nút Gửi (hoặc Enter).
* **Process:** Lưu lịch sử hội thoại tạm thời trong phiên làm việc (`List<ChatMessage>`).
* **Output:** Khung chat dạng bong bóng (User bubble bên phải, AI bubble bên trái hỗ trợ syntax highlighting).
* **Acceptance Criteria:** Scroll tự động xuống tin nhắn mới nhất, cho phép xóa lịch sử chat khi cần.

---

### [FR-08] Trực quan hóa Mạng lưới Tri thức (Knowledge Graph View)
* **Mô tả:** Biểu diễn trực quan toàn bộ Vault dưới dạng đồ thị (Nodes = Các bài Note, Edges = Liên kết `[[...]]`).
* **Input:** Dữ liệu phân tích liên kết từ `NoteRepository`.
* **Process:** Dùng thư viện `graphview` hoặc vẽ bằng `CustomPainter` để bố trí các Node dạng Force-Directed Graph.
* **Tương tác:**
  * Zoom in / Zoom out / Kéo rê đồ thị (Pan & Zoom).
  * Click vào một Node bất kỳ trên đồ thị $\rightarrow$ Tự động mở bài Note tương ứng trong Editor.
* **Acceptance Criteria:** Đồ thị hiển thị trực quan ít nhất từ 5–10 notes mẫu liên kết chéo; không bị đơ giật UI.

---

## 4. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS - NFR)

1. **NFR-01: Tốc độ & Tiêu tốn tài nguyên (Performance):**
   * Thời gian nạp cấu trúc Vault dưới 1 giây với thư mục chứa 100 notes.
   * Chuyển đổi giữa các note phản hồi tức thì (<100ms).
2. **NFR-02: Toàn vẹn dữ liệu (Data Integrity):**
   * Cơ chế ghi đè an toàn (Atomic File Write): Ghi tạm ra file phụ rồi rename để tránh hỏng dữ liệu khi ứng dụng tắt đột ngột.
3. **NFR-03: Hoạt động Offline-First:**
   * Mọi tính năng quản lý file, soạn thảo Markdown, Wikilinks, và Graph View hoạt động 100% khi không có Internet.
   * Chỉ có tính năng Gemini AI yêu cầu kết nối mạng.
4. **NFR-04: Giao diện trực quan & Hiện đại (UX/UI):**
   * Thiết kế giao diện Dark Mode chủ đạo (giống Obsidian / VS Code).
   * Phân chia bố cục 3 cột rõ ràng: Sidebar (Explorer) — Editor & Preview — AI & Graph Panel.

---

## 5. USER FLOW CHUẨN (END-TO-END DEMO FLOW)

Luồng trải nghiệm xuyên suốt cho người dùng và dùng để chấm điểm đồ án:

```
[BƯỚC 1: Khởi động]
       │
       ▼
[Nhấn "Open Vault" -> Chọn thư mục "FPTU_Notes" trên máy tính]
       │
       ▼
[Sidebar hiển thị cây thư mục các môn: PRM393, PRN231, SWE201...]
       │
       ▼
[BƯỚC 2: Soạn thảo & Liên kết]
       │
       ▼
[Mở note "Flutter_Architecture.md" -> Gõ nội dung và chèn link: "Xem thêm [[Provider_Pattern]]"]
       │
       ▼
[Nhấp vào link [[Provider_Pattern]] -> Hệ thống tự tạo file "Provider_Pattern.md" và mở Editor]
       │
       ▼
[BƯỚC 3: Trợ lý AI]
       │
       ▼
[Nhấn nút "⚡ Tóm tắt Note" trên AI Panel -> Gemini trả về 3 ý chính tóm tắt kiến thức]
       │
       ▼
[Nhấn nút "📝 Tạo 3 câu Quiz" -> Gemini tạo Card trắc nghiệm ôn tập thực chiến]
       │
       ▼
[BƯỚC 4: Trực quan hóa Tri thức]
       │
       ▼
[Chuyển sang tab "Knowledge Graph" -> Thấy 2 node liên kết với nhau bằng đường nối có mũi tên]
       │
       ▼
[Click vào Node "Flutter_Architecture" trên Graph -> Quay lại màn hình Editor note đó]
```
