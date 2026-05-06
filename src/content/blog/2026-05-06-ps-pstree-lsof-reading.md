---
title: "ps / pstree / lsof の読み方:プロセス毎リソースとPID表示の集合"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "ps の BSD系/UNIX系オプションと出力列、pstree -p の表記、lsof の PID 併記仕様を整理し、「プロセス毎リソース」「PID表示」の集合に top を含めて並べ直す。"
---

LPIC201 の主題200(キャパシティプランニング)で `ps` 系の問題を解いていて、`ps aux` と `ps -ef` を「どっちかを覚えていればいい」程度に流していたら、出力列の判別問題で詰まった。`aux` と `-ef` は **オプション系統そのものが違う**(BSD系 vs UNIX系)ので、出力列も並びも別物として独立に押さえないと崩れる。さらに `pstree -p` と `lsof` まで含めると、「プロセス毎リソースを出せるコマンドの集合」「PID を表示するコマンドの集合」という横串論点が見えてくる。本記事ではプロセス系3コマンドの読み解きと、`top` を含めた集合論まで 1 本にまとめておく。

[vmstatの読み方](/posts/2026-05-05-vmstat-bottleneck-reading/) ・ [sarコマンドの読み方](/posts/2026-05-06-sar-command-reading/) ・ [topコマンドの読み方](/posts/2026-05-06-top-header-reading/) ・ [uptime / w コマンドの読み方](/posts/2026-05-06-uptime-w-reading/) と対になる記事。

## 3コマンドの位置付け

`ps` / `pstree` / `lsof` は守備範囲がはっきり違う。混同すると集合問題で取りこぼす。

| コマンド | 主目的 | 表示の単位 |
|---|---|---|
| **ps** | プロセス一覧 + リソース統計 | フラットな表(1 行 = 1 プロセス) |
| **pstree** | 親子関係のツリー表示 | ASCII 罫線のツリー |
| **lsof** | open files(開いているファイル)一覧 | 1 行 = 1 ファイル(PID 併記) |

`ps` は「どのプロセスが今動いているか + どれだけリソースを食っているか」、`pstree` は「親から子への系統樹」、`lsof` は「どのプロセスが何を開いているか」。`lsof` だけプロセス起点ではなくファイル起点だが、PID を必ず併記する性質上、後述の「PID表示集合」に入る。

## ps コマンドの実行形式と 3 系統

`ps` のオプションは歴史的に **3 系統が混在** している。同じことを違う書き方で指示できるので、慣れていないと混乱する。

| 系統 | 記法 | 例 |
|---|---|---|
| **UNIX 系**(SystemV) | ハイフン `-` 必須 | `ps -ef`, `ps -e -o pid,cmd` |
| **BSD 系** | ハイフン `-` 不要 | `ps aux`, `ps ax` |
| **GNU long** | `--` 始まり | `ps --forest`, `ps --pid 1234` |

混乱を避ける呪文として「**`a`/`u`/`x` はハイフンなし、`e`/`f` はハイフンあり**」を覚えておく。`ps aux` と `ps -aux` は別の意味として解釈される実装もある(POSIX 準拠の挙動では警告が出るか、ユーザ名 `x` の検索になる)ので、`aux` と `-ef` は **書式から系統が違う** と理解する。

代表的な実行例:

| コマンド | 系統 | 目的 |
|---|---|---|
| `ps`(引数なし) | デフォルト | 自端末・自ユーザのみ(最小出力) |
| `ps aux` | BSD | 全プロセス + ユーザ名 + リソース統計 |
| `ps -ef` | UNIX | 全プロセス + 親 PID + 起動時刻 |
| `ps axjf` | BSD | プロセス親子関係をツリー風に表示 |
| `ps -eo pid,cmd` | UNIX | 出力列を任意に指定 |

## ps aux の出力 11 列

```
USER    PID  %CPU  %MEM    VSZ    RSS  TTY  STAT  START  TIME    COMMAND
root      1   0.0   0.1  167848  11756  ?    Ss    Apr27  0:08    /sbin/init
mysql  1234   1.5   3.2  856432 264912  ?    Sl    May01  3:42    /usr/sbin/mysqld
```

これは小規模 Linux サーバの想定出力(値は記事用に再構成)。各列の意味は次の通り。

