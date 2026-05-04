---
title: "Javaにおけるパッケージ"
pubDate: 2026-04-30
type: "tech"
draft: false
tags: [java]
---

## パッケージとは？

Javaにおける「パッケージ」とは、プログラムをフォルダのように階層化して整理したもの。

パッケージ内に保管されるプログラムの先頭に基本構文が記載される。

```java
// 基本構文
package パッケージ名;
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

利用頻度が高いクラスやインターフェースを予めパッケージにしたものが「標準API」。
Javaの標準APIはJDKに同梱されており、具体的な配置はJavaのバージョンによって異なる。
具体例は下記。[Oracle社のホームページ](https://docs.oracle.com/en/java/javase/)にドキュメントあり。

> **JDK（Java Development Kit）**\
> Java開発キット。プログラムを書く・コンパイルする・実行するために必要な公式ツール一式

- java.io：入出力処理を扱うパッケージ（ファイル読み書きやストリーム操作）
- java.lang：Java言語の基本となるクラスを集めたパッケージ
- java.util：コレクションや日付などのユーティリティクラスを集めたパッケージ（List・Map・Date等）

## java.langパッケージ

java.langパッケージだけは自動的にimportされるため、import文なしで利用可能。
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

## サンプルコード：HelloWorldをインポート

```java
package import_sample1;

public class HelloWorld {
	// 別パッケージから呼べるように public static で切り出す
	public static void sayHello() {
		System.out.println("Hello World");
	}

	public static void main(String[] args) {
		sayHello();
	}
}
```

```java
package import_sample2;

import import_sample1.HelloWorld; // sample1 の HelloWorld を取り込む

public class ImportHelloWorld {

	public static void main(String[] args) {
		HelloWorld.sayHello(); // import したクラスの static メソッドを呼ぶ
	}

}
```

```text
// import_sample2のmainメソッドの実行結果
Hello World
```

- public 必須の話：別パッケージを参照するには参照元のクラス・メソッド両方が`public`である必要がある
- importの意味：import 文は「フル修飾名の省略」の宣言にすぎず、書かなくても `import_sample1.HelloWorld.sayHello()` のようにフルパスで書けば同じ動作になる

## 参考リンク

- [Oracle: Creating and Using Packages（Javaチュートリアル）](https://docs.oracle.com/javase/tutorial/java/package/index.html)
- [Oracle: Naming a Package（Javaチュートリアル）](https://docs.oracle.com/javase/tutorial/java/package/namingpkgs.html)

## 変更履歴

- 2026-04-30: 初版公開（パッケージ概念・標準API・java.lang・命名規則）
- 2026-05-01: 標準APIにJDK補足追加・サンプルコード（HelloWorldインポート例＋解説）追加
