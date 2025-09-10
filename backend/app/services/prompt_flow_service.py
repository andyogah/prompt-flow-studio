from typing import Dict, List, Any
import asyncio
import yaml
import tempfile
import os
from pathlib import Path

class PromptFlowService:
    def __init__(self):
        try:
            from promptflow import PFClient
            self.pf_client = PFClient()
        except ImportError:
            self.pf_client = None
            print("Warning: promptflow not installed, using mock execution")
    
    async def create_flow_definition(self, nodes: List[Dict], connections: List[Dict]) -> Dict:
        """Convert UI nodes/connections to Prompt Flow format"""
        flow_definition = {
            "nodes": self._convert_nodes(nodes),
            "node_variants": {},
            "environment_variables": {}
        }
        return flow_definition
    
    def _convert_nodes(self, ui_nodes: List[Dict]) -> List[Dict]:
        """Convert UI node format to Prompt Flow node format"""
        pf_nodes = []
        for node in ui_nodes:
            pf_node = {
                "name": node["id"],
                "type": node["type"],
                "source": {
                    "type": "code" if node["type"] == "python" else "package",
                    "path": node.get("source_path", "")
                },
                "inputs": node.get("inputs", {}),
                "use_variants": False
            }
            pf_nodes.append(pf_node)
        return pf_nodes
    
    async def execute_flow(self, flow_config: Dict, inputs: Dict) -> Dict:
        """Execute a flow with given inputs"""
        if not self.pf_client:
            # Mock execution for development
            return {
                "outputs": {"result": "Mock execution result"},
                "metrics": {"duration": 1.5, "tokens": 150}
            }
        
        try:
            # Create temporary flow directory
            with tempfile.TemporaryDirectory() as temp_dir:
                flow_path = Path(temp_dir) / "flow"
                flow_path.mkdir()
                
                # Write flow.dag.yaml
                flow_yaml = flow_path / "flow.dag.yaml"
                with open(flow_yaml, 'w') as f:
                    yaml.dump(flow_config, f)
                
                # Execute flow
                result = self.pf_client.test(flow=str(flow_path), inputs=inputs)
                return {
                    "outputs": result,
                    "metrics": {"duration": 1.0}  # Add actual metrics
                }
        except Exception as e:
            return {"error": str(e)}
    
    async def validate_flow(self, flow_config: Dict) -> Dict:
        """Validate flow configuration"""
        errors = []
        warnings = []
        
        # Basic validation
        if not flow_config.get("nodes"):
            errors.append("Flow must have at least one node")
        
        # Check for circular dependencies
        # Add more validation logic here
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings
        }
