# Backlog – Quiet Canvas

Danh sách việc cần làm sau bản build đầu tiên (2026-10-08). Thứ tự ưu tiên do chủ dự án quyết định: ghi số vào cột **Thứ tự** (1 = làm trước), để trống nếu chưa làm.

Cột **Đề xuất** là gợi ý mức ưu tiên (P1 cao nhất). **Công sức**: S < 1 giờ, M 1–4 giờ, L > 4 giờ.

## A. Trải nghiệm tô màu

Đã làm xong A1–A6 và A8 (2026-10-08). A7 và A9 đã bỏ theo quyết định của chủ dự án.

| ID | Thứ tự | Việc | Vì sao | Đề xuất | Công sức | File chính |
|---|---|---|---|---|---|---|
| A1 | ✅ xong | Chạm trượt vẫn tô: nếu điểm chạm không trúng vùng của màu đang chọn, tô vùng gần nhất cùng màu trong bán kính ~12pt trên màn hình | Vùng nhỏ và nét viền (thường là màu 1) rất khó chạm trúng, nhất là với người lớn tuổi | P1 | M | PaintModel.swift (`tap`) |
| A2 | ✅ xong | Phản hồi khi chạm sai màu: chỉ rung nhẹ (không nhãn) | Hiện chạm sai không có phản hồi, người dùng tưởng app lỗi | P1 | S | PaintView.swift |
| A3 | ✅ xong | Hint di chuyển và zoom mượt (~0,4s) thay vì nhảy | Nhảy đột ngột làm mất định hướng | P1 | M | PaintView.swift (`hint`) |
| A4 | ✅ xong | Chạm hai lần để zoom: vào 2,5x, chạm hai lần nữa thì về toàn tranh | Thao tác quen thuộc trên iOS, hiện chưa có | P1 | S | PaintView.swift |
| A5 | ✅ xong | Hiệu ứng màu loang ra khi tô một vùng (~0,15s) | Tạo cảm giác thỏa mãn mỗi lần chạm | P2 | M | PaintView.swift (`draw`) |
| A6 | ✅ xong | Cho tranh rộng tối đa theo chiều ngang, bớt khoảng trống phía trên và dưới | Tranh to hơn thì số đọc được nhiều hơn ở zoom 1x | P2 | S | PaintView.swift (`layout`) |
| A8 | ✅ xong | Ẩn các màu đã tô xong khỏi bảng màu (tùy chọn trong Cài đặt) | Tranh khó có ~32 màu, bảng màu dài | P3 | S | PaintView.swift, SettingsView.swift |

## B. Thư viện và nội dung

| ID | Thứ tự | Việc | Vì sao | Đề xuất | Công sức | File chính |
|---|---|---|---|---|---|---|
| B1 | ✅ xong | Hàng "New this week" chỉ hiện tranh được thêm sau ngày cài app, trong 14 ngày (`Store.isNew`). **Badge NEW trên thumbnail đã bỏ** (2026-10-08), thêm lại sau | Hiện tranh nào cũng là NEW nên badge mất ý nghĩa | P1 | S | Store.swift (`isNew`), LibraryView.swift |
| B2 | ✅ xong | Bớt trùng lặp: các hàng gợi ý bỏ qua tranh đã có ở hàng "Tô tiếp" | Một tranh có thể hiện tới 4 lần trên Thư viện | P2 | S | LibraryView.swift |
| B3 | ✅ xong | Tên tranh dài chạy ngang (marquee), đứng yên khi bật Reduce Motion | "Bumblebee Sunflo…" bị cắt | P2 | S | DesignSystem.swift (`Thumb`) |
| B4 | ✅ xong | Thumbnail tranh chưa bắt đầu hiển thị **xám** (chốt 2026-10-09 sau khi so sánh full color / faded / gray, xem `docs/design/b4_thumbnail_compare.png`). Tranh đang tô hiện phần đã tô, tranh xong hiện đủ màu | Tranh đã tô nổi bật, cảm giác "tô màu cho tranh" | P3 | S | DesignSystem.swift (`Thumb`) |

## C. Challenges và cảm xúc

