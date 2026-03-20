## Short

Hôm nay chúng ta sẽ cùng tìm hiểu sâu về **kiến trúc hệ thống chart của Apache Superset** — cơ chế phía sau giúp Superset có thể hiển thị các biểu đồ đẹp, linh hoạt và hiệu quả.

Ở mức tổng quan, kiến trúc charting của Superset được xây dựng dựa trên 4 nguyên tắc chính: **linh hoạt** để hỗ trợ nhiều loại biểu đồ, **hiệu năng** để xử lý tập dữ liệu lớn, **khả năng mở rộng** để cho phép tạo chart tùy chỉnh, và **trải nghiệm nhất quán** giữa các loại visualization khác nhau.

Toàn bộ hệ thống có thể được nhìn theo 3 lớp chính: **data layer**, **visualization layer** và **interaction layer**.

- **Data layer** chịu trách nhiệm lấy dữ liệu từ database. Khi tạo chart, người dùng thực chất đang cấu hình một truy vấn dựa trên metric, dimension, filter và các tham số khác trong chart editor. Superset dùng **SQLAlchemy** để sinh và chạy truy vấn động. Sau khi database trả dữ liệu về ở dạng bảng, Superset có thể thực hiện thêm các bước hậu xử lý như pivot, tính phần trăm, format hoặc biến đổi dữ liệu trước khi render.
- **Visualization layer** là nơi dữ liệu được biến thành biểu đồ ở phía frontend. Superset chủ yếu sử dụng **Apache ECharts** làm thư viện chart mặc định từ phiên bản 2.0, đồng thời vẫn hỗ trợ các thư viện khác như **D3.js** cho một số loại visualization đặc thù.
- **Interaction layer** đảm nhiệm việc kết nối giữa cấu hình người dùng, truy vấn backend và rendering phía frontend, giúp toàn bộ trải nghiệm chart hoạt động mượt và đồng nhất.

Luồng hoạt động cơ bản của chart trong Superset là: người dùng cấu hình chart trên frontend, dữ liệu cấu hình được gửi về backend Flask/Python, backend dùng các **Viz classes** để chuyển form data thành query, query được chạy trên database, dữ liệu thô được trả về, Superset có thể hậu xử lý rồi gửi lại frontend dưới dạng **JSON**, sau đó plugin chart ở frontend sẽ render thành biểu đồ hoàn chỉnh.

Về **hiệu năng**, Superset có nhiều cơ chế tối ưu như dùng thư viện visualization hiệu quả, hỗ trợ progressive loading, client-side caching và virtualization cho các chart dạng bảng. Những kỹ thuật này giúp hệ thống vẫn phản hồi tốt ngay cả với dữ liệu lớn.

Một điểm rất mạnh khác là **khả năng mở rộng**. Nếu các chart có sẵn chưa đáp ứng nhu cầu, bạn có thể xây dựng **custom visualization plugin** riêng bằng JavaScript/React. Plugin này có thể tích hợp trực tiếp vào Superset như chart gốc, hỗ trợ đầy đủ các tính năng như lưu, export và đưa vào dashboard. Điều này cho phép doanh nghiệp mở rộng Superset cho các bài toán đặc thù như network graph, biểu đồ 3D hoặc các visualization chuyên ngành.

Tóm lại, kiến trúc chart của Apache Superset vận hành theo chuỗi: **frontend cấu hình chart → backend sinh query → database trả dữ liệu → frontend plugin render biểu đồ**, tạo nên một hệ thống vừa mạnh, vừa linh hoạt, vừa dễ mở rộng.

---

## Full

Chào mừng đến với nội dung hôm nay, nơi chúng ta sẽ cùng đi sâu vào **kiến trúc hệ thống chart của Apache Superset**.

Trong phần này, chúng ta sẽ khám phá cách bộ máy visualization của Superset hoạt động phía sau, cũng như cách nền tảng mã nguồn mở mạnh mẽ này có thể render những biểu đồ đẹp và linh hoạt mà chúng ta thường thấy khi sử dụng.

Hãy bắt đầu từ góc nhìn tổng quan.

