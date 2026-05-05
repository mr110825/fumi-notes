---
title: "JavaのList — ArrayListの使い方と代表メソッド"
pubDate: 2026-05-05
type: "tech"
draft: false
tags: [java]
---

## 結論

| 概念 | 役割 |
|---|---|
| List | 順序付けられた要素の集合。**インデックス**で値を管理する |
| 重複 | **許可**（同じ値を複数持てる） |
| 主な実装クラス | `ArrayList`（配列ベース、ランダムアクセスが速い） |

複数の値をまとめて扱う仕組みを **コレクションフレームワーク** と呼び、Listはその代表格。配列との違いは「サイズが可変」「便利メソッドが揃っている」の2点。

## サンプルコード

`List` インターフェースと `ArrayList` 実装クラスをimportして使う。

```java
import java.util.ArrayList; // Listの実装クラスであるArrayListをインポート
import java.util.List;      // Listインターフェースをインポート

public class Main {

    public static void main(String[] args) {

        // ArrayListのインスタンスを生成し、List型の変数sampleListに代入
        List<Integer> sampleList = new ArrayList<>();

        // sampleListに0〜9まで挿入
        for (int i = 0; i < 10; i++) {
            sampleList.add(i);
        }

        // sampleListの要素を全て表示
        for (int i = 0; i < sampleList.size(); i++) {
            System.out.print(sampleList.get(i) + " ");
        }

        sampleList.add(10); // リストの末尾に10を追加

        System.out.println();
        for (int i = 0; i < sampleList.size(); i++) {
            System.out.print(sampleList.get(i) + " ");
        }

        sampleList.add(1, 11); // 要素番号1に11を追加
        sampleList.remove(0);  // 要素番号0を削除（最初の0が削除される）

        System.out.println();
        for (int i = 0; i < sampleList.size(); i++) {
            System.out.print(sampleList.get(i) + " ");
        }

        System.out.println();
        System.out.println(sampleList.get(0)); // 要素番号0の値を表示（11が表示される）
    }
}
```

実行結果：

```text
0 1 2 3 4 5 6 7 8 9
0 1 2 3 4 5 6 7 8 9 10
11 1 2 3 4 5 6 7 8 9 10
11
```

ポイントは2つ。

- **`List<Integer> = new ArrayList<>()`** という書き方： 変数の型はインターフェース（`List`）、実体は実装クラス（`ArrayList`）にしておく。これで後から実装を差し替えやすくなる
- **インデックスは0始まり**： `add(1, 11)` は「2番目の位置に11を割り込ませる」という意味になる

## 代表メソッド

| メソッド | 概要 | 戻り値 |
|---|---|---|
| `add(E element)` | リストの末尾に要素を追加 | `boolean` |
| `add(int index, E element)` | 指定位置に要素を挿入（後続要素は1つ後ろにシフト） | `void` |
| `get(int index)` | 指定位置の要素を返す | `E`（要素の型） |
| `remove(int index)` | 指定位置の要素を削除（後続要素は1つ前にシフト） | `E`（削除した要素） |
| `size()` | リスト内の要素数を返す | `int` |

`add(int, E)` と `remove(int)` は、後続要素のシフトが発生する点に注意。先頭近くで頻繁に挿入・削除する用途では `LinkedList` のほうが速いが、ランダムアクセス（`get(i)`）は `ArrayList` のほうが圧倒的に速い。迷ったら `ArrayList` でよい。

## 型パラメータの制約 — 基本型は使えない

`List<型名>` の **型パラメータには参照型しか指定できない**。

```java
List<int> sampleList = new ArrayList<>();      // コンパイルエラー
List<Integer> sampleList = new ArrayList<>();  // OK
```

基本型（プリミティブ型）の値を格納したい場合は、対応する **ラッパークラス** を指定する。

| 基本型 | ラッパークラス |
|---|---|
| `int` | `Integer` |
| `double` | `Double` |
| `boolean` | `Boolean` |
| `char` | `Character` |
| `long` | `Long` |

ラッパークラスを使う以上、`==` 比較ではなく `.equals()` を使うべき場面が出てくる。詳細は [Javaの == と equals() の使い分け](/posts/2026-05-02-java-equals-vs-reference/) を参照。

## まとめ

- Listは「順序付き・重複許可・インデックスアクセス」のコレクション
- 実装クラスは基本 `ArrayList` でよい
- 変数型は `List<E>` で宣言、実体は `new ArrayList<>()` で生成するのが定石
- 型パラメータには参照型のみ指定可。基本型はラッパークラスで代替する

関連記事：

- [JavaのMap — HashMapの使い方と代表メソッド](/posts/2026-05-05-java-collection-map/)
- [JavaのSet — HashSetの使い方と重複排除](/posts/2026-05-05-java-collection-set/)

## 変更履歴

- 2026-05-05: 初版公開
