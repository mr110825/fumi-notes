---
title: "iostat / mpstat の読み方:CPU使用率の3階層とディスクI/Oの集合"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "iostat の2ブロック構造(avg-cpu行 + Device表)と mpstat の CPU毎統計を読み解き、システム全体・CPU毎(コア毎)・プロセス毎の CPU使用率3階層 + ディスクI/O集合を整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で `iostat` と `mpstat` を「どっちもシステム全体のリソースを見るやつ」程度にざっくり覚えていたら、画像問題で取り違えた。`iostat` は **CPU + デバイス毎I/O の 2 ブロック構造**、`mpstat` は **CPU 毎(コア毎)** の統計が主役で、**観点軸が違う**。さらに「システム全体 / CPU 毎 / プロセス毎」の **CPU 使用率 3 階層** を整理しないと、`top` や `vmstat` まで含めた集合問題で崩れる。本記事ではこの 2 コマンドの読み解きと、CPU 使用率 3 階層・ディスクI/O 集合まで 1 本にまとめておく。

[vmstatの読み方](/posts/2026-05-05-vmstat-bottleneck-reading/) ・ [topコマンドの読み方](/posts/2026-05-06-top-header-reading/) ・ [sarコマンドの読み方](/posts/2026-05-06-sar-command-reading/) ・ [ps / pstree / lsof の読み方](/posts/2026-05-06-ps-pstree-lsof-reading/) と対になる記事。

## 2 コマンドの位置付け

| コマンド | 主目的 | 出力ブロック | パッケージ |
|---|---|---|---|
| **iostat** | デバイス毎ディスクI/O + システム全体CPU | 2 ブロック(avg-cpu / Device) | sysstat |
| **mpstat** | CPU 毎(コア毎)の統計 | 1 ブロック(時刻 + CPU列) | sysstat |

両者とも `sysstat` パッケージに同居しているが、**iostat はデバイス側、mpstat は CPU 側** に視点が振れている。`vmstat` のように 1 行で全体を出すのではなく、**特定リソースに踏み込む** ためのコマンド。

## iostat の出力 2 ブロック構造

```
Linux 5.15.0-105-generic (host)   05/06/2026   _x86_64_   (4 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           5.20    0.00    1.50    0.30    0.00   93.00

Device             tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
sda               2.50         12.40        45.20     125000     458000
sdb               0.10          0.50         0.20       5000       2000
```

冒頭にカーネルバージョン + ホスト名 + 日付 + 「(N CPU)」のヘッダ。その下に `avg-cpu:` 行(1 行ブロック)と `Device` 表(N 行ブロック)が続く。**この 2 ブロック構造そのものが iostat の識別キー** になる。

### avg-cpu 行(システム全体 CPU)

| 列 | 意味 |
|---|---|
| `%user` | ユーザモード CPU 時間の割合 |
| `%nice` | nice 値変更プロセスのユーザモード時間 |
| `%system` | カーネルモード CPU 時間 |
| `%iowait` | I/O 待ちで CPU が空いた時間(ディスクI/O 飽和の指標) |
| `%steal` | 仮想化環境でハイパーバイザに奪われた時間 |
| `%idle` | アイドル時間 |

これは **`vmstat` の cpu 欄や `sar -u` と同じ「システム全体 CPU 使用率」**。iostat は **CPU 毎(コア毎)は出さない**(後述、`-P` オプションも持たない)。

### Device 表(デバイス毎 I/O 統計)

| 列 | 意味 | 単位 |
|---|---|---|
| `Device` | デバイス名(sda / sdb / nvme0n1 等) | – |
| `tps` | transactions per second(1 秒あたりの I/O 要求数) | 回/秒 |
| `kB_read/s` | 読込スループット | **KiB/秒**(`-k` 既定) |
| `kB_wrtn/s` | 書込スループット | **KiB/秒**(`-k` 既定) |
| `kB_read` | 累積読込量 | KiB |
| `kB_wrtn` | 累積書込量 | KiB |

列名に `tps` と `kB_read/s` `kB_wrtn/s` の組合せが見えたら iostat 確定。`-m` オプション付きなら `MB_read/s` `MB_wrtn/s` に変わる。`-x`(拡張)を付けると `rrqm/s` `wrqm/s` `await` `%util` が追加されるが、出題対象は通常書式。

### 主要オプション

