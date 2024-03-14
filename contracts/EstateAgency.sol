// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 < 0.9.0;

contract EstateAgency{

    enum EstateType { House, Flat, Loft }
    enum AdvertisementStatus { Opened, Closed }

    struct Estate{
        uint size;
        string estateAddress;
        address owner;
        EstateType esType;
        bool isActive;
        uint idEstate;
    }

    struct Advertisement{
        address owner;
        address buyer;
        uint price;
        uint idEstate;
        uint dateTime;
        AdvertisementStatus adStatus;
    }

    Estate[] public estates;
    Advertisement[] public ads;

    mapping(address => uint) public balances;

    event estateCreated(address owner, uint idEstate, uint dateTime, EstateType esType);
    event adCreated(address owner, uint idAd, uint dateTime, uint idEstate, uint price);
    event estateStatusChanged(address owner, uint dateTime, uint idEstate, bool isActive);
    event adStatusChanged(address owner, uint dateTime, uint idAd, uint idEstate, AdvertisementStatus adStatus);
    event fundsBack(address to, uint amount, uint dateTime);
    event estatePurchased(address adOwner, address buyer, uint idAd, uint idEstate, AdvertisementStatus adStatus, uint dateTime, uint price);

    modifier enoughValue(uint value, uint price) {
        require(value >= price, unicode"У вас недостаточно средств");
        _;
    }

    modifier onlyEstateOwner(uint idEstate) {
        require(estates[idEstate].owner == msg.sender, unicode"Вы не владелец данной недвижимости");
        _;
    }

    modifier onlyAdOwner(uint idAd) {
        require(ads[idAd].owner == msg.sender, unicode"Вы не владелец данной объявления");
        _;
    }

    modifier isActiveEstate(uint idEstate) {
        require(estates[idEstate].isActive, unicode"Данная недвижимость недоступна");
        _;
    }

    modifier isClosedAd(uint idAd) {
        require(ads[idAd].adStatus == AdvertisementStatus.Opened, unicode"Данное объявление закрыто");
        _;
    }

    function createEstate(uint size, string memory estateAddress, EstateType esType) public {
        require(size > 1, "Size must be greater than 1");
        estates.push(Estate(size, estateAddress, msg.sender, esType, true, estates.length + 1));
        emit estateCreated(msg.sender, estates.length, block.timestamp, esType);
    }

    function createAdvertisement(uint idEstate, uint price) public {
        require(estates[idEstate].owner == msg.sender, unicode"Только владелец недвижимости может создать объявление");
        require(estates[idEstate].isActive, unicode"Недвижимость должна быть активной");
        ads.push(Advertisement(msg.sender, address(0), price, idEstate, block.timestamp, AdvertisementStatus.Opened));
        emit adCreated(msg.sender, ads.length, block.timestamp, idEstate, price);
    }

    function updateEstateStatus(uint idEstate, bool newStatus) public onlyEstateOwner(idEstate){
        estates[idEstate].isActive = newStatus;
        emit estateStatusChanged(msg.sender, block.timestamp, idEstate, newStatus);
        if (!newStatus) {
            for (uint i = 0; i < ads.length; i++) {
                if (ads[i].idEstate == idEstate) {
                    ads[i].adStatus = AdvertisementStatus.Closed;
                    emit adStatusChanged(msg.sender, block.timestamp, i, idEstate, AdvertisementStatus.Closed);
                }
            }
        }
    }

    function updateAdvertisementStatus(uint idAd) public {
        uint idEstate = ads[idAd].idEstate;
        require(estates[idEstate].owner == msg.sender, unicode"Только владелец недвижимости может изменить статус объявления");
        require(estates[idEstate].isActive, unicode"Недвижимость должна быть активной");
        ads[idAd].adStatus = AdvertisementStatus.Closed;
        emit adStatusChanged(msg.sender, block.timestamp, idAd, idEstate, AdvertisementStatus.Closed);
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, unicode"Недостаточно средств");
        require(amount > 0, unicode"Введите сумму для вывода больше 0");
        payable(msg.sender).transfer(amount);
        balances[msg.sender] -= amount;
        emit fundsBack(msg.sender, amount, block.timestamp);
    }

    function buyEstate(uint idAd, uint price) public payable {
        require(idAd < ads.length, unicode"Ошибочный идентификатор объявления");
        Advertisement storage ad = ads[idAd];
        require(ad.adStatus == AdvertisementStatus.Opened, unicode"Объявление закрыто");
        require(msg.value >= price, unicode"У вас недостаточно средств");
        ad.adStatus == AdvertisementStatus.Closed;
        ad.buyer = msg.sender;
        address payable estateOwner = payable(estates[ad.idEstate].owner);
        estateOwner.transfer(msg.value);
        emit estatePurchased(ad.owner, msg.sender, idAd, ad.idEstate, ad.adStatus, block.timestamp, ad.price);
    }

    function getBalance() public view returns(uint){
        return balances[msg.sender];
    }

    function getAdvertisement() public view returns(Advertisement[] memory){
        return ads;
    }

    function getEstates() public view returns(Estate[] memory){
        return estates;
    }


}