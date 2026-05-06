---
title: "collectd / MRTG / Nagios の読み方:設定ファイル名と LoadPlugin、監視ツールの役割整理"
pubDate: 2026-05-06
type: "tech"
draft: false
tags: [linux, lpic201]
description: "collectd の設定ファイル(/etc/collectd.conf)と LoadPlugin 命令、MRTG / Nagios / cacti / Zabbix / munin の役割の違いを 1 表で整理する。"
---

LPIC201 の主題200(キャパシティプランニング)で監視ツールの章にきて、`collectd` / `MRTG` / `Nagios` / `cacti` を「どれもサーバ監視」と一括りにしていた。実際は **役割が独立した別カテゴリ**で、`collectd` はプラグイン式デーモン、`MRTG` は SNMP トラフィック専用、`Nagios` は死活監視 + アラート、`cacti` は MRTG の GUI 後継、と棲み分けている。試験では `collectd` の **設定ファイル名(`/etc/collectd.conf`)と `LoadPlugin` 命令** が中核論点。本記事ではこの **監視ツール章** を 1 本にまとめておく。

[sysstat パッケージと sa1 / sa2 の読み方](/posts/2026-05-06-sysstat-sa1-sa2-reading/) と対になる記事(同じ「統計収集システム」だが、sysstat は cron + バイナリログ、collectd はデーモン + プラグインで設計が違う)。

## collectd

### 概要

- **システム監視デーモン**(常駐型)
- **プラグイン式アーキテクチャ**(read プラグイン = データ収集、write プラグイン = データ出力)
- データ出力先: RRD ファイル / CSV / Graphite / InfluxDB 等

`sysstat` が cron + バイナリログでスナップショットを取る設計なのに対し、collectd は **常駐デーモンが常時収集**する設計。プラグインの追加で監視対象も出力先も拡張できる。

### 設定ファイル: /etc/collectd.conf

```
# /etc/collectd.conf
Hostname "myhost"
FQDNLookup true
Interval 10

# プラグイン読込
LoadPlugin cpu
LoadPlugin memory
LoadPlugin disk
LoadPlugin interface
LoadPlugin network
LoadPlugin swap
LoadPlugin rrdtool

<Plugin disk>
    Disk "/^[hs]d[a-z]/"
    IgnoreSelected false
</Plugin>

<Plugin rrdtool>
    DataDir "/var/lib/collectd/rrd"
</Plugin>
```

冒頭にホスト設定 + 収集間隔(`Interval`)、次に `LoadPlugin <name>` の列挙、必要に応じて `<Plugin xxx> ... </Plugin>` ブロックで詳細設定、という構造。

ディストリによっては `/etc/collectd/collectd.conf` パスのこともあるが、**Ping-t 標準解答は `/etc/collectd.conf`**。

### LoadPlugin

```
LoadPlugin <plugin_name>
```

- プラグインを読込・有効化する命令
- 例: `LoadPlugin cpu` で CPU プラグインが読み込まれ、CPU 統計の収集が有効化される
- 各プラグインの詳細設定は `<Plugin xxx> ... </Plugin>` ブロックで記述(既定値で動くなら省略可)

### 主要プラグイン

| プラグイン | 用途 |
|---|---|
| `cpu` | CPU 統計収集 |
| `memory` | メモリ統計 |
| `disk` | ディスクI/O |
| `interface` | NIC 統計 |
| `network` | collectd 間通信(マルチノード) |
| `swap` | スワップ統計 |
| `df` | ファイルシステム使用量 |
| `load` | load average |
| `rrdtool` | RRD ファイル出力(write プラグイン) |
| `csv` | CSV 出力 |
| `unixsock` | Unix ソケット経由のクエリ |

read 系(cpu / memory / disk / interface / load 等)と write 系(rrdtool / csv 等)の **両方がプラグイン**になっている点が collectd の設計思想。

## MRTG / cacti / Nagios / その他

### MRTG(Multi Router Traffic Grapher)

- **SNMP** ベースのトラフィックグラフ生成
- 主にネットワーク機器(ルータ・スイッチ)の bps 監視
- HTML + PNG 出力(5 分間隔)
- 設定: `/etc/mrtg/mrtg.cfg`
- 後継: cacti(GUI 強化版)

