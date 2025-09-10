from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from app.database import get_db
from app.models.flow import Flow, FlowVersion
from app.services.prompt_flow_service import PromptFlowService
from pydantic import BaseModel

router = APIRouter()
flow_service = PromptFlowService()

class FlowCreate(BaseModel):
    name: str
    description: str = ""
    nodes: List[Dict[str, Any]]
    connections: List[Dict[str, Any]]

class FlowExecute(BaseModel):
    flow_id: int
    inputs: Dict[str, Any]

@router.post("/flows/")
async def create_flow(flow_data: FlowCreate, db: Session = Depends(get_db)):
    """Create a new prompt flow"""
    flow_config = await flow_service.create_flow_definition(
        flow_data.nodes, 
        flow_data.connections
    )
    
    # Validate flow
    validation = await flow_service.validate_flow(flow_config)
    if not validation["valid"]:
        raise HTTPException(status_code=400, detail=validation["errors"])
    
    # Save to database
    db_flow = Flow(
        name=flow_data.name,
        description=flow_data.description,
        flow_config={
            "nodes": flow_data.nodes,
            "connections": flow_data.connections,
            "pf_config": flow_config
        }
    )
    db.add(db_flow)
    db.commit()
    db.refresh(db_flow)
    
    return db_flow

@router.get("/flows/")
async def list_flows(db: Session = Depends(get_db)):
    """List all flows"""
    flows = db.query(Flow).all()
    return flows

@router.get("/flows/{flow_id}")
async def get_flow(flow_id: int, db: Session = Depends(get_db)):
    """Get a specific flow"""
    flow = db.query(Flow).filter(Flow.id == flow_id).first()
    if not flow:
        raise HTTPException(status_code=404, detail="Flow not found")
    return flow

@router.post("/flows/execute")
async def execute_flow(execute_data: FlowExecute, db: Session = Depends(get_db)):
    """Execute a flow with inputs"""
    flow = db.query(Flow).filter(Flow.id == execute_data.flow_id).first()
    if not flow:
        raise HTTPException(status_code=404, detail="Flow not found")
    
    # Execute flow
    result = await flow_service.execute_flow(
        flow.flow_config["pf_config"],
        execute_data.inputs
    )
    
    return result

@router.post("/flows/{flow_id}/versions")
async def create_flow_version(flow_id: int, version_data: dict, db: Session = Depends(get_db)):
    """Create a new version of a flow"""
    flow = db.query(Flow).filter(Flow.id == flow_id).first()
    if not flow:
        raise HTTPException(status_code=404, detail="Flow not found")
    
    # Create new version
    version = FlowVersion(
        flow_id=flow_id,
        version=version_data.get("version", "1.0"),
        flow_config=version_data.get("flow_config", flow.flow_config),
        metrics=version_data.get("metrics", {})
    )
    db.add(version)
    db.commit()
    db.refresh(version)
    
    return version

@router.get("/")
async def list_flows():
    return {"flows": [], "message": "Flow management endpoint"}
