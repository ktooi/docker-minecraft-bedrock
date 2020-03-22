# docker-bedrock

このプロジェクトは、超簡単に Minecraft 統合版のサーバ (bedrock-server) を構築し、運用する為のものです。

このプロジェクトには次の特徴があります。

*   bedrock-server の更新やセーブデータのバックアップをスクリプト化することで、 bedrock-server を全自動で運用できる。
*   起動するコンテナ毎に、 bedrock-server のバージョンを指定できる。
*   bedrock-server のファイルを各利用者の環境でダウンロードし、 Docker Image をビルドすることで[マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)に適合する(bedrock-server の再頒布を行わない)。

## Getting Started

### Prerequisites

```
docker
```

*   [マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)
*   [プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)

### Installing

1.  `containers.lst` ファイルを作成します。

    `containers.lst` ファイルは起動する bedrock-server のコンテナを定義するファイルです。
    1行につき1つのコンテナを示し、各行はタブ区切りで次のようにで記載します。

    ```
    <name>	<port>	<volume>	<image>
    ```

    *   <name> : コンテナ名です。後述する `env-files/*.env` のファイル名としても利用します。
    *   <port> : コンテナが待ち受けるポート番号(udp)です。
    *   <volume> : セーブデータ等を保存する Docker Volume の名前です。
    *   <image> : コンテナが利用する Docker Image の名前です。 `bedrock:1.14.32.1`, `bedrock:latest` のように指定します。
        *   `bedrock:1.14.32.1` のように、特定のバージョンを指定した場合には、そのコンテナは指定したバージョンで動作し続けます。
        *   `bedrock:latest` と指定した場合には、そのコンテナは Docker Image が更新されるたびに `manage_containers.sh` により停止・再作成・起動され、常に最新版の bedrock-server で動作し続けます。

    e.g.,

    ```
    example-be	19132	example-be-volume	bedrock:latest
    ```
2.  `env-files/<name>.env` ファイルを作成します。

    `env-files/<name>.env` ファイルはコンテナの環境変数を定義するファイルです。
    `docker run --env-file` として指定されます。
    ファイル名の `<name>` には `containers.lst` で定義したものを指定してください。

    利用可能なパラメータは `env-files/example.env` を参照してください。
3.  `bedrock_server.sh` を実行します。

    このスクリプトは最新版の bedrock-server-*.zip をダウンロードし、 Docker Image をビルドします。

    実行は `root` で次のように行います。

    ```shell-session
    # bedrock_server.sh
    ```

    この場合は、[マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)及び[プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)に同意するかをインタラクティブに聞かれます。
    同意する場合は `yes` を入力してください。

    [マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)及び[プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)に同意していて、インタラクティブに聞かれたくない場合には次のように実行することが可能です。

    ```shell-session
    # bedrock_server.sh --i-agree-to-meula-and-pp
    ```
4.  `manage_containers.sh` を実行します。

    このスクリプトは、 `containers.lst` に記載された情報をもとにして bedrock-server のコンテナを作成・起動・停止・再作成を行います。

    実行は、 `root` で次のように行います。

    ```shell-session
    # manage_containers.sh
    ```
5.  [オプション] cron を設定します。

    cron を設定することで、 Docker Image の最新化及び各コンテナへの適用を自動化することができます。

    例えば、次のような cron エントリを `/etc/cron.d/docker-bedrock` として作成すると、毎朝4時に bedrock-server の更新チェックと、必要があればコンテナの更新作業が自動的に行われます。

   ```
   00 4 * * * root /path/to/docker-bedrock/bedrock_server.sh --i-agree-to-meula-and-pp && /path/to/docker-bedrock/manage_containers.sh
   ```

### Connectiong

## Authors

## License
