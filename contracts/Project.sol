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
            revokedCerts[index++] = allCerts[i];
        }
    }

    return revokedCerts;
}
