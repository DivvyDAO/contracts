/*
We are starting from a simple identity contract supporting KYC using hashes computed off chain, e.g.

sha-1(NAME/GIVENNAMES/DATEOFBIRTH/PLACEOFBIRTH/NATIONALIY/EMAIL/ADDRESS1/ADDRESS2/ADDRESS3/RANDOM)

Specific factors to be hashed in identity hash for RChain is TBD. No identity factors are exposed on the blockchain.

For rchain membership we will need claimed and verified mappings and may want to use encrypted rather than hashed credentials. 

Use case using hashes: 
1. a membership request is made off chain by supplying rhain with their identity factors kept off chain. (google form?)
2. The hashed identity with a random string at the end is emailed to the user verifying email address.
3. The user requests membership paying 1 eth to become a claimed identity giving the hash of their identity factors they received by email from an ethereum address they own..
4. Requests are handled manually and then registered on the blockchain
5. a random key is sent to the user by postal mail offline.
6. An encrypted value by that key is sent to the contract and set in the code mapping.
7. When the user receives the key by mail they invoke a validator method in the contract which attempts to decode the verification string and conditionally adds the ethereum address as a corroboration of the mailing address and email to the verified mapping.
8. The contract owner (rchain) can revoke a corroboration. Later, in the case of rejection of a membership request, the eth should be returned returned if it can be done safely. Returning the eth offline is safer.
*/
// work in progress, starting from a simple solidity example, comment and suggest edits.
// TODO make Owned?
contract MemberIdentityRegistry {

    address owner = msg.sender;
    address wallet; // wallet to receive membership fees
    mapping(address => mapping(bytes32 => uint256)) verified;
    mapping(address => mapping(bytes32 => uint256)) claimed;  
    mapping(address => mapping(bytes32 => uint256)) code;
    mapping(address => address) uPortAddress; // future use
    
    event Registered(uint256 hash);
    event Verified(uint256 hash);

    function claimIdHash(bytes32 factor, uint256 hash) {
        // receive eth coop membership fee
	    if(msg.value != 1 ether) throw;
	    if ( ! wallet.send(msg.value) ) throw;
        claimed[msg.sender][factor] = hash;
        Registered(hash);
    }

    function verifyCode(bytes32 factor,uint256 key) {
        uint256 encrypted = code[msg.sender];
        // TODO decode encrypted with key better than product of primes
        bool decoded = encrypted == (key % 1000000) * (key/1000000);
        if ( decoded ) {
            int256 hash = claimed[msg.sender][factor];
            verified[msg.sender][factor] = hash;
            verified[msg.sender]["email"] = hash;
            Verified(hash);
            return true;
        }
        return false;
    }

    function setCode(address who, int256 encrypted) {
        if(owner != msg.sender) throw;
        code[who] = encrypted;
    }

    function verifyIdentity(address who,bytes32 factor, uint256 hash) constant returns(bool) {
        return verified[who][factor] == hash;
    }
    function bringuPort(address uPortId) {   // for future
        // TODO verify address belongs to uPortId
   // corroborate address in uPort ID
        uPortAddress[msg.sender] = uPortId;
    }

    function revoke(bytes32 factor,address who) {
        if(owner != msg.sender) throw;
        delete verified[who][factor];
    }
    function revokeMyId(bytes32 factor) { 
       delete verified[factor][msg.sender];
    }
    function revokeAll(bytes32 factor, address who) {
        if(owner != msg.sender) throw;
        delete verified[who];
    }
    function revokeAllMyId() { 
       delete verified[msg.sender];
    }
}