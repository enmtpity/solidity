pragma solidity ^0.4.26;

contract RandomNumber {
    address beneficiary;
    address owner;
    uint64 maxNumber;
    uint64 normal;
    uint64 rare;
    uint64 ultimate;
    uint64 quantity1;
    uint64 quantity2;
    uint64 quantity3;
    uint64 quantity11;
    uint64 quantity22;
    uint64 quantity33;
    uint64 price;
    uint64 price1;
    uint64 price2;
    uint64 price3;

    uint256 allprice = 0;

    struct lootBox {
        uint64 blockNumber;
        string phrase;
        string prize5;
    }

    struct lootBoxes {
        uint64 numberedTicket;
        mapping(uint64 => lootBox) lootBoxes;
    }
    mapping(address => lootBoxes) requests;

    struct xoshiro256ss {
        uint64[4] state;
    }

    event TicketAndPhrase(uint64 numberedTicket, string phrase);
    event ReturnProbability(
        uint64 normal,
        uint64 rare,
        uint64 ultimate,
        uint64 maxNumber
    );

    constructor(address _beneficiary) public {
        beneficiary = _beneficiary;
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function setProbability(
        uint64 _normal,
        uint64 _rare,
        uint64 _ultimate,
        uint64 _quantity1,
        uint64 _quantity2,
        uint64 _quantity3,
        uint64 _price1,
        uint64 _price2,
        uint64 _price3
    ) public isOwner {
        normal = _normal;
        rare = _rare;
        ultimate = _ultimate;
        quantity1 = _quantity1;
        quantity2 = _quantity2;
        quantity3 = _quantity3;
        quantity11=_quantity1;
        quantity22=_quantity2;
        quantity33=_quantity3;
        price1 = _price1;
        price2 = _price2;
        price3 = _price3;
        maxNumber =
            normal *
            quantity1 +
            rare *
            quantity2 +
            ultimate *
            quantity3;
        price = price1 * quantity1 + price2 * quantity2 + price3 * quantity3;
        emit ReturnProbability(normal, rare, ultimate, maxNumber);
    }

    /* function setPrice(uint64 _numberedTicket2,uint64 _numberOfTimes2)public payable{
        	require(
                   msg.value > price*_numberOfTimes2,
                    "There already is a higher bid."
                   );
            require(
                _numberedTicket2 < requests[msg.sender].numberedTicket,
                "Unknown Numbered Ticket"
                );
        
		    
            _numberedTicket=_numberedTicket2;
            _numberOfTimes=_numberOfTimes2;
            allprice=allprice+msg.value;
    
    }*/

    function request(string _phrase) public {
        requests[msg.sender]
        .lootBoxes[requests[msg.sender].numberedTicket]
        .blockNumber = uint64(block.number);
        requests[msg.sender]
        .lootBoxes[requests[msg.sender].numberedTicket]
        .phrase = _phrase;
        requests[msg.sender].numberedTicket++;
        emit TicketAndPhrase(requests[msg.sender].numberedTicket - 1, _phrase);
    }

    function getPrize(uint64 _numberedTicket, uint64 _numberOfTimes)
        public
        payable
    {
        uint64[] memory randomNumber = new uint64[](_numberOfTimes);
        xoshiro256ss memory oshiro;
        uint64 t;
        string memory prize;
        string memory usersPhrase = requests[msg.sender]
        .lootBoxes[_numberedTicket]
        .phrase;
        uint64 targetBlockNumber = requests[msg.sender]
        .lootBoxes[_numberedTicket]
        .blockNumber;
        bytes32 seedPhrase;

        require(
            msg.value > price/(quantity1+quantity2+quantity3) * _numberOfTimes,
            "There already is a higher bid."
        );
        allprice = allprice + msg.value;

        require(
            _numberedTicket < requests[msg.sender].numberedTicket,
            "Unknown Numbered Ticket"
        );

        targetBlockNumber++;
        require(targetBlockNumber < block.number, "Not Mined");
        seedPhrase = keccak256(
            abi.encodePacked(
                blockhash(targetBlockNumber),
                msg.sender,
                _numberedTicket,
                usersPhrase
            )
        );

        oshiro.state[0] = uint64(seedPhrase);
        oshiro.state[1] = uint64(seedPhrase >> 64);
        oshiro.state[2] = uint64(seedPhrase >> 128);
        oshiro.state[3] = uint64(seedPhrase >> 192);

        for (uint256 i = 0; i < _numberOfTimes; i++) {
            randomNumber[i] = (rol64(oshiro.state[1] * 5, 7) * 9) >> 8; //下位ビットが線形なのでカット
            randomNumber[i] = (randomNumber[i] % maxNumber) + 1; //生成されうる乱数の最大値に合わせる

            t = oshiro.state[1] << 17;
            oshiro.state[2] ^= oshiro.state[0];
            oshiro.state[3] ^= oshiro.state[1];
            oshiro.state[1] ^= oshiro.state[2];
            oshiro.state[0] ^= oshiro.state[3];
            oshiro.state[2] ^= t;
            oshiro.state[3] = rol64(oshiro.state[3], 45);

            if (randomNumber[i] <= normal * quantity11) {
                quantity1 = quantity1 - 1;
                prize = stringConnect(prize, "Normal,");
            } else if (
                randomNumber[i] > normal * quantity11 &&
                randomNumber[i] <= normal * quantity11 + rare * quantity22
            ) {
                quantity2 = quantity2 - 1;
                prize = stringConnect(prize, "Rare,");
            } else if (
                randomNumber[i] > normal * quantity11 + rare * quantity22 &&
                randomNumber[i] <=
                normal * quantity11 + rare * quantity22 + ultimate * quantity33
            ) {
                quantity3 = quantity3 - 1;
                prize = stringConnect(prize, "Ultimate,");
            }
           
        }
        price = price1 * quantity1 + price2 * quantity2 + price3 * quantity3;
        requests[msg.sender].lootBoxes[_numberedTicket].prize5 = prize;
    }

    function getprize2(uint64 _numberedTicket) public view returns (string) {
        return requests[msg.sender].lootBoxes[_numberedTicket].prize5;
    }

    function rol64(uint64 _x, uint64 _k) private pure returns (uint64) {
        return (_x << _k) | (_x >> (64 - _k));
    }

    function stringConnect(string _prize, string _rarity)
        private
        pure
        returns (string)
    {
        bytes memory bytePrize = bytes(_prize);
        bytes memory byteRarity = bytes(_rarity);
        bytes memory connect = new bytes(bytePrize.length + byteRarity.length);
        uint256 pointer = 0;

        for (uint256 i = 0; i < bytePrize.length; i++) {
            connect[pointer++] = bytePrize[i];
        }
        for (uint256 j = 0; j < byteRarity.length; j++) {
            connect[pointer++] = byteRarity[j];
        }
        return (string(connect));
    }

    function returnPrice()
        public
        view
        returns (
            uint64,
            uint64,
            uint64,
            uint64,
            uint64,
            uint64,
            uint64
        )
    {
        return (price/(quantity1+quantity2+quantity3), quantity1, quantity2, quantity3,normal*quantity11*1000/maxNumber,
        rare*quantity22*1000/maxNumber,ultimate*quantity33*1000/maxNumber);
    }

    function auctionEnd() public isOwner {
        beneficiary.transfer(allprice);
    }
}
