// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FinanceControl {

    address public owner;
        
    mapping (address => uint) public payments;

    event regPay(address _from, uint256 _amount);
    event addBalance(address _user, uint256 _amount);
    event withdraw(address _to, uint256 _amount);

    constructor() {
        owner = msg.sender;
    }

    // Структура для хранения информации о пользователе
    struct user {
        address userAddress; 
        uint256 balance;
    }

    //массив пользователей типа user
    user[] public users;


    // функция перевода средств на другой кошелёк
    function pay() public payable {
        payments[msg.sender] = msg.value;
        emit regPay(msg.sender, msg.value);
        emit addBalance(msg.sender, msg.value);
    }


    // функция проверки баланса с выводом значения uint256
    function CheckBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // функция вывода средств с аккаунта
    function withdrawAll(address payable _to, uint _amount) public {
        require(_amount <= address(this).balance, "Insufficient balance"); // проверка на наличие введённой суммы
        require(_amount > 0, "withdrawAll amount must be greater than 0"); // 
        payable(msg.sender).transfer(_amount);
        emit withdraw(_to, _amount);(msg.sender, _amount); 
    }


}