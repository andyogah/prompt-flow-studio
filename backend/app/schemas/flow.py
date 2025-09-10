from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from datetime import datetime

class NodeBase(BaseModel):
    id: str
    type: str
    position: Dict[str, float]
    data: Dict[str, Any]

class ConnectionBase(BaseModel):
    id: str
    source: str
    target: str
    sourceHandle: Optional[str] = None
    targetHandle: Optional[str] = None

class FlowBase(BaseModel):
    name: str
    description: Optional[str] = ""

class FlowCreate(FlowBase):
    nodes: List[NodeBase]
    connections: List[ConnectionBase]

class FlowUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    nodes: Optional[List[NodeBase]] = None
    connections: Optional[List[ConnectionBase]] = None

class FlowResponse(FlowBase):
    id: int
    flow_config: Dict[str, Any]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class FlowExecuteRequest(BaseModel):
    flow_id: int
    inputs: Dict[str, Any]

class FlowExecuteResponse(BaseModel):
    outputs: Dict[str, Any]
    metrics: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

class FlowVersionCreate(BaseModel):
    version: str
    flow_config: Dict[str, Any]
    metrics: Optional[Dict[str, Any]] = None

class FlowVersionResponse(BaseModel):
    id: int
    flow_id: int
    version: str
    flow_config: Dict[str, Any]
    metrics: Optional[Dict[str, Any]]
    created_at: datetime
    
    class Config:
        from_attributes = True
