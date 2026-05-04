---
title: "Javaのthrowsとthrow — 似て非なる2つのキーワード"
pubDate: 2026-05-04
type: "jot"
draft: false
tags: [java]
---

## 結論

`throws` と `throw` は1文字違いだが、**役割は別物**。むしろ対になる関係。

| キーワード | 書く場所 | 意味 |
|---|---|---|
| **throws** | メソッド宣言の末尾 | 「このメソッドは指定した例外を投げる**かもしれない**」と呼び出し元に**宣言**する |
| **throw** | メソッド本体の中 | 「ここで例外を**実際に発生させる**」 |

`throws` は予告、`throw` は実行。両者を一緒に使うことで「自作例外を意図的に投げて呼び出し元に委ねる」設計が成立する。

## throws — 例外を呼び出し元に委ねる

例外への対処は、その場で `try-catch` するだけでなく、**呼び出し元に処理を委譲する**選択肢もある。それを実現するのが `throws`。

### 構文

```text
[修飾子] 戻り値型 メソッド名(引数リスト) throws 例外クラス {
    // メソッド本体
}
```

メソッド宣言の末尾に書く。「このメソッドは `例外クラス` を投げる可能性がある」と呼び出し元に通告する仕組み。

### 例

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class ConfigLoader {
    // 「IOException が出るかも」と呼び出し元に通告
    public String loadConfig(String path) throws IOException {
        return Files.readString(Paths.get(path));
    }
}
```

`throws` を書くと、メソッド内で `try-catch` しなくてもチェック例外がコンパイルを通る。代わりに、呼び出し元がこの例外を `try-catch` するか、自身も `throws` で上位に渡す責任を負う。

### 例外の伝播

例外がメソッド呼び出しの連鎖を遡って伝わることを「**例外の伝播**」と呼ぶ。

```text
main()
  └─ start()           throws IOException
        └─ loadConfig()  throws IOException
              └─ IOException 発生
                          ↑
              ←── catch せず上に投げる
        ←── catch せず上に投げる
  ←── main で処理 or JVM へ
```

伝播の途中で誰も `catch` しないまま `main` を突き抜けると、JVMが受け取ってプログラムは強制終了する。

### 複数例外の指定

複数種類の例外を投げる可能性がある場合は**カンマ区切り**で並べる。

```java
public void process(String path) throws IOException, SQLException {
    // ファイル読み込みも DB 操作もする処理
}
```

呼び出し元はこのメソッドを呼ぶ際、両方の例外を扱う必要がある（複数catch・マルチキャッチ・自身も throws のいずれか）。

## throw — 意図的に例外を発生させる

`throw` は**メソッド本体の中で実際に例外を投げる**キーワード。

### 構文

```text
戻り値の型 メソッド名(引数リスト) throws 例外クラス {
    if (判定) {
        throw new 例外クラス(メッセージ文字列);
    }
}
```

ポイントは2段階の動作。`new 例外クラス(...)` で例外オブジェクトを生成し、`throw` でそれを投げる。

> **チェック例外を `throw` する場合は、メソッド宣言に `throws` を併記する必要がある**（非チェック例外なら不要）。これが `throws` と `throw` がペアで登場する理由。

## throws と throw を組み合わせる例（自作例外）

実用シナリオ：在庫管理。残量より多く引き出そうとしたら例外を投げる。

### 自作のチェック例外

```java
public class InsufficientStockException extends Exception {
    public InsufficientStockException(String message) {
        super(message);
    }
}
```

`Exception` を継承するとチェック例外、`RuntimeException` を継承すると非チェック例外になる。今回はチェック例外として呼び出し元に処理を強制したいので `Exception` 側を継承。

### Stockクラス（throws + throw）

```java
public class Stock {
    private int quantity;

    public Stock(int initial) {
        this.quantity = initial;
    }

    // ↓ throws で「呼び出し元に委ねる」と宣言
    public void consume(int amount) throws InsufficientStockException {
        if (amount > quantity) {
            // ↓ throw で「ここで実際に発生させる」
            throw new InsufficientStockException(
                "在庫不足: 要求 " + amount + ", 在庫 " + quantity);
        }
        quantity -= amount;
    }

    public int getQuantity() {
        return quantity;
    }
}
```

### 呼び出し側

```java
public class Main {
    public static void main(String[] args) {
        Stock stock = new Stock(10);
        try {
            stock.consume(15);
        } catch (InsufficientStockException e) {
            System.out.println(e.getMessage());
            // → 在庫不足: 要求 15, 在庫 10
        }
    }
}
```

`Stock.consume` 側は「投げる」ことに集中し、Main側は「受けてどう反応するか」に集中する。**責務が分離されている**点に注目。

## try-catch と throws の使い分け

`try-catch` と `throws` は同じ例外への二択の関係。判断基準は「**適切に処理できる場所で `catch` する**」こと。

| 状況 | 選択 |
|---|---|
| ここで意味のある対応（エラー表示・リトライ・代替処理など）が取れる | try-catch |
| ここでは対応できない／責務外 | throws で上位に渡す |

低レベル層（ファイルIO・DBアクセスなど）は `throws` で素通しし、上位層（main付近・コントローラ層）で `try-catch` するのが一般的な構成。低レベルで握りつぶすと、呼び出し元は何が起きたか分からなくなり、デバッグも困難になる。

## まとめ

| | throws | throw |
|---|---|---|
| 書く場所 | メソッド宣言の末尾 | メソッド本体の中 |
| 役割 | 「投げる**可能性**を宣言」 | 「実際に投げる」 |
| 文法 | `throws ExceptionA, ExceptionB` | `throw new ExceptionA(...)` |
| チェック例外を投げるとき | **必須** | (`throws` 併記が必須) |
| 非チェック例外を投げるとき | 不要 | (`throws` 不要) |

- 「予告」と「実行」のペアで、**責務を呼び出し元に委ねる**設計が組める
- 自作例外を作るときは `Exception`（チェック）か `RuntimeException`（非チェック）かを選んで継承する
- 「ここで対応できる」なら try-catch、「ここでは対応できない」なら throws、と責務で切り分ける

## 関連

- [Javaの例外処理と例外クラス階層](/posts/2026-05-04-java-exception-overview/)
- [Javaのtry-catch — 複数catch・マルチキャッチ・finally](/posts/2026-05-04-java-try-catch/)

## 変更履歴

- 2026-05-04: 初版公開
