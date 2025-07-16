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
    
    /**
     * @dev Issue a new digital certificate
     * @param _recipientName Name of the certificate recipient
     * @param _courseName Name of the course/program
     * @param _issuingInstitution Name of the issuing institution
     * @param _certificateHash Hash of the certificate document
     * @return certificateId The unique identifier for the certificate
     */
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
        
        emit CertificateIssued(
            certificateId,
            _recipientName,
            _courseName,
            _issuingInstitution,
            block.timestamp
        );
        
        return certificateId;
    }
    
    /**
     * @dev Verify the authenticity of a certificate
     * @param _certificateId The unique identifier of the certificate
     * @return isValid Whether the certificate is valid
     * @return recipientName Name of the certificate recipient
     * @return courseName Name of the course/program
     * @return issuingInstitution Name of the issuing institution
     * @return issueDate Timestamp when the certificate was issued
     */
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
    
    /**
     * @dev Revoke a certificate (mark as invalid)
     * @param _certificateId The unique identifier of the certificate to revoke
     */
    function revokeCertificate(bytes32 _certificateId) public onlyAuthorizedIssuer {
        require(certificates[_certificateId].issueDate > 0, "Certificate does not exist");
        require(certificates[_certificateId].isValid, "Certificate is already revoked");
        
        certificates[_certificateId].isValid = false;
        
        emit CertificateRevoked(_certificateId);
    }
    
    /**
     * @dev Authorize a new issuer (only owner)
     * @param _issuer Address of the issuer to authorize
     */
    function authorizeIssuer(address _issuer) public onlyOwner {
        require(_issuer != address(0), "Invalid issuer address");
        require(!authorizedIssuers[_issuer], "Issuer already authorized");
        
        authorizedIssuers[_issuer] = true;
        
        emit IssuerAuthorized(_issuer);
    }
    
    /**
     * @dev Revoke issuer authorization (only owner)
     * @param _issuer Address of the issuer to revoke
     */
    function revokeIssuer(address _issuer) public onlyOwner {
        require(_issuer != owner, "Cannot revoke owner");
        require(authorizedIssuers[_issuer], "Issuer not authorized");
        
        authorizedIssuers[_issuer] = false;
        
        emit IssuerRevoked(_issuer);
    }
    
    /**
     * @dev Get certificate details by ID
     * @param _certificateId The unique identifier of the certificate
     * @return Certificate details
     */
    function getCertificate(bytes32 _certificateId)
        public
        view
        returns (Certificate memory)
    {
        require(certificates[_certificateId].issueDate > 0, "Certificate does not exist");
        return certificates[_certificateId];
    }
}
