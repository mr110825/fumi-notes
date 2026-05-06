---
title: "iotop の読み方:プロセス毎ディスクI/Oと iostat / top との見分け"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "iotop の識別キー(Total DISK READ/WRITE ヘッダ + プロセス毎 DISK READ/WRITE 列)を読み解き、iostat(デバイス毎)と top(CPU/メモリ)との 3 者識別を整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で出力スクリーンショットからコマンドを当てる問題を解いていて、`iotop` と `top` を取り違えた。両者とも対話型 ncurses で見た目が似ているが、**ヘッダと列が完全に違う**。`iotop` は `Total DISK READ` / `Total DISK WRITE` のヘッダ + プロセス毎 I/O 列、`top` は 5 行ヘッダ + `%CPU` `%MEM` 列。さらに `iostat` は **デバイス毎**で観点軸そのものが違う。本記事ではこの 3 者の見分けと、`iotop` 出力の読み方を 1 本にまとめておく。

[topコマンドの読み方](/posts/2026-05-06-top-header-reading/) ・ [iostat / mpstat の読み方](/posts/2026-05-06-iostat-mpstat-reading/) と対になる記事。

## iotop の出力

```
Total DISK READ:        12.34 K/s | Total DISK WRITE:        45.67 K/s
Current DISK READ:      10.00 K/s | Current DISK WRITE:      40.00 K/s
   PID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND
  1234  be/4  root     12.34 K/s    0.00 B/s  0.00 %  5.43 %  bash
  5678  be/4  mysql     0.00 B/s   45.67 K/s  0.00 %  3.21 %  mysqld --daemonize
  9012  be/4  www       0.00 B/s    0.00 B/s  0.00 %  0.00 %  nginx: worker process
```

冒頭 2 行のヘッダ(`Total DISK READ:` / `Total DISK WRITE:` / `Current DISK READ:` / `Current DISK WRITE:`)+ プロセス毎の I/O 表、というのが iotop の固定書式。**ヘッダの `Total DISK READ:` を見たら iotop 確定**。

### 列の意味

| 列 | 意味 |
|---|---|
| `PID` | プロセス ID |
| `PRIO` | I/O 優先度(`be/4` = best-effort クラス、レベル 4) |
| `USER` | プロセス所有者 |
| `DISK READ` | プロセス毎の読込スループット |
| `DISK WRITE` | プロセス毎の書込スループット |
| `SWAPIN` | スワップイン率 |
| `IO>` | I/O 待ち時間の割合 |
| `COMMAND` | コマンドライン |

`PRIO` 列の `be/4` `rt/N` `idle` といった I/O 優先度クラス表記も iotop 固有の見分け点。`ionice` で変更できる。

### 主要オプション

| オプション | 機能 |
|---|---|
| `-o` / `--only` | I/O アクティブなプロセスのみ表示 |
| `-b` / `--batch` | バッチモード(ファイル出力向け、対話キー無効) |
| `-n N` | N 回サンプリングで終了 |
| `-d N` | N 秒間隔 |
| `-P` | スレッドではなくプロセス単位 |

### root 権限

iotop は **root 権限が必要**(`CAP_NET_ADMIN`)。一般ユーザで叩くと `Could not run iotop as a non-root user` エラーになる。

## iotop と iostat の対比

両者ともディスクI/O 系だが、**観点軸が違う**。

| 項目 | iostat | iotop |
|---|---|---|
| 観点 | **デバイス毎** | **プロセス毎** |
| 出力 | sda / sdb / nvme0n1 等 | PID / COMMAND |
| 主用途 | デバイスの I/O 飽和判定 | I/O 多発プロセスの特定 |
| 列 | `tps` / `kB_read/s` / `kB_wrtn/s` | `DISK READ` / `DISK WRITE` / `IO>` |
| 表示形式 | 静的(コマンド一発) | **対話型 ncurses**(`top` と同様) |

