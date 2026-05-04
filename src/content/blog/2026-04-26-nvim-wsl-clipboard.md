---
title: "Neovim on WSL でクリップボード連携を設定する"
pubDate: 2026-04-26
type: "tech"
draft: false
tags: [neovim, wsl]
description: "WSL2 上の Neovim から win32yank.exe 経由で Windows クリップボードと y/p 連携する手順"
---

## 問題：WSL2のNeovimでコピーした内容がWindowsクリップボードに渡らない

WSL2上でメモをマークダウンで管理しており、Neovim で `yy` や Visual モード選択でコピーした内容を Windows 側のアプリに貼りたい場面がある。だが、デフォルト構成だと Windows 側にペーストできない。

`win32yank.exe` 経由でクリップボードを橋渡しする方式で解決したので、手順をまとめる。

## 解決手順

### 1. win32yankのインストール

```bash
curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
unzip /tmp/win32yank.zip -d /tmp/
chmod +x /tmp/win32yank.exe
sudo mv /tmp/win32yank.exe /usr/local/bin/
```

### 2. 動作確認（Neovim設定前にCLI単体で）

```bash
echo "hello from wsl" | win32yank.exe -i && win32yank.exe -o
```

往復で `hello from wsl` が出力され、Windows側でも `Ctrl+V` で貼れればOK。
ここで動かない場合は Neovim 設定に進んでも解決しないので、PATH や `win32yank.exe` の実行権限を先に確認する。

### 3. Neovim設定（`~/.config/nvim/init.lua`）

`vim.opt.termguicolors` のあたり（基本設定セクション）に以下を追加。

```lua
-- クリップボード連携（WSL: win32yank.exe 経由でWindowsクリップボードと連携）
vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
  name = "win32yank",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf",
  },
  paste = {
    ["+"] = "win32yank.exe -o --lf",
    ["*"] = "win32yank.exe -o --lf",
  },
  cache_enabled = 0,
}
```

### 4. 動作確認（Neovim側）

1. Neovim再起動 or `:source ~/.config/nvim/init.lua`
2. `yy` で行ヤンク → Windowsの他アプリで `Ctrl+V` で貼れる
3. Windowsで何かコピー → Neovimで `p` で貼れる

不調時は `:checkhealth` の Clipboard セクションで状態確認。

## 原因：なぜこの問題は発生したか

今回の問題の原因は、WSL2 には Neovim から呼び出せる Windows クリップボード操作用コマンドが既定で用意されていないことだ。

Neovim の仕様上、Neovim 自身がクリップボードを直接操作することはない。
Neovim から外部コマンドに丸投げする設計となっており、macOS や Linux X11 では既定のコマンド（pbcopy / xclip 等）が利用できる。

一方 WSL2 では、Linux 側のコマンド（xclip 等）は X11 セレクションを操作するもので Windows クリップボードには届かないため、Neovim から依頼できる橋渡しコマンドが存在しない状態になる。
これが今回コピー＆ペーストができなかった原因である。

win32yank はこの欠落を埋めるコマンドであり、Windows ネイティブバイナリとして Win32 クリップボード API を直接操作するため、WSL2 から実行することで橋渡しを実現できる。

## 変更履歴

- 2026-04-26: 初版公開
