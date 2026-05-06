---
title: "sysstat パッケージと sa1 / sa2 の読み方:収集と日次レポートの cron 構造"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "sysstat パッケージの所属コマンド一覧と、sa1 → sadc(収集)/ sa2 → sar(日次レポート)の cron ラッパ関係、/var/log/sa の運用を整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で `sysstat` 周辺を「sar の親パッケージ」程度に流していたら、`sa1` と `sa2` の役割を取り違えた。`sa1` は **データ収集**(`sadc` を呼ぶ)、`sa2` は **日次レポート生成**(`sar` を呼ぶ)で、cron からの呼ばれ方も違う。さらに「sysstat に含まれるコマンド」の集合問題では、`vmstat` や `netstat` を入れてしまう罠がある。本記事では sysstat の所属コマンド一覧、sa1/sa2 の呼出関係、`/var/log/sa` の運用までを 1 本にまとめておく。

[sarコマンドの読み方](/posts/2026-05-06-sar-command-reading/) ・ [iostat / mpstat の読み方](/posts/2026-05-06-iostat-mpstat-reading/) と対になる記事。

## sysstat とは何のパッケージか

`sysstat` は **システム統計の収集・レポート系コマンドを束ねた 1 パッケージ**。`sar` を主役に、データコレクタ・cron ラッパ・各種統計コマンドが同居している。

### 所属コマンド一覧

| コマンド | 用途 | 出題対象 |
|---|---|---|
| `sar` | システムアクティビティレポータ | ✅ 頻出 |
| `sadc` | System Activity Data Collector(バイナリ、データ収集) | ✅ |
| `sa1` | sadc を呼ぶシェルスクリプト(短期収集 cron 用) | ✅ |
| `sa2` | sar を呼ぶシェルスクリプト(日次レポート cron 用) | ✅ |
| `sadf` | sar データを CSV / XML / JSON に変換 | ✅ |
| `iostat` | ディスクI/O 統計 | ✅ |
| `mpstat` | CPU 毎統計 | ✅ |
| `pidstat` | プロセス毎統計 | – |
| `cifsiostat` | CIFS(Windows ファイル共有)I/O 統計 | ✅ |
| `nfsiostat` | NFS I/O 統計 | ✅ |
| `tapestat` | テープデバイス I/O 統計 | – |

「sysstat に含まれるコマンド」と問われたら、`sar` / `sadc` / `sa1` / `sa2` / `sadf` / `iostat` / `mpstat` / `pidstat` / `cifsiostat` / `nfsiostat` / `tapestat` の集合。

### sysstat に含まれないコマンド

| コマンド | 所属パッケージ |
|---|---|
| `vmstat` | procps-ng |
| `free` | procps-ng |
| `top` | procps-ng |
| `ps` | procps-ng |
| `netstat` | net-tools |
| `ss` | iproute2 |

「同じシステム監視系だから sysstat だろう」で `vmstat` を選ぶのが典型的な誤答。**vmstat は procps-ng パッケージ**で別所属。`netstat` も `net-tools`(レガシー)、`ss` は `iproute2` の所属。

## sa1 → sadc / sa2 → sar の呼出関係

```
[cron 10分毎]
    ↓
sa1 (shell script: /usr/lib/sa/sa1)
    ↓
sadc (binary: /usr/lib/sa/sadc) ──→ /var/log/sa/saYYYY (バイナリデータ)
                                            ↑
                                            │ 読込
[cron 23:53]                                │
    ↓                                       │
sa2 (shell script: /usr/lib/sa/sa2) ─────→ sar
    ↓
/var/log/sa/sarYYYY (テキストレポート)
```

cron が `sa1` と `sa2` を異なる頻度で叩き、`sa1` が `sadc` を呼んでバイナリデータを蓄積、`sa2` が `sar` を呼んでテキストレポートを生成する。

### sa1(短期収集側)

- `/usr/lib/sa/sa1` シェルスクリプト
- 引数: `sa1 <interval> <count>`(例: `sa1 1 1` = 即時 1 回収集)
- **`sadc` を呼んで `/var/log/sa/saYYYY` に追記**

### sa2(日次レポート側)

- `/usr/lib/sa/sa2` シェルスクリプト
- 引数: `sa2 -A`(全レポート生成)
- **`sar` を呼んで `/var/log/sa/sarYYYY` にテキストレポート出力**

### cron 設定例(/etc/cron.d/sysstat)

```
# 10 分毎に sa1 でデータ収集
*/10 * * * * root /usr/lib/sa/sa1 1 1

# 毎日 23:53 に sa2 で日次レポート生成
53 23 * * * root /usr/lib/sa/sa2 -A
```

`*/10` で 10 分間隔の収集、`53 23` で 23 時 53 分に 1 日分の集計が回る。これは LPIC 試験で「sysstat の cron 例」として出題される定番のシェイプ。

### 役割の覚え方

| 名前 | 動作 | 呼ぶ先 | 役割 |
|---|---|---|---|
| **sa1** | データ収集 | **sadc** | 「1 = 収集」(System Activity collect 1) |
| **sa2** | レポート生成 | **sar** | 「2 = 報告」(System Activity report 2) |

