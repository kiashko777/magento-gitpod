<?php
/**
 * CSP Merger Interface Compatibility Stub
 */
namespace Magento\Csp\Model\Collector;

interface MergerInterface
{
    /**
     * Merge CSP policies
     * @param array $policies
     * @return array
     */
    public function merge(array $policies): array;
}