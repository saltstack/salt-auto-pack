#!/bin/bash

# obtains token to authenticate for vault access, presumes vault, curl and jq installed on master
# user svc-builder, password is for example purpose only
# example address 'vault.aws.saltstack.net'
vault_address='10.1.50.149'
VAULT_ADDR="http://$vault_address:8200"
export VAULT_ADDR
vault_token=$(curl -s --request POST --data '{"password": "kAdLNTDt*ku7R9Y"}' $VAULT_ADDR/v1/auth/userpass/login/svc-builder| jq .auth.client_token)
vault status -address=$VAULT_ADDR
vault auth -address=$VAULT_ADDR $vault_token 