Kiến trúc charting của Apache Superset được thiết kế dựa trên một số nguyên tắc cốt lõi. Thứ nhất là **tính linh hoạt**, nhằm hỗ trợ nhiều loại visualization khác nhau. Thứ hai là **hiệu năng**, để có thể xử lý các tập dữ liệu lớn. Thứ ba là **khả năng mở rộng**, cho phép bổ sung các loại biểu đồ tùy chỉnh. Và cuối cùng là **trải nghiệm người dùng nhất quán**, bảo đảm các loại chart khác nhau vẫn có cảm giác sử dụng đồng bộ và dễ tiếp cận.

Ở mức cao nhất, hệ thống charting của Superset gồm **ba lớp chính**:

- **Data layer**
- **Visualization layer**
- **Interaction layer**

Chúng ta sẽ lần lượt đi qua từng lớp.

### Data layer

**Data layer** chịu trách nhiệm lấy dữ liệu từ các cơ sở dữ liệu đã kết nối.

Khi bạn tạo một chart trong Superset, về bản chất bạn đang định nghĩa một truy vấn sẽ được thực thi trên data source của mình. Truy vấn này được hình thành dựa trên các thành phần mà bạn cấu hình trong chart editor, chẳng hạn như:

- metrics
- dimensions
- filters
- time range
- và các tham số khác

Superset sử dụng **SQLAlchemy**, một bộ công cụ SQL rất mạnh trong Python, để sinh và thực thi các truy vấn này một cách động.

Sau khi truy vấn được thực thi, kết quả sẽ được trả về Superset dưới dạng **bảng dữ liệu** gồm các hàng và cột. Tuy nhiên, dữ liệu này thường chưa được đưa ngay vào biểu đồ mà có thể phải trải qua thêm một số bước biến đổi.

Tùy vào loại chart và cách cấu hình, Superset có thể:

- pivot dữ liệu
- tính phần trăm
- áp dụng các hàm post-processing
- format lại giá trị
- hoặc chuyển đổi cấu trúc dữ liệu sang dạng phù hợp hơn với thư viện visualization sẽ dùng để render

Điều này rất quan trọng vì mỗi loại chart có thể yêu cầu cấu trúc dữ liệu đầu vào khác nhau.

### Visualization layer

Tiếp theo là **visualization layer**, tức lớp frontend nơi dữ liệu được biến thành hình ảnh trực quan.

Superset không tự xây dựng mọi thứ từ đầu cho việc render chart. Thay vào đó, nó tận dụng các thư viện visualization JavaScript phổ biến. Hiện nay, thư viện chính được sử dụng là **Apache ECharts**, và đây đã trở thành thư viện chart mặc định của Superset từ phiên bản **2.0**.

Ngoài ra, Superset vẫn hỗ trợ một số thư viện khác như **D3.js** cho những loại visualization chuyên biệt.

Chính lớp này là nơi “phép màu” xảy ra: dữ liệu dạng bảng hoặc JSON sau khi được backend xử lý sẽ được plugin frontend chuyển thành biểu đồ trực quan mà người dùng nhìn thấy trên màn hình.

### Interaction layer

Lớp thứ ba là **interaction layer**, chịu trách nhiệm kết nối các thành phần lại với nhau để bảo đảm trải nghiệm chart hoạt động trơn tru.

Về mặt luồng xử lý, khi người dùng thao tác trên giao diện chart editor ở frontend, cấu hình đó sẽ được đóng gói thành **form data** và gửi về backend Superset chạy trên **Flask/Python**.

Ở backend, Superset sử dụng các thành phần gọi là **Viz classes**. Các class này có nhiệm vụ chuyển form data thành một truy vấn thực tế để gửi đến database.

Khi query đã được sinh ra, nó sẽ được thực thi trên nguồn dữ liệu kết nối, có thể là:

- PostgreSQL
- MySQL
- Druid
- hoặc bất kỳ hệ thống nào mà Superset hỗ trợ

Database sẽ chạy query và trả về dữ liệu thô, thường là ở dạng tabular. Sau đó, Superset có thể áp dụng thêm một số bước hậu xử lý như:

- pivot
- aggregation
- formatting
- hoặc các phép biến đổi khác

