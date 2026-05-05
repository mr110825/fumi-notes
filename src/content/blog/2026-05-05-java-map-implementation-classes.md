---
title: "JavaのMap実装クラスの選び方 — HashMap/LinkedHashMap/TreeMap"
pubDate: 2026-05-05
type: "tech"
draft: false
tags: [java]
description: "HashMap・LinkedHashMap・TreeMapの順序保証・計算量・用途を比較し、選択基準を整理する。"
---

## 結論

| 要件 | 選ぶべき実装 |
|---|---|
| 順序が要らない・最速で動かしたい | `HashMap` |
| 入力した順をそのまま保ちたい | `LinkedHashMap` |
| キー自体で自動ソートしたい・範囲検索したい | `TreeMap` |

`Map<K, V>` インターフェースで受けておけば、実装クラスの差し替えは1行で済む。**用途に合わせて中身だけ入れ替える設計**が定石。

詳しい使い方は [JavaのMap — HashMapの使い方と代表メソッド](/posts/2026-05-05-java-collection-map/) を参照。本記事は **3つの実装クラスをどう使い分けるか** に絞る。

## 動機 — イベントログを `HashMap` に入れたら時系列が壊れた

サーバー起動からの経過秒数とログメッセージを `Map<Long, String>` で管理する例を考える。

```java
import java.util.HashMap;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        Map<Long, String> eventLog = new HashMap<>();
        eventLog.put(0L,   "サーバー起動");
        eventLog.put(5L,   "DB接続確立");
        eventLog.put(90L,  "APIリクエスト処理");
        eventLog.put(135L, "エラー: タイムアウト");
        eventLog.put(180L, "リトライ成功");

        for (Long time : eventLog.keySet()) {
            System.out.println(time + "秒: " + eventLog.get(time));
        }
    }
}
```

期待としては `0, 5, 90, 135, 180` の時系列順。しかし実際の出力は:

```text
0秒: サーバー起動
180秒: リトライ成功
5秒: DB接続確立
135秒: エラー: タイムアウト
90秒: APIリクエスト処理
```

ログとしてまったく読めない。これが `HashMap` の「順序保証なし」仕様。

## なぜ崩れるか — `HashMap` のバケット計算

`Long.hashCode(value)` の中身は `(int)(value ^ (value >>> 32))`。今回のように 0〜180 のような小さい long であれば、上位32bitは0なので結果は `(int)value` と等しくなる。

デフォルト容量16の `HashMap` では、バケット位置は `hash & 15`（下位4bit）で決まる。

| キー (`long`) | hashCode | バケット (`hash & 15`) |
|---|---|---|
| 0 | 0 | 0 |
| 5 | 5 | 5 |
| 90 | 90 | 10 |
| 135 | 135 | 7 |
| 180 | 180 | 4 |

バケット番号順 `0 → 4 → 5 → 7 → 10` で取り出されるので、出力順は `0, 180, 5, 135, 90` になる。これが「順序保証なし」の正体。

JDKバージョンや初期容量を変えれば順番は変わるが、いずれにせよ「挿入順とは別の何かに従って並ぶ」のは確定仕様。**順序を期待してはいけない**。

## 解決策その1 — `LinkedHashMap`（挿入順を保つ）

`put` した順をそのまま維持したいなら `LinkedHashMap` に差し替える。コードの変更は **1行のみ**。

```java
import java.util.LinkedHashMap;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        Map<Long, String> eventLog = new LinkedHashMap<>();
        eventLog.put(0L,   "サーバー起動");
        eventLog.put(5L,   "DB接続確立");
        eventLog.put(90L,  "APIリクエスト処理");
        eventLog.put(135L, "エラー: タイムアウト");
        eventLog.put(180L, "リトライ成功");

        for (Long time : eventLog.keySet()) {
            System.out.println(time + "秒: " + eventLog.get(time));
        }
    }
}
```

出力:

```text
0秒: サーバー起動
5秒: DB接続確立
90秒: APIリクエスト処理
135秒: エラー: タイムアウト
180秒: リトライ成功
```

時系列順に並んだ。これは **「`put` した順 = タイムスタンプ昇順」が成立している** から有効。`LinkedHashMap` は内部でハッシュ表に加えて **双方向リンクリスト** を持ち、挿入順を覚えている。

### 落とし穴 — 「届いた順 ≠ 時系列順」のケース

非同期処理や複数のソースからログが集約される場合、`put` 順が時系列とずれることがある。

```java
Map<Long, String> eventLog = new LinkedHashMap<>();
eventLog.put(180L, "リトライ成功");      // 後発のログが先に届いた
eventLog.put(0L,   "サーバー起動");
eventLog.put(90L,  "APIリクエスト処理");
eventLog.put(5L,   "DB接続確立");
eventLog.put(135L, "エラー: タイムアウト");
```

この場合の出力は **`put` した順そのまま**:

```text
180秒: リトライ成功
0秒: サーバー起動
90秒: APIリクエスト処理
5秒: DB接続確立
135秒: エラー: タイムアウト
```

「入力順」と「キーの自然順」は別物。`LinkedHashMap` が保証するのは前者のみで、**キー自体で並べたいなら次の `TreeMap` を使う**。

## 解決策その2 — `TreeMap`（キー昇順で自動ソート）

