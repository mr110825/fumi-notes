---
title: "JavaのSet — HashSetの使い方と重複排除"
pubDate: 2026-05-05
type: "tech"
draft: false
tags: [java]
---

## 結論

| 概念 | 役割 |
|---|---|
| Set | **順不同・重複なし** の要素集合 |
| 順序 | 保証されない（`HashSet` の場合） |
| 主な用途 | **重複排除** と **存在確認の高速化** |
| 主な実装クラス | `HashSet`（ハッシュテーブルベース） |

「同じ要素を1つしか持たない」ことを保証したいときに使う。`List.contains()` が O(N) なのに対し、`HashSet.contains()` は O(1)、という性能差も大事なポイント。

## サンプルコード

`Set` インターフェースと `HashSet` 実装クラスをimportして使う。重複ありの `List` を `HashSet` に渡すと、自動で重複が排除される挙動を確認するサンプル。

```java
import java.util.ArrayList;
import java.util.HashSet; // Setの実装クラスであるHashSetをインポート
import java.util.List;
import java.util.Set;     // Setインターフェースをインポート

public class Main {

    public static void main(String[] args) {
        // 重複ありのフルーツリスト
        List<String> fruitList = new ArrayList<>();
        fruitList.add("apple");
        fruitList.add("banana");
        fruitList.add("apple");
        fruitList.add("orange");
        fruitList.add("banana");

        System.out.println("リスト: " + fruitList);

        // ArrayListをHashSetに変換 → 重複が排除される
        Set<String> fruitSet = new HashSet<>(fruitList);
        System.out.println("セット: " + fruitSet);

        // 要素の追加（戻り値は追加成否）
        boolean added1 = fruitSet.add("grape"); // 新規 → true
        boolean added2 = fruitSet.add("apple"); // 既存 → false
        System.out.println("grapeを追加: " + added1);
        System.out.println("appleを追加: " + added2);

        // 要素の存在確認
        System.out.println("appleは含まれるか: " + fruitSet.contains("apple"));
        System.out.println("melonは含まれるか: " + fruitSet.contains("melon"));
    }
}
```

実行結果（セットの順序は保証されないため、出力順は環境により異なる）：

```text
リスト: [apple, banana, apple, orange, banana]
セット: [banana, orange, apple]
grapeを追加: true
appleを追加: false
appleは含まれるか: true
melonは含まれるか: false
```

ポイント：

- **`new HashSet<>(list)`** という書き方で、`List` から重複排除した `Set` を一発生成できる
- **`add()` の戻り値**で「新規追加か既存スキップか」を見分けられる（`true` なら新規）
- **順序は保証されない**ので、出力順はJVMバージョンや内部状態に依存する

## 代表メソッド

| メソッド | 概要 | 戻り値 |
|---|---|---|
| `add(E element)` | 要素がセットに存在しない場合のみ追加 | `boolean`（新規追加なら `true`、既存なら `false`） |
| `contains(Object o)` | 指定要素がセットに含まれるかを判定 | `boolean` |

サイズ取得（`size()`）や削除（`remove(Object)`）はListやMapと同じ感覚で使える。Listとの大きな違いは2つ：

- **`add()` の意味** — Listは「末尾追加（必ず増える）」、Setは「存在しなければ追加（増えないこともある）」
- **`contains()` の計算量** — `ArrayList` は線形探索（O(N)）、`HashSet` はハッシュ参照（O(1)）

「大量の要素から特定の値があるか何度も確認する」ような処理は、`List` で書くとどんどん遅くなる。`Set` に詰め替えるだけで劇的に速くなることがある。

## 型パラメータの制約

Listと同じく **参照型のみ** 指定可能。基本型はラッパークラスを使う。詳細は [JavaのList](/posts/2026-05-05-java-collection-list/) の該当節を参照。

## まとめ

- Setは「順不同・重複なし」のコレクション
- 用途は **重複排除** と **高速な存在確認**
- 実装クラスは基本 `HashSet` でよい（挿入順を保ちたいなら `LinkedHashSet`、ソート順なら `TreeSet`）
- `add()` の戻り値で新規/既存を判定できる
- `contains()` がO(1)で動く点が `List` との決定的な性能差

関連記事：

- [JavaのList — ArrayListの使い方と代表メソッド](/posts/2026-05-05-java-collection-list/)
- [JavaのMap — HashMapの使い方と代表メソッド](/posts/2026-05-05-java-collection-map/)

## 変更履歴

- 2026-05-05: 初版公開
