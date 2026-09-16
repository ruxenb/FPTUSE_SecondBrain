# Task 2 — Pre-commit Stabilization

## Dirty-note switching

Trước stabilization, khi người dùng sửa `A.md` rồi mở ngay `B.md` trước khi debounce auto-save chạy, timer của `A.md` bị hủy. Nội dung chưa lưu của `A.md` có thể bị mất.

`NoteProvider.openNote` hiện lưu ngay note đang dirty trước khi mở note đích. Chỉ sau khi lưu thành công provider mới mở note mới. Nếu lưu thất bại, provider giữ note hiện tại, giữ trạng thái dirty và expose error; note đích không được mở. Luồng này cũng giữ content của `A.md` gắn với đúng path của `A.md`.

## Stabilization tests

Ba test được thêm trong checkpoint này xác nhận:

- Sửa `A`, mở `B` trước debounce: `A` được lưu rồi `B` được mở.
- Sửa `A`, lưu thất bại khi mở `B`: `A` vẫn là current note, vẫn dirty và có error; `B` không được mở.
- Phím tắt `Ctrl+S` trong editor gọi manual save.

## Verification

- `flutter analyze`: PASS.
- `flutter test`: 18 tests PASS.
- `flutter run -d windows`: build và khởi động Windows desktop app PASS.

## Integration remaining

Manual editor flow đầy đủ hiện vẫn bị chặn bởi integration Vault → Editor: Member 1 cần cung cấp luồng chọn file Markdown và gọi `NoteProvider.openNote(filePath, vaultRoot: ...)`. Member 4 cần review các thay đổi shared ở application composition và shell trước khi chúng được commit riêng.
