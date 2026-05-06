---
title: "topコマンドの読み方:5行ヘッダの読み解きとvmstatとの差分"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "top コマンド冒頭5行のヘッダをラベル単位で読み解き、%Cpu(s) と vmstat の cpu 欄の差分・MiB Mem 新旧書式の並び違い・avail Mem の意味を整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で `top` の出力スクリーンショットを読む問題を解いていて、思った以上に「ラベル名から逆引き」の癖がついていないことに気づいた。新旧書式で項目の並びが違うので、位置で覚えていると詰む。本記事では top 冒頭の **5行ヘッダ** をラベル単位で読み解き、`vmstat` の cpu 欄との差分・新旧書式の並び違い・他コマンド出力との識別キーまでを 1 本にまとめておく。

[vmstatの読み方](/posts/2026-05-05-vmstat-bottleneck-reading/) ・ [sarコマンドの読み方](/posts/2026-05-06-sar-command-reading/) と対になる記事。

## top とは何を見るコマンドか

`top` は **プロセス毎の CPU/メモリ使用率と、システム全体の負荷状況を 1 画面でリアルタイム表示** するモニタコマンド。`procps` パッケージに含まれる。

- `vmstat` がリソース別の総合モニタ、`sar` が時系列レポートなのに対し、`top` は **プロセス単位** に踏み込めるのが強み
- 既定でインタラクティブ実行(対話キーで並び替え・絞り込み・kill が可能)
- バッチモード(`-b`)でログとして書き出すことも可能だが、長期記録は `sar`/`sadc` が担当

### 実行形式

```
top [options]
```

| オプション | 意味 |
|------|------|
| `-d <秒>` | 更新間隔(既定 3 秒) |
| `-n <回>` | 更新回数。`-b` と併用してログ書き出しに使う |
| `-b` | バッチモード(画面制御をせず stdout に出す) |
| `-u <user>` | 特定ユーザのプロセスのみ表示 |
| `-p <pid>` | 特定 PID のみ表示 |
| `-H` | スレッド単位表示 |

対話キーは別記事で扱うとして、本記事は **冒頭ヘッダの読み解き** に絞る。

## 出力の構造(5行ヘッダ + 空行 + プロセステーブル)

top の出力は冒頭が 5 行のヘッダ、1 行の空行、その後にプロセステーブルが続く。試験で問われる読み取りポイントはほぼこのヘッダ 5 行に集中している。

```
top - 09:23:14 up 2 days,  5:42,  3 users,  load average: 1.24, 0.87, 0.62   ← 1行目: 時刻 + uptime + load avg
Tasks: 156 total,   2 running, 154 sleeping,   0 stopped,   0 zombie         ← 2行目: タスク数
%Cpu(s): 12.3 us,  4.1 sy,  0.0 ni, 82.8 id,  0.5 wa,  0.0 hi,  0.3 si,  0.0 st  ← 3行目: CPU使用率(全体)
MiB Mem :   7891.2 total,   2456.8 free,   3120.4 used,   2314.0 buff/cache  ← 4行目: 物理メモリ
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   4218.6 avail Mem   ← 5行目: スワップ + 利用可能メモリ
                                                                              ← 空行
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND  ← プロセステーブル
   1834 ito       20   0  812456  56248  32104 S   2.3   0.7   0:42.18 node
    782 root      20   0  104560   8240   6912 S   0.7   0.1   0:11.04 systemd
...
```

これは普段使いの WSL2/Ubuntu 22.04 で軽い開発作業をしているときの想定出力。値は LPIC 試験対策の解説用に再構成したもので、実機ログそのままではない。

## 1行目: top 自身のサマリー

```
top - HH:MM:SS up <稼働時間>, <ユーザ数> users, load average: <1分>, <5分>, <15分>
```

`uptime` / `w` コマンドの先頭行と **完全に同じ書式**。試験で「現在時刻・稼働時間・ログイン数・load average の 4 項目を表示するコマンド」が問われたら、この行を持っている `top` / `uptime` / `w` の 3 兄弟を即答できるようにしておきたい。

| 項目 | 例 | 意味 |
|---|---|---|
| 時刻 | `09:23:14` | 現在時刻(HH:MM:SS) |
| uptime | `up 2 days, 5:42` | 起動からの経過時間 |
| users | `3 users` | ログイン中のユーザ数 |
| load average | `1.24, 0.87, 0.62` | 直近 1 分 / 5 分 / 15 分の負荷平均 |

