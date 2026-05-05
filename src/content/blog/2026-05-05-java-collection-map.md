---
title: "JavaのMap — HashMapの使い方と代表メソッド"
pubDate: 2026-05-05
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
- 実装クラスは基本 `HashMap` でよい（順序が必要なら `LinkedHashMap`、ソート順が必要なら `TreeMap`）
- 型パラメータは2つ、`Map<K, V>` の形で指定する。基本型はラッパークラスで代替

関連記事：

- [JavaのList — ArrayListの使い方と代表メソッド](/posts/2026-05-05-java-collection-list/)
- [JavaのSet — HashSetの使い方と重複排除](/posts/2026-05-05-java-collection-set/)

## 変更履歴

- 2026-05-05: 初版公開