| ID | Thứ tự | Việc | Vì sao | Đề xuất | Công sức | File chính |
|---|---|---|---|---|---|---|
| C1 | | Khi streak = 0, hiện "Start your streak today" và ẩn "0 of N days" | Người mới thấy số 0, cảm giác như bị chấm điểm kém | P1 | S | ChallengesView.swift |
| C2 | | Màn hoàn thành có khoảnh khắc ăn mừng: tranh phóng to nhẹ, vài đốm màu rơi. Bật Reduce Motion thì chỉ fade | Cảm xúc khi tô xong, đúng như mockup | P2 | M | PaintView.swift (`CompletionView`) |
| C3 | | Huy hiệu streak (7 / 30 ngày) | Thêm động lực quay lại | P3 | M | ChallengesView.swift |
| C4 | | Lịch tranh challenge cố định: thêm mảng `daily: [{date, id}]` vào catalog.json. Ngày nào chưa có lịch thì mới xoay vòng | Hiện tranh của mỗi ngày được tính từ danh sách tranh, nên mỗi lần import thêm chủ đề thì tranh của hôm nay và các ngày đã qua bị đổi theo (thumbnail trên lịch thay đổi; ai đang tô dở tranh challenge hôm nay sẽ không được tính). Lịch cố định còn cho phép xếp tranh Halloween đúng dịp | P1 | M | Store.swift (`challenge`), catalog.json, tools/import_templates.py |

## D. Accessibility

| ID | Thứ tự | Việc | Vì sao | Đề xuất | Công sức | File chính |
|---|---|---|---|---|---|---|
| D1 | | Chữ tối thiểu 11pt: số % trong vòng tiến độ (đang 9pt) và chữ "rest" (đang 9pt) | Dưới mức đọc được tối thiểu | P1 | S | DesignSystem.swift, ChallengesView.swift |
| D2 | | Vùng chạm ≥ 44pt: chip lọc độ khó (đang 36pt), ô ngày trong lịch (đang 38pt) | Chuẩn iOS, quan trọng với người lớn tuổi | P1 | S | LibraryView.swift, ChallengesView.swift |
| D3 | | Thumbnail rộng theo Dynamic Type (đang cố định 150pt) | Khi bật chữ lớn, tên tranh bị cắt nhiều | P2 | M | DesignSystem.swift (`Shelf`) |

## E. Kiếm tiền (đang hoãn)

| ID | Thứ tự | Việc | Vì sao | Đề xuất | Công sức | File chính |
|---|---|---|---|---|---|---|
| E1 | | **Quyết định:** subscription (năm + tuần), mua một lần, hay quảng cáo + subscription | Cần có trước khi làm E2 | – | – | – |
| E2 | | Paywall thật bằng StoreKit 2 theo `docs/design/03_paywall.png`: gói năm có 7 ngày dùng thử, gói tuần, khôi phục giao dịch | Hiện chỉ là màn tạm hiện ảnh mockup + nút debug | – | L | SettingsView.swift (`PaywallView`), Store.swift |
| E3 | | **Quyết định:** có hiện paywall cuối onboarding không | Tỉ lệ mua cao hơn nhưng có thể làm một số người khó chịu | – | S | OnboardingView.swift |
| E4 | | Dòng "Restore purchases" trong Cài đặt | Apple yêu cầu khi có mua hàng | – | S | SettingsView.swift |

## F. Trước khi phát hành

| ID | Thứ tự | Việc | Vì sao | Đề xuất | Công sức | File chính |
|---|---|---|---|---|---|---|
| F1 | | Trang Privacy Policy và Terms of Use, thêm link vào Cài đặt và Paywall | Apple bắt buộc khi có subscription | – | M | SettingsView.swift |
| F2 | | Dòng "Send feedback": cần email hỗ trợ | Chưa có địa chỉ email | – | S | SettingsView.swift |
| F3 | | Icon app Quiet Canvas | Chưa có | – | M | Assets.xcassets/AppIcon |
| F7 | | Dung lượng app: 80 tranh đang chiếm ~46 MB (JSON 21 MB, ảnh 27 MB). Cân nhắc nén JSON hoặc tải tranh theo đợt từ server khi vượt ~150 tranh | Ảnh hưởng thời gian tải app | – | M | tools/import_templates.py |
| F4 | | Kiểm tra bản quyền ảnh do AI tạo, và yêu cầu ghi chú của App Store | Mục 7 trong content-plan.md | – | – | – |
| F5 | | Giữ tên "Quiet Canvas" trong App Store Connect, tra nhãn hiệu | Tên có thể đã bị người khác dùng | – | S | – |
| F6 | | Ảnh chụp màn hình cho App Store | Cần để nộp app | – | M | – |

## Để sau khi phát hành

- Thêm lại badge NEW trên thumbnail khi có đợt tranh mới. Logic đã có sẵn: `Store.isNew(entry)` (tranh thêm sau ngày cài app, trong 14 ngày). Chỉ cần vẽ lại nhãn ở góc trên trái của `Thumb` trong DesignSystem.swift

- Âm thanh nền thư giãn
- Timelapse quá trình tô để chia sẻ
- Đồng bộ iCloud
- Tải tranh mới từ server thay vì đóng gói sẵn trong app
- Thử thách theo tuần ("Tô 3 tranh Hoa")
- Tìm kiếm (khi thư viện lên vài trăm tranh)
