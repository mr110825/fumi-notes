---
title: "sarコマンドの読み方:オプション別出力とsysstat役割分担"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "sar の主要オプションごとの列構成と判別キー、sysstat パッケージ内の sa1/sa2/sadc/sadf の役割分担をまとめる。"
---

LPIC201 の主題200(キャパシティプランニング)で `sar` を学習する中で、出力スクリーンショットからオプションを逆引きする問題に何度か詰まった。列ヘッダだけでは決まらず、CPU 列の値や単位まで踏み込まないと判別できない。本記事ではオプション別の出力構成と判別キー、そして混同しやすい `sa1` / `sa2` / `sadc` / `sadf` の役割分担を整理する。

[vmstatの読み方](/posts/2026-05-05-vmstat-bottleneck-reading/) と対になる記事。

## sar とは何を見るコマンドか

`sar`(System Activity Reporter)は **時系列のシステム活動レポート** を表示するコマンド。`sysstat` パッケージに含まれる。

- `vmstat` がリアルタイム総合モニタなのに対し、`sar` は **過去のログを読み出して時系列で表示** できる
- 収集役は `sadc`(`sa1` 経由で cron 起動)、レポート役が `sar`、変換役が `sadf` という役割分担
- 長期キャパシティプランニング・週次レビューに向く

### 実行形式

```
sar [options] [interval [count]]
```

| 引数 | 意味 | 例 |
|------|------|----|
| `interval` | 秒単位の表示間隔 | `sar 3 1` → 3 秒間隔で 1 回 |
| `count` | 表示回数 | 省略時は無限 |
| `-f <file>` | 過去ログファイルを読み出す | `sar -f /var/log/sa/sa05` |

引数なしで実行すると、当日の `/var/log/sa/saXX` に記録された CPU 使用率(`-u` 相当)を時系列で表示する。

## オプション別の表示列(早見表)

「列ヘッダ → オプション逆引き」の暗記が 9 割。

| オプション | 主要な列ヘッダ | 内容 |
|---|---|---|
| (なし) / `-u` | `CPU` `%user` `%nice` `%system` `%iowait` `%steal` `%idle` | CPU 使用率全体(CPU 列の値が `all`) |
| `-P N` / `-P ALL` | (上と同じ) | CPU 毎の使用率(CPU 列の値が `0`,`1`,...) |
| `-r` | `kbmemfree` `kbavail` `kbmemused` `%memused` `kbbuffers` `kbcached` | メモリ使用状況 |
| `-b` | `tps` `rtps` `wtps` `bread/s` `bwrtn/s` | ブロックデバイス全体の I/O |
| `-d` | `DEV` `tps` `rd_sec/s` `wr_sec/s` | デバイス毎の I/O |
| `-n DEV` | `IFACE` `rxpck/s` `txpck/s` `rxkB/s` `txkB/s` | NIC 統計(正常パケット) |
| `-n EDEV` | `IFACE` `rxerr/s` `txerr/s` `coll/s` ... | NIC 統計(エラーパケット) |
| `-q` | `runq-sz` `plist-sz` `ldavg-1/5/15` | ランキュー長・load average |
| `-W` | `pswpin/s` `pswpout/s` | スワップ I/O 回数 |
| `-f <file>` | (対象オプションに依存) | 過去ログを読み出し |

## オプション別 詳細

### `-u` / オプションなし — CPU 使用率(全体)

デフォルト動作。全 CPU 合算の使用率を時系列で表示。`top` の Cpu(s) 行に近いが、`-u` は静的記録向け。

```
            CPU   %user   %nice  %system  %iowait  %steal   %idle
14:00:01    all    5.21    0.00    1.34     0.42    0.00    93.03
```

判別キー: **CPU 列が `all`**。

### `-P N` / `-P ALL` — CPU 毎の使用率

列ヘッダは `-u` と同じだが、**CPU 列の値が数値**(指定 CPU 番号)になる。マルチコアで偏りを見るときに使う。`-P ALL` は `all` 行 + 各 CPU 行の両方。

```
            CPU   %user   %nice  %system  %iowait  %steal   %idle
14:00:01      0    10.81    0.00    0.68    0.34    0.00    88.18
```

判別キー: **CPU 列が `0` `1` `2` ...の数値**。

### `-r` — メモリ使用状況

`free` コマンドの時系列版。空き・使用・バッファ・キャッシュが個別に出る。

