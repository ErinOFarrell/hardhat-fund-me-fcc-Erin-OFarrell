// Get money from users
// Withdraw funds
// Set a minimum funding value in USD

// PRAGMA
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IMPORTS
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
import "hardhat/console.sol";

// INTERFACES

// LIBRARIES

// CONTRACTS
/**
 * @title A contract for crowd funding
 * @author Erin O'Farrell
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // TYPE DECLARATIONS
    using PriceConverter for uint256;

    // STATE VARIABLES
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    AggregatorV3Interface private s_priceFeed;

    // EVENTS
    event Funded(address indexed from, uint256 amount);

    // ERRORS
    error FundMe__NotOwner(); // its a good practice to name errors after the contract theyre in

    // MODIFIERS
    modifier onlyOwner() {
        //revert(msg.sender == i_owner, "Sender is not owner!");
        //revert(msg.sender == i_owner, NotOwner());
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // FUNCTIONS
    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough >:("
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000 wei
        // 18 decimals
        console.log("Funding contract...");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
        emit Funded(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        //revert(msg.sender == owner, "Sender is not owner!");
        /* starting index, ending index (as boolean), step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            // reset the msg.value
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        // msg.sender = address
        // payable(msg.sender) = payable address

        //3 ways to send native blockchain currency
        //-transfer
        //payable(msg.sender).transfer(address(this).balance); !!!>>typecaster<<!!!
        //-send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //revert(sendSuccess, "Send failed");
        //-call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings cant be in memory!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
