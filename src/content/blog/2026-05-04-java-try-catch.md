---
title: "Javaのtry-catch — 複数catch・マルチキャッチ・finally"
pubDate: 2026-05-04
type: "tech"
draft: false
tags: [java]
---

## 結論

| 形態 | 用途 |
|---|---|
| 基本 try-catch | 例外発生時の処理を1ブロックで受ける |
| 複数 catch | 例外の種類ごとに**違う処理**を書きたいとき |
| マルチキャッチ（`\|`） | 複数の例外を**同じ処理**で一括して受けたいとき |
| try-catch-finally | 例外の有無にかかわらず**必ず通したい**処理（リソース解放など）を書く |

例外処理の前提として、例外クラスの階層構造（`Throwable` / `Error` / `Exception` / `RuntimeException`）を理解しておくと読みやすい → [Javaの例外処理と例外クラス階層](/posts/2026-05-04-java-exception-overview/)。

## 基本構文

```text
try {
    // 例外が発生する可能性がある処理
} catch (例外クラス 変数名) {
    // 例外発生時に行う処理
}
```

`try` ブロックの中で例外が発生した場合のみ `catch` ブロックが実行される。`catch` の引数は「メソッドの仮引数」と同じ書き方で、`変数名` には発生した例外オブジェクトが束縛される。

## 複数 catch ブロック

`catch` は複数並べられる。**例外クラスごとに違う処理**を書きたいときに使う。

```java
public class AverageCalculator {
    public static void main(String[] args) {
        try {
            int total = Integer.parseInt(args[0]);
            int count = Integer.parseInt(args[1]);
            int avg   = total / count;
            System.out.println("平均: " + avg + "点");
        } catch (NumberFormatException e) {
            System.out.println("数値で入力してください: " + e.getMessage());
        } catch (ArithmeticException e) {
            System.out.println("人数は1以上にしてください");
        } catch (Exception e) {
            System.out.println("予期せぬエラー: " + e.getMessage());
        }
    }
}
```

| 入力例 | 発生する例外 | 表示 |
|---|---|---|
| `300 5` | なし | `平均: 60点` |
| `300 0` | `ArithmeticException`（0除算） | `人数は1以上にしてください` |
| `300 abc` | `NumberFormatException` | `数値で入力してください: For input string: "abc"` |

### 順番ルール — サブクラスは先、スーパークラスは後

複数 catch は**上から順にマッチ評価**され、最初に一致したブロックだけが実行される。そのため**サブクラスを先、スーパークラスを後**に書く必要がある。

```java
// NG: 到達不能でコンパイルエラー
try { ... }
catch (Exception e) { ... }              // 先に Exception で受けてしまう
catch (NumberFormatException e) { ... }  // 永遠に到達できない
```

`NumberFormatException` は `Exception` のサブクラス。スーパークラスを上に書くと、サブクラスを指定した catch には永遠に処理が回らない（コンパイラが `unreachable code` として弾く）。

## マルチキャッチ

複数の例外を**同じ処理**で受けたいときは、パイプ `|` で並べる。

```text
catch (ExceptionA | ExceptionB e) {
    // A・B 共通の処理
}
```

複数 catch が「**ブロックを増やして**例外ごとに別処理」なのに対して、マルチキャッチは「**1つのブロックで複数の例外を受けて**同じ処理」をする。コードの重複を排除できる。

```java
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

public class UserInput {
    public static void main(String[] args) {
        try {
            int age       = Integer.parseInt(args[0]);
            LocalDate dob = LocalDate.parse(args[1]);   // YYYY-MM-DD 形式
            System.out.println(age + "歳, 生年月日 " + dob);
        } catch (NumberFormatException | DateTimeParseException e) {
            // 「入力フォーマット異常」として一括処理
            System.out.println("入力フォーマット不正: " + e.getMessage());
        }
    }
}
```

`Integer.parseInt` は数値以外で `NumberFormatException`、`LocalDate.parse` は日付フォーマット異常で `DateTimeParseException` を投げる。どちらも「入力フォーマット異常」と扱いたいなら、マルチキャッチで一本化できる。

### 制約

- **継承関係にある例外を同時指定するとコンパイルエラー**。例えば `IOException | FileNotFoundException` は後者がサブクラスなので冗長
- 引数 `e` は実質 `final` 扱いで再代入不可

## try-catch-finally

例外の発生有無にかかわらず**必ず実行したい**処理を `finally` ブロックに書く。

```text
try {
    // 例外が発生する可能性がある処理
} catch (Exception e) {
    // 例外発生時の処理
} finally {
    // 例外の有無にかかわらず必ず実行される処理
}
```

`finally` の最大の特徴は、try / catch 内で `return` が実行されても、catch 内で別の例外が発生しても、**必ず通る**点。この性質を活かして**リソース解放**（ファイルclose・DB接続切断・ロック解放など）を書くのが典型用途。

```java
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class LogReader {
    public static void main(String[] args) {
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new FileReader("app.log"));
            System.out.println(reader.readLine());
        } catch (IOException e) {
            System.out.println("読み込み失敗: " + e.getMessage());
        } finally {
            try {
                if (reader != null) reader.close();   // 例外発生有無にかかわらずclose
            } catch (IOException e) {
                System.out.println("close失敗: " + e.getMessage());
            }
        }
    }
}
```

`reader` が開けたか否か、`readLine()` が成功したか否かに関係なく、`finally` の `close()` は通る。これを書かないと、try の途中で例外が起きたときファイルハンドルが開きっぱなしになる。

### 補足：try-with-resources（Java 7 以降）

Java 7以降は `try-with-resources` 構文で**リソース解放を自動化**できる。`finally` で手動closeを書く必要がなくなる。実務ではこちらを使うのが主流。

```java
try (BufferedReader reader = new BufferedReader(new FileReader("app.log"))) {
    System.out.println(reader.readLine());
} catch (IOException e) {
    System.out.println("読み込み失敗: " + e.getMessage());
}
```

ただし `finally` の挙動自体（必ず通る性質）は理解しておく価値があるので、まず手動の形を覚えてから try-with-resources に移行するのがよい。

## まとめ

- **基本 try-catch**：`try` ブロックで例外が起きたら、対応する `catch` の処理が走る
- **複数 catch**：例外の種類ごとに別の処理を書く。**サブクラスを先、スーパークラスを後**に並べる
- **マルチキャッチ（`|`）**：**複数の例外型を同じ処理で受ける**。継承関係にある型を並べるとコンパイルエラー
- **finally**：**必ず通る**ブロック。リソース解放の置き場として使う。Java 7以降は try-with-resources で自動化できる

throws と throw については後続の記事で扱う → [Javaのthrowsとthrow — 似て非なる2つのキーワード](/posts/2026-05-04-java-throws-and-throw/)。

## 変更履歴

- 2026-05-04: 初版公開
