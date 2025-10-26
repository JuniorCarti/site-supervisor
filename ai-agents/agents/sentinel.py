
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import requests
import json
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime
from openai import OpenAI
from config.models import config
from .memory import AgentMemory

# Set up logging
logging.basicConfig(level=config.log_level)
logger = logging.getLogger(__name__)

class SiteSupervisorAgent:
    def __init__(self, memory: AgentMemory):
        self.memory = memory
        self.client = OpenAI(api_key=config.openai_api_key)
        
        self.n8n_config = {
            'webhook_url': config.n8n_webhook_url,
            'api_key': config.n8n_api_key
        }
        
        logger.info(f"SiteSupervisorAgent initialized with model: {config.openai_model}")
    
    def _call_model(self, prompt: str, system_message: str = None) -> str:
        """Call OpenAI model with proper error handling"""
        messages = []
        
        if system_message:
            messages.append({"role": "system", "content": system_message})
        
        messages.append({"role": "user", "content": prompt})
        
        try:
            response = self.client.chat.completions.create(
                model=config.openai_model,
                messages=messages,
                temperature=config.temperature,
                max_tokens=config.max_tokens,
                timeout=config.timeout
            )
            
            content = response.choices[0].message.content
            logger.info(f"OpenAI API call successful. Tokens used: {response.usage.total_tokens}")
            return content
            
        except Exception as e:
            error_msg = f"Error calling OpenAI API: {str(e)}"
            logger.error(error_msg)
            return error_msg
    
    def analyze_site_data(self, site_data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze construction site data"""
        system_message = """You are SiteSupervisor AI, an expert construction site monitoring assistant. 
        Your role is to analyze site data, identify issues, and provide actionable recommendations.
        
        Always respond in this JSON format:
        {
            "safety_analysis": {"issues": [], "risk_level": "low|medium|high", "recommendations": []},
            "progress_analysis": {"status": "behind|on_track|ahead", "completion_estimate": "", "bottlenecks": []},
            "resource_analysis": {"equipment_issues": [], "staffing_issues": [], "material_issues": []},
            "overall_risk_score": 0-10,
            "priority_actions": []
        }"""
        
        prompt = f"""
        Analyze this construction site data and provide a comprehensive assessment:
        
        SITE DATA:
        {json.dumps(site_data, indent=2)}
        
        Please provide a thorough analysis covering:
        1. Safety compliance and potential hazards
        2. Project progress against timeline
        3. Resource allocation and utilization
        4. Identified risks and mitigation strategies
        5. Priority actions for site management
        
        Be specific, actionable, and professional in your assessment.
        """
        
        start_time = datetime.now()
        analysis_text = self._call_model(prompt, system_message)
        processing_time = (datetime.now() - start_time).total_seconds()
        
        try:
            # Try to parse JSON response
            analysis_data = json.loads(analysis_text)
        except json.JSONDecodeError:
            # If not JSON, structure the text response
            analysis_data = {
                "analysis": analysis_text,
                "format_warning": "Response was not in expected JSON format"
            }
        
        result = {
            "analysis": analysis_data,
            "metadata": {
                "processing_time_seconds": processing_time,
                "model_used": config.openai_model,
                "timestamp": datetime.now().isoformat()
            }
        }
        
        # Store in memory
        self.memory.store_interaction({
            "type": "site_analysis",
            "input": site_data,
            "output": result,
            "processing_time": processing_time
        })
        
        return result
    
    def process_n8n_data(self, n8n_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process data received from n8n webhook"""
        try:
            action = n8n_data.get('action', 'analyze')
            site_data = n8n_data.get('data', {})
            workflow_id = n8n_data.get('workflow_id', 'unknown')
            
            logger.info(f"Processing n8n request: action={action}, workflow_id={workflow_id}")
            
            if action == 'analyze':
                result = self.analyze_site_data(site_data)
            elif action == 'inspect':
                result = self.perform_site_inspection(site_data)
            elif action == 'report':
                result = self.generate_daily_report(site_data)
            else:
                result = {'error': f'Unknown action: {action}'}
            
            # Store workflow interaction
            self.memory.store_workflow_data(workflow_id, {
                "last_action": action,
                "last_processed": datetime.now().isoformat(),
                "input_data": site_data
            })
            
            return result
            
        except Exception as e:
            error_msg = f"Error processing n8n data: {str(e)}"
            logger.error(error_msg)
            return {'error': error_msg}
    
    def perform_site_inspection(self, inspection_data: Dict[str, Any]) -> Dict[str, Any]:
        """Perform detailed site inspection analysis"""
        system_message = """You are a construction site safety inspector. Analyze inspection data 
        and provide detailed safety assessments and compliance checks."""
        
        prompt = f"""
        Perform a comprehensive safety inspection analysis:
        
        INSPECTION DATA:
        {json.dumps(inspection_data, indent=2)}
        
        Provide detailed safety assessment including compliance status, violations found, 
        and corrective actions required.
        """
        
        analysis = self._call_model(prompt, system_message)
        
        return {
            "inspection_report": analysis,
            "timestamp": datetime.now().isoformat()
        }
    
    def generate_daily_report(self, daily_data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate daily site report"""
        system_message = """You are a construction project manager. Generate comprehensive 
        daily reports summarizing site progress, issues, and next steps."""
        
        prompt = f"""
        Generate a professional daily construction report:
        
        DAILY DATA:
        {json.dumps(daily_data, indent=2)}
        
        Include: work completed, workforce present, issues encountered, safety observations, 
        and plan for next day.
        """
        
        report = self._call_model(prompt, system_message)
        
        return {
            "daily_report": report,
            "report_date": datetime.now().isoformat(),
            "generated_by": "SiteSupervisor AI"
        }
    
    def trigger_n8n_workflow(self, workflow_data: Dict[str, Any]) -> bool:
        """Trigger an n8n workflow from the agent"""
        try:
            if not self.n8n_config['webhook_url']:
                logger.warning("No n8n webhook URL configured")
                return False
            
            headers = {
                'Content-Type': 'application/json',
                'X-N8N-API-KEY': self.n8n_config.get('api_key', '')
            }
            
            response = requests.post(
                self.n8n_config['webhook_url'],
                json=workflow_data,
                headers=headers,
                timeout=30
            )
            
            success = response.status_code == 200
            if success:
                logger.info(f"Successfully triggered n8n workflow")
            else:
                logger.error(f"Failed to trigger n8n workflow: {response.status_code}")
            
            return success
            
        except Exception as e:
            logger.error(f"Error triggering n8n workflow: {e}")
            return False
