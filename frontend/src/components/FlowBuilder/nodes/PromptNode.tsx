import React, { useState } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';

interface PromptNodeData {
  label: string;
  config: {
    template: string;
    variables: string[];
  };
}

const PromptNode: React.FC<NodeProps<PromptNodeData>> = ({ data, selected }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [template, setTemplate] = useState(data.config.template);

  const handleDoubleClick = () => {
    setIsEditing(true);
  };

  const handleSave = () => {
    // Update node data
    data.config.template = template;
    setIsEditing(false);
  };

  return (
    <div
      className={`px-4 py-2 shadow-md rounded-md border-2 bg-white ${
        selected ? 'border-blue-500' : 'border-gray-200'
      }`}
      onDoubleClick={handleDoubleClick}
    >
      <Handle
        type="target"
        position={Position.Top}
        className="w-3 h-3 !bg-teal-500"
      />
      
      <div className="flex flex-col">
        <div className="font-bold text-sm text-gray-700 mb-2">
          {data.label}
        </div>
        
        {isEditing ? (
          <div className="min-w-[300px]">
            <textarea
              value={template}
              onChange={(e) => setTemplate(e.target.value)}
              className="w-full p-2 border rounded text-sm"
              rows={4}
              placeholder="Enter your prompt template..."
            />
            <div className="flex gap-2 mt-2">
              <button
                onClick={handleSave}
                className="px-3 py-1 bg-blue-500 text-white rounded text-xs"
              >
                Save
              </button>
              <button
                onClick={() => setIsEditing(false)}
                className="px-3 py-1 bg-gray-300 rounded text-xs"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <div className="text-xs text-gray-600 max-w-[200px] truncate">
            {template}
          </div>
        )}
        
        <div className="text-xs text-gray-500 mt-1">
          Variables: {data.config.variables.join(', ')}
        </div>
      </div>

      <Handle
        type="source"
        position={Position.Bottom}
        className="w-3 h-3 !bg-teal-500"
      />
    </div>
  );
};

export default PromptNode;
