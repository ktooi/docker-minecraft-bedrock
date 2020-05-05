# docker-minecraft-bedrock

このプロジェクトは、超簡単に Minecraft 統合版のサーバ (bedrock-server) を構築し、運用する為のものです。

このプロジェクトには次の特徴があります。

*   bedrock-server の更新やセーブデータのバックアップをスクリプト化することで、 bedrock-server を全自動で運用できる。
*   起動するコンテナ毎に、 bedrock-server のバージョンを指定できる。
*   bedrock-server のファイルを各利用者の環境でダウンロードし、 Docker Image をビルドすることで[マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)に適合する(bedrock-server の再頒布を行わない)。

## Getting Started

### Prerequisites

このプロジェクトを利用するためには、下記のソフトウェアやライブラリがセットアップされている必要があります。

```
docker
```

また、 bedrock-server を利用する為に、下記の利用規約にも同意する必要があります。

*   [マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)
*   [プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)

### Installing

1.  このプロジェクトをダウンロードもしくはクローンし、展開したディレクトリに移動します。
2.  Minecraft 統合版サーバの Docker Image を作成します。

    `bedrock_server.sh` を実行します。
    このスクリプトは最新版の bedrock-server-*.zip をダウンロードし、 Docker Image をビルドします。

    実行は `root` で次のように行います。

    ```shell-session
    # ./bedrock_server.sh
    ```

    この場合は、[マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)及び[プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)に同意するかをインタラクティブに聞かれます。
    同意する場合は `yes` を入力してください。

    [マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)及び[プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)に同意していて、インタラクティブに聞かれたくない場合には次のように実行することが可能です。

    ```shell-session
    # ./bedrock_server.sh --i-agree-to-meula-and-pp
    ```
3.  コンテナを定義し、 Minecraft 統合版サーバの起動を準備します。

    `containers.lst` ファイルを作成します。
    `containers.lst` ファイルは起動する bedrock-server のコンテナを定義するファイルです。
    1行につき1つのコンテナを示し、各行はタブ区切りで次のようにで記載します。

    ```
    <name>	<port>	<volume>	<image>
    ```

    *   &lt;name&gt; : コンテナ名です。後述する `env-files/*.env` のファイル名としても利用します。
    *   &lt;port&gt; : コンテナが待ち受けるポート番号(udp)です。
    *   &lt;volume&gt; : セーブデータ等を保存する Docker Volume の名前です。
    *   &lt;image&gt; : コンテナが利用する Docker Image の名前です。 `bedrock:1.14.32.1`, `bedrock:latest` のように指定します。
        *   利用可能なイメージやタグは次のコマンドで確認できます。

            ```shell-session
            # docker images bedrock
            REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
            bedrock             1.14.60.5           cef587589e72        2 weeks ago         1.53GB
            bedrock             latest              cef587589e72        2 weeks ago         1.53GB
            bedrock             1.14.32.1           9b4d35d2da38        5 weeks ago         309MB
            ```
        *   `bedrock:1.14.32.1` のように、特定のバージョンを指定した場合には、そのコンテナは指定したバージョンで動作し続けます。
        *   `bedrock:latest` と指定した場合には、そのコンテナは Docker Image が更新されるたびに `manage_containers.sh` により停止・再作成・起動され、常に最新版の bedrock-server で動作し続けます。

    e.g.,

    ```
    example-be	19132	example-be-volume	bedrock:latest
    ```
    他の例が必要な場合は、 [containers.lst.example](containers.lst.example) も参照してみてください。
4.  各コンテナの環境変数を定義します。

    `env-files/<name>.env` ファイルを作成します。
    `env-files/<name>.env` ファイルはコンテナの環境変数を定義するファイルです。
    `manage_containers.sh` 実行時に `docker run --env-file` の値として指定されます。
    ファイル名の `<name>` には `containers.lst` で定義したものを指定してください。

    利用可能なパラメータは [env-files/example.env](env-files/example.env) を参照してください。
5.  `containers.lst` の定義に則り、コンテナを起動します。

    `manage_containers.sh` を実行します。
    このスクリプトは、 `containers.lst` に記載された情報をもとにして bedrock-server のコンテナを作成・起動・停止・再作成を行います。

    実行は、 `root` で次のように行います。

    ```shell-session
    # ./manage_containers.sh
    ```
    ここまでの手順で Minecraft 統合版サーバが起動され、 Minecraft のクライアントから接続できるようになりました。
6.  [オプション] Minecraft 統合版サーバの自動更新を設定します。

    cron を設定することで、 Docker Image の最新化及び各コンテナへの適用を自動化することができます。

    例えば、次のような cron エントリを `/etc/cron.d/docker-minecraft-bedrock` として作成すると、毎朝4時に bedrock-server の更新チェックと、必要があればコンテナの更新作業が自動的に行われます。

   ```
   0 4 * * * root /path/to/docker-minecraft-bedrock/bedrock_server.sh --i-agree-to-meula-and-pp && /path/to/docker-minecraft-bedrock/manage_containers.sh
   ```

### Connecting

## Authors

*   **Kodai Tooi** [GitHub](https://github.com/ktooi), [Qiita](https://qiita.com/ktooi)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
