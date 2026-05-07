---
title: "Javaのメソッドオーバーロード — シグネチャと成立条件"
pubDate: 2026-05-07
type: "tech"
draft: false
tags: [java]
---

## 結論

| 概念 | 役割 |
|---|---|
| オーバーロード | 同じクラス内に**同名のメソッド**を複数定義すること |
| 成立条件 | 引数の**型リスト（型・個数・順序）**が異なること |
| シグネチャ | メソッド名 + 引数の型リスト（戻り値・修飾子・throwsは含まない） |
| コンストラクタ | 同じ仕組みで複数定義できる |

## オーバーロードとは

同じクラス内に同名のメソッドを複数定義すること。コンパイラは**シグネチャ**で識別し、呼び出し時の引数から呼び出すメソッドを決定する。

```java
public int calc(int x, double y) { ... }
public int calc(double y, int x) { ... }   // 型の順序が違う → 別シグネチャ
public int calc(int x)            { ... }   // 個数が違う   → 別シグネチャ
```

## シグネチャ = メソッド名 + 引数の型リスト

シグネチャに含まれるもの・含まれないものを整理する。

| 要素 | シグネチャの一部か |
|---|---|
| メソッド名 | ○ |
| 引数の型 | ○ |
| 引数の個数 | ○ |
| 引数の順序（型の並び） | ○ |
| 戻り値の型 | × |
| アクセス修飾子（public/private 等） | × |
| `throws` 句 | × |

つまり**「メソッド名 + 引数の型リスト」が同じ**なら、戻り値や修飾子をどう変えても重複定義エラーになる。

> 同じ型同士の並び替えは型リストが変わらないので不成立（例: `(int, int)` の順序入れ替えは同一シグネチャ）。

## 利点

同じ概念の処理を、引数の違いだけで呼び分けられる。呼び出し側は「同じ名前」で扱えるので API がシンプルになる。

代表例は `System.out.println`。`println(int)` / `println(String)` / `println(double)` … と多数の引数型でオーバーロードされており、利用者は型を意識せず常に「println で表示」と1つの名前で覚えられる。

## コンストラクタもオーバーロード可能

メソッドと同じ仕組みで、コンストラクタも引数違いで複数定義できる。

```java
public class Rectangle {
    int width;
    int height;

    public Rectangle() {
        this.width = 1;
        this.height = 1;
    }

    public Rectangle(int side) {
        this.width = side;
        this.height = side;
    }

    public Rectangle(int width, int height) {
        this.width = width;
        this.height = height;
    }
}
```

呼び出し側は `new Rectangle()` / `new Rectangle(5)` / `new Rectangle(3, 4)` のいずれでもインスタンス化できる。

## 練習問題

以下のメソッドをオーバーロードした記述として適切なものを**すべて**選べ。

```java
public int calc(int x, double y)
```

- ア. `public int calc(int x, double y) throws Exception`
- イ. `private int calc(int x, double y)`
- ウ. `public int calc(double y, int x)`
- エ. `public double calc(int x, double y)`
- オ. `public int calculate(int x, double y)`
- カ. `public int calc(int x)`

<details>
<summary>解答</summary>

正解: **ウ と カ**

</details>

## 選択肢ごとの判定

| 選択肢 | 違い | 判定 | 理由 |
|---|---|---|---|
| ア | `throws` のみ追加 | × 重複定義エラー | `throws` はシグネチャに含まれない |
| イ | アクセス修飾子のみ変更 | × 重複定義エラー | 修飾子はシグネチャに含まれない |
| ウ | 引数の**順序（型の並び）**が違う | ○ オーバーロード成立 | `(int, double)` と `(double, int)` は別シグネチャ |
| エ | 戻り値の型のみ変更 | × 重複定義エラー | 戻り値はシグネチャに含まれない |
| オ | メソッド名が違う | -- | 別メソッド（オーバーロードではない） |
| カ | 引数の**個数**が違う | ○ オーバーロード成立 | 引数2個 vs 1個で別シグネチャ |

呼び出し時も `calc(1, 2.0)` / `calc(2.0, 1)` / `calc(1)` で明確に判別できる。

## まとめ

- オーバーロードの成立条件は「メソッド名が同じ」かつ「引数の型リスト（型・個数・順序）が異なる」こと
- 戻り値・修飾子・`throws` を変えても、引数の型リストが同じなら重複定義エラー
- コンストラクタも同じ仕組みで複数定義できる
- 利点は「同じ概念を1つの名前で扱える」こと（例: `System.out.println`）

## 変更履歴

- 2026-05-07: 初版公開
