---
title: "JavaのMap — HashMapの使い方と代表メソッド"
pubDate: 2026-05-05
updatedDate: 2026-05-05
type: "tech"
draft: false
tags: [java]
---

## 結論

| 概念 | 役割 |
|---|---|
| Map | **キー（key）と値（value）の組** を格納するコレクション |
| キーの重複 | **不可**（同じキーに `put` すると値が上書きされる） |
| アクセス方法 | **キー指定** で値を取得（Listのインデックスアクセスとの違い） |
| 主な実装クラス | `HashMap`（ハッシュテーブルベース、検索が速い） |

「IDから名前を引く」「英単語から意味を引く」のような **対応表** を扱いたいときに使う。

## サンプルコード

`Map` インターフェースと `HashMap` 実装クラスをimportして使う。

```java
import java.util.HashMap; // Mapの実装クラスであるHashMapをインポート
import java.util.Map;     // Mapインターフェースをインポート

public class Main {

    public static void main(String[] args) {
        // HashMapのインスタンスを生成し、Map型の変数colorMapに代入
        // （キーの型:String、値の型:String）
        Map<String, String> colorMap = new HashMap<>();

        // マップにデータを登録する
        colorMap.put("red", "赤");
        colorMap.put("blue", "青");
        colorMap.put("yellow", "黄");
        colorMap.put("green", "緑");

        // キー指定して値を取得
        System.out.println(colorMap.get("red"));
        System.out.println(colorMap.get("blue"));

        // キー指定して上書きする
        colorMap.put("red", "赤色");
        System.out.println(colorMap.get("red"));

        // "yellow" キーのペアを削除
        colorMap.remove("yellow");
        // マップの要素数を表示（3が表示される）
        System.out.println(colorMap.size());
    }
}
```

実行結果：

```text
赤
青
赤色
3
```

ポイント：

- **`put` は登録と上書きを兼ねる**： 同じキーに2回 `put` すると、後から入れた値で上書きされる
- **`get` で存在しないキーを引くと `null`**： `NullPointerException` を避けたいなら `getOrDefault(key, defaultValue)` も使える
- **キーの重複は許されない**が、**値の重複は許される**（複数のキーが同じ値を指してOK）

## 代表メソッド

| メソッド | 概要 | 戻り値 |
|---|---|---|
| `put(K key, V value)` | キーと値の組をマップに追加。同じキーが既に存在する場合は値を上書き | `V`（上書き前の値、存在しなかった場合は `null`） |
| `get(Object key)` | 指定キーに対応する値を返す。キーが存在しない場合は `null` | `V`（値の型） |
| `remove(Object key)` | 指定キーのキー・値ペアを削除 | `V`（削除した値） |
| `size()` | マップ内のキー・値ペアの数を返す | `int` |

`put` の戻り値が「上書き前の値」になっている点は意外と便利で、「初回登録か上書きか」を見分けるのに使える（戻り値が `null` なら新規登録）。

## 全要素を反復する — `keySet()` で取り出す

特定のキーで `get()` するだけでなく、Mapに入っている **全てのキー・値ペアを順に処理したい** 場面がある。Mapのメリットを活かすなら、`keySet()` で「Map自身に持っているキー一覧を聞く」のが定石。

```java
import java.util.HashMap;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        Map<Integer, String> greetByTime = new HashMap<>();
        greetByTime.put(9, "おはようございます");
        greetByTime.put(12, "こんにちは");
        greetByTime.put(18, "こんばんは");
        greetByTime.put(22, "おやすみなさい");

        for (int time : greetByTime.keySet()) {
            System.out.println(time + "時：" + greetByTime.get(time));
        }
    }
}
```

`keySet()` はMapに登録されている **キーの集合（`Set<K>`）** を返す。拡張for文で回せば、登録キーの数だけ処理できる。キーが `9, 12, 18, 22` の4つなら4回ループ、`100, 200, 300` の3つなら3回ループする。

「キーが何個あるか・何の値かを事前に知らなくても処理できる」のがMapらしい書き方。

## HashMap は挿入順を保証しない

上記コードの実行結果は、`put` した順とは違う **意外な順序** になる。

```text
18時：こんばんは
22時：おやすみなさい
9時：おはようございます
12時：こんにちは
```

`put` は `9 → 12 → 18 → 22` の順だったが、出力は `18 → 22 → 9 → 12`。これは `HashMap` が **ハッシュ計算でバケット位置を決める** ため。

`Integer.hashCode()` は値そのままを返し、デフォルト容量16の `HashMap` ではバケット位置が `key & 15`（下位4bit）で決まる。

| キー | バケット位置（`key & 15`）|
|---|---|
| 9 | 9 |
| 12 | 12 |
| 18 | 2 |
| 22 | 6 |