## 2行目: タスク数の内訳

```
Tasks: <total> total, <running> running, <sleeping> sleeping, <stopped> stopped, <zombie> zombie
```

zombie プロセス検出の標準的な確認場所。**zombie は親プロセスに回収されないまま残った終了済みプロセス** のことで、増え続けると PID 枯渇につながる。試験では稀(書式問題でたまに出る程度)。

## 3行目: %Cpu(s) — システム全体の CPU 使用率(試験頻出)

8 項目を `, ` 区切りで列挙する。**並びは固定**で、`us, sy, ni, id, wa, hi, si, st` の順。

| 略号 | フル名 | 意味 |
|---|---|---|
| `us` | user | 通常ユーザプロセス(nice 変更なし) |
| `sy` | system | カーネル処理(システムコール) |
| `ni` | nice | nice 値を変更したユーザプロセス |
| `id` | idle | アイドル(未使用 CPU 時間) |
| `wa` | iowait | I/O 待ち |
| `hi` | hardware interrupt | ハードウェア割り込み |
| `si` | software interrupt | ソフト割り込み |
| `st` | steal | 仮想化スチール時間(KVM 等のホスト側に取られた時間) |

### vmstat と top の cpu 欄差分

ここが試験で問われやすい。

| 列 | top | vmstat |
|---|:---:|:---:|
| `us`(user) | ○ | ○ |
| `sy`(system) | ○ | ○ |
| `ni`(nice) | **○** | × |
| `id`(idle) | ○ | ○ |
| `wa`(iowait) | ○ | ○ |
| `hi`(hardware irq) | **○** | × |
| `si`(software irq) | **○** | × |
| `st`(steal) | ○ | ○ |

vmstat は `us / sy / id / wa / st` の **5 項目のみ**、top は `ni / hi / si` を追加した **8 項目**。出力に `ni` または `hi`/`si` の列があれば top(または `mpstat` / `sar -u` 系で `%nice`/`%irq`/`%soft` 表記)と判定できる。

## 4行目: MiB Mem — 物理メモリ(試験頻出)

```
MiB Mem :  <total> total,  <free> free,  <used> used,  <buff/cache> buff/cache
```

| 項目 | 意味 |
|---|---|
| `total` | 物理メモリ総量 |
| `free` | 完全に未使用の物理メモリ |
| `used` | total − free − buff/cache |
| `buff/cache` | バッファ + ページキャッシュ(解放可能) |

### 新旧書式の並び違い

旧バージョンの top は `KiB Mem` 表記で、**並び順も異なる**。

```
# 新書式(procps-ng 3.3 以降、現行 RHEL/Ubuntu の既定)
MiB Mem :   7891.2 total,   2456.8 free,   3120.4 used,   2314.0 buff/cache

# 旧書式(procps 旧版、CentOS 6 系などの古い環境)
Mem:   2058432k total,  1782640k used,   275792k free,   124560k buffers
Swap:  4194300k total,    12480k used,  4181820k free.   891720k cached
```

| 観点 | 新書式 | 旧書式 |
|---|---|---|
| 単位 | MiB(小数) | KiB(`k` サフィックス、整数) |
| 並び | total → **free → used** → buff/cache | total → **used → free** → buffers |
| キャッシュ | `buff/cache`(統合) | `buffers` / `cached`(別行) |

「used = 2 番目の値」と位置で暗記すると詰む。**ラベル名から読む** 癖をつける。

## 5行目: MiB Swap — スワップ + avail Mem

```
MiB Swap:  <total> total,  <free> free,  <used> used.  <avail> avail Mem
```

注目すべきは末尾の `avail Mem`。**4 行目ではなく 5 行目の末尾にある** のが地味な引っかけポイント。

### avail Mem は何を指すか

```
avail Mem ≒ free + 解放可能な buff/cache
```

つまり「アプリが新規確保できる実質的な空きメモリ量」。Linux は積極的にメモリを buff/cache に回す設計のため、`free` 単独で見ると常に小さく見える。本当のメモリ余裕は `avail Mem` で見る。

### メモリ逼迫の判定 3 条件

「物理メモリの `free` が少ないからメモリ増設が必要」と早合点するのは典型的な罠。**Linux では buff/cache が大きければ free は小さくて当然**。次の 3 条件が揃って初めて「メモリ逼迫」と言える。

1. `avail Mem` が極端に小さい(例: 100 MiB 未満)
2. かつ `Swap used` が増加傾向
3. かつ `%wa` が高い(スワップ I/O 待ち)