```
        kbmemfree kbavail kbmemused %memused kbbuffers kbcached
14:00:01  234560  1234560  789440    77.04    45120    456780
```

判別キー: **`kb` プレフィックスが多数**、`mem` を含む列がある。

### `-b` — ブロックデバイス I/O(全体)

ディスク I/O 全体の概要。デバイス毎には分けない総合値。

```
        tps   rtps   wtps   bread/s   bwrtn/s
14:00:01 5.33  0.00   5.33    0.00     59.00
```

| 列 | 意味 | 単位 |
|---|---|---|
| `tps` | 全転送 **回数**/秒 | 回数 |
| `rtps` | 読み込み転送回数/秒 | 回数 |
| `wtps` | 書き込み転送回数/秒 | 回数 |
| `bread/s` | 読み込みブロック数/秒 | **512 B ブロック** |
| `bwrtn/s` | 書き込みブロック数/秒 | **512 B ブロック** |

関係式: `tps = rtps + wtps`。

判別キー: **`tps` `rtps` `wtps` `bread/s` `bwrtn/s` の 5 列**(`DEV` 列なし)。

> **罠**: `bread`/`bwrtn` の `b` は **block(512 B)** であって bytes ではない。LPIC 試験で頻出のひっかけ。`tps` も「回数」であって「データ量」ではない。

### `-d` — デバイス毎の I/O

`-b` と違い、デバイス毎(sda, sdb...)に分けて表示。`iostat` に近い。

```
        DEV   tps   rd_sec/s  wr_sec/s  await  %util
14:00:01 sda  5.33   0.00     59.00     3.45   0.66
```

判別キー: **`DEV` 列があり、デバイス毎の行が並ぶ**。

### `-n DEV` — NIC 統計(正常パケット)

ネットワーク I/F 毎のパケット送受信統計。`netstat -i` の時系列版。

```
        IFACE   rxpck/s  txpck/s  rxkB/s   txkB/s
14:00:01 eth0    12.34    8.56     1.23     0.89
```

判別キー: **`IFACE` 列 + `rx*` `tx*` 列**(エラー系列なし)。

### `-n EDEV` — NIC 統計(エラーパケット)

`-n DEV` のエラー版。`rxerr/s` `txerr/s` 等のエラー系列のみ。

```
        IFACE   rxerr/s  txerr/s  coll/s   rxdrop/s  txdrop/s
14:00:01 eth0    0.00     0.00     0.00     0.00      0.00
```

判別キー: **`IFACE` 列 + `err`/`drop`/`coll` 系列**。

### `-q` — ランキュー長・load average

`uptime` の時系列版。負荷平均と実行待ちプロセス数。

```
        runq-sz  plist-sz  ldavg-1  ldavg-5  ldavg-15
14:00:01  2       234       0.45     0.32     0.25
```

判別キー: **`ldavg-*` 列**。

### `-W` — スワップ I/O 回数

スワップイン/アウトの **回数**。メモリ不足の兆候を見るときに使う。

```
        pswpin/s  pswpout/s
14:00:01  0.00     0.00
```

判別キー: **`pswpin/s` `pswpout/s` の 2 列のみ**。

> **注意**: `vmstat` の `si`/`so` と意味は同じだが、**vmstat は KB/s** 単位、**sar -W は回数/秒** で単位が異なる。

### `-f <file>` — 過去ログの読み出し

リアルタイムではなく、過去の sar ログファイル(`/var/log/sa/saXX`、XX は日付 2 桁)を読み出す。

```bash
sar -f /var/log/sa/sa05         # 5 日のログを読み出し
sar -u -f /var/log/sa/sa05      # 5 日のログから CPU 使用率を読み出し
```

## 出力結果からオプションを当てる手順

LPIC201における「以下のような出力をするオプションはどれか」型の問題は、次の順で詰めると外しにくい。

1. **列ヘッダを見る** → オプション群を絞る
   - `IFACE` → `-n`(`DEV`/`EDEV`)
   - `kb*` 多数 → `-r`
   - `DEV` + `tps` → `-d`
   - `tps`/`bread`/`bwrtn` → `-b`
   - `CPU` 列 → `-u` か `-P`
   - `runq-sz`/`ldavg` → `-q`
   - `pswpin`/`pswpout` → `-W`