Kết quả cuối cùng sẽ được gửi về frontend dưới dạng **JSON**. Từ đây, plugin chart ở frontend sẽ nhận dữ liệu và render thành biểu đồ hoàn chỉnh.

### Hiệu năng khi render chart

Một chủ đề rất quan trọng là **hiệu năng render**.

Việc trực quan hóa các tập dữ liệu lớn trên trình duyệt không phải lúc nào cũng dễ dàng, đặc biệt với các chart phức tạp. Để giải quyết bài toán này, Superset đã tích hợp nhiều cơ chế tối ưu.

Trước hết là việc sử dụng các thư viện visualization hiệu quả như **Apache ECharts**, vốn được thiết kế để xử lý tốt các tập dữ liệu lớn và các visualization phức tạp.

Tiếp theo là **progressive loading**, tức chart có thể hiển thị nhanh một phần dữ liệu ban đầu trước, sau đó tiếp tục hoàn thiện khi có thêm dữ liệu. Cách tiếp cận này giúp người dùng có cảm giác phản hồi nhanh hơn.

Superset cũng hỗ trợ **client-side caching**, giúp tránh việc render lại không cần thiết khi dữ liệu nền chưa thay đổi. Điều này đặc biệt hữu ích trong dashboard có nhiều chart cùng lúc.

Đối với một số loại visualization như bảng dữ liệu, Superset có thể áp dụng **virtualization**, tức chỉ render các hàng và cột đang nằm trong vùng nhìn thấy, thay vì render toàn bộ dữ liệu cùng lúc. Nhờ đó, hiệu năng frontend được cải thiện đáng kể.

Tất cả các cơ chế này phối hợp với nhau để mang lại trải nghiệm mượt mà, kể cả khi làm việc với lượng dữ liệu lớn.

### Khả năng mở rộng bằng custom plugin

Một trong những điểm mạnh nhất của Superset là **extensibility** — khả năng mở rộng.

Nếu các loại chart dựng sẵn không đáp ứng nhu cầu của bạn, bạn hoàn toàn có thể xây dựng **custom visualization plugin**.

Các plugin này có thể tích hợp liền mạch vào Superset, xuất hiện ngay trong danh sách chọn chart type, đứng cạnh các chart mặc định. Đồng thời, chúng vẫn hỗ trợ các tính năng quen thuộc như:

- lưu chart
- export
- tích hợp dashboard
- và tương tác như các chart chuẩn

Để tạo một plugin chart tùy chỉnh, bạn cần có kiến thức về **JavaScript** và **React**. Tuy nhiên, Superset đã cung cấp sẵn nhiều utility và ví dụ để giúp quá trình này dễ tiếp cận hơn.

Khi xây plugin, bạn thường cần:

- định nghĩa metadata của plugin
- tạo React component để render chart
- cấu hình control panel
- triển khai logic transform dữ liệu nếu cần

Một điểm rất đáng giá là custom plugin không bị giới hạn chỉ với thư viện mặc định của Superset. Bạn có thể dùng **bất kỳ thư viện visualization JavaScript nào** phù hợp với nhu cầu của mình.

Điều này mở ra khả năng tích hợp các loại visualization chuyên biệt hơn như:

- network graph
- 3D visualization
- chart chuyên ngành
- hoặc các biểu đồ đặc thù cho từng domain nghiệp vụ

### Tóm tắt luồng hoạt động

Để tóm tắt ngắn gọn toàn bộ kiến trúc:

- Người dùng cấu hình chart ở **frontend**
- Superset backend nhận cấu hình và **sinh query**
- Query được gửi xuống **database**
- Database trả dữ liệu về
- Backend có thể **hậu xử lý**
- Dữ liệu được gửi lại frontend dưới dạng **JSON**
- Plugin frontend **render biểu đồ**

Đó chính là cách Superset tạo ra chart ở phía người dùng.

Tóm lại, kiến trúc charting của Apache Superset được thiết kế rất hợp lý: vừa tách bạch rõ các lớp xử lý, vừa tối ưu hiệu năng, lại vừa mở rộng tốt cho các nhu cầu visualization đặc thù. Đây là một trong những nền tảng quan trọng giúp Superset trở thành công cụ BI mã nguồn mở mạnh mẽ và linh hoạt.