サンプル出力では `avail Mem = 4218.6 MiB` で、`Swap used = 0.0`、`%wa = 0.5` なのでメモリは健全と判断できる。

## 出力 → コマンド識別の判別キー

LPIC201 では「以下の出力について正しいものを選択せよ」という形でコマンド名が伏せられた問題が出る。**直前に学習していたコマンドの文脈に引きずられず、画像の列名・ヘッダから機械的に識別する** ためのチートシート。

| 特徴 | コマンド |
|---|---|
| プロンプトが `top -` で始まる先頭行 / `%Cpu(s)` 行 + `ni`/`hi`/`si` 列 / `MiB Mem` `MiB Swap` ヘッダ | **top** |
| `procs r b memory swpd free buff cache swap si so io bi bo system in cs cpu us sy id wa st` の 1 行ヘッダ | **vmstat** |
| 冒頭に `avg-cpu: %user %nice %system %iowait %steal %idle` 行 + `Device tps kB_read/s ...` | **iostat** |
| 列に `CPU %user %nice %system %iowait %steal %idle` のみで CPU 列が `all` | **sar -u** |
| 同じ列構成で CPU 列が `0` `1` ... 数値 | **sar -P** |

判定の優先順:

1. プロンプト/先頭行を見る → `top -` で始まれば top 確定
2. なければ列ヘッダを見る → `procs` が先頭にあれば vmstat、`avg-cpu:` があれば iostat
3. CPU 列の値を見る → `all` のみなら sar -u、数値なら sar -P
4. 列に `ni` `hi` `si` があるかどうか → top と vmstat の最終切り分け

## 試験本番で踏みやすい罠 4 種

ソースメモから抜き出した、自分が踏んだ/踏みかけた罠。

### 罠①: 「使用率」と「idle」の混同

`%Cpu(s)` 行の `id` は **idle**(未使用率)であって **使用率** ではない。

```
%Cpu(s):  4.5 us,  2.8 sy, ...,  92.5 id, ...
```

これを見て「CPU 使用率は 92.5%」と書いてある選択肢は **完全に逆**。

```
CPU 使用率 = 100 − id
            = 100 − 92.5
            = 7.5  (%)
```

`id = idle = 暇`、`100 − id = 使用率` を呪文のように覚える。

### 罠②: free 単独でメモリ不足判定

4 行目の `free` だけ見て「空きメモリが少ない=増設必要」と判断する選択肢。実際の判断は **avail Mem**(5 行目末尾)で行う。さらにメモリ逼迫の判定は前述の 3 条件(`avail` 極小 + `Swap used` 増 + `%wa` 高)が揃って初めて成立する。

### 罠③: 文脈バイアスで他コマンドと混同

「直前に vmstat を学習していた」「セクションの章タイトルが top」といった **学習中の文脈** で出力を誤認するパターン。試験本番では章タイトルが伏せられている前提で、**画像の列名・ヘッダだけから識別する** 練習をしておく。前掲の判別キー表が安全策。

### 罠④: 新旧書式の並び違い

```
# 旧書式(used が 2 番目)
Mem:  2058432k total,  1782640k used,  275792k free, ...

# 新書式(free が 2 番目)
MiB Mem :  7891.2 total,  2456.8 free,  3120.4 used, ...
```

「used = 2 番目」「free = 3 番目」と **位置で暗記すると逆転して詰む**。ラベル名(`used` / `free` / `total`)から値を引く癖をつける。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- top 1 行目に並ぶ 4 項目は何か(時刻・稼働時間・ユーザ数・load average)
- top 1 行目と同じ書式の先頭行を持つコマンドは何か(`uptime` / `w`)
- `%Cpu(s)` 行の 8 項目を順に書けるか(`us, sy, ni, id, wa, hi, si, st`)
- top にあって vmstat にない cpu 欄の項目は何か(`ni` / `hi` / `si`)
- `id = 92.5` のとき CPU 使用率はいくつか(7.5%)
- `MiB Mem` 行で `used` は何番目に並ぶか(新書式は 3 番目、旧書式は 2 番目)
- `avail Mem` は何行目の末尾にあるか(5 行目)
- `avail Mem` を free と buff/cache から計算する近似式は何か
- メモリ逼迫と判定するための 3 条件は何か
- 列ヘッダに `ni`/`hi`/`si` があれば、それは top か vmstat か(top)

## 変更履歴

- 2026-05-06: 初版公開
