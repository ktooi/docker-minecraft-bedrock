[![TestDownload](https://github.com/ktooi/docker-minecraft-bedrock/workflows/TestDownload/badge.svg)](https://github.com/ktooi/docker-minecraft-bedrock/actions?query=workflow%3ATestDownload+branch%3Amain)

# docker-minecraft-bedrock

このプロジェクトは、 Docker がインストールされた Linux サーバ上で、超簡単に Minecraft 統合版のサーバ (bedrock-server) を構築し、運用する為のものです。

このプロジェクトには次の特徴があります。

*   bedrock-server の更新やセーブデータのバックアップをスクリプト化することで、 bedrock-server を全自動で運用できる。
*   起動するコンテナ毎に、 bedrock-server のバージョンを指定したり、自動更新するよう設定できる。
*   bedrock-server のファイルを各利用者の環境でダウンロードし、 Docker Image をビルドすることで[マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)に適合する(bedrock-server の再頒布を行わない)。

## Getting Started

### Prerequisites

このプロジェクトを利用するためには、 Linux サーバ上で下記のソフトウェアやライブラリがセットアップされている必要があります。

```
docker
curl
```

動作確認を行っている環境は次の通りです。

*   Debian 9.13
*   Docker version 18.09.1

また、 bedrock-server を利用する為に、下記の利用規約にも同意する必要があります。

*   [マインクラフト エンドユーザーライセンス規約](https://account.mojang.com/terms)
*   [プライバシーポリシー](https://privacy.microsoft.com/ja-jp/privacystatement)

### Installing

1.  このプロジェクトを Linux サーバ上にて `git clone` もしくは tar.gz をダウンロードし、展開したディレクトリに移動します。
    *   git clone する場合

        ```shell-session
        # git clone https://github.com/ktooi/docker-minecraft-bedrock.git
        # cd docker-minecraft-bedrock
        ```

    *   tar.gz でダウンロードする場合

        ```shell-session
        # curl -L https://github.com/ktooi/docker-minecraft-bedrock/archive/refs/heads/master.tar.gz -o docker-minecraft-bedrock-master.tar.gz
        # cd docker-minecraft-bedrock-master
        ```

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
    *   &lt;image&gt; : コンテナが利用する Docker Image の名前です。 `bedrock:1.14.32.1`, `bedrock:1.14`, `bedrock:latest` のように指定します。
        *   利用可能なイメージやタグは次のコマンドで確認できます。

            ```shell-session
            # docker images bedrock
            REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
            bedrock             1.14.60.5           cef587589e72        2 weeks ago         1.53GB
            bedrock             latest              cef587589e72        2 weeks ago         1.53GB
            bedrock             1.14.32.1           9b4d35d2da38        5 weeks ago         309MB
            ```
        *   `bedrock:1.14.32.1` のように、特定のバージョンを指定した場合には、そのコンテナは指定したバージョンで動作し続けます。
        *   `bedrock:1.14` のように、マイナーバージョンまでを指定した場合には、そのコンテナは指定したマイナーバージョンの Docker Image が更新されるたびに `manage_containers.sh` により停止・再作成・起動され、そのマイナーバージョンの最新版の bedrock-server で動作し続けます。
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

### Addons

このプロジェクトは一部の Addon (Mod) に対応しています。具体的には次のタイプの Addon を利用できるはずです。

* resources

Addon を導入し、コンテナ上で動かしている Minecraft 統合版サーバに適用する手順は次の通りです。
例示では `LunaRTX Free 1.19.mcpack` を利用する場合の物を記載します。

1.  Addon をダウンロードし、このプロジェクトの `addons/` ディレクトリに配置します。

    ダウンロードした Addon (`*.mcpack`, `*.mcworld`) を `addons/` ディレクトリに配置してください。

    ```shell-session
    # ls -l addons/
    drwxr-xr-x 5 root root     4096 Feb 26 23:35  extracted
    -rw-r--r-- 1 root root 87438989 Feb 19 01:24 'LunaRTX Free 1.19.mcpack'
    ```
    ※ `extracted` ディレクトリは存在しない場合もあります。

2.  配置した Addon を展開します。

    `manage_containers.sh` を実行すると、配置した Addon を展開します。

    ```shell-session
    # bash ./manage_containers.sh
    ```
    展開された Addon は `addons/extracted/` ディレクトリ配下に存在します。

    ```shell-session
    # ls -l addons/extracted/resources/by-name/
    total 0
    lrwxrwxrwx 1 root root 57 Feb 26 21:45 'LunaRTX Free 1.19' -> ../by-uuid_ver/010c9a9a-1c7f-4710-8fe0-321031eb0754_0_0_1
    ```
3.  コンテナごとに `addons/<name>.addons` ファイルを作成します。

    `<name>` は `containers.lst` で指定したコンテナの名前です。
    有効にする Addon のファイルパスを、 `addons/extracted/` より下の部分から指定します。

    `example-be` にて `LunaRTX Free 1.19.mcpack` を有効にする場合は次のようになります。
    ```shell-session
    # vim addons/example-be.addons
    # cat addons/example-be.addons
    resources/by-name/LunaRTX Free 1.19
    ```
4.  コンテナを再起動します。

    `docker` コマンドを利用してコンテナを再起動します。

    ```shell-session
    # docker restart example-be
    ```

**■ 注意**

Addon の制約により、 Minecraft 統合版のバージョンを固定したい場合には、 `containers.lst` で `<image>` を指定する際に `bedrock:latest` ではなく `bedrock:w.x.y.z` もしくは `bedrock:w.x` 形式でバージョンを指定してください。

---

コンテナで動作している `entrypoint.sh` が古い場合、 Addon を利用できない場合があります。
コンテナの `entrypoint.sh` が古くなっているかは、次のコマンドで確認することができます。

```shell-session
# md5sum entrypoint.sh  # リポジトリ上の entrypoint.sh のハッシュ値を確認。
# docker exec <name> md5sum entrypoint.sh  # <name> で指定したコンテナ上の entrypoint.sh のハッシュ値を確認。
```

上記2つのコマンドの結果から、ハッシュ値が異なっている場合にはコンテナ上の `entrypoint.sh` が古くなっている可能性があります。

最新版の Minecraft 統合版のコンテナイメージを利用している場合は、次のコマンドでイメージを再ビルドし、コンテナを再作成することで Addon に対応できるようになります。

```shell-session
# bash ./bedrock_server.sh --force-build
# bash ./manage_containers.sh
```

## Authors

*   **Kodai Tooi** [GitHub](https://github.com/ktooi), [Qiita](https://qiita.com/ktooi)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
