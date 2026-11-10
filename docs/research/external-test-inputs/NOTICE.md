# Ghi công nguồn của các file đầu vào test

Các file `*.tsv` trong thư mục này chứa **chuỗi phím** lấy từ bộ test của các dự án dưới đây, **không có kết quả mong đợi** của họ (đáp án của họ chỉ nằm trong `build/external-answers/`, không commit). Cách lấy, ký hiệu và lý do giữ/bỏ: `docs/research/EXTERNAL-TEST-INPUTS.md`. Script tạo lại các file: `scripts/research/external-tests/extract.sh`.

Với nguồn MIT và BSD-3-Clause, thông báo bản quyền và toàn văn giấy phép được chép nguyên từ file giấy phép của họ ở đúng commit ghi dưới đây. Với nguồn GPL chỉ ghi tên giấy phép và đường dẫn, vì Dấu phát hành theo GPLv3 (văn bản ở file `LICENSE` của repo Dấu).

## bamboo-core

- Repo: https://github.com/BambooEngine/bamboo-core
- Commit: `b2e49a2b48c7d3772a3673142a7747eccd9d5f79`
- Giấy phép (SPDX): MIT
- File TSV: `docs/research/external-test-inputs/bamboo-core.tsv`
- Dòng bản quyền, chép nguyên văn từ `LICENSE`:

```
Copyright (C) 2018 Luong Thanh Lam <ltlam93@gmail.com>
```

Toàn văn giấy phép (`LICENSE`):

```
The MIT License (MIT)

Copyright (C) 2018 Luong Thanh Lam <ltlam93@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## ibus-bamboo

- Repo: https://github.com/BambooEngine/ibus-bamboo
- Commit: `49e03d7a36b8a8b796950c158b545af8cf9707d4`
- Giấy phép (SPDX): GPL-3.0 (`LICENSE` là văn bản GNU GPL phiên bản 3; README ghi GPL v3)
- File TSV: `docs/research/external-test-inputs/ibus-bamboo.tsv`
- Dòng bản quyền, chép nguyên văn từ đầu các file mã của họ (ví dụ `emoji_test.go`; `LICENSE` chỉ là văn bản GPL, không có dòng bản quyền của dự án):

```
Copyright (C) 2018 Luong Thanh Lam <ltlam93@gmail.com>
```

Giấy phép: GNU General Public License v3.0, https://www.gnu.org/licenses/gpl-3.0.html

## fcitx5-unikey

- Repo: https://github.com/fcitx/fcitx5-unikey
- Commit: `ed9170c35c1a6275d105e03d7f9bc4f674c1469c`
- Giấy phép (SPDX): GPL-2.0-or-later (dòng SPDX trong `test/testunikey.cpp`; văn bản ở `LICENSES/GPL-2.0-or-later.txt`)
- File TSV: `docs/research/external-test-inputs/fcitx5-unikey.tsv`
- Dòng bản quyền, chép nguyên văn từ `test/testunikey.cpp`:

```
SPDX-FileCopyrightText: 2021-2021 CSSlayer <wengxt@gmail.com>
```

Giấy phép: GNU General Public License v2.0 or later, https://www.gnu.org/licenses/old-licenses/gpl-2.0.html; Dấu dùng theo nhánh "or later" (GPLv3).

## goxkey

- Repo: https://github.com/huytd/goxkey
- Commit: `b197c57218ceb9096c341a9862acfabf7cb6932b`
- Giấy phép (SPDX): BSD-3-Clause
- File TSV: `docs/research/external-test-inputs/goxkey.tsv`
- Dòng bản quyền, chép nguyên văn từ `LICENSE`:

```
Copyright (c) 2023, Huy Tran
```

Toàn văn giấy phép (`LICENSE`):

```
BSD 3-Clause License

Copyright (c) 2023, Huy Tran

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## vi-rs

- Repo: https://github.com/zerox-dg/vi-rs
- Commit: `192e246d37e83094a1228e798b160f3cee14c879`
- Giấy phép (SPDX): MIT (`Cargo.toml`: `license-file = "LICENSE"`; README ghi MIT)
- File TSV: `docs/research/external-test-inputs/vi-rs.tsv`
- Dòng bản quyền, chép nguyên văn từ `LICENSE`:

```
Copyright 2020, Hung Nguyen
```

