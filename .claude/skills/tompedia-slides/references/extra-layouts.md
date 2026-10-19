# 追加の型（実例の資料から持ってくるページ）

公式テンプレート（`layout-catalog.md` の22ページ）にない型を、実例の資料から集めたもの（2026-10-19 調査）。
すべて公式と同じフレーム（F3扉／F4本文カード）で作られているので、そのページを `merge-designs`（`insert_pages`）で持ってきて文章を差し替えれば見た目が崩れない。

- **ここにない型が必要になったら、作る前にユーザーに相談する**（ユーザーの方針）。
- 要素IDは元デザインの値。持ってきた後は必ず `read-design` で読み直す。
- 元デザインの数字・人名・写真が残りやすいので、差し替え後に全文を確認する。写真枠（`IMG*`）は差し替えられない場合「写真の差し替えが必要」と伝える。

## 元デザイン
| 略号 | デザインID | 名前 |
|---|---|---|
| **Q** | `DAHLVv4QdWU` | 【公開中】15分でわかるとんペディア（45ページ） |
| **A** | `DAHXIFJiZ5I` | とんペディア_ラボの「ありたい姿」と「現在地」（9ページ） |

## 一覧

| 型ID | 名前 | 元 | 使う場面 |
|---|---|---|---|
| `x-list-numbered` | 番号付きリスト | A-2 | 論点・項目を並べる（目次の代わり、議題一覧） |
| `x-ideal-current` | 理想／現状 | A-3 | 理想と現状、Before/After、課題→解決 |
| `x-before-after` | これまで／これから | Q-35 | 変化を箇条書きで並べ、下に結論 |
| `x-two-column` | 2カラム（縦線区切り） | Q-31 | 2つの事例・2つの選択肢を並べる |
| `x-two-box-merge` | 2つの枠→1つに合流 | Q-15 | 2つの要素が合わさって1つの結論になる |
| `x-steps-3` | 3ステップ（番号付き） | Q-33 | 手順・計画を①→②→③で見せる（左半分）＋右に画像 |
| `x-phases-3` | 3段階（ボックス＋▶） | Q-37 | 段階・フェーズの移行、下に結論 |
| `x-venn` | 2つの円の重なり | Q-39 | 2つの視点の重なり、下に結論 |
| `x-converge` | 左右→中央の円 | Q-25 | 2つの手段が1つの価値に集まる |
| `x-card-grid` | カード並び（ラベル＋カード8枚） | Q-18 | プロジェクト・サービスなど複数項目の一覧 |
| `x-channels` | 大カード1＋小カード4 | Q-30 | 主要1つ＋その他の一覧（SNS、施策など） |
| `x-diagram-summary` | 図（左）＋概要・番号リスト（右） | Q-36 | 体制図や仕組み図に説明を添える |
| `x-text-photos` | テキスト（左）＋写真コラージュ（右） | Q-40 | 施策・成果物を写真で見せる |
| `x-text-illust` | 長文（左）＋イラスト（右） | Q-44 | ビジョン・想いを文章で語る |
| `x-heading-text` | 見出し＋本文（縦棒なし） | Q-32 | P6より軽い本文ページ。見出し53px＋本文37px |
| `x-photo-message-3` | 写真全面＋3行メッセージ | Q-12 | 大きいメッセージ（上下が小さめ、中央が大きい） |
| `x-subsection` | 小扉（3本バー） | Q-22 | 章の中の小区切り。左のバーで「何番目か」を示す |
| `x-members-4-lab` | メンバー紹介（ラボ版） | Q-10 | P18と同じ型。ラボの代表・部署リーダー |

---

## 差し替える要素

書式は `要素ID：役割（元の文言）— サイズ`。フォントはすべて `YAFdJgDCFgs`。

### x-list-numbered（A-2）
- `LBrShxCk0F64BCbN`：リスト本体（主体性⏎議論・共創の場⏎…7項目）— 48px bold 黒、`decimal`、行間1.91、@(155,276) 幅706 — 1項目15文字、7項目まで
- ページタイトルはなし（必要ならP6から持ってくるか、空欄のまま）

