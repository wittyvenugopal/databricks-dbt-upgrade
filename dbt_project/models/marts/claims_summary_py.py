# Python model: claims per triage outcome. Runs on Databricks serverless compute.
def model(dbt, session):
    dbt.config(
        materialized="table",
        submission_method="serverless_cluster",
        data_owner="claims_team",  # V2: custom key in config, must move under meta
    )
    return dbt.ref("fct_claims").groupBy("triage_outcome").count()
