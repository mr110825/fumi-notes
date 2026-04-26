# /fumi/notes

個人技術ブログ → <https://fumi-notes.pages.dev/>

> 自分と、5年後の自分のための作業ログ。

## 技術スタック

| 層 | 採用 |
|---|---|
| SSG | [Astro 6](https://astro.build) |
| ホスティング | [Cloudflare Pages](https://pages.cloudflare.com)(Free Plan) |
| デプロイ | Workers Builds(`main` push で自動) |
| CSS | Vanilla(React/Vue/Svelte/Tailwind 不採用) |
| フォント | JetBrains Mono + Noto Sans JP(Google Fonts CDN) |
| 配色 | tmux/Classic(`#101214` × `#a6e22e` × `#fd971f`) |

## ローカル開発

```sh
npm install         # 依存インストール
npm run dev         # localhost:4321 で開発サーバー起動
npm run build       # 本番ビルド → dist/
npm run preview     # 本番ビルドのプレビュー
npx astro check     # 型チェック
```

Node.js 22.12 以上推奨(動作確認: 24.5 / Cloudflare ビルド: 24.13)。

## 記事を書く

雛形生成:

```sh
scripts/new-post.sh "記事タイトル" --slug my-slug          # post
scripts/new-post.sh "短いメモ"     --slug my-slug --type jot
```

`src/content/blog/YYYY-MM-DD-<slug>.md` を `draft: true` で生成する。手で書く場合は以下の Markdown を配置:

```yaml
---
title: "記事タイトル"
pubDate: 2026-04-25
type: "post"        # "post" | "jot"
draft: true         # ビルドから除外
tags: [astro]
---
```

`main` への push で自動再デプロイ(Workers Builds 経由、約1〜2分)。

詳細な記事作成フロー・コミット規約・画像管理規約は [`CLAUDE.md`](./CLAUDE.md) を参照。

## 運用方針

- 量ノルマなし、公開タイミング自由
- 反応指標(PV / いいね)は計測・参照しない
- SEO能動施策・集客導線なし
- ターゲット読者は自分自身と「5年後の自分」のみ