### x-ideal-current（A-3）
- `LBdhPlS4PpGXXrbn`：ページタイトル（①主体性）— 42.67px 紫
- `LBkFqJSpGKkPNr4G`：上ラベル（理想）— 45.3px bold 紫
- `LB5Wdcqh9YpNQNYw`：上のボックス（#eddeff 角丸）の中の箇条書き — 34.67px bold、`disc` — 37文字×4行
- `LBnj7LqJPfKrhKkK`：下ラベル（現状）
- `LBVkrN3MbZwd8bqx`：下のボックス（#dddddd）の中の箇条書き。2段目（`circle`）も可 — 37文字×6行
- `LBJ2L5ZGMHx7wD8n`：矢印の右のギャップ説明 — 34.67px medium、`disc` — 28文字×3行
- ボックス内の文字は `replace_text` でボックス（shape）の locator_id を指定して差し替える

### x-before-after（Q-35）
- `LBgzYZ4t73P43TYh`：ページタイトル
- `LBwZD8q5xbF1n4Kv`：大見出し（HRチームを新設）— 66.7px bold **#0097b2**（紫 `#825dab` に `format_text` で変える）
- `LBGzjPhBDB6H8gM1`：見出し右のサブコピー — 48px medium
- `LBw3FskcqYGKh4xV`：前提の1行 — 40px bold
- `LBFZTj4tBGHrFy0l`／`LBGbPLkD1Rtfthpw`：ラベル（これまで／これから）— 40px bold
- `LBKGSCGRj1NcRmqL`／`LByMysXKfXSnCyRm`：箇条書き — 40px medium `disc` — 33文字×3〜4行
- `LBbVzWqJSmKhgQ0w`：結論（2行、中央）— 48px bold — 34文字×2行

### x-two-column（Q-31）
- `LBb2X0ytb7dJ2Kww`：ページタイトル
- `LBgzpX2wMQ9DVYV6`：左上の小見出し（新歓実績）— 53px bold 紫
- `LBHWhsy1c900Ypwz`／`LBnN4pnVd8Gwpblx`：左／右の見出し — 48px bold **#ff5757**（強調色は赤系。内容によって紫に変える）
- `LBPtj0MSV3w6bDK5`／`LBmJ8WZSN4wLL8nm`：左／右の本文 — 37px medium、幅797 — 21文字×5行
- 写真：左3枚（`LBn5lqkzQtByTQfT` `LBjkMN3nGYqsjwbS` `LBMsgfz8KvnXbp1d`）、右1枚（`LB8PP5brhlV6H7yh`）
- 中央の縦線 `LBdnXMg5xnbdyX4C`

### x-two-box-merge（Q-15）
- `LBSpTkms5QyHsD5K`：ページタイトル
- 左の枠：ラベル `LBlqXj5kSqF6WQFx`（37px、枠付き）、小見出し `LBJmb1YXjVlHVKrc`（32px）、本文 `LBCYHh7BwwlvqCTB`（37px、幅728 — 19文字×5行）、強調 `LB2WxtFmvlcswm25`（42.67px）
- 右の枠：ロゴ画像 `LBBW2YhKddR8JQ39`、写真 `LBQTty3kzBCZmTNv`、小見出し `LB61LmNqXtqlDggG`・`LBwT6GYjYRqYvnmw`、本文 `LBqcfcmZrncB6tpf`
- 下の合流先：とんペディアのロゴ画像 `LB5F1HLPYCmXPXb6`（別の結論にするときは画像を消してテキストを置く必要がある → 要相談）

### x-steps-3（Q-33）
- `LBmMvGbYGyl1njBz`：ページタイトル
- `LBTQPTGwdqQ7ZDfh`：見出し（2行）— 33.4px bold 赤 #ff5757
- `LBBzBV439hnGYvYd`：リード文 — 33.4px heavy 赤 — 26文字×2行
- `LB9x3sPMXy2wQYwk`：目標文 — 32px bold — 30文字×2行
- ステップ：番号丸 `LBjF6hYDf0Yxfnlp`(1) `LBQRd6XZpncWdBtL`(2) `LBtGtb1DrJw3dNyH`(3) ＝紫丸 56px、説明 `LBynkV3Ryx5Prwx3` `LBcJ6qnZ43jKgDdH` `LB0WRrZXfhy5mh1k` — 26.8px bold — 11文字×3行
- 数字ブロック（寄付総額など）`LB7WXkPfRDQVGF8s` のグループ：不要なら削除
- 右側の画像群（`LBqWHsBR5rb8dnhB` と グループ `LBC9Zw5sDxVyCt8t`）：クラファンのページ画像なので、使わないなら削除して左側を広げる

