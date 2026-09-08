# dotfiles

macOS と Ubuntu のマシンを、一行のコマンドで同じ状態に揃えるためのリポジトリ。

chezmoi が dotfiles を展開し、mise がパッケージとツールを揃える。

## 対象

- macOS
- Ubuntu 24.04

## セットアップ

新しいマシンで次の一行を実行する。OS は自動で判別される。
パイプ（`curl ... | sh`）では stdin がスクリプト本体に占有され、`chezmoi init` のプロンプトが動かない。
必ず上のコマンド置換形式を使う。

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/kunikeni/dotfiles/main/bin/install.sh)"
```

実行されること。

1. OS を判定する
2. 前提を入れる。macOS は Xcode Command Line Tools と Homebrew、Ubuntu は apt の最小構成
3. mise と chezmoi を入れる
4. `chezmoi init --apply` でこのリポジトリを取得し、dotfiles を展開する
5. `mise bootstrap` でパッケージ、ツール、ログインシェルを揃える。macOS では Formula の導入後に `Brewfile` の Cask を適用する

初回は 4 で設定値を尋ねられ、`~/.config/chezmoi/chezmoi.toml` が生成される。2回目以降は尋ねない。
5 の終盤、ログインシェルの変更でパスワードを聞かれる。

## リポジトリの構成

| パス | 役割 |
| --- | --- |
| `bin/install.sh` | エントリポイント。OS を判定して以下を読み込み、chezmoi と mise を起動する |
| `bin/{mac,ubuntu}/install.sh` | OS 固有の前提導入。単体では実行せず `bin/install.sh` から読み込まれる |
| `bin/ubuntu/apt-repos.sh` | docker の apt リポジトリ登録 |
| `mise.toml` | 共通のセットアップ定義と `sync` タスク |
| `mise.{mac,ubuntu}.toml` | OS 固有のパッケージとログインシェル |
| `Brewfile` | macOS の Cask。Homebrew Bundle が参照する正本 |
| `dot_config/mise/config.toml` | mise が管理するツール。両 OS 共通 |
| `.chezmoi.toml.tmpl` | 初回に尋ねる設定値の定義 |
| `.chezmoiignore` | ホームに展開しないファイル |
| `dot_*`, `Library/`, `AppData/` | dotfiles 本体 |

## 管理している dotfiles

| 対象 | ソース |
| --- | --- |
| シェル | `dot_zshrc.tmpl`, `dot_bashrc.tmpl`, `dot_zprofile` |
| git | `dot_gitconfig.tmpl` |
| エディタ | `dot_vimrc`, `dot_config/nvim/` |
| ターミナル | `dot_config/ghostty/`, `dot_config/wezterm/` |
| プロンプトとファイラ | `dot_config/starship.toml`, `dot_config/yazi/` |
| AI コーディング | `dot_claude/`, `dot_codex/` |
| GitHub CLI | `dot_config/gh/` |
| VSCode | `Library/Application Support/Code/User/settings.json` |

## パッケージを追加する

**マシンの一部なら OS のパッケージマネージャ、作業環境の一部なら mise。**

マシンの一部とは、そのマシンに一度あればよく、OS の他の部分と整合していることに価値があるもの。
標準コマンドの置換、シェルとそのプラグイン、システムエディタ、ビルドツール、証明書、実行基盤、GUI アプリが該当する。
作業環境の一部とは、開発作業に伴って使い、別のマシンや CI でも同じものが欲しいもの。

判定したら、次のファイルに書く。

| 判定 | 書くファイル |
| --- | --- |
| 作業環境の一部 | `dot_config/mise/config.toml` |
| マシンの一部（macOS Formula） | `mise.mac.toml` |
| マシンの一部（macOS Cask） | `Brewfile` |
| マシンの一部（Ubuntu） | `mise.ubuntu.toml` |

言語やインフラのツールは `dot_config/mise/config.toml` に既定版を置く。
プロジェクトごとの版は、各プロジェクトの `mise.toml` が上書きする。

`bootstrap.packages` はエントリ単位の OS 判定を持たないため、OS 固有分はファイルを分けて `MISE_ENV` で切り替えている。

macOS の Formula は `mise.mac.toml`、Cask は `Brewfile` が管理する。初回セットアップでは `mise bootstrap` が Formula を導入した後、`post-packages` hook から `brew bundle --file="{{ config_root }}/Brewfile" --no-upgrade` を実行して Cask を適用する。bootstrap は既存項目をアップグレードせず、不足分だけを反映する。

## 日常運用

```bash
chezmoi git pull   # 変更の取得
chezmoi diff       # 適用前に差分を確認
mise run sync      # chezmoi apply + パッケージとツールの差分反映
brew update        # Homebrew の定義を更新
brew upgrade       # Formula を更新
brew upgrade --cask # Cask を更新
```

`mise run sync` は宣言された不足分を反映する。Homebrew の更新は必要なタイミングで `brew update`、`brew upgrade`、`brew upgrade --cask` を明示的に実行する。

### 既存の mise-owned Cask を移行する

既存環境で mise 管理の Cask を `Brewfile` へ移行するときは、通常の `mise run sync` より先に次の順序で実行する。

1. まず prune の対象を確認する。

   ```bash
   mise -E mac bootstrap packages prune --manager brew-cask --dry-run
   ```

2. dry-run の表示を確認し、安全に削除できる対象だけを prune する。

   ```bash
   mise -E mac bootstrap packages prune --manager brew-cask --yes
   ```

3. `mise run sync` を実行し、Formula の導入後に post-packages hook から `Brewfile` を適用する。

   ```bash
   mise run sync
   ```

4. Brewfile の Cask が Homebrew の管理下にあることを確認する。

   ```bash
   brew bundle check --file=Brewfile
   ```

5. prune が古い receipt、自己更新アプリ、pkg、lifecycle action、変更済み target などを理由にスキップした項目は、表示理由と `brew info --cask <token>` を確認する。同一 artifact だと確認できたものだけ、必要に応じて adopt する。

   ```bash
   brew install --cask --adopt <token>
   ```

同一 artifact と確認できない項目は一括削除せず、アプリ固有の安全なアンインストールまたはバックアップ後の個別インストールを行う。アプリ bundle の削除や再導入で Accessibility、Screen Recording、Full Disk Access などの macOS 権限が失われることがあるため、必要に応じて再付与する。権限が重要なアプリは、同一 artifact と確認できる場合に adopt を優先する。

dotfiles を変更するときは、実ファイルではなくこのリポジトリ内のソースを編集して `chezmoi apply` する。

## トラブルシューティング

### `chezmoi init` が `could not open a new TTY` で失敗する

`promptStringOnce` は `/dev/tty` を開くため、標準入力へのパイプでは応答できない。
実端末で実行するか、非対話環境では `~/.config/chezmoi/chezmoi.toml` を先に配置しておく。

### `chezmoi diff` が config file template has changed と警告する

`.chezmoi.toml.tmpl` を変更したあと、生成物である `~/.config/chezmoi/chezmoi.toml` が古いときに出る。
`chezmoi init` で再生成する。既存値があるプロンプトは尋ねられない。

### `mise bootstrap` が chsh で止まる

ログインシェルの変更でパスワードを聞かれる。無人実行はここだけできない。

### macOS で `btop` が unsupported env で失敗する

mise の aqua バックエンドが Linux 向けしか提供していないため、`btop` は brew と apt に置いてある。

### `mise install` が HTTP 403 で失敗する

GitHub API のレート制限。時間をおくか、`GITHUB_TOKEN` を設定してから再実行する。
