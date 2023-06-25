// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// contract SimpleStorage{

//     uint256  myfavNo;
//     // uint256[] listFavNo;

//     mapping (string => uint256) public nameToNum;

//     struct Person {
//         uint256 favNo;
//         string name;
//     }

// //dynamic array
//     Person[] public listOfPeople;

//     // Person public pat = Person({favNo: 7, name: "Pat"});
//     // Person public marina = Person({favNo: 10, name: "Marina"});
//     // Person public dev = Person({favNo: 1, name: "Dev"});



//     function store(uint256 _favNo) public {
//         myfavNo = _favNo;
//     }

//     function retrive() public view returns (uint256) {
//         return myfavNo;
//     }

//     function addPerson(string memory _name, uint256 _favNo) public {
//         // Person memory newPerson = Person({name: _name, favNo: _favNo});
//         // listOfPeople.push(newPerson);

//         listOfPeople.push(Person({name: _name, favNo: _favNo}));
//         nameToNum[_name] = _favNo;
//     }
// }

// ########################################

pragma solidity ^0.8.18;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 myFavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    Person[] public listOfPeople;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        myFavoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return myFavoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

contract SimpleStorage2 {}

contract SimpleStorage3 {}

contract SimpleStorage4 {}
