---
title: "AtCoder PracticeA 1問で出会うRust文法トピック総ざらい"
pubDate: 2026-05-05
type: "tech"
draft: false
tags: [rust, atcoder]
---

## はじめに

AtCoder Beginners Selection の1問目「PracticeA - Welcome to AtCoder」は、Rust完全初学者にとって文法地雷の宝庫だ。
入出力するだけの問題に見えて、踏むべきトピックは少なくとも以下が含まれる。

- 標準入力 `io::stdin().read_line()`
- 文字列前処理 `trim()`
- 文字列から数値への `parse()`
- 複数値の分割 `split_whitespace()` + `collect()`
- 所有権・借用（`String` vs `&str`）
- 整形出力 `println!`

この記事はPracticeAをACした実コードを起点に、これらのトピックを公式本（The Rust Programming Language、以下「公式本」）の章番号と紐付けて整理したものだ。
1問解くだけで、Rust入門の最初の壁をだいたい踏める。

## 問題と解答コード

題材: [PracticeA - Welcome to AtCoder](https://atcoder.jp/contests/abs/tasks/practice_1)

問題文の本文は載せないので、上記リンクから参照してほしい。
以下の入出力例は、自作コードの動作確認に必要な範囲で同ページから引用する。

入力例（出典: [PracticeA](https://atcoder.jp/contests/abs/tasks/practice_1)）:

```
1
2 3
test
```

出力例（出典: [PracticeA](https://atcoder.jp/contests/abs/tasks/practice_1)）:

```
6 test
```

ACした最終コード（自作）:

```rust
use std::io;

fn main() {
    let mut line1 = String::new();
    io::stdin().read_line(&mut line1).expect("...");

    let mut line2 = String::new();
    io::stdin().read_line(&mut line2).expect("...");

    let mut line3 = String::new();
    io::stdin().read_line(&mut line3).expect("...");

    let s: &str = line3.trim();

    let a: i32 = line1.trim().parse().expect("line1 should be an integer");
    let parts: Vec<&str> = line2.trim().split_whitespace().collect();
    let b: i32 = parts[0].parse().expect("b should be int");
    let c: i32 = parts[1].parse().expect("c should be int");
    println!("{} {}", a + b + c, s);
}
```

以下、出てきたトピックをひとつずつ見ていく。

## トピック1: `fn main()` の構造（公式本 ch1.2 / ch3.3）

| 要素 | 意味 |
|---|---|
| `fn` | 関数宣言キーワード |
| `main` | エントリポイント（特別扱いされる関数名） |
| `()` | 引数なし |
| `{ ... }` | 関数本体（ブロック） |

Rustファイルには2種類のコンテキストがある。

- **item context**: ファイル直下。`fn` / `struct` / `enum` 等の定義のみ書ける
- **statement context**: 関数の中。文（statement）を書ける

セミコロン `;` は文の終端。`fn main() { ... }` の本体ブロックの中だけが statement context。

## トピック2: 標準入力 `read_line`（公式本 ch2 §Receiving User Input）

```rust
use std::io;

let mut buf = String::new();
io::stdin().read_line(&mut buf).expect("...");
```

ポイントは3つ。

- `String::new()` で空のヒープ文字列を作る（`String` は所有型）
- `read_line(&mut buf)` の `&mut` は**可変借用**。「変数を書き換える権利を一時的に貸す」の意味
- 戻り値は `io::Result<usize>` 型。`.unwrap()` または `.expect("...")` で中身を取り出す

`read_line` は読み取った文字列を `buf` の末尾に**追記**するため、ループで使うときは毎回 `clear()` するか、新しい `String` を用意する。

`buf` の中身は読み取り直後で `"1\n"` のように末尾改行付きになっている。次のトピックで落とす。

## トピック3: 文字列前処理 `trim()`（公式本 ch2）

```rust
let trimmed: &str = buf.trim();
```

`str::trim()` は前後の空白・改行を取り除いた `&str` を返す。
新しい文字列を作らずに、元の文字列の中の有効範囲を指す**スライス**として返ってくるため、メモリコピーは発生しない。

ドキュメント上の `str::trim()` の `str::` は所属表記であり、実コードでは `.trim()` で呼び出す。

ここで Rust ならではの区別が出る。

| 用語 | 例 | 説明 |
|---|---|---|
| メソッド | `buf.trim()` | `&self` を取る関数。ドット記法で呼ぶ |
| 関連関数 | `String::new()` | `&self` を取らない関数。`型名::` で呼ぶ |

JavaのstaticメソッドとインスタンスメソッドのRust版、と捉えればだいたい合う。

## トピック4: 所有権と借用、`String` vs `&str`（公式本 ch4）

PracticeA を書いていると、`String` と `&str` の差が必然的に出てくる。

| 型 | 実体 | 所有 |
|---|---|---|
| `String` | ヒープに確保された文字列バッファ | 所有する |
| `&str` | 既存の文字列の一部範囲を指す参照 | 所有しない（借りている） |

`buf.trim()` は `&str` を返すが、これは `buf`（`String`）の中身を借用しているだけだ。
したがって、`buf` がスコープを抜けて破棄されると、`&str` も同時に無効になる。

借用ルールはざっくり次の3つに集約される。

- 値には**1つの所有者**しかいない
- 所有者がスコープを抜けた瞬間に値は破棄される（自動 `Drop`）
- 不変借用 `&T` は何個でもOK、可変借用 `&mut T` は同時に1つだけ。両者は同時に共存できない

PracticeA の解答では、`line3.trim()` の戻り値を `let s: &str = line3.trim();` で受けている。
この `s` が有効な間は、`line3` を勝手に書き換えたり破棄したりできない、ということが型システム上で保証される。

## トピック5: 文字列から数値への変換 `parse`（公式本 ch2 + ch9）

```rust
// 型注釈で受け側に型を教える
let n: i32 = "42".parse().unwrap();

// ターボフィッシュ構文で parse 側に型を教える
let n = "42".parse::<i32>().unwrap();
```

`parse()` はパース対象の型を呼び出し側が知らせない限り推論できない。
このため、`let n: i32 = ...` のような型注釈、または `parse::<i32>()` のターボフィッシュ構文が必須になる。

戻り値は `Result<T, E>`。学習段階では `unwrap()` よりも `expect("メッセージ")` を推奨する。
失敗時に panic するのは同じだが、エラー出力にメッセージが残るので、どこで失敗したか分かりやすい。

```rust
let a: i32 = line1.trim().parse().expect("line1 should be an integer");
```

`parse` の典型的な失敗パターンは3つ。

- `trim()` 忘れ（末尾改行が残っていて失敗）
- 型注釈・ターボフィッシュ忘れ（コンパイルエラー）
- 範囲外値（`i32::MAX` を超える数字をパースしようとする）

## トピック6: 複数値の分割 `split_whitespace` + `collect`（公式本 ch8 + ch13）

入力 `"2 3"` のように1行に複数値が入っているとき、空白区切りで切り出す。

```rust
// パターンA（学習推奨）
let parts: Vec<&str> = line2.trim().split_whitespace().collect();
let b: i32 = parts[0].parse().unwrap();
let c: i32 = parts[1].parse().unwrap();

// パターンB（メモリ確保ゼロ、慣れてから）
let mut iter = line2.trim().split_whitespace();
let b: i32 = iter.next().unwrap().parse().unwrap();
let c: i32 = iter.next().unwrap().parse().unwrap();
```

`split_whitespace()` はイテレータを返す（遅延評価）。
パターンAは `collect::<Vec<&str>>()` でイテレータを `Vec` に変換し、インデックスで取り出している。
パターンBはイテレータを直接 `next()` で1つずつ取り出す。

パターンBは `Vec` を確保しないぶん速いが、ABSの最初の数問では実行時間にまず効かないので、可読性優先でパターンAから入って良い。

`Vec<&str>` の `&str` は元の文字列 `line2` を借用しているため、`line2` が生きている間しか有効でない。
このあたり、Rust初学者だと型注釈を読んでも一発で意味が掴めないので、最初は `Vec<&str>` のまま書いて、コンパイラの怒り方で理解する。

## トピック7: 整形出力 `println!`（公式本 ch1.2 / ch3）

```rust
println!("{} {}", a + b + c, s);
```

`{}` は `Display` トレイト実装の出力。本番出力（提出コード）はこちら。

```rust
println!("{:?}", parts); // ["2", "3"]
```

`{:?}` は `Debug` トレイト実装の出力。クオートが付いたり、配列が `[..]` で囲まれたりする。
学習中のデバッグでは `{:?}` を多用する。提出時は `{}` に戻すこと。

`println!` は関数ではなくマクロ（末尾の `!`）。コンパイル時にフォーマット文字列の整合性をチェックしてくれるので、「`{}` の数と引数の数が合っていない」とコンパイルエラーで止まる。

## まとめ表

PracticeA で踏むトピックと、対応する公式本の章をまとめておく。

| トピック | 公式本 | 出てきた箇所 |
|---|---|---|
| `fn main()` 構造 | ch1.2 / ch3.3 | コード全体 |
| `io::stdin().read_line()` | ch2 | `line1` 〜 `line3` の入力 |
| 可変借用 `&mut buf` | ch4 | `read_line(&mut line1)` |
| `String` vs `&str` | ch4 | `String::new()` と `trim()` の戻り値 |
| `trim()` | ch2 | `line1.trim()` |
| `parse::<T>()` / 型注釈 | ch2 + ch9 | `let a: i32 = ...parse()` |
| `Result<T, E>` / `expect("...")` | ch9 | `.expect("...")` |
| `split_whitespace()` + `collect()` | ch8 + ch13 | `line2` の分割 |
| `Vec<&str>` | ch8 | `parts[0]` / `parts[1]` |
| `println!` マクロ | ch1.2 / ch3 | 結果出力 |

PracticeA を1問解いて、ここまでが手で動いた状態で公式本のch1〜ch9を読み始めると、知識の抽象度を上げる側に専念できる。
逆に、本を全部読み切ってから問題に着手すると、ch4（所有権）あたりで抽象だけが先行して、手が動かない状態に陥りやすい。

## 残った課題

PracticeA を AC した時点で、まだ手を付けていないトピックを残しておく。

- `?` 演算子と `main() -> Result<(), Box<dyn Error>>`（公式本 ch9）
  - `expect()` で panic させる代わりに、エラーを呼び出し元に返すパターン
  - ABSではあまり使わないが、実務コードでは必須
- `next()` パターンによるメモリ確保ゼロのパース
  - 上で挙げたパターンBの形
- 共通入力処理の `src/lib.rs` への抽出
  - 3〜4問解いて重複が見えてから判断、という指針で進める

これらは ABS の2問目以降で順次踏んでいく予定。

## 関連

- [The Rust Programming Language（公式）](https://doc.rust-lang.org/book/)
- [The Rust Programming Language 日本語版](https://doc.rust-jp.rs/book-ja/)
- [AtCoder Beginners Selection](https://atcoder.jp/contests/abs)
- [PracticeA - Welcome to AtCoder](https://atcoder.jp/contests/abs/tasks/practice_1)

## 変更履歴

- 2026-05-05: 初版下書き
