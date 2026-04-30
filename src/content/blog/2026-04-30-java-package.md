---
title: "Javaにおけるパッケージ"
pubDate: 2026-04-30
type: "jot"
draft: false
tags: [java]
---

## パッケージとは？

Javaにおける「パッケージ」とは、プログラムをフォルダのように階層化して整理したもの。

パッケージ内に保管されるプログラムの先頭に基本構文が記載される。

```java
// 基本構文
package パッケージ名
```

パッケージ内のプログラムを別のパッケージから利用するときはimport文を利用する。
パッケージの中のすべてのクラスをインポートする場合はアスタリスク（*）を使用する。

```java
// import文
import パッケージ名.クラス名;

// import文・すべてのクラスをインポートする場合
import パッケージ名.*;
```

## 標準API

利用頻度が高いクラスやインターフェースを予めパッケージにしたものが「標準API」
具体例は下記。[Oracle社のホームページ](https://docs.oracle.com/en/java/javase/)にドキュメントあり

- java.io：入出力処理を扱うパッケージ（ファイル読み書きやストリーム操作）
- java.lang：Java言語の基本となるクラスを集めたパッケージ
- java.util：コレクションや日付などのユーティリティクラスを集めたパッケージ（List・Map・Date等）

## java.langパッケージ

java.langパッケージだけはimport文なしで利用可能。
java.langパッケージでは頻繁に利用するクラスやインターフェースが定義されている。

- Objectクラス：すべてのクラスのスーパークラス
- Stringクラス：文字列を格納するためのクラス
- Integerクラス：int型のラッパークラス（基本データ型の値を参照型として扱う際に利用するクラス）

## パッケージ命名規則

Oracle公式が示す命名規則の基本は次の2点。

- 全て小文字：クラス名（UpperCamelCase）と区別するため
- 逆ドメイン記法：自分が所有するドメインを逆順にして先頭に置く（パッケージ名を世界で一意にするため）

具体例：

- Oracle（oracle.com）→ `com.oracle.*`
- Apache Foundation（apache.org）→ `org.apache.*`
- 個人（GitHub Pages利用者：username.github.io）→ `io.github.username.*`

注意点：

- `java.*` と `javax.*` は標準ライブラリ専用なので、自分のコードでは使えない
- ドメインにハイフンを含む場合（例：`my-company.com`）はアンダースコアに置き換える（`com.my_company`）

## 参考リンク

- [Oracle: Creating and Using Packages（Javaチュートリアル）](https://docs.oracle.com/javase/tutorial/java/package/index.html)
- [Oracle: Naming a Package（Javaチュートリアル）](https://docs.oracle.com/javase/tutorial/java/package/namingpkgs.html)
