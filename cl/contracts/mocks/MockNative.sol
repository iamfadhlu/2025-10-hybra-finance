// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockNative is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function deposit() payable public {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        _burn(msg.sender, wad);
        msg.sender.transfer(wad);
    }

    receive() external payable {
        deposit();
    }
}