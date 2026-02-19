import os
from pathlib import Path
from dagster import Definitions, asset, define_asset_job, AssetSelection
from dagster_dbt import DbtCliResource, dbt_assets


# プロジェクトルートからの dbt_models へのパス
DBT_MODELS_DIR = Path(__file__).joinpath("..", "..", "dbt_models").resolve()

# dbtをアセットとして定義
@dbt_assets(manifest=DBT_MODELS_DIR / "target/manifest.json")
def my_dbt_assets(context, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()

# Pythonでのデータ処理（Rawデータ挿入を想定）の練習用アセット
@asset
def simple_python_asset():
    return "Hello Dagster!"

# Staging層だけの固まり
# dbt_project.yml で定義した階層構造（Group）をキーとする
staging_job = define_asset_job(
    name="run_staging_layer",
    selection=AssetSelection.groups("staging")
)

# Salesドメイン（staging/sales と intermediate/sales）だけの固まり
sales_domain_job = define_asset_job(
    name="run_sales_domain",
    selection=AssetSelection.groups("sales") | AssetSelection.groups("int_sales")
)

# 全体の定義
defs = Definitions(
    assets=[my_dbt_assets, simple_python_asset],
    jobs=[staging_job, sales_domain_job],
    resources={
        "dbt": DbtCliResource(project_dir=os.fspath(DBT_MODELS_DIR)),
    },
)