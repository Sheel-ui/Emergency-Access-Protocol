// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/Setup.sol";

struct Pool {
    bool isSet;
    uint avlFunds;
    uint lockedFunds;
}

struct Doctor {
    string d_uid;
    string h_uid;
}

struct DecryptKey {
    string p_uid;
    string key;
}

struct Hospital {
    string d_uid;
    string h_uid;
    address wallet;
    Pool pool;
}

struct Patient {
    string p_uid;
    address wallet;
    Pool pool;
}

struct Vote {
    string h_uid;
    string p_uid;
    uint dsCount;
    uint xCount;
    uint yCount;
    string[] recipients;
    uint pool;
}

interface ISetup {
    function getDecryptKey(string memory p_uid) external returns (string memory);
    function verifyPatient(string memory p_uid) external returns (bool) ;
    function getPool(string memory h_uid,string memory p_uid) external returns (Pool memory);
    function verifyHospital(address  addr) external returns (bool);
    function getPatient(string memory uid) external returns (Patient memory);
    function getPatient(address addr) external returns (Patient memory);
    function getHospital(address addr) external returns (Hospital memory);
    function getHospital(string memory uid) external returns (Hospital memory);
    function getRecipientHospitals(string memory uid) external returns (string[] memory);
    function creditHospitalAvlFunds(string memory uid, uint amount) external;
    function creditPatientAvlFunds(string memory uid, uint amount) external;
    function creditHospitalLockedFunds(string memory uid, uint amount) external;
    function creditPatientLockedFunds(string memory uid, uint amount) external;
    function debitHospitalAvlFunds(string memory uid, uint amount) external;
    function debitPatientAvlFunds(string memory uid, uint amount) external;
    function debitHospitalLockedFunds(string memory uid, uint amount) external;
    function debitPatientLockedFunds(string memory uid, uint amount) external;
    function uploadVote(string memory h_uid,string memory p_uid, string[] memory recipients, uint) external;
    function getVote(string memory h_uid,string memory p_uid) external returns (Vote memory);
}

contract EAP {
    
    address setupAddr;
    uint incentive = 10;


    constructor(address _setupAddr){
        setupAddr = _setupAddr;
    }

    function compare(string memory str1, string memory str2) public pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function pledge() payable public returns (bool) {
        Hospital memory h = ISetup(setupAddr).getHospital(msg.sender);
        Patient memory p = ISetup(setupAddr).getPatient(msg.sender);
        if(compare(h.h_uid, "") && compare(p.p_uid, "")){
            payable(msg.sender).transfer(msg.value);
            return false;
        }
        if(!compare(h.h_uid, "")){
            ISetup(setupAddr).creditHospitalAvlFunds(h.h_uid,msg.value);
        }
        if(!compare(p.p_uid, "")){
            ISetup(setupAddr).creditPatientAvlFunds(p.p_uid,msg.value);
        }
        return true;
    }

    function initiateEAP(string memory h_uid, string memory p_uid) public returns (string memory) {
        // verify hospital membership - hospital pool
        // verify patient membership - patient membership
        // verify hospital pool > patient pool

        if(!ISetup(setupAddr).verifyHospital(msg.sender) || !ISetup(setupAddr).verifyPatient(p_uid)) {
            return "";
        }

        Pool memory pool = ISetup(setupAddr).getPool( h_uid, p_uid);
        if(!pool.isSet){
            return "";
        }

        // get ids of recipient hospitals
        string[] memory recipientIDs = ISetup(setupAddr).getRecipientHospitals(h_uid);


        // debit patient available funds and hospital available funds
        uint patientPool = ISetup(setupAddr).getPatient(p_uid).pool.avlFunds;
        ISetup(setupAddr).debitPatientAvlFunds(p_uid,patientPool);
        ISetup(setupAddr).debitHospitalAvlFunds(h_uid,patientPool);

        // return recipientIDs[1];

        uint totalPool = 2*patientPool;
        uint transferAmt = totalPool/recipientIDs.length;

        // credit transfer amount to hospitals
        for(uint i=0;i<recipientIDs.length;i++){
            ISetup(setupAddr).creditHospitalLockedFunds(recipientIDs[i],transferAmt);
        }

        // return decrypt key to caller
        string memory key = ISetup(setupAddr).getDecryptKey(p_uid);

        // generate voting instance on IPFS
        ISetup(setupAddr).uploadVote(h_uid,p_uid, recipientIDs, patientPool);

        return key;

    }

    function terminateEAP(string memory h_uid, string memory p_uid) public {
        Vote memory vote = ISetup(setupAddr).getVote(h_uid,p_uid);
        uint numRecipients = vote.recipients.length;
        uint majorityCount = numRecipients/2 + 1;
        uint transferAmt = 2*vote.pool/numRecipients;
        uint commission = transferAmt*incentive/100;
        uint returnAmt =  (transferAmt-commission)*numRecipients;
        uint hospitalReturnAmt = vote.pool*(100+incentive)/100;
        uint patientReturnAmt = returnAmt-hospitalReturnAmt;
        
        if(vote.yCount>=majorityCount){
            if(vote.dsCount>=majorityCount){
                // decuct commission and return Hospital and Patient stake
                for(uint i=0;i<numRecipients;i++){
                    ISetup(setupAddr).debitHospitalLockedFunds(vote.recipients[i],transferAmt);
                    ISetup(setupAddr).creditHospitalAvlFunds(vote.recipients[i],commission);
                }
                ISetup(setupAddr).creditHospitalAvlFunds(h_uid,hospitalReturnAmt);
                ISetup(setupAddr).creditPatientAvlFunds(p_uid,patientReturnAmt);
            } else{
                // both lose
                for(uint i=0;i<numRecipients;i++){
                    ISetup(setupAddr).debitHospitalLockedFunds(vote.recipients[i],transferAmt);
                    ISetup(setupAddr).creditHospitalAvlFunds(vote.recipients[i],transferAmt);
                }
            }
        } else {
            // only return patient money
            for(uint i=0;i<numRecipients;i++){
                ISetup(setupAddr).debitHospitalLockedFunds(vote.recipients[i],transferAmt);
                ISetup(setupAddr).creditHospitalAvlFunds(vote.recipients[i],transferAmt/2);
            }
            ISetup(setupAddr).creditPatientAvlFunds(p_uid,transferAmt*numRecipients/2);
        }
    }

}