2. **`CPU` 列なら値(`all`/数値)を見る** → `-u` と `-P` を切り分け
3. **`-b` 系なら "512" を含む選択肢を疑う**(正解候補)
4. **"バイト" と素直に書いてある選択肢は罠を疑う**(`b` は block)
5. **`tps` 系の数値は "回数"** であって "バイト数" ではない

オプションを問われたら逆方向に「**代表列 3 つ + 何を見るための機能か**」を即答できるようにしておく。

```
-u  : %user / %system / %idle           → CPU 使用率全体
-P  : (-u と同じ列) + CPU 列が "数値"     → CPU 毎使用率
-r  : kbmemfree / kbmemused / %memused  → メモリ使用状況
-b  : tps / bread/s / bwrtn/s           → ブロック I/O 全体
-d  : DEV / rd_sec/s / wr_sec/s         → デバイス毎 I/O
-n  : IFACE / rxpck/s / txpck/s         → NIC 統計(DEV=正常 / EDEV=エラー)
-q  : runq-sz / ldavg-1/5/15            → 負荷平均
-W  : pswpin/s / pswpout/s              → スワップ I/O 回数
-f  : (依存)                            → 過去ログ /var/log/sa/saXX 読み出し
```

## sysstat パッケージの役割分担

`sar` と一緒に紛らわしいのが `sa1` / `sa2` / `sadc` / `sadf`。**動詞で区別する** のが効く。

```
sadc   ← システム情報を「収集」してバイナリログに書く(バックエンド)
  ↑
sa1    ← cron が定期実行(10 分ごと等)。中で sadc を呼び出す
sa2    ← cron が日次実行。中で sar を呼び出してテキストレポートを生成
sar    ← バイナリログを「読み取って」表形式で表示
sadf   ← バイナリログを「読み取って」JSON/XML/CSV 等に「変換」
```

### 動詞で覚える

- **収集する** = `sadc`(cron から `sa1` 経由で呼ばれる)
- **記録する**(cron 経由のラッパー) = `sa1`(`sadc` を呼ぶ) / `sa2`(`sar` を呼ぶ)
- **読む・表示する** = `sar`
- **読む・変換する** = `sadf`

### `sadf` の主要オプション

| オプション | 形式 |
|---|---|
| `-j` | JSON |
| `-x` | XML |
| `-d` | CSV(DB 用) |
| `-p` | 人間可読(pretty) |
| `-r` | レポート形式 |

書式:

```bash
sadf /var/log/sa/sa05                    # デフォルトはタブ区切り
sadf -j /var/log/sa/sa05                 # JSON 形式
sadf -d /var/log/sa/sa05 -- -r           # CSV + sar の -r オプション渡し
sadf /var/log/sa/sa05 -- -P ALL          # `--` 以降は sar に渡される
```

ポイント: **`--` セパレータ以降は sar コマンドに渡される引数**。`-sar` のような書式は存在しない。

### よくある罠選択肢

| 選択肢 | 正誤 | 判断根拠 |
|---|:---:|---|
| `sadf` は **log ファイルから情報を収集** する | ❌ | これは `sa1`/`sadc` の説明(`sadf` は変換役) |
| `sa1` が `sar` を呼ぶ | ❌ | 階層ミスマッチ(`sa1` → `sadc`、`sa2` → `sar`) |
| `sar` がログを書き込む | ❌ | 書き込みは `sadc` |
| `sadf` が cron で定期実行 | ❌ | cron は `sa1`/`sa2` を呼ぶ |
| `sadf` は `--` で sar オプションを渡す | ✅ | 引数書式の通り |
| `sadf` は `-j`/`-x`/`-d` で形式を切り替えられる | ✅ | フォーマットオプションの通り |

## 自己チェック

書きながら自問できるようにしておきたい項目:

- `sar` 引数なしのとき、何を表示するか
- `sar -u` と `sar -P 0` の出力の違いを 1 行で説明できるか
- `sar -b` の `bread/s` の単位は何か
- `sar -b` の `tps` `rtps` `wtps` の関係式を書けるか
- `sar -n DEV` と `sar -n EDEV` の違いを 1 行で説明できるか
- `sar -W` と `vmstat` の `si`/`so` の単位の違いは
- `sa1` と `sadc`、どちらが情報を「収集」しているか
- `sa2` は内部で何を呼んでいるか
- `sadf` の `--` セパレータの意味は

## 変更履歴

- 2026-05-06: 初版公開
