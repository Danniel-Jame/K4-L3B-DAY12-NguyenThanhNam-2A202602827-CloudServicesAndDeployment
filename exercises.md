# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Thành Nam  Mã học viên: 2A202602827

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Giả sử deploy lên Render nhưng quên cấu hình biến `AGENT_API_KEY` trong dashboard. Nếu để mặc định là `"changeme"`, app vẫn khởi động thành công và trở thành public. Các bot quét Internet hoặc kẻ xấu có thể dùng khóa `"changeme"` này để gọi API miễn phí, làm cạn sạch ngân sách LLM của tôi trước khi tôi kịp nhận ra. Việc "chết sớm" (báo lỗi ValidationError ngay lúc deploy) giúp em phát hiện thiếu sót lập tức và API không bao giờ mở cửa trong trạng thái hớ hênh.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng log: `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T11:11:10+00:00", "user_id": "sv-test", "cost_usd": 0.0001, "tokens_in": 10, "tokens_out": 20}`
> Hai việc làm được:
> 1. Dùng công cụ quản lý log (như Datadog, Kibana) để tổng hợp/vẽ biểu đồ tổng tiền (`cost_usd`) mà user `sv-test` đã tiêu thụ trong tháng.
> 2. Cài đặt cảnh báo tự động (alert) báo qua Slack nếu có bất kỳ request nào tiêu tốn `tokens_in` vượt quá 5000 trong một lần gọi.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ~ 500 MB |
| Multi-stage | ~ 160 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Phần dung lượng chênh lệch khổng lồ đó là các công cụ biên dịch (compiler như gcc), các gói thư viện hệ điều hành không cần thiết cho lúc chạy, và đặc biệt là bộ nhớ cache của pip sinh ra trong quá trình cài đặt thư viện. Multi-stage build loại bỏ toàn bộ những thứ rác này, chỉ copy đúng các thư viện đã được biên dịch thành công từ stage builder sang stage runtime.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi sửa main.py, các layer COPY requirements.txt . và RUN pip install vẫn được dùng lại từ cache vì file requirements không đổi. Chỉ layer COPY . . và các layer sau nó mới phải chạy lại. Nếu đặt COPY . . lên trước, việc sửa 1 ký tự trong main.py sẽ làm invalid cache của layer COPY . .. Hệ quả là layer RUN pip install ngay phía sau cũng bị mất cache và Docker sẽ phải tải/cài đặt lại toàn bộ thư viện từ đầu, làm thời gian build kéo dài thêm vài phút một cách vô ích.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request trong 2 giây. Người dùng có thể gửi 10 request vào lúc 10:00:59 (thuộc chu kỳ phút thứ nhất, hợp lệ) và gửi tiếp 10 request vào lúc 10:01:00 (chu kỳ phút thứ hai vừa được reset, hợp lệ). Sliding window khắc phục được kẽ hở này vì nó luôn nhìn ngược lại đúng 60 giây từ thời điểm hiện tại.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Khác biệt: Rate limit đếm số lượng request (tần suất). Cost guard đếm chi phí (tiền/token).

>Rate limit cho qua, Cost guard chặn: User gửi 1 request duy nhất (chưa vi phạm hạn mức 10 req/phút) nhưng prompt nhồi một tài liệu khổng lồ tốn 15 USD. Vì vượt ngân sách 10 USD/tháng nên Cost guard chặn lại ngay.

>Cost guard cho qua, Rate limit chặn: User viết script gửi 15 câu hỏi liên tục trong 5 giây, mỗi câu cực ngắn tốn 0.001 USD. Tổng tiền mới là 0.015 USD (dưới ngân sách), nhưng Rate limit chặn ở request thứ 11 vì vi phạm ngưỡng 10 req/phút.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Redis mất kết nối.

>Cả 3 container đều báo /health thất bại (unhealthy).

>Hệ thống quản lý (Orchestrator) tưởng cả 3 process đã treo nên ra lệnh SIGKILL và khởi động lại toàn bộ 3 container cùng lúc.

>Khi Redis sống lại sau 30s, không có container nào sẵn sàng phục vụ vì tất cả đang trong quá trình boot up lại từ đầu, gây gián đoạn toàn hệ thống (downtime). Tách riêng /ready giúp Load Balancer chỉ tạm ngưng gửi request chứ không giết chết container.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Nếu dùng dict Python nội bộ, history_length sẽ nhảy loạn xạ không theo thứ tự (ví dụ: 1, 1, 2, 1, 3, 2). Lý do là request thứ nhất rớt vào container A, request thứ hai rớt vào container B (chưa có lịch sử), làm agent "mất trí nhớ" luân phiên. Khi lưu ở Redis, cả 3 container cùng đọc chung một kho dữ liệu, nên history_length sẽ luôn tăng tịnh tiến đều đặn (1, 2, 3, 4, 5).

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

