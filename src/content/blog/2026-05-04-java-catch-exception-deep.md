---
title: "catch (Exception e) を深掘り — 多態性・スコープ・型の絞り方"
pubDate: 2026-05-04
type: "jot"
draft: false
tags: [java]
---

## 結論

`catch (Exception e)` は、書き方としては便利だが、**意図しない例外まで巻き込んで判別不能にする**ので使いどころに注意。中で起きていることを分解すると次の3点に整理できる。

| 観点 | 内容 |
|---|---|
| `e` の正体 | 例外オブジェクトを束縛する**ローカル変数**。文法はメソッドの仮引数と同形 |
| 捕まえる範囲 | `catch (X e)` は **X 型およびその全サブクラス**を捕まえる（多態性） |
| 危険性 | 広い `Exception` で受けると、本来の例外と意図しない例外が同じ catch で吸収され、デバッグが地獄になる |

## e の正体

`catch (Exception e)` は **try 内で投げられた例外オブジェクトを `Exception` 型として受け取り、ローカル変数 `e` に束縛する**仕組み。文法的にはメソッドの仮引数宣言と同形。

| 要素 | 役割 |
|---|---|
| `Exception` | 受け取る例外の型 |
| `e` | 例外オブジェクトを束縛するローカル変数 |
| `{ ... }` | catch ブロック本体 |

`e` のスコープは catch ブロック内のみ。catch を抜けたら参照不可。`e` は単なる変数名で、`ex` や `exception` でも文法上は通るが、慣習で `e` が一番多い。

`throw new Exception("...")` で投げた**例外オブジェクトそのもの**が `e` に入る。throw した側と catch した側で同じオブジェクトを参照している（JVMが呼び出しスタックを遡って catch を探し、見つけたブロックの `e` に代入してから本体を実行する）。

## catch は「型」でキャッチ範囲が決まる（多態性）

`catch (X e)` は **X 型およびその全サブクラス**の例外を捕まえる。これが catch の本質。

`catch (Exception e)` の場合：

- ✅ チェック例外（`IOException`, `SQLException`, 自作例外含む `Exception` 直系）
- ✅ 非チェック例外（`RuntimeException` 系すべて）
- ❌ `Error` 系（`OutOfMemoryError` 等）は捕まえない

範囲を狭めたい場合は具体型を指定する。

| catch句 | 捕まえる範囲 |
|---|---|
| `catch (NumberFormatException e)` | この型だけ |
| `catch (RuntimeException e)` | 非チェック例外のみ |
| `catch (IOException e)` | I/O系のみ |
| `catch (Exception e)` | チェック例外 + 非チェック例外（Errorを除く全例外） |

## 広い catch の弊害 — ユーザー登録の例

題材：「名前と年齢を受け取って登録する」メソッド。年齢の入力検証で複数の例外が起こりうる。

```java
public class UserRegister {
    public void register(String name, String ageStr) {
        try {
            int age = Integer.parseInt(ageStr);
            if (age < 0) {
                throw new IllegalArgumentException(
                    "年齢は0以上を指定してください: " + age);
            }
            // (DB保存などの処理)
            System.out.println(name + "さん(" + age + "歳)を登録しました");
        } catch (Exception e) {
            // 何が起きても "登録失敗" としか言えない
            System.out.println("登録失敗: " + e.getMessage());
        }
    }
}
```

呼び出し：

```java
public class Main {
    public static void main(String[] args) {
        UserRegister registrar = new UserRegister();
        registrar.register("Tanaka", "abc");   // NumberFormatException
        registrar.register("Tanaka", "-5");    // IllegalArgumentException
        registrar.register("Tanaka", null);    // NullPointerException
    }
}
```

実行結果：

```text
登録失敗: For input string: "abc"
登録失敗: 年齢は0以上を指定してください: -5
登録失敗: Cannot invoke "String.length()" because "ageStr" is null
```

`catch (Exception e)` で全部受けてしまうと、**どの種類のエラーかをユーザーに伝えられない**し、自分のコードの不具合（`null` チェック漏れ）まで「登録失敗」で握りつぶされてしまう。

### 具体型で書き直す

```java
public void register(String name, String ageStr) {
    try {
        int age = Integer.parseInt(ageStr);
        if (age < 0) {
            throw new IllegalArgumentException(
                "年齢は0以上を指定してください: " + age);
        }
        System.out.println(name + "さん(" + age + "歳)を登録しました");
    } catch (NumberFormatException e) {
        System.out.println("年齢は数値で入力してください: " + ageStr);
    } catch (IllegalArgumentException e) {
        System.out.println("年齢は0以上を指定してください: " + ageStr);
    }
    // NullPointerException は catch しない → コードのバグなので外で気付かせる
}
```

- `NumberFormatException` と `IllegalArgumentException` は**意味を持たせた catch**
- `NullPointerException` は**バグなので意図的に通す**（catchしない）。バグは事前条件チェック（`Objects.requireNonNull` など）で防ぐ

これで「想定済みのエラー」と「自分の不具合」が分離される。

## e から取れる情報

`Exception` は `Throwable` のサブクラスなので、`Throwable` 由来のメソッドが使える。

| メソッド | 取得内容 |
|---|---|
| `e.getMessage()` | throw 時に渡したメッセージ |
| `e.getClass().getName()` | 例外クラスの完全修飾名 |
| `e.printStackTrace()` | スタックトレース全体を標準エラー出力に表示 |
| `e.toString()` | クラス名 + メッセージ |
| `e.getCause()` | 原因例外（あれば） |

実務でデバッグするときは `e.printStackTrace()` か、ロガー経由で `logger.error("...", e)` のように **`e` オブジェクト自体**を渡すのが定番。`e.getMessage()` だけだと発生箇所がわからない。

## 実務原則

- **可能な限り具体的な例外型で catch する**（自作例外を作って `catch (NegativeAgeException e)` のように受ける、など）
- 広い `catch (Exception e)` を使うのは、**最後の砦としてログに記録する用途のみ**
- `null` 参照や配列範囲外のような「自分のコードのバグ」は catch で握りつぶさず、表に出して直す

ただし学習教材レベルでは `Exception` を投げて `Exception` で受ける構成が多い。文法を覚える段階では問題ないが、実用コードに移るときには「なぜ広い catch が危険か」を意識すると保守性が上がる。

## まとめ

- `catch (X e)` の `e` は**ローカル変数**、X 型およびその全サブクラスを束縛できる
- `catch (Exception e)` は便利だが**意図しない例外まで握り潰す**
- 「想定済みのエラー」と「コードのバグ」を分けるために、可能な限り**具体的な例外型**で catch する
- どうしても広く捕まえたいなら、ログ記録の最後の砦として使う

## 関連

- [Javaの例外処理と例外クラス階層](/posts/2026-05-04-java-exception-overview/)
- [Javaのtry-catch — 複数catch・マルチキャッチ・finally](/posts/2026-05-04-java-try-catch/)
- [Javaのthrowsとthrow — 似て非なる2つのキーワード](/posts/2026-05-04-java-throws-and-throw/)

## 変更履歴

- 2026-05-04: 初版公開
