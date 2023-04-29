// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Setup{

    string test ="test";

    constructor() {
        populate();
    }

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

    Patient[] public patients;
    Hospital[] public hospitals;
    Doctor[] public doctors;
    DecryptKey[] public decryptKeys;
    Vote[] public votes;

    function compare(string memory str1, string memory str2) public pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function populate() private {
        patients.push(Patient("p1",0xdD870fA1b7C4700F2BD7f44238821C26f7392148,Pool(true,0,0)));
        doctors.push(Doctor("d1","h1"));
        doctors.push(Doctor("d2","h2"));
        doctors.push(Doctor("d3","h3"));
        doctors.push(Doctor("d4","h4"));
        doctors.push(Doctor("d5","h5"));
        decryptKeys.push(DecryptKey("p1","abcd"));

        hospitals.push(Hospital(
            "d1",
            "h1",
            0x583031D1113aD414F02576BD6afaBfb302140225,
            Pool(true,0,0)
        ));

        hospitals.push(Hospital(
            "d2",
            "h2",
            0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,
            Pool(true,0,0)
        ));


        hospitals.push(Hospital(
            "d3",
            "h3",
            0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
            Pool(true,0,0)
        ));


        hospitals.push(Hospital(
            "d4",
            "h4",
            0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c,
            Pool(true,0,0)
        ));


        hospitals.push(Hospital(
            "d5",
            "h5",
            0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC,
            Pool(true,0,0)
        ));
    }

    function uploadVote(string memory h_uid,string memory p_uid, string[] memory recipients, uint pool) public {
        votes.push(Vote(h_uid,p_uid,0,0,0,recipients,pool));
    }    

    function incrementVote(string memory h_uid,string memory p_uid, bool ds, bool x, bool y) public {
        for(uint i=0;i<votes.length;i++){
            if(compare(votes[i].h_uid,h_uid) && compare(votes[i].p_uid,p_uid)){
                if(ds) votes[i].dsCount += 1;
                if(x) votes[i].xCount += 1;
                if(y) votes[i].yCount += 1;
                return;
            }
        }
    }        

    function getVote(string memory h_uid,string memory p_uid) public view returns (Vote memory){
        for(uint i=0;i<votes.length;i++){
            if(compare(votes[i].h_uid,h_uid) && compare(votes[i].p_uid,p_uid)){
                return votes[i];
            }
        }
        return Vote("","",0,0,0,new string[](0),0);
    }    


    function creditHospitalAvlFunds(string memory uid, uint amount) public{
        for(uint i=0;i<hospitals.length;i++){
            if(compare(hospitals[i].h_uid,uid)){
                hospitals[i].pool.avlFunds += amount;
            }
        }
    }

    function creditPatientAvlFunds(string memory uid, uint amount) public {
        for(uint i=0;i<patients.length;i++){
            if(compare(patients[i].p_uid,uid)){
                patients[i].pool.avlFunds += amount;
            }
        }
    }

    function creditHospitalLockedFunds(string memory uid, uint amount) public{
        for(uint i=0;i<hospitals.length;i++){
            if(compare(hospitals[i].h_uid,uid)){
                hospitals[i].pool.lockedFunds += amount;
            }
        }
    }

    function creditPatientLockedFunds(string memory uid, uint amount) public {
        for(uint i=0;i<patients.length;i++){
            if(compare(patients[i].p_uid,uid)){
                patients[i].pool.lockedFunds += amount;
            }
        }
    }

    function debitHospitalAvlFunds(string memory uid, uint amount) public{
        for(uint i=0;i<hospitals.length;i++){
            if(compare(hospitals[i].h_uid,uid)){
                hospitals[i].pool.avlFunds -= amount;
            }
        }
    }

    function debitPatientAvlFunds(string memory uid, uint amount) public {
        for(uint i=0;i<patients.length;i++){
            if(compare(patients[i].p_uid,uid)){
                patients[i].pool.avlFunds -= amount;
            }
        }
    }

    function debitHospitalLockedFunds(string memory uid, uint amount) public{
        for(uint i=0;i<hospitals.length;i++){
            if(compare(hospitals[i].h_uid,uid)){
                hospitals[i].pool.lockedFunds -= amount;
            }
        }
    }

    function debitPatientLockedFunds(string memory uid, uint amount) public {
        for(uint i=0;i<patients.length;i++){
            if(compare(patients[i].p_uid,uid)){
                patients[i].pool.lockedFunds -= amount;
            }
        }
    }

    function getPatient(string memory uid) public view returns (Patient memory) {
        for(uint i=0;i<patients.length;i++){
            if(compare(patients[i].p_uid,uid)){
                return patients[i];
            }
        }
        return Patient("",address(0),Pool(false,0,0));
    }

    function getPatient(address addr) public view returns (Patient memory) {
        for(uint i=0;i<patients.length;i++){
            if(patients[i].wallet==addr){
                return patients[i];
            }
        }
        return Patient("",address(0),Pool(false,0,0));
    }

    function getHospital(string memory uid) public view returns (Hospital memory) {
        for(uint i=0;i<hospitals.length;i++){
            if(compare(hospitals[i].h_uid,uid)){
                return hospitals[i];
            }
        }
        return Hospital("","",address(0),Pool(false,0,0));
    }

    function getHospital(address addr) public view returns (Hospital memory) {
        for(uint i=0;i<hospitals.length;i++){
            if(hospitals[i].wallet==addr){
                return hospitals[i];
            }
        }
        return Hospital("","",address(0),Pool(false,0,0));
    }

    function getDoctor(string memory uid) public view returns (Doctor memory) {
        for(uint i=0;i<doctors.length;i++){
            if(compare(doctors[i].d_uid,uid)){
                return doctors[i];
            }
        }
        return Doctor("","");
    }

    function getHospitals() public view returns (Hospital[] memory) {
        return hospitals;
    }

    function getDoctors() public view returns (Doctor[] memory) {
        return doctors;
    }

    function getPatients() public view returns (Patient[] memory) {
        return patients;
    }

    function getDecryptKey(string memory p_uid) public view returns (string memory) {
        for(uint i=0;i<decryptKeys.length;i++){
            if(compare(decryptKeys[i].p_uid,p_uid)){
                return decryptKeys[i].key;
            }
        }
        return "";
    }

    function getPool(string memory h_uid,string memory p_uid) public view returns (Pool memory) {
        // in actual practice this function will check h_uid associated with msg.sender.adress
        Hospital memory h = getHospital(h_uid);
        Patient memory p = getPatient(p_uid);

        if(h.pool.isSet && p.pool.isSet){
            if(h.pool.avlFunds>=p.pool.avlFunds){
                return p.pool;
            }
        }
        return Pool(false,0,0);
    }

    function verifyPatient(string memory p_uid) public view returns (bool) {
        for(uint i=0;i<patients.length;i++){
            if(compare(patients[i].p_uid,p_uid)){
                return true;
            }
        }
        return false;
    }

    function verifyHospital(address  addr) public view returns (bool) {
        for(uint i=0;i<hospitals.length;i++){
            if(hospitals[i].wallet==addr){
                return true;
            }
        }
        return false;
    }

    function getRecipientHospitals(string memory uid) public view returns (string[] memory){
        string[] memory uids = new string[](hospitals.length-1);
        uint idx = 0;
        for(uint i=0;i<hospitals.length;i++){
            if(!compare(hospitals[i].h_uid,uid)){
                uids[idx]=hospitals[i].h_uid;
                idx++;
            }
        }
        return uids;
    }

}