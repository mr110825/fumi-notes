---
title: "free / swapon -s の読み方:available 列が指す「真の空き」とスワップの 5 列構造"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "free の available 列が表す実質利用可能メモリ(buff/cache 解放分加味)と、swapon -s の 5 列構造(Filename/Type/Size/Used/Priority)を読み解き、free 単独で判断する誤答パターンを整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で `free` の出力を見て「`free` 列が小さいからメモリ不足」と判断する選択肢に引っかかった。Linux はメモリを積極的にバッファ・キャッシュに回す設計のため、`free` 列単独では「真の空き」を表さない。**実質利用可能メモリは `available` 列**(buff/cache の解放分加味)。さらにスワップ側は `swapon -s` の 5 列構造で識別する必要があり、両者を 1 本にまとめておく。

[vmstatの読み方](/posts/2026-05-05-vmstat-bottleneck-reading/) ・ [topコマンドの読み方](/posts/2026-05-06-top-header-reading/) と対になる記事。

## free の出力(procps-ng 3.3.10 以降)

```
              total        used        free      shared  buff/cache   available
Mem:        8000000     2000000     1000000      100000     5000000     5500000
Swap:       2000000      100000     1900000
```

これは 8 GB RAM・2 GB Swap を想定した出力。procps-ng 3.3.10 以降の標準書式で、列ヘッダに `available` が登場する。

### 列の意味

| 列 | 意味 | 解釈 |
|---|---|---|
| `total` | 総物理メモリ | – |
| `used` | 使用中(`total - free - buff/cache` ≒ アプリケーション使用量) | – |
| `free` | **未使用**(カーネルに割り当てられていない領域) | **「メモリ空き」とイコールではない** |
| `shared` | tmpfs 等の共有メモリ | – |
| `buff/cache` | バッファ + ファイルキャッシュ(**解放可能**) | – |
| `available` | **実質利用可能量**(buff/cache の解放分加味) | **真の空き** |

### available 列が「真の空き」である理由

Linux は「使われていないメモリは無駄」という思想で、**ディスクキャッシュとして積極的に buff/cache を埋める**。なので `free` 列は普段から小さい値で出てくるのが普通。アプリケーションがメモリを要求すれば、buff/cache から必要分が解放されてアプリに渡る。

つまり、

```
真の空き ≒ free + 解放可能な buff/cache  =  available
```

「実質的に利用可能なメモリ量」と問われたら **`available` 列** を選ぶ。`free` 列を選ぶと、Linux のメモリ運用思想を理解していないと判定される。

### 旧書式との違い

procps-ng 3.3.10 未満の古い環境では `available` 列がなく、`buffers` と `cached` が別列で出る。

```
              total       used       free     shared    buffers     cached
Mem:        8000000    2000000    1000000     100000     200000    4800000
Swap:       2000000     100000    1900000
```

旧書式を見るときは「used = total − free − (buffers + cached)」と読み替える。新書式と並びが違う点に注意(used / free / shared / buff/cache vs used / free / shared / buffers / cached)。

### 主要オプション

| オプション | 単位 |
|---|---|
| `-b` | バイト |
| `-k` | KiB(既定) |
| `-m` | MiB |
| `-g` | GiB |
| `-h` | 自動人間可読(K/M/G) |
| `-s N` | N 秒間隔で繰り返し |
| `-t` | total 行(Mem + Swap 合計)追加 |

## swapon -s の出力(5 列構造)

```
Filename                Type            Size    Used    Priority
/dev/sda5               partition       2097148 102400  -2
/swapfile               file            1048576 0       -3
```

`Filename Type Size Used Priority` の 5 列が並んだら **`swapon -s` 確定**。`/proc/swaps` を `cat` した出力と同等。

### 列の意味

| 列 | 意味 |
|---|---|
| `Filename` | スワップ領域のパス(デバイスファイル or 通常ファイル) |
| `Type` | `partition`(パーティション) or `file`(通常ファイル) |
| `Size` | 全体サイズ(KiB) |
| `Used` | 使用中サイズ(KiB) |
| `Priority` | 優先度(数値、大きいほど優先、`-2` 等の負値が既定) |

### Type 列の 2 値

- `partition`: スワップ領域として作成された専用パーティション(`mkswap /dev/sda5` 等)
- `file`: 通常ファイル(`dd if=/dev/zero of=/swapfile` で作成 + `mkswap /swapfile`)

`Type` 列に `partition` または `file` が見えたら swapon -s 確定。

### swapon の他オプション

| オプション | 機能 |
|---|---|
| `-s` / `--summary` | 一覧表示(= `cat /proc/swaps`) |
| `-a` | `/etc/fstab` の swap エントリを全て有効化 |
| `-p PRIO` | 優先度指定 |

`swapoff -a` で全スワップを無効化、`swapon -a` で `/etc/fstab` の `sw` エントリを再有効化。

## 出力 → コマンド識別の判別キー

| 特徴 | コマンド |
|---|---|
| 列 `total used free shared buff/cache available` + 行 `Mem:` `Swap:` | **free**(procps-ng 新書式) |
| 列 `total used free shared buffers cached` + 行 `Mem:` `Swap:` | **free**(旧書式) |
| 列 `Filename Type Size Used Priority`(5 列) + Type に `partition` / `file` | **swapon -s** |

## 試験本番で踏みやすい罠 4 種

### 罠①: free 単独でメモリ不足判定

`free` 列だけ見て「空きメモリが少ない = メモリ不足」と判定する選択肢。実際の判断は `available` 列で行う。さらに「メモリ逼迫」は単一値ではなく、

1. `available` が極端に小さい
2. かつ `Swap used` が増加傾向
3. かつ `vmstat` の `si`/`so` や `wa` が高い

の 3 条件が揃って初めて成立する。

### 罠②: 「buff/cache が大きい = メモリ無駄遣い」

これは Linux のメモリ運用思想を勘違いしている。**buff/cache はキャッシュ用途で積極的に使われ、アプリ要求時には即解放される**。「buff/cache が大きい = ディスクキャッシュが効いている健全な状態」と読むのが正しい。

### 罠③: swapon -s と /proc/swaps を別物と誤認

`swapon -s` と `cat /proc/swaps` は **同じ内容** を出す。試験で「同等の出力を得る方法」を問われたら両者は等価。

### 罠④: Type の `partition` と `file` を取り違え

専用パーティションなら `partition`、通常ファイル(swapfile)なら `file`。`mkswap` 後にどちらの形態でも作れるので、`Type` 列で見分ける。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- free 出力で「実質利用可能メモリ」を表す列は何か(`available`)
- なぜ `free` 列単独でメモリ不足判定できないか(Linux は buff/cache を積極利用するため、必要時に解放されて使える)
- `available` 列は概念的にどう計算されるか(`free` + 解放可能な buff/cache)
- swapon -s の出力列を順に書けるか(`Filename Type Size Used Priority`)
- swapon -s の `Type` 列に入る 2 値は何か(`partition` / `file`)
- swapon -s と等価のコマンドは何か(`cat /proc/swaps`)
- procps-ng 旧書式と新書式の列の違いは何か(旧: `buffers` / `cached` 別列、新: `buff/cache` 統合 + `available` 列追加)
- 「メモリ逼迫」と判定するための 3 条件は何か(`available` 極小 + `Swap used` 増 + `wa` 高)

## 変更履歴

- 2026-05-06: 初版公開
