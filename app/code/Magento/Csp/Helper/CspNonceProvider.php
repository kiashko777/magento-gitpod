<?php
/**
 * CSP Nonce Provider Compatibility Stub
 * This is a compatibility stub for Hyva theme
 */
namespace Magento\Csp\Helper;

class CspNonceProvider
{
    /**
     * Generate nonce
     * @return string
     */
    public function generateNonce(): string
    {
        return base64_encode(random_bytes(16));
    }

    /**
     * Get nonce
     * @return string
     */
    public function getNonce(): string
    {
        return $this->generateNonce();
    }
}