### x-phases-3（Q-37）
- `LBbPLxFv5fTNYv4W`：ページタイトル
- `LB5XXMSf23LZ6Qrm`：小見出し1 — 38px #441e6d／`LB6HxHPyV47xlj6H`：小見出し2 — 40.8px 紫
- `LBJJGC2LKDjrzVzC`：図の見出し（ラボメンバー３段階のフェーズ）— 51.4px
- 段階1：見出し `LBxVK7YVpbHnbGcb`、本文 `LBxBchbVBqHZcR8w`（40.8px、14文字×4行）
- 段階2：見出し `LBg97B7Xds5Mrb8Y`、本文 `LBYKjgfKSkXSK8hn`、ラベル `LBcFcMbdJ8lMyNxs`（白文字）
- 段階3：見出し `LBsQ8NTnGBb0wSxM`、本文 `LBMkDwrkJpDjlh9j`、補足 `LBNhDcv6r3jkJXq8`、ラベル `LB5Ctgnx6H3L0Zvb`
- 結論 `LBCR7ZmmWx5Zgb4Y` — 48px bold — 31文字×1行
- 背景の紫ボックス `LBZs0fGJRpRbS5z9` は段階1〜2を囲っている（強調したい範囲に合わせて `resize_element`）

### x-venn（Q-39）
- `LB88RFyk9FLmgMPB`：ページタイトル、`LBq6dQP7rpQ8qLbb`／`LBxFjkhm63rpcqmr`：小見出し
- 左の円の文字 `LBsK4TZHpTvHJpzB`、右の円の文字 `LBqyWhNndSGWMPyT` — 41.6px — 8文字×3行
- 左の円のラベル画像 `LBwPJ81gTDXC81bx`（「とんペディア」ロゴ）：内容が違えば削除
- 結論 `LBQ2dszVkDg1Dg3J` — 41.6px bold — 31文字×2行
- 円は画像（`LBVBFSCG17sWnssK`）なので色・大きさは変えない

### x-converge（Q-25）
- `LBYNZLC2GWRN8Cns`：ページタイトル、`LBpxqwFh6nXCqzb4`：見出し（56px）
- 左 `LBGvMJS3tb2Vzsjg`（48px medium、10文字×2行）、右 `LBk6WF31HtJ8cfT8`（48px bold オレンジ）
- 中央の円 `LBcDdDD6bbV9RX67`（#ffba8b、円の中に文字）— 円の locator_id で `replace_text`
- 背景写真あり（差し替え要）

### x-card-grid（Q-18）
- `LBSxY1hp8v0XX58g`：ページタイトル
- ラベル2つ（`LBzhdXX3ptYMZyxt`／`LBlyP3t9VhcS0tvR`）＋その右の説明（`LBMMXcm28NYjSFdN`／`LBnFSg020Kj1vt8P`、42.67px）
- カード8枚：各グループ＝白い角丸＋ロゴ画像＋名前＋説明（24〜26px、13文字×3行）。ロゴは各プロジェクトの画像なので差し替えが必要
- カードが8枚より少なければグループごと `delete_element`

### x-channels（Q-30）
- `LBsfHLlchPlLjGGh`：ページタイトル
- 大カード（左）：名前 `LBy7yxFbpHX3PjHn`、数字ラベル `LB99BpXhR2TK91CJ` `LBtv328y850Xf0qF`、数字 `LB1lwDPX6JNXkf21` `LBWxykG6RyB0sms1`（70.8px）、箇条 `LBFgPyFs6gQp8KT0`、結論 `LBZC8J1Tq4xQR0Nz`
- 小カード（右）4枚：名前（48px 紫）、補足（30.7px）、「これから」ラベル（32px オレンジ）
- アイコンは各SNSのロゴ画像

