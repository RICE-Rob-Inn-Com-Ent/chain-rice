// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceFeedConsumer
 * @notice Example contract for consuming Chainlink Price Feeds
 */
contract PriceFeedConsumer {
    AggregatorV3Interface internal ethUsdPriceFeed;
    AggregatorV3Interface internal btcUsdPriceFeed;
    AggregatorV3Interface internal linkUsdPriceFeed;

    /**
     * Network: Ethereum Mainnet
     */
    constructor() {
        // ETH/USD Price Feed
        ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        // BTC/USD Price Feed
        btcUsdPriceFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);

        // LINK/USD Price Feed
        linkUsdPriceFeed = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }

    /**
     * @notice Get latest ETH/USD price
     * @return Latest price with 8 decimals
     */
    function getLatestETHPrice() public view returns (int) {
        (, /*uint80 roundID*/ int price, , , ) = /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
        ethUsdPriceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Get latest BTC/USD price
     * @return Latest price with 8 decimals
     */
    function getLatestBTCPrice() public view returns (int) {
        (, /*uint80 roundID*/ int price, , , ) = /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
        btcUsdPriceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Get price feed decimals
     */
    function getDecimals() public view returns (uint8) {
        return ethUsdPriceFeed.decimals();
    }

    /**
     * @notice Get historical price data
     */
    function getHistoricalPrice(uint80 roundId) public view returns (int) {
        (, /*uint80 id*/ int price, , , ) = /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
        ethUsdPriceFeed.getRoundData(roundId);
        return price;
    }

    /**
     * @notice Get price with USD conversion
     * @param amountInWei Amount in wei to convert
     * @return USD value with 18 decimals
     */
    function convertETHToUSD(uint256 amountInWei) public view returns (uint256) {
        int price = getLatestETHPrice();
        uint8 decimals = getDecimals();

        // price has 8 decimals, we want 18
        uint256 priceWith18Decimals = uint256(price) * 10 ** 10;

        // Calculate USD value
        return (amountInWei * priceWith18Decimals) / 1 ether;
    }
}
