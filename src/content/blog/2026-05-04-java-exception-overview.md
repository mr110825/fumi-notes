---
title: "Javaの例外処理と例外クラス階層"
pubDate: 2026-05-04
type: "tech"
draft: false
tags: [java]
---

## 結論

| 概念 | 役割 |
|---|---|
| 例外処理 | 実行中に発生したエラーで強制終了させず、別の振る舞い（通知・回復・伝播・打ち切り）に差し替える仕組み |
| 例外クラス | 発生したエラーの種類を表すクラス。`Throwable` を頂点とする3階層で整理されている |
| チェック例外 / 非チェック例外 | コンパイラが処理記述を**強制するかどうか**で分かれる |

## 例外処理がないとどうなるか

例外処理を書かないと、エラー発生時点でプログラムは強制終了し、以降の処理は実行されない。

```java
public class WeatherReport {
    public static void main(String[] args) {
        int[] temps = {25, 28, 30};

        // 4日目を読もうとして配列範囲外
        for (int i = 0; i < 4; i++) {
            System.out.println("Day " + (i + 1) + ": " + temps[i] + "℃");
        }
        System.out.println("レポート終了");
    }
}
```

実行結果：

```text
Day 1: 25℃
Day 2: 28℃
Day 3: 30℃
Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3
    at WeatherReport.main(WeatherReport.java:7)
```

`temps[3]` を読もうとした瞬間に `ArrayIndexOutOfBoundsException` が発生し、その下の `"レポート終了"` の `println` には到達していない。文法ミスではないので**コンパイルは通る**。実行してみるまで気づけない種類のエラー。

## 例外オブジェクトと例外クラス

例外発生時に内部で起きていること。

1. JVMが、発生したエラーに対応する**例外クラス**（上の例なら `ArrayIndexOutOfBoundsException`）を特定する
2. そのクラスを基に**例外オブジェクト**を生成する
3. 例外オブジェクトを `throw`（投げる）する
4. catchされなければ呼び出し階層を遡り、最終的にmainを突き抜けてJVMが受け取る → 強制終了

つまりエラーは「クラス」と「クラスから生成された具体的なオブジェクト」の2段構造で扱われる。

## 例外クラスの3階層

例外クラスは `Throwable` を頂点とする階層構造で整理されている。

```text
Throwable                   ← すべての頂点
├── Error                   ← JVMやハードウェアの問題（対処不能）
│   ├── OutOfMemoryError
│   └── StackOverflowError 等
│
└── Exception               ← プログラムで対処すべきもの
    │
    ├── RuntimeException    ← ここだけ特別扱い「非チェック例外」
    │   ├── NullPointerException
    │   ├── ArithmeticException
    │   ├── IndexOutOfBoundsException
    │   └── NumberFormatException
    │
    └── その他のサブクラス   ← 「チェック例外」
        ├── IOException
        ├── SQLException
        └── ClassNotFoundException
```

### Error — 対処不能

JVMやハードウェアレベルの問題（メモリ不足・スタック溢れなど）。プログラム側でcatchしても直しようがないので**触らない**のが原則。

### Exception — プログラムで対処すべきもの

null参照、配列範囲外、ファイル不在、DB切断などプログラム側で対処可能なエラー。**「例外処理」と言うときに対象としているのはこちら側だけ**。

## チェック例外と非チェック例外

`Exception` の中はさらに2分類できる。

| 分類 | 該当クラス | コンパイラの挙動 |
|---|---|---|
| **チェック例外** | `RuntimeException` 以外の `Exception` サブクラス（`IOException`, `SQLException` 等） | try-catch または throws の記述を**強制**。書かないとコンパイルエラー |
| **非チェック例外** | `RuntimeException` とそのサブクラス（`NullPointerException`, `ArithmeticException` 等） | 強制しない。書かなくてもコンパイルは通る（実行時に発生して未処理なら強制終了） |

### なぜ2分類するのか

コンパイラが強制チェックする対象を分けるため、というのが直接的な理由。背景の思想は次のとおり。

- **非チェック例外**：null参照漏れ・配列範囲外などプログラムのバグが原因で、コードで修正できる種類のエラー。try-catchで握りつぶすと根本原因のバグが隠れて害になる → コンパイラは強制しない（「事前条件チェックで防げ」というメッセージ）
- **チェック例外**：DB切断・ファイル不在など実行環境起因が主で、コードで予防することは困難 → 書き忘れを防ぐためコンパイラが処理記述を強制する

## 代表的な例外クラス

実務で頻繁に出会うもの。クラス名はJava SE 8日本語ドキュメントへのリンク。

### チェック例外

| クラス | 説明 |
|---|---|
| [ClassNotFoundException](https://docs.oracle.com/javase/jp/8/docs/api/java/lang/ClassNotFoundException.html) | 指定したクラスが見つからない（JDBCドライバ読み込み時など） |
| [IOException](https://docs.oracle.com/javase/jp/8/docs/api/java/io/IOException.html) | 入出力処理でエラー（ファイル読み書き・標準入力など） |
| [SQLException](https://docs.oracle.com/javase/jp/8/docs/api/java/sql/SQLException.html) | データベース処理関連のエラー |

### 非チェック例外

| クラス | 説明 |
|---|---|
| [ArithmeticException](https://docs.oracle.com/javase/jp/8/docs/api/java/lang/ArithmeticException.html) | 0除算など不正な計算 |
| [IndexOutOfBoundsException](https://docs.oracle.com/javase/jp/8/docs/api/java/lang/IndexOutOfBoundsException.html) | 配列・List・Stringの範囲外アクセス |
| [NullPointerException](https://docs.oracle.com/javase/jp/8/docs/api/java/lang/NullPointerException.html) | null が代入された参照型変数のメンバにアクセス |
| [NumberFormatException](https://docs.oracle.com/javase/jp/8/docs/api/java/lang/NumberFormatException.html) | 数値に変換できない文字列を数値変換しようとした |

## 例外クラスのメソッド

`Throwable` 由来で、`Exception` のサブクラス全般から呼べる代表メソッド。

| メソッド | 取得内容 |
|---|---|
| `getMessage()` | 例外オブジェクトの詳細メッセージ |
| `printStackTrace()` | 例外発生時のスタックトレースを標準エラー出力に表示 |

実装で扱う場面は後続の記事（[try-catch](/posts/2026-05-04-java-try-catch/)）以降に出てくる。

## まとめ

- 例外処理は「強制終了させない」ための仕組み
- 例外は `Throwable → Error / Exception` の3階層構造
- 触るのは `Exception` 側だけ（`Error` は対処不能）
- `Exception` はさらに**チェック例外**と**非チェック例外**に分かれ、コンパイラが処理記述を強制するかどうかが違う
- バグ起因の非チェック例外は「捕まえて隠す」のではなく「事前条件チェックで防ぐ」のが原則

具体的な書き方は後続の記事で扱う。

- [Javaのtry-catch — 複数catch・マルチキャッチ・finally](/posts/2026-05-04-java-try-catch/)
- [Javaのthrowsとthrow — 似て非なる2つのキーワード](/posts/2026-05-04-java-throws-and-throw/)
- [catch (Exception e) を深掘り — 多態性・スコープ・型の絞り方](/posts/2026-05-04-java-catch-exception-deep/)

## 変更履歴

- 2026-05-04: 初版公開
