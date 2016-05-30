# これは何か

OSS推進フォーラムの研究テーマで作成したAzure用EventHub/IoTHub用データ送信プログラムです。

# IoTHubの利用方法について

1. `npm install -g iothub-explorer@latest`で`iothub-explorer`をインストールしてください。
1. Azureポータルからiothubownerポリシーの接続文字列を取得します。
1. `iothub-explorer "上記で得た接続文字列" create 機器名 --connection-string`を実行します。機器名は任意のものでOK。
1. `iothub-explorer`の結果得られた`connectionString`を環境変数`CONNECTION_STRING`に設定して`iothub/cruby_iothub.rb`を実行。このとき、`connectionString`は二重引用符で囲んでおく必要あり。