語呂で「**1 が集めて、2 が出す**」と覚える。逆を選ぶと両方失点。

## cifsiostat / nfsiostat

`iostat` は **ローカルブロックデバイス**(sda / sdb 等)向けで、リモートファイルシステムの I/O は対象外。リモート FS の I/O 監視には別コマンドを使う。

| コマンド | 対象 |
|---|---|
| `cifsiostat` | CIFS マウント(Windows ファイル共有 / Samba)の I/O 統計 |
| `nfsiostat` | NFS マウントの I/O 統計 |

### nfsiostat の出力例

```
Linux 5.15.0-105-generic   05/06/2026   _x86_64_   (4 CPU)

server.example.com:/exports/data mounted on /mnt/nfs:

   op/s     rpc bklog
   2.50         0.00

read:  ops/s    kB/s    kB/op   retrans  avg_RTT_ms  avg_exe_ms
        1.20    24.00   20.00       0       1.50        2.00

write: ops/s    kB/s    kB/op   retrans  avg_RTT_ms  avg_exe_ms
        0.50    10.00   20.00       0       2.00        3.00
```

`mounted on /mnt/nfs:` のように **マウントポイントを単位**にして、read / write 別に `ops/s` `kB/s` `kB/op` `retrans` `avg_RTT_ms` `avg_exe_ms` が並ぶ。「リモートファイルシステムの I/O 統計」という言葉で問われたら、迷わず `cifsiostat` / `nfsiostat`。

## /var/log/sa の運用

### ファイル構成

```
/var/log/sa/
├── sa01     ← 月初日のバイナリデータ(sadc 出力)
├── sa02
├── ...
├── sa31
├── sar01    ← 月初日のテキストレポート(sa2 出力)
├── sar02
└── ...
```

- `saDD` = 日付(`DD` は 01〜31)のバイナリデータ
- `sarDD` = 同日のテキストレポート
- 既定で **直近 1 ヶ月分** が循環保存される(`/etc/sysconfig/sysstat` の `HISTORY=28` 等で日数調整)

### sar -f でファイル指定読込

```
sar -f /var/log/sa/sa05      # 5 日のデータを CPU レポートで読み出し
sar -r -f /var/log/sa/sa05   # 同データをメモリレポートで読み出し
```

過去のバイナリデータを `sar -f` で読み出して別レポートに加工できる。`sa2 -A` が出力したテキストファイル(`sarDD`)はそのまま `cat` で見られる。

## 試験本番で踏みやすい罠 4 種

### 罠①: sa1 と sa2 の役割逆転

**`sa1` = 収集(`sadc`)**、**`sa2` = レポート(`sar`)**。「1 が集めて、2 が出す」と語呂で覚える。逆に答えると 9087 / 9108 系の問題で両方失点する。

### 罠②: sysstat に vmstat を入れる

`vmstat` は **procps-ng** パッケージ。同じシステム監視系だが別所属。`free` `top` `ps` も procps-ng。`netstat` は `net-tools`、`ss` は `iproute2`。「sysstat に含まれる」と聞かれたら `sar` 一族 + `iostat` / `mpstat` / `pidstat` / `cifsiostat` / `nfsiostat` 系のみ。

### 罠③: sadc と sa1 の関係を逆に覚える

sadc は **バイナリ**(C 言語実装、`/usr/lib/sa/sadc`)、sa1/sa2 は **シェルスクリプト**ラッパ(`/usr/lib/sa/sa1` `/usr/lib/sa/sa2`)。「シェルスクリプトがバイナリを呼ぶ」関係であって逆ではない。

### 罠④: /var/log/sa の循環日数

既定 1 ヶ月(`HISTORY=28` や `31` 等、ディストリ依存)。`saDD`(バイナリ)と `sarDD`(テキスト)の **2 系統が並存**する点も忘れがち。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- sysstat に含まれるコマンドを 5 つ以上挙げられるか(sar / sadc / sa1 / sa2 / sadf / iostat / mpstat / pidstat / cifsiostat / nfsiostat 等)
- vmstat はどのパッケージに含まれるか(procps-ng)
- netstat はどのパッケージに含まれるか(net-tools)
- sa1 が呼ぶのは何か(sadc)
- sa2 が呼ぶのは何か(sar)
- sa1 と sa2 を実装言語の観点で見るとどうか(両者ともシェルスクリプト、sadc はバイナリ)
- /var/log/sa に並ぶ 2 種類のファイルは何か(saDD バイナリ / sarDD テキスト)
- 過去のバイナリデータを別レポートに加工するコマンドは何か(sar -f)
- リモート FS の I/O 監視に使うコマンドは何か(cifsiostat / nfsiostat)
- /etc/cron.d/sysstat に `*/10 * * * * root /usr/lib/sa/sa1 1 1` がある場合、何を意味するか(10 分毎に sa1 が走り sadc 経由でデータ収集)

## 変更履歴

- 2026-05-06: 初版公開
