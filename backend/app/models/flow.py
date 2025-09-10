from sqlalchemy import Column, Integer, String, Text, DateTime, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class Flow(Base):
    __tablename__ = "flows"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(Text)
    flow_config = Column(JSON)  # stores nodes and connections
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    versions = relationship("FlowVersion", back_populates="flow")

class FlowVersion(Base):
    __tablename__ = "flow_versions"
    
    id = Column(Integer, primary_key=True, index=True)
    flow_id = Column(Integer, ForeignKey("flows.id"))
    version = Column(String)
    flow_config = Column(JSON)
    metrics = Column(JSON)  # execution metrics
    created_at = Column(DateTime, default=datetime.utcnow)
    
    flow = relationship("Flow", back_populates="versions")
