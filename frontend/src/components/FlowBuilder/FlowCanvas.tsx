import React, { useCallback, useState } from 'react';
import ReactFlow, {
  addEdge,
  useNodesState,
  useEdgesState,
  Connection,
  Edge,
  Node,
  ReactFlowProvider,
  Controls,
  Background,
  MiniMap,
} from 'reactflow';
import 'reactflow/dist/style.css';

import PromptNode from './nodes/PromptNode';
import LLMNode from './nodes/LLMNode';
import PythonNode from './nodes/PythonNode';
import { FlowToolbar } from './FlowToolbar';

const nodeTypes = {
  prompt: PromptNode,
  llm: LLMNode,
  python: PythonNode,
};

interface FlowCanvasProps {
  flowId?: number;
  onSave?: (nodes: Node[], edges: Edge[]) => void;
  onExecute?: (inputs: any) => void;
}

export const FlowCanvas: React.FC<FlowCanvasProps> = ({ flowId, onSave, onExecute }) => {
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);

  const onConnect = useCallback(
    (params: Connection) => setEdges((eds) => addEdge(params, eds)),
    [setEdges]
  );

  const addNode = useCallback((type: string) => {
    const newNode: Node = {
      id: `${type}-${Date.now()}`,
      type,
      position: { x: Math.random() * 400, y: Math.random() * 400 },
      data: {
        label: `${type} Node`,
        config: getDefaultNodeConfig(type),
      },
    };
    setNodes((nds) => nds.concat(newNode));
  }, [setNodes]);

  const getDefaultNodeConfig = (type: string) => {
    switch (type) {
      case 'prompt':
        return { template: 'Hello {{name}}!', variables: ['name'] };
      case 'llm':
        return { model: 'gpt-3.5-turbo', temperature: 0.7 };
      case 'python':
        return { code: 'def main(input):\n    return input' };
      default:
        return {};
    }
  };

  const handleSave = useCallback(() => {
    if (onSave) {
      onSave(nodes, edges);
    }
  }, [nodes, edges, onSave]);

  const handleExecute = useCallback(() => {
    if (onExecute) {
      // Collect inputs from input nodes
      const inputs = {}; // Extract from nodes
      onExecute(inputs);
    }
  }, [nodes, onExecute]);

  return (
    <div className="h-screen w-full">
      <FlowToolbar
        onAddNode={addNode}
        onSave={handleSave}
        onExecute={handleExecute}
      />
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        nodeTypes={nodeTypes}
        fitView
      >
        <Controls />
        <MiniMap />
        <Background variant="dots" gap={12} size={1} />
      </ReactFlow>
    </div>
  );
};

export default function FlowBuilderPage() {
  return (
    <ReactFlowProvider>
      <FlowCanvas />
    </ReactFlowProvider>
  );
}
