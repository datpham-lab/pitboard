# Pitboard (allow-root build)

[![root-build](https://github.com/datpham-lab/pitboard/actions/workflows/root-build.yml/badge.svg?branch=root-build)](https://github.com/datpham-lab/pitboard/actions/workflows/root-build.yml)
[![release](https://img.shields.io/github/v/release/datpham-lab/pitboard?label=release)](https://github.com/datpham-lab/pitboard/releases/latest)

Bản build của [datlechin/pitboard](https://github.com/datlechin/pitboard) **cho phép chạy bằng root / sudo trên Linux**, dùng nội bộ trên các server Ubuntu vận hành bằng root.

Upstream cố ý chặn root vì file do root tạo ra thì user thường không đọc được. Trên server chỉ dùng root thì không có user thường nào, nên việc chặn chỉ gây cản trở. Ngoài chỗ này, binary giống hệt upstream.

> Nhánh `root-build` (default branch) chỉ chứa phần tự động hoá. Mã nguồn luôn lấy thẳng từ upstream theo tag release, không có bản sao nào ở đây. Nhánh `main` là bản fork gốc, để nguyên, không dùng.

## Cài đặt trên server

Chạy bằng root:

```sh
curl -fsSL -o /usr/local/sbin/pitboard-update \
  https://raw.githubusercontent.com/datpham-lab/pitboard/root-build/install.sh
chmod 755 /usr/local/sbin/pitboard-update

pitboard-update                       # bản stable mới nhất
pitboard-update v1.0.0-beta.4-root    # hoặc một bản cụ thể, kể cả prerelease
pitboard --version
```

Script tự chọn bản `x86_64` hoặc `aarch64`, kiểm tra SHA-256 rồi cài vào `/usr/local/bin/pitboard`.
Đổi chỗ cài bằng `PITBOARD_INSTALL_DIR=/đường/dẫn`.

### Đăng nhập các account

```sh
claude                                # /login account thứ nhất
pitboard enroll work
pitboard enroll personal --sign-in    # account thứ hai
pitboard use work
pitboard status
```

Xem thêm trong [tài liệu upstream](https://docs.usepitboard.com).

### Tự cập nhật lúc 07:45 giờ VN

```sh
base=https://raw.githubusercontent.com/datpham-lab/pitboard/root-build/systemd
curl -fsSL -o /etc/systemd/system/pitboard-update.service "$base/pitboard-update.service"
curl -fsSL -o /etc/systemd/system/pitboard-update.timer   "$base/pitboard-update.timer"

systemctl daemon-reload
systemctl enable --now pitboard-update.timer
systemctl list-timers pitboard-update.timer
journalctl -u pitboard-update -n 20 --no-pager
```

Timer khai báo múi giờ `Asia/Ho_Chi_Minh` ngay trong lịch, nên không phụ thuộc múi giờ của server.

## Cách hoạt động

| Giờ VN | Ở đâu | Việc |
| --- | --- | --- |
| 07:07 (GitHub có thể trễ tới ~07:30) | GitHub Actions | Kiểm tra release upstream. Có bản mới thì áp patch, build, smoke test bằng `sudo`, rồi tạo release `<tag>-root`; không có thì bỏ qua |
| 07:45 | Server | Tải release stable mới nhất, kiểm checksum, thay binary |

| File | Việc |
| --- | --- |
| [`.github/workflows/root-build.yml`](.github/workflows/root-build.yml) | Build `x86_64` + `aarch64` (musl, static) và tạo GitHub Release |
| [`scripts/allow-root.py`](scripts/allow-root.py) | Patch: `elevation()` trong `crates/pitboard-core/src/host/unix/user.rs` luôn trả `Elevation::Normal`. Upstream đổi đoạn này thì script báo lỗi và build dừng |
| [`install.sh`](install.sh) | Cài / cập nhật binary trên server |
| [`systemd/`](systemd) | Service + timer tự cập nhật hằng ngày |

## Build bằng tay

**Actions → root-build → Run workflow**:

- `tag`: tag upstream cụ thể, ví dụ `v0.15.0`. Để trống thì lấy bản mới nhất.
- `channel`: `stable` hoặc `prerelease`, dùng khi để trống `tag`.
- `force`: build lại và ghi đè release đã có.

## Xử lý sự cố

| Triệu chứng | Cách xử lý |
| --- | --- |
| Job đỏ ở *Apply allow-root patch* | Upstream đã đổi `elevation()`. Sửa `OLD`/`NEW` trong `scripts/allow-root.py`, rồi Run workflow với `force` |
| Job đỏ ở *Publish release* với lỗi 403 | **Settings → Actions → General → Workflow permissions** → *Read and write permissions* |
| Lịch chạy không còn tự chạy | GitHub tắt `schedule` sau 60 ngày repo không có commit. Vào Actions bật lại, hoặc push một commit nhỏ |
| `pitboard` vẫn báo *changes nothing as root* | Đang chạy bản upstream. Kiểm tra `command -v pitboard` và xoá bản cũ, thường ở `~/.local/bin/pitboard` |

## Lưu ý

- Binary không ký, chỉ dùng nội bộ.
- Mọi lỗi của Pitboard không liên quan đến root thì báo cho [upstream](https://github.com/datlechin/pitboard/issues), sau khi đã thử lại với bản gốc.
- Giấy phép theo upstream, xem [LICENSE](https://github.com/datlechin/pitboard/blob/main/LICENSE).
