# Provider Pattern trong Flutter

**Summary**: Thư viện quản lý trạng thái chính thống cho Flutter cung cấp cơ chế Dependency Injection và đồng bộ dữ liệu giao diện.

**Sources**: sample_vault/PRM393/Provider_Pattern.md

**Last updated**: 2026-09-20

---

Provider là thư viện quản lý trạng thái phổ biến nhất trong Flutter:
- `ChangeNotifierProvider`: Quản lý các models thông báo thay đổi.
- `ProxyProvider`: Đồng bộ dữ liệu giữa các Provider.
- `context.watch()` & `context.read()`: Đọc và lắng nghe state trong widget tree.

Mô hình này là thành phần cốt lõi của [[flutter-clean-architecture]].

## Related pages

- [[flutter-clean-architecture]]
- [[agile-scrum]]
