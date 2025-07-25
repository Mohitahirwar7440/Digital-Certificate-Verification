// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    struct Certificate {
        string recipientName;
        string courseName;
        string issuingInstitution;
        uint256 issueDate;
        string certificateHash;
        bool isValid;
    }

    mapping(bytes32 => Certificate) public certificates;
    mapping(address => bool) public authorizedIssuers;
    mapping(address => uint256) public certificatesIssuedBy;
    mapping(address => bytes32[]) private certificatesByIssuer;

    address public owner;
    uint256 public totalCertificates;

    address[] private issuerList;

    event CertificateIssued(
        bytes32 indexed certificateId,
        string recipientName,
        string courseName,
        string issuingInstitution,
        uint256 issueDate
    );

    event CertificateRevoked(bytes32 indexed certificateId);
    event IssuerAuthorized(address indexed issuer);
    event IssuerRevoked(address indexed issuer);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Not an authorized issuer");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedIssuers[msg.sender] = true;
        issuerList.push(msg.sender);
    }

    function issueCertificate(
        string memory _recipientName,
        string memory _courseName,
        string memory _issuingInstitution,
        string memory _certificateHash
    ) public onlyAuthorizedIssuer returns (bytes32) {
        require(bytes(_recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(_courseName).length > 0, "Course name cannot be empty");
        require(bytes(_issuingInstitution).length > 0, "Institution name cannot be empty");
        require(bytes(_certificateHash).length > 0, "Certificate hash cannot be empty");

        bytes32 certificateId = keccak256(
            abi.encodePacked(
                _recipientName,
                _courseName,
                _issuingInstitution,
                block.timestamp,
                msg.sender
            )
        );

        require(certificates[certificateId].issueDate == 0, "Certificate already exists");

        certificates[certificateId] = Certificate({
            recipientName: _recipientName,
            courseName: _courseName,
            issuingInstitution: _issuingInstitution,
            issueDate: block.timestamp,
            certificateHash: _certificateHash,
            isValid: true
        });

        totalCertificates++;
        certificatesIssuedBy[msg.sender]++;
        certificatesByIssuer[msg.sender].push(certificateId);

        emit CertificateIssued(
            certificateId,
            _recipientName,
            _courseName,
            _issuingInstitution,
            block.timestamp
        );

        return certificateId;
    }

    function verifyCertificate(bytes32 _certificateId)
        public
        view
        returns (
            bool isValid,
            string memory recipientName,
            string memory courseName,
            string memory issuingInstitution,
            uint256 issueDate
        )
    {
        Certificate memory cert = certificates[_certificateId];
        return (
            cert.isValid && cert.issueDate > 0,
            cert.recipientName,
            cert.courseName,
            cert.issuingInstitution,
            cert.issueDate
        );
    }

    function revokeCertificate(bytes32 _certificateId) public onlyAuthorizedIssuer {
        require(certificates[_certificateId].issueDate > 0, "Certificate does not exist");
        require(certificates[_certificateId].isValid, "Certificate is already revoked");

        certificates[_certificateId].isValid = false;

        emit CertificateRevoked(_certificateId);
    }

    function authorizeIssuer(address _issuer) public onlyOwner {
        require(_issuer != address(0), "Invalid issuer address");
        require(!authorizedIssuers[_issuer], "Issuer already authorized");

        authorizedIssuers[_issuer] = true;
        issuerList.push(_issuer);

        emit IssuerAuthorized(_issuer);
    }

    function revokeIssuer(address _issuer) public onlyOwner {
        require(_issuer != owner, "Cannot revoke owner");
        require(authorizedIssuers[_issuer], "Issuer not found");

        authorizedIssuers[_issuer] = false;

        emit IssuerRevoked(_issuer);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function getCertificateCountByIssuer(address _issuer) public view returns (uint256) {
        return certificatesIssuedBy[_issuer];
    }

    function getCertificateHash(bytes32 _certificateId) public view returns (string memory) {
        require(certificates[_certificateId].issueDate > 0, "Certificate does not exist");
        return certificates[_certificateId].certificateHash;
    }

    function getAllCertificatesIssuedBy(address _issuer) public view returns (bytes32[] memory) {
        return certificatesByIssuer[_issuer];
    }

    function isAuthorizedIssuer(address _issuer) public view returns (bool) {
        return authorizedIssuers[_issuer];
    }

    function getCertificateDetails(bytes32 _certificateId) public view returns (Certificate memory) {
        require(certificates[_certificateId].issueDate > 0, "Certificate does not exist");
        return certificates[_certificateId];
    }

    function certificateExists(bytes32 _certificateId) public view returns (bool) {
        return certificates[_certificateId].issueDate > 0;
    }

    function transferCertificate(bytes32 _certificateId, string memory _newRecipientName) public onlyAuthorizedIssuer {
        require(certificates[_certificateId].issueDate > 0, "Certificate does not exist");
        require(certificates[_certificateId].isValid, "Certificate is not valid");
        require(bytes(_newRecipientName).length > 0, "New recipient name is empty");

        certificates[_certificateId].recipientName = _newRecipientName;
    }

    function getValidCertificateCountByIssuer(address _issuer) public view returns (uint256) {
        uint256 count = 0;
        bytes32[] memory certs = certificatesByIssuer[_issuer];
        for (uint256 i = 0; i < certs.length; i++) {
            if (certificates[certs[i]].isValid) {
                count++;
            }
        }
        return count;
    }

    function getCertificatesByCourse(address _issuer, string memory _courseName) public view returns (bytes32[] memory) {
        bytes32[] memory allCerts = certificatesByIssuer[_issuer];
        uint256 count = 0;

        for (uint256 i = 0; i < allCerts.length; i++) {
            if (
                keccak256(bytes(certificates[allCerts[i]].courseName)) ==
                keccak256(bytes(_courseName))
            ) {
                count++;
            }
        }

        bytes32[] memory filtered = new bytes32[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allCerts.length; i++) {
            if (
                keccak256(bytes(certificates[allCerts[i]].courseName)) ==
                keccak256(bytes(_courseName))
            ) {
                filtered[index++] = allCerts[i];
            }
        }

        return filtered;
    }

    function getAllAuthorizedIssuers() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < issuerList.length; i++) {
            if (authorizedIssuers[issuerList[i]]) {
                count++;
            }
        }

        address[] memory activeIssuers = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < issuerList.length; i++) {
            if (authorizedIssuers[issuerList[i]]) {
                activeIssuers[index++] = issuerList[i];
            }
        }

        return activeIssuers;
    }

    function getCertificatesByInstitution(string memory _institution) public view returns (bytes32[] memory) {
        uint256 totalMatches = 0;

        for (uint256 i = 0; i < issuerList.length; i++) {
            bytes32[] memory certs = certificatesByIssuer[issuerList[i]];
            for (uint256 j = 0; j < certs.length; j++) {
                if (
                    keccak256(bytes(certificates[certs[j]].issuingInstitution)) ==
                    keccak256(bytes(_institution))
                ) {
                    totalMatches++;
                }
            }
        }

        bytes32[] memory matches = new bytes32[](totalMatches);
        uint256 index = 0;

        for (uint256 i = 0; i < issuerList.length; i++) {
            bytes32[] memory certs = certificatesByIssuer[issuerList[i]];
            for (uint256 j = 0; j < certs.length; j++) {
                if (
                    keccak256(bytes(certificates[certs[j]].issuingInstitution)) ==
                    keccak256(bytes(_institution))
                ) {
                    matches[index++] = certs[j];
                }
            }
        }

        return matches;
    }

    // ✅ NEW FUNCTION ADDED BELOW
    function getCertificatesByRecipient(string memory _recipientName) public view returns (bytes32[] memory) {
        uint256 matchCount = 0;

        for (uint256 i = 0; i < issuerList.length; i++) {
            bytes32[] memory certs = certificatesByIssuer[issuerList[i]];
            for (uint256 j = 0; j < certs.length; j++) {
                if (
                    keccak256(bytes(certificates[certs[j]].recipientName)) ==
                    keccak256(bytes(_recipientName))
                ) {
                    matchCount++;
                }
            }
        }

        bytes32[] memory matches = new bytes32[](matchCount);
        uint256 index = 0;

        for (uint256 i = 0; i < issuerList.length; i++) {
            bytes32[] memory certs = certificatesByIssuer[issuerList[i]];
            for (uint256 j = 0; j < certs.length; j++) {
                if (
                    keccak256(bytes(certificates[certs[j]].recipientName)) ==
                    keccak256(bytes(_recipientName))
                ) {
                    matches[index++] = certs[j];
                }
            }
        }

        return matches;
    }
}
