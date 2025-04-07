# Dify Azure VM デプロイメント

このリポジトリは、AzureにDifyサーバーとWindowsジャンプボックスをデプロイするためのTerraformスクリプトを提供します。

## 前提条件

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0以上)
- [Azure CLI](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli) (最新版推奨)
- Azureアカウント (サブスクリプション権限が必要)

## セットアップと実行手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/dify-azureVM.git
cd dify-azureVM
```

### 2. Azureへのログイン

```bash
# Azureにログイン
az login

# 特定のテナントを使用する場合
az login --tenant <tenant-id>

# 使用するサブスクリプションを設定
az account set --subscription <subscription-id>
```

### 3. Terraformの実行

```bash
# Terraformの初期化
terraform init

# 実行計画の確認
terraform plan -var="tenant_id=<your-tenant-id>" -var="subscription_id=<your-subscription-id>"

# インフラストラクチャのデプロイ
terraform apply -var="tenant_id=<your-tenant-id>" -var="subscription_id=<your-subscription-id>"
```

### 4. リソースへのアクセス

Dify VMへのアクセス:
- WindowsジャンプボックスにAzure Bastionを使ってRDP接続
- WindowsジャンプボックスからDify VMにアクセス (プライベートIP: 10.0.10.x)
- DifyのWebインターフェースには http://<dify-private-ip> でアクセス可能

### 5. リソースの削除

```bash
terraform destroy -var="tenant_id=<your-tenant-id>" -var="subscription_id=<your-subscription-id>"
```

## デプロイされるリソース

- リソースグループ
- 仮想ネットワークとサブネット (Dify用、Windows用、Bastion用)
- ネットワークセキュリティグループ
- Dify VM (Ubuntu)
- Windows VM (ジャンプボックス)
- Azure Bastion

## カスタマイズ

`variables.tf` ファイルを編集することで、以下の設定をカスタマイズできます：

- VMサイズ
- サブネットアドレス空間
- VMユーザー名
- リソース名

## 注意事項

- このテンプレートはWindows VMのパスワードをハードコードしています。本番環境では適切なシークレット管理を使用してください。
- デプロイ後、Azure Bastionを使用してWindowsジャンプボックスに接続できます。