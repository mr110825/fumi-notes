---
title: "Javaのswitch文"
pubDate: 2026-04-26
type: "jot"
draft: false
tags: [java]
---

## Javaのswitch文とは？

変数の値によって、処理を分岐させる処理を実装するのが`switch文`

## 基本構文

```java
switch (変数) {
case 値1:
    処理1;
    break;
case 値2:
    処理2;
    break;
default:
    デフォルト処理
}
```

- `break`に処理が停止される。つまり、`case 値1`の`break`がない場合は、処理1と処理2が実行される。
- `case 値:`の`:`はコロン。セミコロンではないことに注意。
- `default`はどのcaseの処理も実行されなかった場合に実行される。省略可能。
- 変数として利用できるのは整数型（long型以外）String型。

Java 14 からswitch 式（アロー構文）が正式機能。

```java
データ型 受け取る変数名 = switch (判定する変数) {
    case 値1 -> 返す値1;
    case 値2 -> 返す値2;
    case 値3 -> 返す値3;
    default  -> デフォルトの値;
};
```

## 例文

```java
public class SwitchSample {

    public static void main(String[] args) {
        String signal = "red";
        switch (signal) {
        case "red":
            System.out.println("止まれ");
            break;
        case "yellow":
            System.out.println("注意");
            break;
        case "green":
            System.out.println("進め");
            break;
        default:
            System.out.println("不明な信号");
        }
    }
}
```

`switch文`を`switch式`（アロー構文）で書き直した例：

```java
public class SwitchSampleArrow {

    public static void main(String[] args) {
        String signal = "red";
        String action = switch (signal) {
            case "red"    -> "止まれ";
            case "yellow" -> "注意";
            case "green"  -> "進め";
            default       -> "不明な信号";
        };
        System.out.println(action);
    }
}
```

## 関連リンク

- [Oracle-Java_switch式および文](https://docs.oracle.com/javase/jp/23/language/switch-expressions-and-statements.html#GUID-BA4F63E3-4823-43C6-A5F3-BAA4A2EF3ADC)
- [Oracle-Java_Switch式](https://docs.oracle.com/javase/jp/14/language/switch-expressions.html)

