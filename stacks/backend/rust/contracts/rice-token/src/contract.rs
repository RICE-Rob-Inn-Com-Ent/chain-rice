#[cfg(test)]
mod tests {
    use cosmwasm_std::testing::{mock_dependencies, mock_env, mock_info};
    use cosmwasm_std::{coins, from_json, Addr};

    use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg, Config, TokenInfo};

    const ADMIN: &str = "admin";
    const USER: &str = "user";

    #[test]
    fn test_instantiate() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let info = mock_info(ADMIN, &coins(1000, "token"));

        let msg = InstantiateMsg {
            name: "Chain Rice Token".to_string(),
            symbol: "CRT".to_string(),
            decimals: 6,
            initial_supply: 1000000,
        };

        let res = crate::instantiate(deps.as_mut(), env, info, msg).unwrap();
        assert_eq!(0, res.messages.len());

        // Verify config was stored correctly
        let config: Config = from_json(
            &crate::query(deps.as_ref(), mock_env(), QueryMsg::GetConfig {}).unwrap(),
        )
        .unwrap();

        assert_eq!(config.name, "Chain Rice Token");
        assert_eq!(config.symbol, "CRT");
        assert_eq!(config.decimals, 6);
        assert_eq!(config.total_supply, 1000000);
        assert_eq!(config.owner, Addr::unchecked(ADMIN));

        // Verify token info was stored correctly
        let token_info: TokenInfo = from_json(
            &crate::query(deps.as_ref(), mock_env(), QueryMsg::GetTokenInfo {}).unwrap(),
        )
        .unwrap();

        assert_eq!(token_info.total_supply, 1000000);
        assert_eq!(token_info.minted, 1000000);
    }

    #[test]
    fn test_mint_tokens() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let info = mock_info(ADMIN, &coins(1000, "token"));

        // First instantiate
        let init_msg = InstantiateMsg {
            name: "Chain Rice Token".to_string(),
            symbol: "CRT".to_string(),
            decimals: 6,
            initial_supply: 1000000,
        };

        crate::instantiate(deps.as_mut(), env.clone(), info.clone(), init_msg).unwrap();

        // Then mint
        let mint_msg = ExecuteMsg::Mint {
            to: USER.to_string(),
            amount: 500000,
        };

        let res = crate::execute(deps.as_mut(), env, info, mint_msg).unwrap();
        assert_eq!(0, res.messages.len());

        // Verify token info was updated
        let token_info: TokenInfo = from_json(
            &crate::query(deps.as_ref(), mock_env(), QueryMsg::GetTokenInfo {}).unwrap(),
        )
        .unwrap();

        assert_eq!(token_info.total_supply, 1500000);
        assert_eq!(token_info.minted, 1500000);
    }

    #[test]
    fn test_burn_tokens() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let info = mock_info(ADMIN, &coins(1000, "token"));

        // First instantiate
        let init_msg = InstantiateMsg {
            name: "Chain Rice Token".to_string(),
            symbol: "CRT".to_string(),
            decimals: 6,
            initial_supply: 1000000,
        };

        crate::instantiate(deps.as_mut(), env.clone(), info.clone(), init_msg).unwrap();

        // Then burn
        let burn_msg = ExecuteMsg::Burn {
            from: ADMIN.to_string(),
            amount: 200000,
        };

        let res = crate::execute(deps.as_mut(), env, info, burn_msg).unwrap();
        assert_eq!(0, res.messages.len());

        // Verify token info was updated
        let token_info: TokenInfo = from_json(
            &crate::query(deps.as_ref(), mock_env(), QueryMsg::GetTokenInfo {}).unwrap(),
        )
        .unwrap();

        assert_eq!(token_info.total_supply, 800000);
        assert_eq!(token_info.minted, 800000);
    }

    #[test]
    fn test_unauthorized_mint() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let admin_info = mock_info(ADMIN, &coins(1000, "token"));
        let user_info = mock_info(USER, &coins(1000, "token"));

        // First instantiate as admin
        let init_msg = InstantiateMsg {
            name: "Chain Rice Token".to_string(),
            symbol: "CRT".to_string(),
            decimals: 6,
            initial_supply: 1000000,
        };

        crate::instantiate(deps.as_mut(), env.clone(), admin_info, init_msg).unwrap();

        // Try to mint as non-owner
        let mint_msg = ExecuteMsg::Mint {
            to: USER.to_string(),
            amount: 500000,
        };

        let res = crate::execute(deps.as_mut(), env, user_info, mint_msg);
        assert!(res.is_err());
    }

    #[test]
    fn test_update_owner() {
        let mut deps = mock_dependencies();
        let env = mock_env();
        let info = mock_info(ADMIN, &coins(1000, "token"));

        // First instantiate
        let init_msg = InstantiateMsg {
            name: "Chain Rice Token".to_string(),
            symbol: "CRT".to_string(),
            decimals: 6,
            initial_supply: 1000000,
        };

        crate::instantiate(deps.as_mut(), env.clone(), info.clone(), init_msg).unwrap();

        // Update owner
        let update_msg = ExecuteMsg::UpdateOwner {
            new_owner: USER.to_string(),
        };

        let res = crate::execute(deps.as_mut(), env, info, update_msg).unwrap();
        assert_eq!(0, res.messages.len());

        // Verify config was updated
        let config: Config = from_json(
            &crate::query(deps.as_ref(), mock_env(), QueryMsg::GetConfig {}).unwrap(),
        )
        .unwrap();

        assert_eq!(config.owner, Addr::unchecked(USER));
    }
}
