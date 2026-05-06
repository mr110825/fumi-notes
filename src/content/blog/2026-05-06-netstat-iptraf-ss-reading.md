---
title: "netstat / iptraf / ss の読み方:NIC毎カウンタとプロトコル別統計の区別"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "netstat -i の NIC毎カウンタ列(RX-OK/RX-ERR/RX-DRP/RX-OVR/TX-*)と netstat -s のプロトコル別統計を区別し、対話型 ncurses の iptraf と netstat 後継の ss まで含めて整理する。"
---

LPIC201 の主題200(キャパシティプランニング)でネットワーク監視周りの問題を解いていて、`netstat -i` と `netstat -s` を「どっちも統計でしょ」と一緒くたにしていたら、画像問題で外した。`-i` は **NIC 毎(インターフェース)のテーブル**、`-s` は **プロトコル毎(IP/ICMP/TCP/UDP)のセクション**で、出力形式そのものが違う。さらに `iptraf`(対話型 ncurses)と `ss`(netstat 後継)を含めると、**役割が独立した 4 つのコマンド**として整理しないと選択肢を絞り切れない。本記事では NW 監視 4 コマンドの読み解きと、`-i` と `-s` の対比を 1 本にまとめておく。

[vmstatの読み方](/posts/2026-05-05-vmstat-bottleneck-reading/) ・ [sarコマンドの読み方](/posts/2026-05-06-sar-command-reading/) と対になる記事。

## 4 コマンドの位置付け

| コマンド | 主目的 | 形式 |
|---|---|---|
| **netstat** | NIC 毎統計 / プロトコル毎統計 / ソケット一覧 / ルーティング | 静的(一発出力) |
| **iptraf** | NIC + 接続毎のリアルタイム監視 | **対話型 ncurses UI** |
| **ss** | netstat の後継、ソケット統計を高速取得 | 静的(コマンドラインツール) |
| **tcpdump** | パケットキャプチャ | 静的(stdout) |

LPIC201 の出題で主役になるのは netstat と iptraf。`ss` は netstat 後継として位置付けを押さえる程度。`iftop`(top の NW 版、接続毎帯域)も補助知識として知っておく。

## netstat -i の NIC 毎カウンタ

```
Kernel Interface table
Iface   MTU  RX-OK RX-ERR RX-DRP RX-OVR  TX-OK TX-ERR TX-DRP TX-OVR  Flg
eth0   1500  12345      0      0      0   6789      0      0      0   BMRU
lo    65536    100      0      0      0    100      0      0      0   LRU
```

冒頭の `Kernel Interface table` ヘッダ + `Iface` 列から始まる **NIC 毎の表形式** が `-i` の識別キー。

### 列の意味

| 列 | 意味 | 区分 |
|---|---|---|
| `Iface` | インターフェース名(eth0 / lo / ens33 等) | – |
| `MTU` | Maximum Transmission Unit | – |
| `RX-OK` | **正常受信**パケット数 | 正常 |
| `RX-ERR` | **受信エラー**パケット数 | エラー |
| `RX-DRP` | 受信ドロップ(破棄) | エラー |
| `RX-OVR` | 受信オーバーラン(バッファ溢れ) | エラー |
| `TX-OK` | **正常送信**パケット数 | 正常 |
| `TX-ERR` | 送信エラー | エラー |
| `TX-DRP` | 送信ドロップ | エラー |
| `TX-OVR` | 送信オーバーラン | エラー |
| `Flg` | フラグ(B=Broadcast, M=Multicast, R=Running, U=Up, L=Loopback, P=Point-to-point 等) | – |

「**正常**にやり取りされたパケット数」を聞かれたら **RX-OK + TX-OK** の 2 列。「**エラー**パケット数」を聞かれたら **RX-ERR + TX-ERR** の 2 列(DRP / OVR は別カウンタとして扱う)。

### DRP と OVR の意味

両者ともエラーカテゴリだが、ERR とは独立したカウンタ。

- `DRP` = Drop(バッファに入れられず破棄、混雑時)
- `OVR` = Overrun(バッファ溢れ)

「正常 / エラー」の 2 値で問われたら、**ERR と DRP と OVR は全てエラー側**。「正常」は OK のみ。

## netstat -s のプロトコル別統計

```
Ip:
    Forwarding: 1
    12345 total packets received
    0 forwarded
    0 incoming packets discarded
    12000 incoming packets delivered
    8000 requests sent out
Icmp:
    50 ICMP messages received
    0 input ICMP message failed
Tcp:
    234 active connections openings
    100 passive connection openings
    1500 segments retransmitted
Udp:
    345 packets received
    1 packets to unknown port received
```

`Ip:` `Icmp:` `Tcp:` `Udp:` のセクションヘッダ + 各カウンタを文章で列挙、というのが `-s` の識別キー。**列ヘッダではなくセクションヘッダ**である点が `-i` との差。

## -i と -s の対比

| オプション | 単位 | 形式 |
|---|---|---|
| `netstat -i` | **NIC 毎** | テーブル形式(列ヘッダ + 行) |
| `netstat -s` | **プロトコル毎** | セクション形式(プロトコル名 + カウンタ列挙) |

「i = interface(NIC)」「s = statistics(プロトコル)」と覚える。

## netstat の主要オプション

