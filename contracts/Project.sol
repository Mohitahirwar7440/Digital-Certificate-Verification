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
    mapping(address => uint256) public certificatesIssuedBy; // 🔹 Track issuer's certificate count

    address public owner;
    uint256 public totalCertificates;

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

        emit IssuerAuthorized(_issuer);
    }

    function revokeIssuer(address _issuer) public onlyOwner {
        require(_issuer != owner, "Cannot revoke owner");
        require(authorizedIssuers[_issuer], "Issuer is not authorized");

        authorizedIssuers[_issuer] = false;

        emit IssuerRevoked(_issuer);
    }

    // 🔹 New function: Get number of certificates issued by an address
    function getCertificatesIssuedBy(address _issuer) public view returns (uint256) {
        return certificatesIssuedBy[_issuer];
    }
}