「タイムスタンプ自体で並べたい」なら `TreeMap`。`put` した順に関係なく、常にキー昇順で並ぶ。

```java
import java.util.Map;
import java.util.TreeMap;

public class Main {
    public static void main(String[] args) {
        Map<Long, String> eventLog = new TreeMap<>();
        eventLog.put(180L, "リトライ成功");      // 後発が先でも
        eventLog.put(0L,   "サーバー起動");
        eventLog.put(90L,  "APIリクエスト処理");
        eventLog.put(5L,   "DB接続確立");
        eventLog.put(135L, "エラー: タイムアウト");

        for (Long time : eventLog.keySet()) {
            System.out.println(time + "秒: " + eventLog.get(time));
        }
    }
}
```

出力はキー昇順:

```text
0秒: サーバー起動
5秒: DB接続確立
90秒: APIリクエスト処理
135秒: エラー: タイムアウト
180秒: リトライ成功
```

`put` 順に依存せず、常に「経過秒数の小さい順」になる。ログが順不同で届くシステムでも安心して使える。

### `TreeMap` だけが持つ追加機能

キーで並んでいる前提があるので、**範囲検索系のメソッド** が使える（`SortedMap` / `NavigableMap` インターフェース由来）。

```java
TreeMap<Long, String> log = new TreeMap<>();
// ... put 略 ...

// 90秒以降のログだけ取り出す
SortedMap<Long, String> after90 = log.tailMap(90L);

// 60〜150秒のログを取り出す
SortedMap<Long, String> middle = log.subMap(60L, 150L);

// 最初・最後のログ
Long firstTime = log.firstKey();
Long lastTime  = log.lastKey();

// 指定キー以下で最も近いエントリ
Map.Entry<Long, String> floor = log.floorEntry(100L);  // 90秒のログが返る
```

これらは `HashMap`/`LinkedHashMap` にはない。**「キーの順序が意味を持つ」用途では `TreeMap` 一択** という場面が多い。

## 3クラスの比較

| 観点 | `HashMap` | `LinkedHashMap` | `TreeMap` |
|---|---|---|---|
| **順序保証** | なし | 挿入順 | キー昇順（`Comparator` 指定可） |
| **内部構造** | ハッシュ表 | ハッシュ表 + 双方向リンクリスト | 赤黒木 |
| **`get`/`put` 計算量** | O(1) 平均 | O(1) 平均 | O(log N) |
| **キー型制約** | なし | なし | `Comparable` 実装 or `Comparator` 指定 |
| **メモリ消費** | 小 | 中（リンクリスト分） | 中 |
| **範囲検索** | 不可 | 不可 | 可（`subMap`/`tailMap`/`firstKey`/`lastKey` 等） |
| **`null` キー** | 1個まで可 | 1個まで可 | **不可**（`NullPointerException`） |

性能だけ見れば `HashMap`/`LinkedHashMap` が勝つが、`TreeMap` は **「キーの順序を活かした便利機能」** が独自に揃っている。

## 選択フロー

```text
順序が必要か?
├─ NO  → HashMap (デフォルト・最速)
└─ YES
    ├─ 入力順を保てばOK
    │   → LinkedHashMap
    └─ キー自体で並べたい
        ├─ 範囲検索 (subMap など) も使う?
        │   → TreeMap (一択)
        └─ ソートだけで十分
            → TreeMap (簡潔・自動)
```

## 実務での使い分けシナリオ

| シナリオ | 適した実装 | 理由 |
|---|---|---|
| ID → ユーザー情報の引き当て | `HashMap` | 順序不要、頻繁な検索、最速 |
| ユーザー設定の保存 | `HashMap` | 順序不要、最小メモリ |
| 操作履歴の Undo/Redo | `LinkedHashMap` | 操作順そのままで保持 |
| LRUキャッシュ | `LinkedHashMap` | アクセス順序モード（`accessOrder=true`）を利用 |
| ソート済みイベントログ | `TreeMap` | 順不同入力でも自動ソート |
| 時間範囲での集計 | `TreeMap` | `subMap` で範囲抽出が自然 |
| スコアランキング（点数→ユーザー名） | `TreeMap` | キー昇順・降順で順位算出が容易 |

## まとめ

- `HashMap` は最速だが順序保証なし。順序が要件なら別を選ぶ
- 「入力順 = 期待出力順」なら `LinkedHashMap`（1行差し替えで対応可）
- 「入力順がバラバラでもキー自体で並べたい」なら `TreeMap`
- `TreeMap` だけが範囲検索系メソッド（`subMap`/`tailMap`/`firstKey`/`lastKey`）を持つ
- 計算量は `HashMap`/`LinkedHashMap` が O(1)、`TreeMap` が O(log N)。性能と機能のトレードオフを判断する
- 変数の型は `Map<K, V>` で宣言しておけば、実装クラスの差し替えは無痛で済む

関連記事:

- [JavaのMap — HashMapの使い方と代表メソッド](/posts/2026-05-05-java-collection-map/)
- [JavaのList — ArrayListの使い方と代表メソッド](/posts/2026-05-05-java-collection-list/)
- [JavaのSet — HashSetの使い方と重複排除](/posts/2026-05-05-java-collection-set/)

## 変更履歴

- 2026-05-05: 初版公開
