#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
from datetime import datetime
from typing import Dict, Any, List, Optional
from config.models import config

class AgentMemory:
    def __init__(self, memory_path: str = None):
        self.memory_path = memory_path or config.agent_memory_path
        self.memory = self._load_memory()
    
    def _load_memory(self) -> Dict[str, Any]:
        """Load memory from JSON file"""
        try:
            if os.path.exists(self.memory_path):
                with open(self.memory_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
        except Exception as e:
            print(f"Error loading memory: {e}")
        
        # Return default memory structure
        return {
            "interactions": [],
            "workflows": {},
            "site_data": {},
            "last_updated": datetime.now().isoformat()
        }
    
    def _save_memory(self):
        """Save memory to JSON file"""
        try:
            self.memory["last_updated"] = datetime.now().isoformat()
            with open(self.memory_path, 'w', encoding='utf-8') as f:
                json.dump(self.memory, f, indent=2)
        except Exception as e:
            print(f"Error saving memory: {e}")
    
    def store_interaction(self, interaction: Dict[str, Any]):
        """Store an interaction in memory"""
        if "interactions" not in self.memory:
            self.memory["interactions"] = []
        
        interaction["id"] = len(self.memory["interactions"]) + 1
        interaction["timestamp"] = datetime.now().isoformat()
        
        self.memory["interactions"].append(interaction)
        
        # Keep only last 1000 interactions
        if len(self.memory["interactions"]) > 1000:
            self.memory["interactions"] = self.memory["interactions"][-1000:]
        
        self._save_memory()
    
    def get_recent_interactions(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent interactions"""
        interactions = self.memory.get("interactions", [])
        return interactions[-limit:] if interactions else []
    
    def store_workflow_data(self, workflow_id: str, data: Dict[str, Any]):
        """Store workflow-specific data"""
        if "workflows" not in self.memory:
            self.memory["workflows"] = {}
        
        self.memory["workflows"][workflow_id] = {
            **data,
            "last_updated": datetime.now().isoformat()
        }
        self._save_memory()
    
    def get_workflow_data(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Get workflow data"""
        return self.memory.get("workflows", {}).get(workflow_id)