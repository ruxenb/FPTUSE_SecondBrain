# PRJ301 - Java Web Application Development

**Summary**: Môn học phát triển ứng dụng web full-stack hướng đối tượng trên nền tảng Java EE với Servlet, JSP và mô hình kiến trúc MVC.

**Sources**: raw/Semester_4/PRJ301_Java_Web_Application_Development_Phát_triển_ứng_dụng_Java_web.md

**Last updated**: 2026-09-20

---

PRJ301 đưa sinh viên bước vào thế giới phát triển ứng dụng web thương mại:

## Kiến trúc Ứng dụng MVC
- **Model:** Các lớp JavaBeans đại diện cho dữ liệu và các lớp DAO (Data Access Object) giao tiếp với SQL Server qua JDBC.
- **View:** Giao diện người dùng render phía server bằng JavaServer Pages (JSP), JSTL và Expression Language (EL).
- **Controller:** Lớp điều phối xử lý nghiệp vụ thông qua Java Servlet và `web.xml` filter mapping.

## Quản lý Phiên & Bảo mật
- Quản lý phiên làm việc người dùng bằng `HttpSession` và `Cookies`.
- Phân quyền người dùng (Role-based access control) bằng Servlet Filter.

## Tiền đề
Được xây dựng từ [[pro192-object-oriented-programming]] và [[dbi202-database-systems]], mở đường cho dự án lớn [[swp391-software-development-project]].

## Related pages

- [[semester-4]]
- [[pro192-object-oriented-programming]]
- [[dbi202-database-systems]]
- [[swp391-software-development-project]]
- [[web-application-architecture]]