`iostat` で「`sda` の `tps` が高い」と分かっても、**どのプロセスが原因かは分からない**。次の一手で `iotop` を叩いてプロセス毎 DISK I/O を見れば、犯人プロセスが特定できる。

> デバイスが詰まっている → `iostat` で見つける
> どのプロセスが詰まらせている → `iotop` で見つける

両者は補完関係で、運用上はセットで使う。

## iotop と top の見分け

両者とも対話型 ncurses だが、**ヘッダと列が完全に違う**。

| 項目 | top | iotop |
|---|---|---|
| ヘッダ | `top -` / `Tasks:` / `%Cpu(s):` / `MiB Mem:` / `MiB Swap:`(5 行) | `Total DISK READ:` / `Total DISK WRITE:`(2 行) |
| プロセス列 | `%CPU` / `%MEM` / `TIME+` | `DISK READ` / `DISK WRITE` / `IO>` |
| 表示中心 | CPU / メモリ | ディスクI/O |

画像問題ではヘッダの 1 行目を見れば即判別できる。`top -` で始まれば `top`、`Total DISK READ:` で始まれば `iotop`。

## 出力 → コマンド識別の判別キー

| 特徴 | コマンド |
|---|---|
| `Total DISK READ:` ヘッダ + `DISK READ` `DISK WRITE` `IO>` 列 + `be/4` 等の優先度表記 | **iotop** |
| `top - HH:MM:SS up …` 第 1 行 + `Tasks:` `%Cpu(s):` `MiB Mem:` `MiB Swap:` ヘッダ + `PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND` 列 | **top** |
| `avg-cpu:` 行 + `Device tps kB_read/s kB_wrtn/s …` 表(2 ブロック) | **iostat** |

## 試験本番で踏みやすい罠 4 種

### 罠①: iostat と iotop の混同

「ディスクI/O のリアルタイム表示」と聞くと両者が候補に挙がるが、**観点軸が違う**:

- iostat = デバイス毎(sda / sdb)
- iotop = プロセス毎(PID / COMMAND)

問題文に「**プロセス毎**」「**ディスクI/O 多発のプロセス特定**」とあったら iotop。「デバイスの I/O 状況」なら iostat。

### 罠②: iotop と top の見分けでヘッダを見落とす

両者とも対話型 ncurses で見た目が似ている。**ヘッダで識別**:

- top → `top -` / `%Cpu(s)` / `MiB Mem`
- iotop → `Total DISK READ` / `Total DISK WRITE`

列見るより先にヘッダで判別するのが速い。

### 罠③: PRIO の `be/4` を見慣れない記号と判定

`be/4` は best-effort クラスのレベル 4 で、iotop 固有の I/O 優先度表記。`be` = best-effort、`rt` = realtime、`idle` = アイドル。`top` の `PR`(優先度)/`NI`(nice)とは別物。`be/4` を見たら iotop 確定。

### 罠④: root 権限で動かないことを忘れる

実機で叩こうとして「権限エラーで動かない」となるケース。`sudo iotop` で動く。試験では権限不要だが、運用では知っておく。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- iotop の識別キー(冒頭ヘッダ)は何か(`Total DISK READ:` / `Total DISK WRITE:` の 2 行)
- iotop と iostat の観点軸の違いは何か(プロセス毎 vs デバイス毎)
- iotop の `PRIO` 列の `be/4` は何を意味するか(best-effort クラス、レベル 4)
- 「ディスクI/O 多発プロセスを特定」したいときに使うコマンドは何か(iotop)
- iotop と top の見分け方の最速の手段は何か(冒頭ヘッダの 1 行目)
- iotop は誰の権限で動くか(root)
- iostat で `sda` の `tps` が高いと分かったあと、次に叩くべきコマンドは何か(iotop でプロセス特定)
- top と iotop の表示中心(主役リソース)はそれぞれ何か(top = CPU/メモリ、iotop = ディスクI/O)

## 変更履歴

- 2026-05-06: 初版公開
