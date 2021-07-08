pragma solidity ^0.4.26;

contract SingleNumber{
    address owner;
	uint64 maxNumber;
	uint64 numberedTicket;
    uint64 blockNumber;
    struct user{
        address name;
        string phrase;
    }
	mapping(uint64 => user)users;
    
    struct xoshiro256ss{
		uint64[4] state;
	}
	
    event eventBlock(uint64 blockNumber);
    event showTicket(string phrase,uint64 numberedTicket);
    event eventReset(uint64 numberedTicket,uint64 newMax);
    
	constructor (uint64 _max)public{
		owner = msg.sender;
		maxNumber = _max;
	}

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    
	function registInfo(string _phrase)public{
        users[numberedTicket].name = msg.sender;
        users[numberedTicket].phrase = _phrase;
        emit showTicket(_phrase,numberedTicket++);
	}
	
    function decideBlock()isOwner public{
        blockNumber = uint64(block.number);
        emit eventBlock(blockNumber);
    }
    
    function seeNumber(uint64 _numberedTicket)public view returns(bytes32,uint64,string){
		uint64 targetBlock=blockNumber+1;
        string memory usersPhrase;
		bytes32 seedPhrase;
		uint64 counter;
		uint64[] memory randomNumber = new uint64[](maxNumber+1);
        xoshiro256ss memory oshiro;
		uint64 t;
        bool[] memory check = new bool[](maxNumber+1); //default is false
        
        if(targetBlock >= block.number){
				return(0,0,"NotMined");
		}else{
            for(uint64 i; i<numberedTicket; i++){
                usersPhrase = stringConnect(usersPhrase,users[i].phrase);
            }
            seedPhrase = keccak256(abi.encodePacked (blockhash(targetBlock),usersPhrase) );
            oshiro.state[0]=uint64(seedPhrase);
            oshiro.state[1]=uint64(seedPhrase >> 64);
            oshiro.state[2]=uint64(seedPhrase >> 128);
            oshiro.state[3]=uint64(seedPhrase >> 192);

            while(counter<maxNumber){
                randomNumber[counter] = (rol64(oshiro.state[1]*5,7) * 9)>>8; //下位ビットカット
                randomNumber[counter] = randomNumber[counter] % maxNumber + 1; //の最大値に合わせる
                
                t = oshiro.state[1] << 17;
                oshiro.state[2] ^= oshiro.state[0];
                oshiro.state[3] ^= oshiro.state[1];
                oshiro.state[1] ^= oshiro.state[2];
                oshiro.state[0] ^= oshiro.state[3];
                oshiro.state[2] ^= t;
                oshiro.state[3] = rol64(oshiro.state[3], 45);

                if(check[randomNumber[counter]]==false){
                    check[randomNumber[counter]]=true;
                    counter++;
                }
            }
            return(blockhash(targetBlock),randomNumber[_numberedTicket],usersPhrase);
        }//elseEND
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
    
    function reset(uint64 _max) isOwner public {
        numberedTicket = 0;
        maxNumber = _max;
        emit eventReset(numberedTicket,_max);
    }
    
}