| オプション | 機能 |
|---|---|
| `-c` | CPU 統計のみ(avg-cpu 行のみ) |
| `-d` | Device 統計のみ |
| `-k` | KiB 単位(既定) |
| `-m` | MiB 単位 |
| `-x` | 拡張統計(rrqm/s, wrqm/s, await, %util 等) |
| `-p [device]` | パーティション含めて表示 |
| `-t` | タイムスタンプ付き |
| `iostat 2 5` | 2 秒間隔 × 5 回サンプリング |

## mpstat の出力

```
Linux 5.15.0-105-generic (host)   05/06/2026   _x86_64_   (4 CPU)

10:00:01     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
10:00:01     all    5.20    0.00    1.50    0.30    0.00    0.00    0.00    0.00    0.00   93.00
```

引数なしの mpstat は **`all`(全 CPU 平均)を 1 行** だけ出す。`mpstat -P ALL` を付けると CPU 番号毎(0, 1, 2, 3 …)も並ぶ。

```
10:00:01     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
10:00:01     all    5.20    0.00    1.50    0.30    0.00    0.00    0.00    0.00    0.00   93.00
10:00:01       0    5.30    0.00    1.40    0.20    0.00    0.00    0.00    0.00    0.00   93.10
10:00:01       1    5.10    0.00    1.60    0.40    0.00    0.00    0.00    0.00    0.00   92.90
```

### 出力列

| 列 | 意味 |
|---|---|
| 時刻 | サンプリング時刻(時:分:秒) |
| `CPU` | CPU 番号(`all` = 全平均、`0` `1` … = コア番号) |
| `%usr` | ユーザモード時間 |
| `%nice` | nice 値変更プロセス |
| `%sys` | カーネルモード時間 |
| `%iowait` | I/O 待ち |
| `%irq` | ハードウェア割り込み処理時間 |
| `%soft` | ソフトウェア割り込み処理時間 |
| `%steal` | 仮想化環境奪取時間 |
| `%guest` | 仮想 CPU 時間 |
| `%gnice` | nice 値変更ゲスト |
| `%idle` | アイドル |

時刻列 + `CPU` 列(`all` または数字) + `%usr` から始まる多数の `%` 列、という並びが mpstat の識別キー。`top` の `%Cpu(s)` 行に近い項目構成だが、**先頭に時刻と `CPU` 列がある** のが mpstat の特徴。

### 主要オプション

| オプション | 機能 |
|---|---|
| `-P ALL` | 全 CPU 毎の統計 |
| `-P 0` | CPU 番号 0 のみ |
| `-A` | 全統計 |
| `mpstat 2 5` | 2 秒間隔 × 5 回 |

## CPU 使用率の 3 階層(横串論点)

主題200 の集合問題では「**CPU 毎**(コア毎)の使用率」「**プロセス毎**の使用率」「**システム全体**の使用率」の **3 階層** を取り違えない訓練が要る。

| 層 | 何が出るか | 該当コマンド |
|---|---|---|
| **システム全体** | 1 サーバ全体の CPU 使用率 | `vmstat` / `iostat`(avg-cpu) / `top`(%Cpu(s)) / `sar -u` |
| **CPU 毎(コア毎)** | コアごとの使用率 | **`mpstat` / `sar -P`** |
| **プロセス毎** | プロセスごとの %CPU | `ps` / `top`(プロセステーブル) |

このうち **CPU 毎を出せるのは `mpstat` と `sar -P` の 2 つだけ**。`top` は **システム全体(ヘッダ %Cpu(s) 行)とプロセス毎(プロセステーブル)の両方を出す** が、CPU 毎(コア毎)は出さない。`iostat` も CPU 毎は出ない(`-P` オプションを持たない、`avg-cpu` はあくまで全体平均)。

集合問題で `iostat` を「CPU 毎集合」に入れたり、`top` を「CPU 毎集合」に入れるのは典型的な誤答。

## ディスクI/O を出すコマンドの集合

| コマンド | 出力単位 | 単位 |
|---|---|---|
| **iostat** | デバイス毎 | KiB/秒(既定) |
| **vmstat** | システム全体 `bi` / `bo` | **ブロック数/秒**(通常 1 KiB ブロック) |
| **sar -b** | システム全体 `rtps` / `wtps` / `bread/s` / `bwrtn/s` | **512 B ブロック/秒** |

「ディスクI/O を出せるコマンド」と問われたら **`iostat` / `vmstat` / `sar -b` の 3 つ**。`netstat` は NW、`free` はメモリ、`top` はシステム全体だがディスクI/O を独立列としては出さないので外す。

`vmstat` と `sar -b` はどちらも「ブロック数」表記だが、**ブロックサイズが違う**(vmstat は通常 1 KiB、sar -b は 512 B)のが地味な引っかけ。プロセス毎のディスクI/O は別軸で `iotop` が担当する(別記事に切り出した)。

