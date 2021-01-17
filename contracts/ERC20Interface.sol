pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

interface ERC20Interface {
    
    //Events
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);


    //Functions
    function transfer(address dest, uint amount) external returns(bool);
    function transferFrom(address dest, address src, uint amount) external returns(bool);
    function approve(address spender, uint amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint);
    function balanceOf(address owner) external view returns(uint);
}