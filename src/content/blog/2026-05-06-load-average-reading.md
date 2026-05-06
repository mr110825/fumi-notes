---
title: "load average の読み方:top / w / uptime の 3 兄弟と %CPU との違い"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "load average の定義(R + D 状態プロセス数の移動平均)、1 / 5 / 15 分平均の解釈、top / w / uptime の 3 コマンド集合、%CPU との別概念性、マルチコアでのコア数比評価を整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で「CPU 負荷平均を表示するコマンドを全て選べ」という問題に出会って、`top` だけ選んで失点した。**load average を表示するコマンドは `top` / `w` / `uptime` の 3 兄弟**で、出力第 1 行が完全に同一書式。さらに **load average は %CPU(CPU 使用率)とは別概念** で、I/O 待ち(D 状態)も含むため「CPU が暇でも load average が高い」ケースがある。本記事ではこの **集合 + 概念整理** を 1 本にまとめておく。

[uptime / w コマンドの読み方](/posts/2026-05-06-uptime-w-reading/) ・ [topコマンドの読み方](/posts/2026-05-06-top-header-reading/) と対になる記事。

## load average の定義

**実行可能(R)+ 不可中断スリープ(D)状態のプロセス数の移動平均**

= 「CPU を欲しがっているプロセスの数」の平均値。

### 1 / 5 / 15 分平均

```
load average: 0.45, 0.52, 0.58
```

| 値 | 期間 |
|---|---|
| 第 1 値 | 過去 **1 分** 平均 |
| 第 2 値 | 過去 **5 分** 平均 |
| 第 3 値 | 過去 **15 分** 平均 |

「現在 → 過去」の順ではなく **「直近 → 長期」の順** で並ぶ。3 値を比べれば負荷のトレンド(上がっている / 下がっている)が読める。

### 値の解釈(コア数 1 台基準)

| load average | コア数 1 台での解釈 |
|---|---|
| 0.0 | アイドル |
| < 0.7 | 余裕あり |
| 0.7〜1.0 | やや負荷 |
| 1.0 | 1 コア飽和 |
| > 1.0 | キュー待ちプロセス発生(過負荷) |

### マルチコアでの評価

load average の絶対値ではなく、**コア数で割って評価**するのが正しい読み方。

- 4 コアなら load average **4.0 で飽和**
- 8 コアなら load average **8.0 で飽和**

`nproc` でコア数確認できる。「load average 2.0 = 過負荷」と即決するのは 1 コア前提の読み方で、現代のマルチコアでは誤判定。

### CPU 使用率(%CPU)との違い

| 指標 | 意味 | 単位 |
|---|---|---|
| **%CPU**(top / mpstat / sar -u) | CPU 時間使用率 | 0〜100% |
| **load average** | プロセス数の移動平均 | 数値、絶対値 |

両者は別概念。**%CPU が低くても load average が高いケース**があるのが要点。

例: ディスクI/O で詰まっているプロセスが多数あると、それらは **D 状態(uninterruptible sleep)** なので CPU を使っていない(%CPU は低い)が、load average には含まれる(プロセス数のカウント対象)。「CPU が暇 + load average 高い」 = I/O ネック。

## load average を表示する 3 コマンド

```
load average を表示するコマンド = top / w / uptime
```

### 3 兄弟の同一書式(出力第 1 行)

| コマンド | load average 表示 | 表示行 |
|---|---|---|
| **top** | ✅ ヘッダ第 1 行 | `top - 10:00:00 up 1 day, ..., load average: 0.45, 0.52, 0.58` |
| **w** | ✅ ヘッダ第 1 行 | `10:00:00 up 1 day, ..., load average: 0.45, 0.52, 0.58` |
| **uptime** | ✅ 唯一の出力 | `10:00:00 up 1 day, ..., load average: 0.45, 0.52, 0.58` |