| 列 | 意味 |
|---|---|
| `USER` | プロセス所有ユーザ |
| `PID` | プロセス ID |
| `%CPU` | 直近の CPU 使用率(プロセス毎) |
| `%MEM` | 物理メモリ使用率(プロセス毎) |
| `VSZ` | 仮想メモリサイズ(KiB) |
| `RSS` | 物理メモリサイズ(Resident Set Size、KiB) |
| `TTY` | 制御端末。`?` は端末なし(デーモン) |
| `STAT` | プロセス状態(後述) |
| `START` | 起動時刻(24 時間以内)or 起動日(それ以前) |
| `TIME` | 累積 CPU 使用時間(`HH:MM` 形式) |
| `COMMAND` | コマンドライン。`[ ]` で囲まれているのはカーネルスレッド |

`%CPU` と `%MEM` が **プロセス毎** に出ている点が、後述の集合論で効いてくる。

## ps -ef の出力 8 列

```
UID    PID  PPID  C  STIME  TTY     TIME      CMD
root     1     0  0  Apr27  ?       00:00:08  /sbin/init
mysql 1234   918  1  May01  ?       00:03:42  /usr/sbin/mysqld
```

`aux` と並べた差分:

| 列 | aux と異なる点 |
|---|---|
| `UID` | aux の `USER` 相当(数値表示の場合あり) |
| `PPID` | **親プロセス ID**(aux にはない) |
| `C` | プロセッサ使用率(短期、粒度が粗い) |
| `STIME` | aux の `START` と同等 |
| `TIME` | aux と同様だが `HH:MM:SS` 形式 |
| `CMD` | aux の `COMMAND` と同等 |

`aux` と `-ef` の使い分け:

- `aux` → **リソース監視向き**(`%CPU` `%MEM` `VSZ` `RSS` `STAT` が見える)
- `-ef` → **プロセス系統樹向き**(`PPID` が見える)

`ps -ef` には `%CPU`/`%MEM` が出ない代わりに `PPID` が出る。「親プロセスをたどりたい」なら `-ef`、「リソース食い犯を探したい」なら `aux`。

## STAT 列の文字

ps aux の `STAT` 列は 1〜2 文字で状態を表す。

| 文字 | 意味 |
|---|---|
| `R` | Running(実行中 or 実行可能) |
| `S` | Sleeping(割り込み可能な待機) |
| `D` | Uninterruptible sleep(I/O 待ち、kill 不可) |
| `Z` | Zombie(終了したが親が回収していない) |
| `T` | Stopped(SIGSTOP 等で停止) |
| `s` | session leader |
| `l` | multi-threaded |
| `+` | foreground process group |
| `<` | high-priority(nice < 0) |
| `N` | low-priority(nice > 0) |

`Ss` は「Sleeping + session leader」、`Sl` は「Sleeping + multi-threaded」。文字が並んでいたら 1 文字目が状態、2 文字目以降が修飾子。

## pstree コマンド

### デフォルト出力

```
systemd─┬─NetworkManager───2*[{NetworkManager}]
        ├─auditd───{auditd}
        ├─cron
        ├─sshd───sshd───sshd───bash───pstree
        └─systemd-journal
```

親プロセスから子プロセスへの **ツリー構造** を ASCII 罫線で表示する。`2*[{NetworkManager}]` の `{}` はスレッド、`2*` は同名 2 個。

### `-p` オプション

```
systemd(1)─┬─NetworkManager(782)───2*[{NetworkManager}]
           ├─auditd(745)───{auditd}(750)
           ├─sshd(901)───sshd(1234)───sshd(1235)───bash(1236)───pstree(1500)
```

各プロセス名の直後に `(PID)` を付加する。**素の `pstree` は PID を表示しない**ので、出力に数字が見えたら `-p` 確定。後述の「PID 表示集合」では `pstree -p` だけが集合に入り、`pstree`(素)は外れる。

### 主要オプション

| オプション | 機能 |
|---|---|
| `-p` | PID 表示 |
| `-n` | PID 順にソート(既定は名前順) |
| `-a` | コマンドライン引数も表示 |
| `-u` | ユーザ名(uid 変化点で) |
| `<PID>` | 指定 PID をルートにツリー表示 |

