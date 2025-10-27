region="eu-west-2"
bucket="bb2-alpha-tfstate"
key="ddb-integration.tfstate"
encrypt="true"
use_lockfile="true"
assume_role = {
    role_arn="arn:aws:iam::521333308695:role/tfstate-mgnt-role-ddb-integration-alpha"
    session_name="ddb-integration-alpha"
}
