#!/usr/bin/env python3
"""
Script to add a validator to the genesis.json file.
"""
import json
import sys
import os

def add_validator_to_genesis(genesis_file, validator_key_file):
    """Add validator to genesis.json"""
    
    # Read the genesis file
    with open(genesis_file, 'r') as f:
        genesis = json.load(f)
    
    # Read the validator key file
    with open(validator_key_file, 'r') as f:
        validator_key = json.load(f)
    
    # Create validator object
    validator = {
        "address": validator_key["address"],
        "pub_key": validator_key["pub_key"],
        "power": "1000000000000",  # Much higher power to meet DefaultPowerReduction
        "name": "validator",
        "commission": "0.100000000000000000",
        "max_commission": "0.200000000000000000",
        "max_change_rate": "0.010000000000000000"
    }
    
    # Add validator to staking section
    if "staking" not in genesis["app_state"]:
        genesis["app_state"]["staking"] = {}
    
    if "validators" not in genesis["app_state"]["staking"]:
        genesis["app_state"]["staking"]["validators"] = []
    
    genesis["app_state"]["staking"]["validators"].append(validator)
    
    # Add delegation
    delegation = {
        "delegator_address": validator_key["address"],
        "validator_address": validator_key["address"],
        "shares": "1000000000000.000000000000000000"
    }
    
    if "delegations" not in genesis["app_state"]["staking"]:
        genesis["app_state"]["staking"]["delegations"] = []
    
    genesis["app_state"]["staking"]["delegations"].append(delegation)
    
    # Update last total power
    genesis["app_state"]["staking"]["last_total_power"] = "1000000000000"
    
    # Add account to auth
    if "auth" not in genesis["app_state"]:
        genesis["app_state"]["auth"] = {}
    
    if "accounts" not in genesis["app_state"]["auth"]:
        genesis["app_state"]["auth"]["accounts"] = []
    
    # Add base account
    account = {
        "@type": "/cosmos.auth.v1beta1.BaseAccount",
        "address": validator_key["address"],
        "pub_key": None,
        "account_number": "0",
        "sequence": "0"
    }
    
    genesis["app_state"]["auth"]["accounts"].append(account)
    
    # Add balance to bank
    if "bank" not in genesis["app_state"]:
        genesis["app_state"]["bank"] = {}
    
    if "balances" not in genesis["app_state"]["bank"]:
        genesis["app_state"]["bank"]["balances"] = []
    
    balance = {
        "address": validator_key["address"],
        "coins": [
            {
                "denom": "stake",
                "amount": "1000000000000"
            }
        ]
    }
    
    genesis["app_state"]["bank"]["balances"].append(balance)
    
    # Update supply
    if "supply" not in genesis["app_state"]["bank"]:
        genesis["app_state"]["bank"]["supply"] = []
    
    genesis["app_state"]["bank"]["supply"] = [
        {
            "denom": "stake",
            "amount": "1000000000000"
        }
    ]
    
    # Write the updated genesis file
    with open(genesis_file, 'w') as f:
        json.dump(genesis, f, indent=2)
    
    print(f"✅ Added validator {validator_key['address']} to genesis.json")
    print(f"   Validator power: 1000000000000")
    print(f"   Delegation: 1000000000000 shares")
    print(f"   Balance: 1000000000000 stake tokens")

if __name__ == "__main__":
    genesis_file = "blockchain-data/config/genesis.json"
    validator_key_file = "blockchain-data/config/priv_validator_key.json"
    
    if not os.path.exists(genesis_file):
        print(f"❌ Genesis file not found: {genesis_file}")
        sys.exit(1)
    
    if not os.path.exists(validator_key_file):
        print(f"❌ Validator key file not found: {validator_key_file}")
        sys.exit(1)
    
    add_validator_to_genesis(genesis_file, validator_key_file)
