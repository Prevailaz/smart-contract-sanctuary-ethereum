//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract AccountRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _INITIAL_MODULE_BUNDLE = 0x0831dd3d62fF9418C8bd749A4D67c9F47d5FdFe5;
    address private constant _ACCOUNT_TOKEN_MODULE = 0x188E9dB1F3Da57b6cea137039aaB3aEd7d91139e;

    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x624bd96d) {
                    if lt(sig,0x35eb2824) {
                        switch sig
                        case 0x01ffc9a7 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.supportsInterface()
                        case 0x06fdde03 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.name()
                        case 0x081812fc { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.getApproved()
                        case 0x095ea7b3 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.approve()
                        case 0x1627540c { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.nominateNewOwner()
                        case 0x18160ddd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.totalSupply()
                        case 0x23b872dd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.transferFrom()
                        case 0x2f745c59 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.tokenOfOwnerByIndex()
                        leave
                    }
                    switch sig
                    case 0x35eb2824 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.isOwnerModuleInitialized()
                    case 0x3659cfe6 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.upgradeTo()
                    case 0x392e53cd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.isInitialized()
                    case 0x40c10f19 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.mint()
                    case 0x42842e0e { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.safeTransferFrom()
                    case 0x4f6ccce7 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.tokenByIndex()
                    case 0x53a47bb7 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.nominatedOwner()
                    leave
                }
                if lt(sig,0xa22cb465) {
                    switch sig
                    case 0x624bd96d { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.initializeOwnerModule()
                    case 0x6352211e { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.ownerOf()
                    case 0x70a08231 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.balanceOf()
                    case 0x718fe928 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.renounceNomination()
                    case 0x79ba5097 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.acceptOwnership()
                    case 0x8da5cb5b { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.owner()
                    case 0x95d89b41 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.symbol()
                    leave
                }
                switch sig
                case 0xa22cb465 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.setApprovalForAll()
                case 0xa6487c53 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.initialize()
                case 0xaaf10f42 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.getImplementation()
                case 0xb88d4fde { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.safeTransferFrom()
                case 0xc7f62cda { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.simulateUpgradeTo()
                case 0xc87b56dd { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.tokenURI()
                case 0xe985e9c5 { result := _ACCOUNT_TOKEN_MODULE } // AccountTokenModule.isApprovedForAll()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}