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

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Not authorized issuer");
        _;
    }

    // Authorize issuer
    function authorizeIssuer(address _issuer) public onlyOwner {
        authorizedIssuers[_issuer] = true;
    }

    // Revoke issuer
    function revokeIssuer(address _issuer) public onlyOwner {
        authorizedIssuers[_issuer] = false;
    }

    // Issue a new certificate
    function issueCertificate(
        address recipient,
        string memory recipientName,
        string memory courseName,
        string memory issuingInstitution,
        uint256 issueDate,
        string memory certificateHash
    ) public onlyAuthorizedIssuer {
        bytes32 certId = keccak256(abi.encodePacked(recipient, certificateHash));
        certificates[certId] = Certificate(
            recipientName,
            courseName,
            issuingInstitution,
            issueDate,
            certificateHash,
            true
        );
        certificatesIssuedBy[msg.sender]++;
        certificatesByIssuer[msg.sender].push(certId);
    }

    // Revoke a certificate
    function revokeCertificate(bytes32 certId) public onlyAuthorizedIssuer {
        require(certificates[certId].issueDate > 0, "Certificate does not exist");
        certificates[certId].isValid = false;
    }

    // Get revoked certificates by a specific issuer
    function getRevokedCertificatesByIssuer(address _issuer) public view returns (bytes32[] memory) {
        bytes32[] memory allCerts = certificatesByIssuer[_issuer];
        uint256 count = 0;

        for (uint256 i = 0; i < allCerts.length; i++) {
            if (!certificates[allCerts[i]].isValid && certificates[allCerts[i]].issueDate > 0) {
                count++;
            }
        }

        bytes32[] memory revokedCerts = new bytes32[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allCerts.length; i++) {
            if (!certificates[allCerts[i]].isValid && certificates[allCerts[i]].issueDate > 0) {
                revokedCerts[index] = allCerts[i];
                index++;
            }
        }

        return revokedCerts;
    }

    // ✅ NEW FUNCTION: Get all certificates issued by an issuer
    function getCertificatesByIssuer(address _issuer) public view returns (bytes32[] memory) {
        return certificatesByIssuer[_issuer];
    }
}

