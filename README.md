# Hệ thống Quản lý Bãi Đỗ Xe - Parking Management System

## Giới thiệu

Đây là hệ thống quản lý bãi đỗ xe được phát triển với SQL Server, cung cấp các tính năng toàn diện để quản lý hoạt động của bãi đỗ xe trong môi trường học thuật. Hệ thống hỗ trợ quản lý xe ra vào, đăng ký gửi xe tháng dành cho sinh viên và giảng viên, và xử lý các báo cáo mất đồ.

## Kiến trúc Cơ sở dữ liệu

### Bảng dữ liệu chính

- **account**: Quản lý thông tin tài khoản người dùng
- **staff**: Thông tin nhân viên quản lý bãi xe
- **vehicle_type**: Loại phương tiện hỗ trợ
- **price**: Giá vé theo loại phương tiện
- **customer**: Thông tin khách hàng
- **lecturer_information/student_information**: Thông tin giảng viên/sinh viên
- **vehicle**: Thông tin phương tiện
- **parking_card**: Thẻ đỗ xe
- **payment**: Thông tin thanh toán
- **parking_record**: Ghi nhận xe đang trong bãi
- **parking_record_history**: Lịch sử ra vào bãi đỗ
- **active_monthly_registration**: Đăng ký gửi xe tháng đang hoạt động
- **expire_monthly_registration**: Lưu trữ đăng ký gửi xe tháng đã hết hạn
- **missing_report**: Quản lý báo cáo mất đồ

### Các ràng buộc và trigger

- **tr_check_staff_identification**: Kiểm tra trùng lặp mã định danh nhân viên
- **tr_check_monthly_registration_customer**: Chỉ cho phép giảng viên và sinh viên đăng ký gửi xe tháng
- **tr_check_parking_card_usage**: Đảm bảo thẻ đỗ xe không được sử dụng đồng thời

## Tính năng chính

### Quản lý bởi ADMIN

1. **Quản lý tài khoản và nhân viên**
   - Tạo tài khoản nhân viên (`sp_create_staff_account`)
   - Cập nhật thông tin nhân viên (`sp_update_staff`)
   - Kích hoạt/vô hiệu hóa tài khoản nhân viên (`sp_toggle_staff_status`)
   - Xem thông tin nhân viên (`sp_get_staff`, `sp_get_all_staff`)

2. **Quản lý giá vé**
   - Thiết lập giá vé cho các loại phương tiện khác nhau

### Quản lý bởi STAFF

1. **Quản lý xe ra vào**
   - Ghi nhận xe vào bãi (`sp_create_parking_record`)
   - Xử lý xe ra khỏi bãi và tính phí (`sp_process_vehicle_exit`)

2. **Đăng ký gửi xe tháng**
   - Xử lý đăng ký gửi xe tháng (`sp_create_active_monthly_registration`)
   - Kiểm tra và chuyển đổi đăng ký hết hạn (`sp_check_expired_monthly_registrations`)

3. **Xử lý báo cáo mất đồ**
   - Tạo báo cáo mất đồ (`sp_create_missing_report`)

## Quyền hạn người dùng

- **ADMIN**: Có quyền quản lý toàn bộ hệ thống, bao gồm quản lý nhân viên và thiết lập giá vé
- **STAFF**: Có quyền thực hiện các hoạt động hàng ngày như quản lý xe ra vào, xử lý đăng ký gửi xe tháng và báo cáo mất đồ

## Tổ chức mã nguồn

- **init.sql**: Script khởi tạo cơ sở dữ liệu, tạo bảng, stored procedures và triggers
- **staff/test_*.sql**: Scripts kiểm thử cho các stored procedures

## Hướng dẫn cài đặt

1. Đảm bảo SQL Server 2022 đã được cài đặt (hoặc chạy trong container Docker)
2. Thực thi script init.sql để khởi tạo cơ sở dữ liệu và các đối tượng
3. Tạo tài khoản người dùng admin và staff với quyền thích hợp
4. Sử dụng scripts kiểm thử để xác minh chức năng hoạt động đúng

## Lưu ý về kiểm thử

Các script kiểm thử trong thư mục staff cung cấp các tình huống kiểm thử cho từng stored procedure, bao gồm:
- Kiểm tra các trường hợp hợp lệ
- Kiểm tra các trường hợp ngoại lệ và xử lý lỗi
- Kiểm tra các ràng buộc và quy tắc nghiệp vụ

---

*Hệ thống được phát triển cho mục đích học tập và thực hành*