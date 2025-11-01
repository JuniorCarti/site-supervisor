#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import requests
import json
import logging
from typing import Dict, Any, List, Optional
from config.models import config

logger = logging.getLogger(__name__)

class N8NIntegration:
    def __init__(self):
        self.base_url = config.n8n_base_url
        self.api_key = config.n8n_api_key
        
    def get_workflows(self) -> List[Dict[str, Any]]:
        """Get list of all n8n workflows"""
        try:
            headers = {'X-N8N-API-KEY': self.api_key}
            response = requests.get(f'{self.base_url}/rest/workflows', headers=headers, timeout=10)
            
            if response.status_code == 200:
                return response.json().get('data', [])
            else:
                logger.error(f"Failed to get workflows: {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"Error getting workflows: {e}")
            return []
    
    def execute_workflow(self, workflow_id: str, data: Dict[str, Any]) -> bool:
        """Execute a specific n8n workflow"""
        try:
            headers = {
                'X-N8N-API-KEY': self.api_key,
                'Content-Type': 'application/json'
            }
            
            payload = {
                'workflow_id': workflow_id,
                'data': data
            }
            
            response = requests.post(
                f'{self.base_url}/rest/workflows/{workflow_id}/run',
                json=payload,
                headers=headers,
                timeout=30
            )
            
            success = response.status_code == 200
            if success:
                logger.info(f"Successfully executed workflow {workflow_id}")
            else:
                logger.error(f"Failed to execute workflow {workflow_id}: {response.status_code}")
            
            return success
            
        except Exception as e:
            logger.error(f"Error executing workflow: {e}")
            return False
    
    def test_connection(self) -> bool:
        """Test connection to n8n instance"""
        try:
            headers = {'X-N8N-API-KEY': self.api_key}
            response = requests.get(f'{self.base_url}/rest/health', headers=headers, timeout=10)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"n8n connection test failed: {e}")
            return False