## lsof コマンド

### 基本: open files 一覧

```
COMMAND  PID  USER   FD   TYPE  DEVICE   SIZE/OFF    NODE  NAME
sshd    1234  root  cwd   DIR     8,1     4096       2     /
sshd    1234  root  txt   REG     8,1   899568   12345     /usr/sbin/sshd
mysqld  5678 mysql    3u  IPv4  98765      0t0     TCP     *:3306 (LISTEN)
```

| 列 | 意味 |
|---|---|
| `COMMAND` | プロセス名 |
| `PID` | プロセス ID(常に併記される) |
| `USER` | 所有ユーザ |
| `FD` | ファイル記述子(`cwd` / `txt` / `mem` / `数字u` 等) |
| `TYPE` | ファイルタイプ(DIR / REG / IPv4 / IPv6 / sock / unix) |
| `NAME` | パス or ネットワークアドレス |

### lsof が「PID 表示集合」に入る理由

`lsof` の主目的は **「開いているファイル」の一覧** で、プロセス起点ではない。それでも出力に PID 列が常にあるのは、**「どのプロセスがそのファイルを開いているか」を併記する仕様**だから。集合問題で `lsof` を「ファイル系コマンドだから PID は出ないだろう」と外すのは典型的な誤答パターン。

実用上もこの併記が便利で、`lsof -i :3306`(3306 番ポートを誰が開いているか)→ PID から `kill` までが 1 連で済む。

## 「プロセス毎」リソース表示の集合

「プロセス毎の CPU 使用率を出せるコマンドを全部選べ」型の問題は集合で覚えると外しにくい。

| コマンド | プロセス毎 CPU | プロセス毎メモリ | システム全体 |
|---|:---:|:---:|:---:|
| **ps** | ◯ `%CPU` 列 | ◯ `%MEM` / `RSS` 列 | × |
| **top** | ◯ `%CPU` 列(プロセステーブル) | ◯ `%MEM` 列(プロセステーブル) | ◯ `%Cpu(s)` / `MiB Mem` 行 |
| vmstat | × | × | ◯ `cpu` 欄・`memory` 欄 |
| iostat | × | × | ◯ `avg-cpu` 行 |
| sar -u | × | × | ◯ |
| uptime / w | × | × | △(load average のみ) |

「**プロセス毎**」を出せるのは `ps` と `top` の **2 つだけ**。`vmstat` / `iostat` / `sar -u` はシステム全体集計に専念する設計のため、プロセス単位には踏み込まない。

逆に「**システム全体**」を聞かれたら `vmstat` / `iostat` / `top` / `sar -u` が正解集合に入り、`ps` は外れる(`ps aux` 行は 1 プロセス毎の値で、合計を出すわけではない)。

`top` だけが両方の集合に入る。`top` のヘッダ 5 行(`%Cpu(s)` 行・`MiB Mem` 行)が「システム全体」、その下のプロセステーブルが「プロセス毎」を担当している。詳しくは [topコマンドの読み方](/posts/2026-05-06-top-header-reading/) を参照。

## PID 表示の集合

「PID を表示するコマンドを全部選べ」型の問題:

```
PID を表示するコマンド = ps / top / pstree -p / lsof
```

| コマンド | PID 表示の根拠 |
|---|---|
| **ps** | `PID` 列が必須出力 |
| **top** | プロセステーブル先頭列が `PID` |
| **pstree -p** | `-p` オプションで `(PID)` を付加(**素の `pstree` は除外**) |
| **lsof** | open files に PID を併記する仕様 |

集合に **入らない** コマンド:

- `uptime` / `w`: PID 出力なし(`w` は `USER`/`TTY`/`FROM`/`LOGIN@`/`IDLE`/`JCPU`/`PCPU`/`WHAT`)
- `vmstat` / `iostat` / `sar`: システム全体集計のため PID 概念がない
- `pstree`(素): プロセス名のみ、`-p` 必須

## 出力 → コマンド識別の判別キー

スクリーンショットからコマンド名を当てる問題用のチートシート。

### ps の判別

