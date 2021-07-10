pragma solidity ^0.4.26;

contract RandomNumber{
    address  beneficiary;
	address owner;
	uint64 maxNumber;
	uint64 normal;
	uint64 rare;
	uint64 ultimate;
	uint64 price;
	uint64 _numberedTicket;
	uint64 _numberOfTimes;
	uint256 allprice=0;

	struct lootBox{
        uint64 blockNumber;
        string phrase;
    }
    
	struct lootBoxes{
		uint64 numberedTicket;
		mapping(uint64 => lootBox)lootBoxes;
	}
	mapping(address => lootBoxes)requests;

	struct xoshiro256ss{
		uint64[4] state;
	}

	event TicketAndPhrase(uint64 numberedTicket,string phrase);
	event ReturnProbability(uint64 normal,uint64 rare,uint64 ultimate,uint64 maxNumber);
    
	constructor (uint64 price2,address _beneficiary)public{
	    beneficiary = _beneficiary;
	    price=price2;
		owner = msg.sender;
	}
    
	modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function setProbability(uint64 _normal,uint64 _rare,uint64 _ultimate,uint64 _max) isOwner public {
        normal = _normal;
        rare = _rare;
        ultimate = _ultimate;
        maxNumber = _max;
        emit ReturnProbability(normal,rare,ultimate,maxNumber);
    }
    
    function setPrice(uint64 _numberedTicket2,uint64 _numberOfTimes2)public payable{
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
    
    }
    
    
    
	function request(string _phrase) public {
		requests[msg.sender].lootBoxes[ requests[msg.sender].numberedTicket ].blockNumber = uint64(block.number);
		requests[msg.sender].lootBoxes[ requests[msg.sender].numberedTicket ].phrase = _phrase;
		requests[msg.sender].numberedTicket++;
		emit TicketAndPhrase(requests[msg.sender].numberedTicket-1,_phrase);
	}

   function getPrize() public view returns(bytes32,uint64[],string){
		uint64[] memory randomNumber = new uint64[](_numberOfTimes);
		xoshiro256ss memory oshiro;
		uint64 t;
		string memory prize;
		string memory usersPhrase = requests[msg.sender].lootBoxes[_numberedTicket].phrase;
		uint64 targetBlockNumber = requests[msg.sender].lootBoxes[_numberedTicket].blockNumber;
		bytes32 seedPhrase;

		if(_numberedTicket >= requests[msg.sender].numberedTicket){
			return(0,randomNumber,"Unknown Numbered Ticket");
		}else{
			targetBlockNumber++;
			if(targetBlockNumber >= block.number){
				return(0,randomNumber,"Not Mined");
			}else{
				seedPhrase = keccak256(abi.encodePacked(blockhash(targetBlockNumber),msg.sender,_numberedTicket,usersPhrase));
				

                oshiro.state[0]=uint64(seedPhrase);
                oshiro.state[1]=uint64(seedPhrase >> 64);
                oshiro.state[2]=uint64(seedPhrase >> 128);
                oshiro.state[3]=uint64(seedPhrase >> 192);

				for(uint i=0; i<_numberOfTimes; i++){
                	randomNumber[i] = (rol64(oshiro.state[1]*5,7) * 9)>>8; //下位ビットが線形なのでカット
					randomNumber[i] = randomNumber[i] % maxNumber + 1; //生成されうる乱数の最大値に合わせる

					t = oshiro.state[1] << 17;
					oshiro.state[2] ^= oshiro.state[0];
					oshiro.state[3] ^= oshiro.state[1];
					oshiro.state[1] ^= oshiro.state[2];
					oshiro.state[0] ^= oshiro.state[3];
					oshiro.state[2] ^= t;
					oshiro.state[3] = rol64(oshiro.state[3], 45);
	
					if(randomNumber[i] <= normal){
						prize = stringConnect(prize,"Normal,");
					}else if(randomNumber[i] > normal && randomNumber[i] <= rare){
                        prize = stringConnect(prize,"Rare,");
					}else if(randomNumber[i] > rare && randomNumber[i] <= ultimate){
						prize = stringConnect(prize,"Ultimate,");
					}
				}
				return(blockhash(targetBlockNumber),randomNumber,prize);
			}
		}
	}
    
    function rol64(uint64 _x,uint64 _k) private pure returns(uint64) {
		return (_x << _k) | (_x >> (64 - _k));
    }
    
    function stringConnect(string _prize,string _rarity) private pure returns(string){
        bytes memory bytePrize = bytes(_prize);
        bytes memory byteRarity = bytes(_rarity);
        bytes memory connect = new bytes(bytePrize.length + byteRarity.length);
        uint pointer=0;
        
        for(uint i=0; i<bytePrize.length; i++){
            connect[pointer++] = bytePrize[i];
        }
        for(uint j=0; j<byteRarity.length; j++){
            connect[pointer++] = byteRarity[j];
        }
        return (string(connect));
    }
    
    function returnPrice() public view returns (uint64){
        return price;
    }
    function auctionEnd() isOwner public {
    beneficiary.transfer(allprice);
    }
}