3 コマンドの第 1 行は完全同一書式(`top` だけプロンプト `top - ` が前置される)。**「現在時刻 + up 稼働時間 + ユーザ数 + load average」の 4 項目** を表示するコマンド集合と問われたら、ここでも `top` / `w` / `uptime`。詳しくは [uptime / w コマンドの読み方](/posts/2026-05-06-uptime-w-reading/) で扱った。

### load average を表示しないコマンド

| コマンド | 理由 |
|---|---|
| `vmstat` | cpu 欄は %、`procs r/b` 列はあるが load average とは別概念 |
| `iostat` | `avg-cpu` は %、load average なし |
| `sar -u` | % のみ |
| `mpstat` | % のみ |
| `ps` | プロセス毎情報、load average なし |
| `free` | メモリのみ |
| `netstat` | NW のみ |

`vmstat` の `procs` 欄(`r` `b`)を見て「これが load average に近い値だな」と直感するのは正しいが、**「load average を表示するコマンド」の集合には入らない**。`r` / `b` は瞬間値で、load average は移動平均という違いがある。

### 例外: sar -q

`sar -q` は例外的に load average を表示する。

| sar -q 列 | 意味 |
|---|---|
| `runq-sz` | 実行キューサイズ |
| `plist-sz` | プロセス数 |
| `ldavg-1` | 1 分平均 |
| `ldavg-5` | 5 分平均 |
| `ldavg-15` | 15 分平均 |

ただし試験で「load average を表示するコマンド」と問われたときの **標準解答は `top` / `w` / `uptime` の 3 つ**。sar -q は補助知識。

## %CPU 系コマンドの集合との対比

|問の言葉|正解集合|
|---|---|
|「**CPU 使用率**(システム全体)」|`vmstat` / `iostat` / `top` / `sar -u`|
|「**CPU 使用率**(プロセス毎)」|`ps` / `top`|
|「**CPU 使用率**(CPU 毎・コア毎)」|`mpstat` / `sar -P`|
|「**負荷平均**」「**load average**」|**`top` / `w` / `uptime`**|

「使用率」と「負荷平均」は **別の集合**。問題文の言葉で切り替える。

## 試験本番で踏みやすい罠 4 種

### 罠①: load average を %CPU と混同

%CPU は時間使用率(0〜100%)、load average はプロセス数の移動平均(絶対値)。**単位も意味も違う**。「load average 0.85」を「85% 使用率」と読むのは誤り。

### 罠②: I/O 待ちが load average に含まれることを忘れる

D 状態(uninterruptible sleep、通常 I/O 待ち)も load average の対象。「CPU が暇 + load average 高い」 = I/O ネック、というシナリオを見逃さない。

### 罠③: マルチコアで絶対値判定

load average 4.0 を「過負荷」と即決するのは 1 コア前提。**4 コアなら飽和、8 コアならむしろ余裕**。`nproc` でコア数を必ず確認する。

### 罠④: 集合に `vmstat` を入れる

`vmstat` の cpu 欄は % 表示で load average は出さない。`procs r/b` は瞬間値で別概念。「load average を表示するコマンド」と問われたら **3 兄弟だけ**。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- load average の定義は何か(R + D 状態のプロセス数の移動平均)
- load average の 3 値は何分平均か(1 / 5 / 15 分)
- load average を表示するコマンドの集合は何か(`top` / `w` / `uptime`)
- 4 コア環境で load average いくつから飽和とみなすか(4.0)
- %CPU と load average の違いは何か(時間使用率 % vs プロセス数の絶対値)
- 「CPU は暇なのに load average が高い」状況は何が原因か(D 状態の I/O 待ちプロセスが多い)
- vmstat の `r` / `b` 列と load average の関係は何か(瞬間値 vs 移動平均で別概念)
- `sar -q` の `ldavg-1/5/15` は何を示すか(load average の 1/5/15 分平均)
- 「現在時刻 / up 時間 / ユーザ数 / load average」を表示する 3 コマンドは何か(`top` / `w` / `uptime`)

## 変更履歴

- 2026-05-06: 初版公開
