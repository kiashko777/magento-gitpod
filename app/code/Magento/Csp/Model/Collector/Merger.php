<?php
/**
 * CSP Merger Implementation Compatibility Stub
 */
namespace Magento\Csp\Model\Collector;

class Merger implements MergerInterface
{
    /**
     * Merge CSP policies
     * @param array $policies
     * @return array
     */
    public function merge(array $policies): array
    {
        // Simple stub implementation
        $merged = [];
        foreach ($policies as $policy) {
            if (is_array($policy)) {
                $merged = array_merge_recursive($merged, $policy);
            }
        }
        return $merged;
    }
}