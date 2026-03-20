# Apache Superset

Mô hình: `Problem - Solution - Architecture` + 5W1H (Why, What, How, When, Where, Who)

## Lời mở đầu

> Chào mọi người. Hôm nay, chúng ta sẽ cùng thảo luận về một bài toán nhức nhối trong hạ tầng dữ liệu của chúng ta: Làm sao để mở rộng khả năng phân tích dữ liệu (BI) cho toàn công ty mà không bị nghẽn về hiệu năng, và không bị 'đốt tiền' vào các license đắt đỏ. Giải pháp tôi muốn đề xuất và mổ xẻ hôm nay là **Apache Superset**.

## Agenda

- Hiện trạng sử dụng - Năng lực trực quan hóa Team GIS ?
- Why: Tại sao chúng ta cần Superset? - Vấn đề & Giải pháp ?
- What: Superset là gì? - Công nghệ ?
- How: Superset hoạt động như thế nào? - Kỹ thuật & Demo ?
- Who: Ai sẽ sử dụng Superset? - Con người ?
- Where: Superset được triển khai ở đâu? - Hạ tầng ?
- When: Lộ trình triển khai Superset ? - Thời gian ? Kế hoạch ?

## WHY - Vấn đề & Giải pháp

> Tại sao chúng ta cần Superset?

**Hiện trạng sử dụng BI Tools**: Năng lực trực quan hóa Team GIS

- Dự án:
  - Dự án công ty nước ngoài BI: Tua bin gió - Power BI
  - Dự án BTS
  - Đầu việc 1: Thu thập địa chỉ số
  - Đầu việc 2: Trực quan hóa dữ liệu Jira - Log Work
  - Đầu việc 3: Trực quan hóa dữ liệu Biso24 - Chấm công
  - Đầu việc 4: Trực quan hóa dữ liệu không gian Team GIS
- Mong muốn:
  - Quý 4/2026: Team xây dựng nền tảng Agentic GIS BI Platform

Agentic GIS BI Platform:

> Phản ứng nhanh với sự kiện: Phòng Kinh Doanh, GPKT, Ban Giám Đốc, Khách hàng, ... liên quan tới dữ liệu (dữ liệu địa chỉ, bao nhiêu nhóm lớp nền, mỗi lớp bao nhiêu đối tượng, có phủ toàn quốc ?)

- Hệ thống Phản ứng Khẩn cấp Thông minh (Smart Emergency Response) - một tình huống có sự cố an ninh (ví dụ: một vụ cháy hoặc báo động xâm nhập) tại một khu vực nhạy cảm.
- Truyền thống: Nhân viên trực tổng đài nhận tin, mở bản đồ xem vị trí, sau đó thủ công tìm kiếm các đơn vị an ninh gần nhất, kiểm tra trạng thái của họ qua bộ đàm, rồi mới ra lệnh điều động.
- Hiện đại:
  - Agent Tự Duy Lý (Reasoning): Nó xác định loại sự cố và mức độ ưu tiên.
  - Agent Truy Vấn Không Gian (Spatial Query): Tự động gọi API PostGIS để tìm 3 đội tuần tra gần nhất đang ở trạng thái "Sẵn sàng".
  - Agent Hành Động:
    - Tự động gửi lộ trình tối ưu nhất đến thiết bị cầm tay của các đội đó.
    - Điều khiển camera giám sát (CCTV) trong khu vực tự động xoay về hướng sự cố để truyền hình ảnh trực tiếp về trung tâm.
    - Đồng thời, BI Agent sẽ so sánh với lịch sử các vụ việc tương tự tại khu vực này để đưa ra cảnh báo về các rủi ro leo thang có thể xảy ra.

**Vấn đề**:

- Chi phí bản quyền (License) tăng cao khi mở rộng quy mô user (Tableau, PowerBI).
- Khó khăn trong việc tích hợp sâu (Embed) vào các ứng dụng nội bộ của công ty.
- Hiệu năng truy vấn giảm sút khi làm việc với tập dữ liệu lớn (Big Data).

**Giải pháp**: Giới thiệu Apache Superset là một nền tảng BI hiện đại, cloud-native, mã nguồn mở và cực kỳ "SQL-friendly".

- **Tối ưu chi phí:** Open-source, không giới hạn số lượng người dùng.
- **SQL-Friendly:** Phù hợp với văn hóa làm việc dựa trên SQL của team kỹ thuật.
- **Khả năng mở rộng (Scale):** Thiết kế Cloud-native, dễ dàng nâng cấp tài nguyên theo nhu cầu.
- **Tích hợp linh hoạt (Embed):** Dễ dàng nhúng (embed) các dashboard vào ứng dụng nội bộ.

## WHAT - Công nghệ

> Superset thực chất là cái gì?

Giới thiệu tổng quan nhưng đi sâu vào bản chất kỹ thuật.

- **Định nghĩa**: Một nền tảng Business Intelligence (BI) hiện đại, cloud-native.
- **Tech stack**: Được viết bằng Python (Flask), dùng React cho frontend.
- **Key Features**: SQL Lab (IDE viết SQL mạnh mẽ), No-code Viz Builder, và bộ Semantic Layer để định nghĩa dữ liệu thống nhất.

## HOW - Kỹ thuật & Demo

> Nó vận hành và kết nối như thế nào?

- **Architecture**: Giải thích về Backend (Gunicorn/Celery), Metadata database (PostgreSQL), và Caching (Redis).
- **Connectivity**: Cách nó "nói chuyện" với các nguồn dữ liệu. - **Ví dụ**: Làm thế nào để Superset kết nối qua Trino để truy vấn dữ liệu từ PostgreSQL hay Data Lake một cách mượt mà.
- **Security**: Cơ chế phân quyền (RBAC) chi tiết đến từng hàng dữ liệu (Row-level security).

## WHO - Con người

> Ai sẽ sử dụng và quản trị nó?

- **Data Engineer**: Người cài đặt, cấu hình kết nối, tối ưu hóa database/Trino.
- **Data Analyst**: Người dùng SQL Lab để tạo dataset và xây dựng Dashboard.
- **End-user (Business)**: Người xem báo cáo, tự thao tác filter/drill-down dữ liệu mà không cần biết code.

## WHERE - Infrastructure

> Triển khai ở đâu?

- **Deployment**: Chạy trên Docker Compose (cho dev/test) hoặc Helm Chart trên Kubernetes (cho production).
- **Integration**: Nó nằm ở đâu trong Data Pipeline hiện tại của công ty? (Nằm sau lớp Data Warehouse/Trino).

## WHEN - Roadmap

> Khi nào chúng ta nên bắt đầu?

- **Giai đoạn PoC (Proof of Concept)**: Dựng một bản demo nhỏ với các dữ liệu hiện có.
- **Giai đoạn Migration**: Khi nào thì chuyển các báo cáo cũ sang Superset.
- **Maintenance**: Kế hoạch backup metadata và nâng cấp phiên bản.

## Q & A

- So sánh & Lựa chọn
- Hiệu năng & Khả năng mở rộng
- Bảo mật & Phân quyền
- Vận hành & Phát triển
- Khả năng tùy biến