### x-diagram-summary（Q-36）
- `LBBk76psJ7xTXXrq`：ページタイトル、`LBSpdG8BqjyNnTXf`：大見出し（#0097b2 → 紫に変える）、`LBw4cdMLT6hnf4WP`：サブコピー
- 左の図：グループ `LBQLy64Jg470XM8Y` の中に箱11個（運営・HR・各リーダー・メンター・メンバー）。箱の locator_id で文字を差し替え、使わない箱は削除
- 右：見出し `LBYtYMPZtrM9rKy2`（42px）、説明 `LBcbSslgLjF9Jgb9` `LBltNcMQ33VdsFlr`（35px、19文字×2行）、見出し `LBYwdztlytY7kCdk`、番号リスト `LBpN4znFV4GcRh9h`（35px、6行）

### x-text-photos（Q-40）
- 背景色が `#ebebeb`（グレー）なのでフレームが他と違う点に注意
- `LBcH9NVgmBHKY53N`：ページタイトル、`LB9H2Xk7WHSg481h`：メッセージ（53px、11文字×3行）、`LBpfMhSkC9MN1XMJ`：補足（42.67px オレンジ）
- 写真7枚（差し替え必要）

### x-text-illust（Q-44）
- `LBLq1W3M67cbDGh4`：ページタイトル
- `LBjXf9CQDSFMJHKS`：長文 — 37px bold、幅1747だが右にイラストが重なるので実質 幅800 — 22文字×13行
- イラスト `LBQxs01JM1YYSKxG`（東北大と人のイラスト。内容が違えば削除）

### x-heading-text（Q-32）
- `LBPLhp7nvLm4yqDY`：ページタイトル
- `LBLHZplD2FWF6Snz`：見出し — 53px bold 紫
- `LBmPCkB4Pf30V7xL`：本文 — 37px medium、幅784（広げてよい）— 幅1700で46文字×14行

### x-photo-message-3（Q-12）
- `LBfcNX8lxlxKM2tn`：ページタイトル
- 上 `LBjpzKFbwhfxtzql`（89px、6文字）／中央 `LBCvPw8q1yPvZQVF`（119px、13文字）／下 `LBZjPBwYVPzGTNGT`（89px、12文字）— すべて白・中央揃え
- 写真 `LB0P44XVrt3dfs4s`（差し替え可）

### x-subsection（Q-22、同じ形が Q-24・Q-29・Q-34）
- 背景 紫、右に薄紫のブロブ
- `LBrsvWV7p3SCK0Qs`：小扉の文字（開発）— 96px bold 白、中央
- 左の3本バー（`LBSC0j87zv5ZYCZl` 上、`LBb9018mmhXfv6pf` 中、`LBzjSjTCHZK8RkXj` 下）：今の位置のバーだけ不透明度1、ほかは0.5（`update_opacity`）
- Q-34 は上に小さいラベル（番外編）が付いた形

### x-members-4-lab（Q-10）
- `LBHqvR0v7JK8X08f`：ページタイトル
- 写真4枚、役職（`LBCqjtlCt6NkXj2l` ほか、枠の中の文字）、名前（`LBqbtbJgjFcphJ5y` ほか）、所属（紫地 `LBZxQhzgcY93NMC5` ほか）

---

## 見つからなかった型（必要になったら相談）
| 型 | 状況 |
|---|---|
| 表（3〜4列） | とんペディアのフレームの実例なし。旧デザインの資料（データクレンジングイベント `DAG_Z1-U4Iw` P9）に小さい表がある程度 |
| タイムテーブル | 公式フレームの実例なし。イベント当日のスライド（`DAHRTgduJho` P6〜P8：縦の時間軸）は**別テーマ（青い波・企業ロゴ）**なので構造の参考のみ。旧デザイン `DAG_Z1-U4Iw` P3 に「時刻＋内容」の一覧＋マスコットの形がある |
| 審査基準などの3カード | `DAHRTgduJho` P10（薄紫のカード3枚）。これも別テーマなので構造の参考のみ |