Toàn văn giấy phép (`LICENSE`):

```
Copyright 2020, Hung Nguyen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## ibus-teni

- Repo: https://github.com/teni-ime/ibus-teni
- Commit: `a3824854c0f5e85dcfea66d984b9bad0c16c2bf2`
- Giấy phép (SPDX): GPL-3.0-or-later (`LICENSE` là văn bản GPLv3; `test-data/LICENSE` ghi "version 3 of the License, or (at your option) any later version")
- File TSV: `docs/research/external-test-inputs/ibus-teni.tsv`
- Dòng bản quyền, chép nguyên văn từ `test-data/LICENSE`:

```
Teni-IME - A Vietnamese Input method editor
Copyright (C) 2018 Nguyen Cong Hoang <hoangnc.jp@gmail.com>
This file and all tdata files in this directory is part of Teni-IME.
```

Giấy phép: GNU General Public License v3.0 or later, https://www.gnu.org/licenses/gpl-3.0.html

## uvie-rs

- Repo: https://github.com/uvie-project/uvie-rs
- Commit: `555ef9dd31b6bf208343a70484e84db79f1bddfe`
- Giấy phép (SPDX): MIT OR Apache-2.0 (`Cargo.toml`); Dấu dùng theo nhánh MIT
- File TSV: `docs/research/external-test-inputs/uvie-rs.tsv`
- Dòng bản quyền, chép nguyên văn từ `LICENSE-MIT`:

```
Copyright (c) 2026 thuupx
```

Nguồn cho chọn một trong hai giấy phép; Dấu chọn MIT nên chỉ chép văn bản MIT. Văn bản Apache-2.0 của họ: `LICENSE-APACHE` trong repo của họ, https://www.apache.org/licenses/LICENSE-2.0

Toàn văn giấy phép (`LICENSE-MIT`):

```
MIT License

Copyright (c) 2026 thuupx

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## ibus-telex

- Repo: https://github.com/manhavn/ibus-telex
- Commit: `fb522b4804c2ef8496ec8746f7b1e4043b3716c2`
- Giấy phép (SPDX): GPL-3.0-or-later, chỉ khai trong `Cargo.toml`
- File TSV: `docs/research/external-test-inputs/ibus-telex.tsv`
- Dòng bản quyền, chép nguyên văn từ `Cargo.toml` (dòng giấy phép; repo không có dòng bản quyền nào):

```
license = "GPL-3.0-or-later"
```

Repo **không có file LICENSE hay COPYING** ở commit này; giấy phép chỉ được khai bằng trường `license` của `Cargo.toml`. Người dùng quyết định giữ nguồn này kèm ghi chú (05/11/2026). Tác giả các commit: Bùi Văn Mạnh. Họ ghi rằng `tests/parity_corpus.tsv` được chụp từ ibus-unikey 0.7.0. Giấy phép: GNU General Public License v3.0 or later, https://www.gnu.org/licenses/gpl-3.0.html

## Gõ Nhanh (gonhanh.org)

- Repo: https://github.com/khaphanspace/gonhanh.org
- Commit: `1fdac7aec67663f2c23df6addfb13c59bbc5f374`
- Giấy phép (SPDX): BSD-3-Clause
- File TSV: `docs/research/external-test-inputs/gonhanh.tsv`
- Dòng bản quyền, chép nguyên văn từ `LICENSE`:

```
Copyright (c) 2025, Gõ Nhanh Contributors
```

Toàn văn giấy phép (`LICENSE`):

```
BSD 3-Clause License

Copyright (c) 2025, Gõ Nhanh Contributors

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## XKey

- Repo: https://github.com/xmannv/xkey
- Commit: `398e78e9c1a92f740d5cbf1673914a3b3c458eff`
- Giấy phép (SPDX): MIT
- File TSV: `docs/research/external-test-inputs/xkey.tsv`
- Dòng bản quyền, chép nguyên văn từ `LICENSE`:

```
Copyright (c) 2025 XKey
```

Engine của XKey ghi trong mã là bản chuyển từ engine OpenKey (GPL-3.0). Dù phần đó thuộc MIT hay GPL-3.0, cả hai đều tương thích với GPLv3 của Dấu.

Toàn văn giấy phép (`LICENSE`):

```
MIT License

Copyright (c) 2025 XKey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