| オプション | 機能 |
|---|---|
| `-i` | NIC 毎統計(インターフェーステーブル) |
| `-s` | プロトコル別統計 |
| `-r` | ルーティングテーブル(`route` コマンドと同等) |
| `-a` | 全ソケット表示 |
| `-t` | TCP のみ |
| `-u` | UDP のみ |
| `-l` | LISTEN 状態のみ |
| `-n` | ホスト名・サービス名を解決せず数値表示 |
| `-p` | プロセス名・PID を併記 |

よく使う組合せ: `netstat -tnp`(TCP + 数値 + プロセス併記)、`netstat -rn`(ルーティング + 数値)、`netstat -anp`(全ソケット + 数値 + プロセス)。

## iptraf

`iptraf` は **対話型 ncurses UI** のネットワーク監視ツール。コマンド一発で結果が出る netstat とは違い、メニューから機能を選んでリアルタイム表示する。

```
+--------------------------------------------------------+
|  iptraf                                                |
+--------------------------------------------------------+
|       IP traffic monitor                               |
|       General interface statistics                     |
|       Detailed interface statistics                    |
|       Statistical breakdowns                           |
|       LAN station monitor                              |
|       Filters                                          |
|       Configure                                        |
|       Exit                                             |
+--------------------------------------------------------+
```

ASCII ボックスで囲まれたメニューリストが見えたら iptraf 確定。`IP traffic monitor` `General interface statistics` `Detailed interface statistics` などのメニュー項目が固有の判別キーになる。

「TCP/UDP 接続 + NIC 統計を **対話型** で表示するツール」と問われたら iptraf。netstat は静的、iptraf は対話型 = 役割が別カテゴリ。

## ss

`ss`(socket statistics)は netstat の後継で、`iproute2` パッケージに同梱される。カーネルから直接ソケット情報を読み取るので netstat より高速に動く。

| オプション | 機能 |
|---|---|
| `-t` | TCP |
| `-u` | UDP |
| `-l` | LISTEN |
| `-n` | 数値表示 |
| `-p` | プロセス併記 |
| `-a` | 全ソケット |

`netstat -tnlp` と `ss -tnlp` はほぼ等価の出力を出す。実機運用では `ss` 推奨だが、**LPIC201 試験では netstat が主役**。新旧併存知識として持つ。

## 出力 → コマンド識別の判別キー

| 特徴 | コマンド |
|---|---|
| `Kernel Interface table` ヘッダ + `Iface MTU RX-OK RX-ERR …` 列 | **netstat -i** |
| `Ip:` `Icmp:` `Tcp:` `Udp:` のセクション + 各カウンタ文章 | **netstat -s** |
| `Proto Recv-Q Send-Q Local Address Foreign Address State` 列 | netstat(`-a` `-t` `-u` 系) |
| `Destination Gateway Genmask Flags MSS Window irtt Iface` 列 | netstat -r |
| ASCII ボックス + メニュー(`IP traffic monitor` 等) | **iptraf** |
| `State Recv-Q Send-Q Local Address:Port Peer Address:Port` 列 | **ss** |

## 試験本番で踏みやすい罠 5 種

### 罠①: -i と -s の混同

`-i` は **NIC 毎の表**、`-s` は **プロトコル毎のセクション**。表形式かセクション形式かで一目判別できる。「i = interface」「s = statistics」と覚えれば取り違えにくい。

### 罠②: iptraf と ss の混同

netstat 後継は **`ss`**(iproute2)であって `iptraf` ではない。`iptraf` は対話型監視で独立カテゴリ。「netstat に代わる新しいコマンド」と問われたら `ss`、「対話型の NW 監視ツール」と問われたら `iptraf`。

### 罠③: DRP / OVR をエラーから外す

「`RX-ERR` だけがエラー」と覚えていると、`DRP`(ドロップ)と `OVR`(オーバーラン)を見落とす。**ERR と DRP と OVR は全てエラーカテゴリ**(ただしカウンタとしては独立)。「正常」と問われたら OK 列のみ。

### 罠④: Flg の文字を機種依存と誤認

`B=Broadcast` `M=Multicast` `R=Running` `U=Up` `L=Loopback` `P=Point-to-point` は標準フラグ。試験で稀にこの読み取りが問われるので、文字の意味は押さえておく。

### 罠⑤: ss / iptraf を「いずれも netstat の後継」と束ねる

`ss` は netstat 後継だが、`iptraf` は **対話型監視**で別カテゴリ。一緒にすると役割識別問題で外す。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- `netstat -i` と `netstat -s` の出力形式の違いは何か(表形式 vs セクション形式)
- 「正常にやり取りされたパケット数」を出す `netstat -i` の列は何か(RX-OK + TX-OK)
- 「エラーパケット数」を出す `netstat -i` の列は何か(RX-ERR + TX-ERR)
- DRP と OVR は何の略か(Drop / Overrun)
- 対話型 ncurses UI の NW 監視ツールは何か(iptraf)
- netstat の後継コマンドは何か(ss、iproute2 パッケージ)
- `netstat -tnlp` を ss で書き換えると何になるか(`ss -tnlp`)
- `Flg` 列の `U` と `R` は何を表すか(Up / Running)
- iptraf と ss の役割の違いは何か(対話型監視 vs netstat 後継のソケット統計)

## 変更履歴

- 2026-05-06: 初版公開