| 列名の組合せ | コマンド |
|---|---|
| `USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND`(11 列) | **ps aux** |
| `UID PID PPID C STIME TTY TIME CMD`(8 列) | **ps -ef** |
| `PID TTY TIME CMD`(4 列のみ) | **ps**(引数なし) |
| `PID TTY STAT TIME COMMAND`(5 列) | **ps a** など |

`top` のプロセステーブル(`PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND`)と紛らわしいが、**`PR` `NI` `VIRT` `RES` `SHR` `TIME+` は `ps` にない**。さらに `top` には冒頭 5 行ヘッダ(`top -` で始まる行 / `Tasks` / `%Cpu(s)` / `MiB Mem` / `MiB Swap`)があるので、画像にこのヘッダが写っていれば `top`、写っていなければ `ps`。

### pstree の判別

| 特徴 | コマンド |
|---|---|
| ASCII 罫線(`─┬─` `├─` `└─`)でツリー構造 | pstree 系 |
| プロセス名の直後に `(数字)` | **pstree -p** |
| プロセス名のみ、PID なし | **pstree**(素) |
| ツリー罫線 + コマンドライン引数 | **pstree -a** |

### lsof の判別

`COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME` の 9 列構成、`FD` 列に `cwd` / `txt` / `mem` / `数字u` などの記号が並ぶのが特徴。

## 試験本番で踏みやすい罠 4 種

### 罠①: ps の系統混在で `aux` と `-ef` を取り違え

`ps aux`(BSD、ハイフン不要)と `ps -ef`(UNIX、ハイフン必須)を「どちらも全プロセス表示」と一緒くたにしていると、出力列の判別で詰まる。**11 列(aux) vs 8 列(-ef)** で列数も違うし、`%CPU`/`%MEM`(aux) vs `PPID`(-ef)で守備範囲が違う。

### 罠②: 出力に数字があるだけで `pstree` を選ぶ

「ツリー罫線 + プロセス名 + 数字」を見て **素の `pstree`** を選んでしまう罠。素の `pstree` は PID を出さないので、数字が見えた時点で `-p` が確定する。集合問題でも `pstree` ではなく `pstree -p` だけが「PID 表示集合」に入る。

### 罠③: 「プロセス毎」と「システム全体」の取り違え

`vmstat` / `iostat` / `sar -u` は **システム全体集計** に専念する。「プロセス毎の CPU 使用率」を聞かれたら、`vmstat` を選んだ時点で誤答確定。逆に「システム全体の CPU 使用率」を聞かれて `ps` を選ぶのも誤り(`ps aux` は 1 プロセス毎の値の列挙)。`top` だけが両方の集合に入るので、迷ったら `top` を中心に置いて整理する。

### 罠④: lsof を「ファイル系」と決めつけて PID 集合から外す

`lsof = list open files` という名前から「ファイル一覧コマンド」とだけ覚えていると、PID 表示集合の問題で外してしまう。**「どのプロセスがそのファイルを開いているか」を答えるコマンドだから PID 列は必ず併記される** と理解する。実運用でも `lsof -i :ポート` で「このポートを使っているプロセス」を引くのが定番。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- `ps aux` の系統と `ps -ef` の系統は何系か(BSD / UNIX)
- `ps aux` の出力列は何列で、何が並ぶか(11 列、`USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND`)
- `ps -ef` の出力列は何列で、`ps aux` と何が違うか(8 列、`PPID` がある代わりに `%CPU`/`%MEM` がない)
- ps の `STAT` 列で `Z` は何を意味するか(Zombie)
- ps の `STAT` 列で `D` は何を意味するか(Uninterruptible sleep、kill 不可)
- `pstree` 単独と `pstree -p` の表示差は何か(PID の有無)
- 「プロセス毎の CPU 使用率」を出せるコマンドの集合は何か(`ps` と `top` の 2 つ)
- 「システム全体の CPU 使用率」を出せるコマンドの集合は何か(`vmstat` / `iostat` / `top` / `sar -u`)
- 両方の集合に入るコマンドはどれか(`top` のみ)
- 「PID を表示するコマンド」の集合は何か(`ps` / `top` / `pstree -p` / `lsof`)
- `lsof` が PID を併記している仕様上の理由は何か(「どのプロセスが開いているか」を答えるため)

## 変更履歴

- 2026-05-06: 初版公開
