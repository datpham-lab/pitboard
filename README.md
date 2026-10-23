# pitboard-root

Bản build của [datlechin/pitboard](https://github.com/datlechin/pitboard) cho phép chạy bằng **root / sudo** trên Linux.

Nhánh này chỉ chứa phần tự động hoá. Mã nguồn luôn được lấy thẳng từ upstream theo tag release, không giữ bản sao nào ở đây:

| File | Việc |
| --- | --- |
| `.github/workflows/root-build.yml` | Hằng ngày kiểm tra release mới của upstream, áp patch, build `x86_64` + `aarch64` (musl, static) rồi tạo release `<tag>-root` |
| `scripts/allow-root.py` | Patch: hàm `elevation()` trong `crates/pitboard-core/src/host/unix/user.rs` luôn trả `Elevation::Normal`. Nếu upstream đổi đoạn này, script báo lỗi và build dừng |
| `install.sh` | Cài/cập nhật binary trên server từ release của repo này |

## Cài đặt fork (một lần)

```sh
# 1. Fork datlechin/pitboard trên GitHub, rồi clone fork về
git clone https://github.com/<you>/pitboard && cd pitboard

# 2. Tạo nhánh mồ côi chỉ chứa các file trong thư mục này
git switch --orphan root-build
git rm -rf --quiet . 2>/dev/null || true
cp -r /đường/dẫn/pitboard-root/. .
git add -A && git commit -m "ci: build allow-root releases"
git push -u origin root-build
```

3. Trên GitHub, **Settings → General → Default branch** đổi thành `root-build`.
   Lịch chạy (`schedule`) chỉ chạy ở default branch, và nhánh này không có workflow nào của upstream nên các job ký Apple/Windows, publish crates.io, Homebrew… sẽ không chạy.
4. **Actions** → bấm *I understand my workflows, go ahead and enable them*.
5. **Actions → root-build → Run workflow** để build lần đầu.

## Cài trên server

```sh
curl -fsSL https://raw.githubusercontent.com/<you>/pitboard/root-build/install.sh \
  | PITBOARD_FORK=<you>/pitboard sh                     # stable mới nhất

curl -fsSL https://raw.githubusercontent.com/<you>/pitboard/root-build/install.sh \
  | PITBOARD_FORK=<you>/pitboard sh -s v1.0.0-beta.4-root   # bản cụ thể
```

Chạy lại lệnh trên để cập nhật. Bản CLI trên Linux không tự update, nên binary này không bị upstream ghi đè.

## Lưu ý

- GitHub tắt lịch chạy của repo sau 60 ngày không có commit. Khi đó vào Actions bật lại, hoặc chạy tay.
- Patch hỏng sau khi upstream refactor: job đỏ ở bước *Apply allow-root patch*. Sửa chuỗi `OLD`/`NEW` trong `scripts/allow-root.py` rồi chạy lại với `force`.
- Binary không ký, chỉ dùng nội bộ.
