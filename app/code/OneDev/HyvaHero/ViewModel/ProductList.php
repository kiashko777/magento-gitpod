<?php
/**
 * OneDev_AdamVarga
 *
 * Copyright © 2024 - OneDev_AdamVarga. All rights reserved.
 * This file is part of a learning project created by Adam Varga for educational purposes.
 */

declare(strict_types=1);

namespace OneDev\HyvaHero\ViewModel;

use Magento\Catalog\Model\ResourceModel\Product\CollectionFactory as ProductCollectionFactory;
use Magento\Framework\View\Element\Block\ArgumentInterface;

class ProductList implements ArgumentInterface
{
    public function __construct(private readonly ProductCollectionFactory $productCollectionFactory)
    {
    }

    /**
     * Get a collection of 4 products
     */
    public function getProducts(): \Magento\Catalog\Model\ResourceModel\Product\Collection
    {
        $collection = $this->productCollectionFactory->create();
        $collection->addAttributeToSelect('*');
        $collection->setPageSize(4); // Limit to 4 products

        return $collection;
    }
}