→ バケット番号順（2 → 6 → 9 → 12）に取り出されるため、**`18, 22, 9, 12` の順** で出力される。JDKバージョンや初期容量で具体的な順は変わるが、いずれにせよ「挿入順を保証しない」のは確定仕様。

順序を保証したい場合は、Map実装クラスの差し替えで対応できる。

| 実装クラス | 順序の保証 |
|---|---|
| `HashMap` | なし |
| `LinkedHashMap` | **挿入順** |
| `TreeMap` | **キー昇順** |

差し替えは1行で済む（`new HashMap<>()` を `new LinkedHashMap<>()` に変えるだけ）。実装クラスの選び方は [JavaのMap実装クラスの選び方 — HashMap/LinkedHashMap/TreeMap](/posts/2026-05-05-java-map-implementation-classes/) で深掘りしている。

## よくある罠 — Listの感覚で `get(i)` を呼ぶ

Listを覚えた直後にMapを触ると、つい以下のように書いてしまいがち。

```java
// 動かない誤りパターン
Map<Integer, String> greetByTime = new HashMap<>();
greetByTime.put(9, "おはようございます");
greetByTime.put(12, "こんにちは");
greetByTime.put(18, "こんばんは");
greetByTime.put(22, "おやすみなさい");

for (int i = 0; i < greetByTime.size(); i++) {
    System.out.println(i + "時：" + greetByTime.get(i));
}
```

このコードの出力は **全て `null`**。

```text
0時：null
1時：null
2時：null
3時：null
```

理由：

- `greetByTime.get(0)` は **「キー `0` に対応する値」を探しに行く**
- 登録されているキーは `9, 12, 18, 22` で、`0, 1, 2, 3` は存在しない
- 存在しないキーへの `get` は `null` を返す（仕様）

**Listはインデックス（0から自動採番される連番）でアクセス、Mapはキー（自分で決めた値）でアクセス** という根本的な違いを混同するとハマる。

| | List | Map |
|---|---|---|
| アクセス方法 | インデックス（自動採番） | キー（任意の値） |
| `get(0)` の意味 | 先頭の要素 | キー `0` に対応する値 |
| `size()` の意味 | 要素数 | キー・値ペアの数 |

Mapは **キー集合を `keySet()` で取得して回す** か、**事前に分かっているキーで直接 `get(key)` する** のが正しい使い方。

## 型パラメータの制約 — 2つの型を指定する

`Map<キーの型, 値の型>` という形で **2つの型パラメータ** を指定する。Listと同じく **参照型のみ** で、基本型はラッパークラスを使う。

```java
Map<String, String> m1  = new HashMap<>();   // キー: 文字列、値: 文字列
Map<Integer, String> m2 = new HashMap<>();   // キー: 数値、値: 文字列
Map<String, List<Integer>> m3 = new HashMap<>(); // キー: 文字列、値: 整数のList
```

キーと値で **異なる型** を指定できる。値側にコレクションをネストさせるパターン（`Map<String, List<...>>`）も実務でよく使う。

## HashMap固有の特徴 — `null` キーが使える

`HashMap` は **キーに `null` を指定できる**（`null` キーを1つだけ持てる）。

```java
Map<String, String> m = new HashMap<>();
m.put(null, "no-key");
System.out.println(m.get(null)); // "no-key"
```

ただし `Hashtable` や `ConcurrentHashMap` など他のMap実装ではキーに `null` 不可。実装クラスを切り替えるときに踏みやすい違いなので注意。

## まとめ

- Mapは「キー → 値」の対応を扱うコレクション
- キーは重複不可・値は重複可・アクセスはキー経由
- 全要素を反復するなら `keySet()` で「Map自身にキー一覧を聞く」
- `HashMap` は **挿入順を保証しない**（バケット位置は `key & (容量-1)` で決まる）。順序が要件なら `LinkedHashMap`/`TreeMap` に差し替える
- Listの感覚で `get(0), get(1), ...` と書くと全て `null` になる罠に注意
- 型パラメータは2つ、`Map<K, V>` の形で指定する。基本型はラッパークラスで代替

関連記事：

- [JavaのMap実装クラスの選び方 — HashMap/LinkedHashMap/TreeMap](/posts/2026-05-05-java-map-implementation-classes/)
- [JavaのList — ArrayListの使い方と代表メソッド](/posts/2026-05-05-java-collection-list/)
- [JavaのSet — HashSetの使い方と重複排除](/posts/2026-05-05-java-collection-set/)

## 変更履歴

- 2026-05-05: 初版公開
- 2026-05-05: 「`keySet()` で全要素を反復」「HashMapは挿入順を保証しない」「Listの感覚で `get(i)` を呼ぶ罠」の3節を追加
