<?php
/**
 * OneDev_AdamVarga
 *
 * Copyright © 2024 - OneDev_AdamVarga. All rights reserved.
 * This file is part of a learning project created by Adam Varga for educational purposes.
 */

declare(strict_types=1);

namespace OneDev\TailwindHero\Controller\Index;

use Magento\Framework\App\Action\Context;
use Magento\Framework\View\Result\PageFactory;
use Magento\Framework\App\Action\Action;

class Index extends Action
{
    protected $resultPageFactory;

    public function __construct(Context $context, PageFactory $resultPageFactory)
    {
        $this->resultPageFactory = $resultPageFactory;
        parent::__construct($context);
    }

    public function execute()
    {
        return $this->resultPageFactory->create();
    }
}