## 出力 → コマンド識別の判別キー

スクリーンショット問題用のチートシート。

### iostat の判別

| 特徴 | コマンド |
|---|---|
| `avg-cpu:` 行 + `Device` 表(2 ブロック構造) | iostat |
| `Device` 列 + `tps` `kB_read/s` `kB_wrtn/s` | iostat(`-k` 既定) |
| `Device` 列 + `MB_read/s` | iostat -m |
| `Device` 列 + `rrqm/s` `wrqm/s` `await` `%util` | iostat -x(拡張) |

### mpstat の判別

| 特徴 | コマンド |
|---|---|
| 時刻列 + `CPU` 列(`all` or 数字) + `%usr/%sys/%iowait/%irq/%soft/%steal/%guest/%gnice/%idle` | **mpstat** |
| `CPU` 列なしで `%user/%nice/%system/%iowait/%steal/%idle` のみ(時刻列も無し) | iostat の avg-cpu 行 |
| 時刻列 + `%user/%nice/%system/%iowait/%steal/%idle`(`CPU` 列なし) | sar -u |

`%CPU` 系の列名表記には `%user`(iostat / sar -u)と `%usr`(mpstat)の **微妙な違い** がある。`CPU` 列の有無と組み合わせて判定する。

## 試験本番で踏みやすい罠 5 種

### 罠①: iostat の avg-cpu を CPU 毎統計と取り違える

iostat の `avg-cpu:` 行は **システム全体平均**。「CPU 毎統計だ」と判断すると mpstat と取り違える。**iostat は `-P` オプションを持たない** ので、CPU 毎は構造的に出ない。CPU 毎が要るなら `mpstat` か `sar -P`。

### 罠②: vmstat の bi/bo と sar -b のブロックサイズの違い

vmstat の `bi`/`bo` は通常 **1 KiB ブロック/秒**(カーネル実装依存)、sar -b の `bread`/`bwrtn` は **512 B ブロック/秒**。同じ「ブロック」でも数字の桁が違うので、ベンチマーク的に値を比較しようとすると合わない。

### 罠③: 「CPU 毎」と「プロセス毎」と「システム全体」の取り違え

問題文の言葉に注意。

- 「**システム全体**の CPU 使用率」 → `vmstat` / `iostat`(avg-cpu) / `top` / `sar -u`
- 「**プロセス毎**の CPU 使用率」 → `ps` / `top`
- 「**CPU 毎**(コア毎)の CPU 使用率」 → **`mpstat` / `sar -P`**

3 階層を 1 つの図で覚える。`top` だけはシステム全体とプロセス毎の両方の集合に入るが、**CPU 毎の集合には入らない**。

### 罠④: `-P` オプションの解釈

`mpstat -P 0` `sar -P 0` の `0` は **CPU 番号 0**(CPU0 = 1 番目のコア)であって、NIC 番号やプロセス番号ではない。`-P ALL` で全 CPU。

### 罠⑤: iostat の単位

既定 `-k` で **KiB/秒**、`-m` で MiB/秒。試験では既定 KiB 想定で問われることが多い。`tps` は **回/秒**(KiB ではない)。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- iostat の出力ブロック構造は何ブロックで、各ブロックの中身は何か(2 ブロック、avg-cpu 行 + Device 表)
- iostat の Device 表で「1 秒あたりの I/O 要求数」を表す列名は何か(tps、単位は回/秒)
- iostat はなぜ CPU 毎統計を出せないのか(`-P` オプションを持たない、avg-cpu はシステム全体平均)
- mpstat の `CPU` 列に並ぶ値は何か(`all` 行 + コア番号 `0` `1` … 行)
- 「CPU 毎(コア毎)の CPU 使用率」を出すコマンドの集合は何か(`mpstat` / `sar -P` の 2 つ)
- 「システム全体の CPU 使用率」を出すコマンドの集合は何か(`vmstat` / `iostat` / `top` / `sar -u`)
- `top` は CPU 使用率 3 階層のうちどの集合に入るか(システム全体 + プロセス毎、CPU 毎は外れる)
- 「ディスクI/O」を出すコマンドの集合は何か(`iostat` / `vmstat` / `sar -b` の 3 つ)
- vmstat の bi/bo と sar -b の bread/bwrtn でブロックサイズはどう違うか(vmstat は通常 1 KiB、sar -b は 512 B)
- iostat の `kB_read/s` の単位は何か(KiB/秒、`-k` 既定)

## 変更履歴

- 2026-05-06: 初版公開