### cacti

- MRTG の Web GUI 強化版
- LAMP(PHP)+ RRDtool ベース
- SNMP / collectd 等から取得

### Nagios

- **ホスト/サービス監視**(死活 + 性能)
- アラート通知(メール / SMS)
- プラグインベース(`check_*` スクリプト)
- 設定: `/etc/nagios/`

### 監視ツール早見表

| ツール | 用途 | データ源 | 出力 |
|---|---|---|---|
| **collectd** | 統合監視(CPU/メモリ/IO/NW) | 内蔵プラグイン | RRD / Graphite |
| **MRTG** | NW トラフィック専用 | SNMP | HTML + PNG |
| **cacti** | NW + サーバ統合(GUI) | SNMP | RRD + Web GUI |
| **Nagios** | 死活 + アラート | check_* プラグイン | Web GUI + 通知 |
| **Zabbix** | 統合監視 + アラート | エージェント / SNMP | DB + Web GUI |
| **munin** | サーバ監視(GUI) | プラグイン | RRD + HTML |

## 役割識別の判別キー

問題文の言葉から正解ツールを引くチートシート。

| 問の言葉 | 正解ツール |
|---|---|
| **SNMP ベースのトラフィックグラフ** | **MRTG** |
| **死活 + アラート通知** | **Nagios** |
| **統合監視(プラグイン式デーモン)** | **collectd** |
| **MRTG の GUI 後継** | **cacti** |
| **エージェント型統合監視 + Web GUI** | Zabbix |
| **サーバ監視 GUI(プラグイン)** | munin |

「常駐デーモン + プラグインで CPU / メモリ / IO / NW を統合的に監視する」 = collectd。「SNMP でトラフィックグラフ」 = MRTG。「死活 + アラート」 = Nagios。**3 つの主役は役割が完全に独立**している。

## 試験本番で踏みやすい罠 4 種

### 罠①: collectd と MRTG / Nagios の役割混同

- collectd = **デーモン型データ収集**(プラグイン)
- MRTG = **SNMP トラフィックグラフ専用**
- Nagios = **死活監視 + アラート**

「統合監視 + プラグイン」と問われたら collectd。「アラート通知」と問われたら Nagios。「SNMP でグラフ」と問われたら MRTG。

### 罠②: LoadPlugin の役割を忘れる

`LoadPlugin cpu` だけで CPU 収集が有効化される。詳細設定は `<Plugin cpu>` ブロックで記述するが、**既定値で動く場合は `<Plugin>` ブロック自体が不要**。「プラグインの詳細設定をする命令」と「プラグインを有効化する命令」を取り違えると失点する。

### 罠③: 出力先もプラグインだと知らない

`LoadPlugin rrdtool` で RRD 出力、`LoadPlugin csv` で CSV 出力。collectd は **read/write 両方プラグイン式**。「データ出力プラグイン」と聞いて該当を選べないと、設計思想を理解していないことになる。

### 罠④: 設定ファイルパスの揺れ

`/etc/collectd.conf`(一般)vs `/etc/collectd/collectd.conf`(一部ディストリ)。試験では **前者が標準解答**。実機調査時は両パスを確認する習慣をつける。

## 自己チェック

書きながら自問できるようにしておきたい項目:

- collectd の設定ファイル名は何か(/etc/collectd.conf)
- collectd でプラグインを読込・有効化する命令は何か(LoadPlugin <plugin_name>)
- collectd のアーキテクチャの特徴は何か(プラグイン式、read/write 両方プラグイン)
- MRTG はどんなデータ源を使うか(SNMP)
- Nagios の主用途は何か(死活監視 + アラート通知)
- cacti は何の後継か(MRTG の GUI 後継)
- 「統合監視 + プラグイン式デーモン」と問われたら何を選ぶか(collectd)
- collectd の出力プラグインを 2 つ挙げられるか(rrdtool / csv)
- collectd と sysstat の違いは何か(常駐デーモン + プラグイン vs cron + バイナリログ)

## 変更履歴

- 2026-05-06: 初版公開
