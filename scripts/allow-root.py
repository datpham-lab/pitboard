#!/usr/bin/env python3
"""Bỏ chặn root/sudo của Pitboard trên macOS/Linux.

Dùng: python3 scripts/allow-root.py <thư mục mã nguồn pitboard>

Thay thân hàm `elevation()` trong crates/pitboard-core/src/host/unix/user.rs để luôn
trả về `Elevation::Normal`. Nếu upstream đổi đoạn code này, script dừng với lỗi
thay vì build ra một binary vẫn chặn root.
"""
import pathlib
import sys

OLD = (
    "    let root = unsafe { libc::geteuid() } == 0;\n"
    "    elevation_of(sudo, root)\n"
)
NEW = (
    "    let _ = (sudo, elevation_of as fn(bool, bool) -> Elevation);\n"
    "    Elevation::Normal // allow-root patch\n"
)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: allow-root.py <pitboard source dir>")
    path = pathlib.Path(sys.argv[1]) / "crates/pitboard-core/src/host/unix/user.rs"
    text = path.read_text()
    if NEW in text:
        print(f"already patched: {path}")
        return
    count = text.count(OLD)
    if count != 1:
        sys.exit(
            f"{path}: expected the root check exactly once, found {count}. "
            "Upstream changed elevation(); update scripts/allow-root.py."
        )
    path.write_text(text.replace(OLD, NEW))
    print(f"patched: {path}")


if __name__ == "__main__":
    main()
